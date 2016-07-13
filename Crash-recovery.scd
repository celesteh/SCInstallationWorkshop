/*
Things that can (and will!) crash:
Your operating system
your helper programs
scserver
SCIDE
sclang
your program
your thread(s) in scserver
your running synth

Eliminate everything uncessary!

Test that things are still running
Try to recover if they've crashed

*/

// Synths

// Has your synth died/ blown up?
// If it's a short synth, maybe this doesn't matter.
// Is it a longer-running synth? We can listen for silence
// (If it's a long running synth that outputs silence on purpose, consider shorter synths with pauses between starting them.)

SynthDef(\stereoListenForSilence, {|in=0, out=0|
	var input;
	input = In.ar(in, Server.default.options.numOutputBusChannels);
	SendPeakRMS.kr(input, 1, 3, '/loudnessMonitoringForInstallation');
	ReplaceOut.ar(out, LeakDC.ar(input).tanh); //Limiter
}).add;


(

var syn, lastrms, max_silence_in_seconds;

syn = Synth(\stereoListenForSilence,  nil, RootNode(Server.default), \addToTail);

max_silence_in_seconds = 10; // for example

lastrms=Array.fill(max_silence_in_seconds, {1});
osc_listener = OSCFunc({ |msg|
	var rms;
	rms = msg[4].asFloat.max(msg[6].asFloat);
	lastrms.removeAt(0);
	lastrms.add(rms);
	(lastrms.sum <= 0.0001).if ({
		"too quiet".postln;
		/* Do something to recover: like start a new synth, set a flag for your main thread, etc */
	});
}, '/loudnessMonitoringForInstallation');

)





// Threads

// Is your Pbind or thread or whatever still running?

// Set a variable and then use another thread to check that variable
// This new thread desn't have a name, but when we're talking about it, we'll refer to it as the watchdog thread.


(
var isAlive;

isAlive = 3;

{
	while {true} {
		5.wait;
		isAlive = isAlive -1;

		if(isAlive <= 0) { /* do something like try to restart the thread or just quit out of sclang */
			"Not alive!".postln;
			p.resume
		}
	}
}.fork;

p = Pbind(
	\isalive, Pfunc({isAlive = 3})
).play;

)


// just for example purposes:
p.stop



//--

// We can keep trying more extreme ways to recover

(
var isAlive;

isAlive = 3;

{
	while {true} {
		5.wait; // adjust as appropriate
		isAlive = isAlive -1;


		case
		{isAlive ==0} {
			"Not alive!".postln;
			p.resume
		}
		{isAlive == -1} {
			"uhoh".postln;
			p.start
		}
		{isAlive == -2} {
			"last chance".postln;
			p.reset;
			p.start;
		}
		{isAlive < -2} {
			"give up!".postln;
			1.exit
		}

	}
}.fork;

p = Pbind(
	\degree, Pwhite(0, 7, 5),
	\isalive, Pfunc({isAlive = 3})
).play;

)

// if your main thread does a lot of things, it might be better to make a single function in charge of saying you're still alive.
// Call that function every so often from different points in your thread

(
var isAlive, click;

click = { isAlive = 3};
click.value;

{
	while {true} {
		2.wait; // adjust as appropriate
		isAlive = isAlive -1;


		case
		{isAlive ==0} {
			"Not alive!".postln;
			p.resume
		}
		{isAlive == -1} {
			"uhoh".postln;
			p.start
		}
		{isAlive == -2} {
			"last chance".postln;
			p.reset;
			p.start;
		}
		{isAlive < -2} {
			"give up!".postln;
			1.exit
		}


	}
}.fork;

p = Pseq([
	Pbind(
		\scale, Scale.choose,
		\degree, Pwhite(0, 7, 5),
		\dur, 0.2,
		\isalive, Pfunc(click)
	),
	Pbind(
		\scale, Scale.choose,
		\degree, Pwhite(0, 7, 5),
		\dur, 0.5,
		\isalive, Pfunc(click)
	)], 1
).play;

)



// What if all your threads freeze, including the watchdog one?

// Modify click so it creates a file:

click = {
	isAlive = 3;
	"touch %".format(alive_file).postln.unixCmd;
}

// We'll need a process OUTSIDE of SuperCollider, checking if that file exists




// sclang / SCIDE

// We don't need SCIDE. We're not going to use it.
// Instead, we'll make a bash script to start our installation and to check on things.

// Let's call this file installation_v1.sh

#!/bin/bash

while :
    do
        sclang installation_v1.scd
        sleep 5
done

// Once you've created that file, you'll need to open a terminal, cd to the directory that it's in and run
% chmod +x installation.sh

// What it does:
// In an infinte loop, it runs your instalation. When that crashes, it sleeps for 5 seconds and starts again

// To test this, go to your system monitor app and kill sclang


// To stop everything for real, kill installation_v1.sh and then sclang

// What about that file we were going to check?

// we'll use a second script called keepAlive_v2.sh

#!/bin/bash

sleep_time=120 #2 minutes
alive=/tmp/installation

rm $alive

sleep $sleep_time

while :
    do

        if [ ! -f $alive ]; then
            echo "File not found! - installation_v2.scd has not checked in and must be hung"
            kill $1
            exit 0
        else

            rm $alive
        fi

        sleep $sleep_time

done

//And we'll need to modify the main bash script, which we'll now call installation_v2.sh

#!/bin/bash

while :
    do
        sclang installation_v2.scd &
        pid=$!

        ./keepAlive_v2.sh $pid &
        alive_pid=$!

        wait $pid
        kill $alive_pid

        sleep 5
done


// both of these scripts need to be made executeable
% chmod +x installation_v2.sh
% chmod +x keepAlive_v2.sh

// Note that in keepAlive_v2.sh, it check every 2 minutes that the file exists.  You can change that duration.
// It should be LONGER than it takes for all the different restart methods in your watchdog sc thread.



// This file is going to be a resource shared across two different programs in two different languages. If we change it one place, it needs to also change in another place.

// We can create a shared configuration file
// it should look like
# This line is a commment
item=value

// This file format is good because it can be read by bash, supercollider, python and many other languages
read_config = {
	var config_path, config_arr, server_port, bad_file, tweet_arr, options;

	config = IdentityDictionary.new;

	config_path = thisProcess.argv[0];
	config_path.postln;

	File.exists(config_path).if ({
		config_arr = FileReader.read(config_path, true, true, delimiter: $=);
		config_arr.do({|pair|
			(pair.size == 2).if ({ // only get get pairs
				config.put(pair[0].asSymbol, pair[1]);
				pair.postln;
			})
		});
	});

	alive_file = config[\alive];

};

read_config.();


// Note the thisProcess.argv. We're going to give the config file as a command line argument to your program.
// Let's call it installation_v3.config
// And put in it:

#files
alive=/tmp/stillAlive

// Then change out installation_v3.sh to pass it in as an argument:
        sclang installation_v3.scd installation_v3.config &



// Including it in the keppAlive bash file means adding a line near the top:
. installation_v3.config



// Server!
// What if the server hangs?

// We need a way of telling the server to boot that also checks if it fails to boot

boot = { |doClick=false|
	var condition, bundle;

	"entering boot".postln;

	condition = Condition(false);

	Server.default.boot(onFailure:{});
	0.1.wait;
	Server.default.doWhenBooted(limit: 5000, onFailure:{1.exit}, // long limit
		onComplete: {
			//Server.default.sync(condition);


			condition.test = true;
			condition.signal;
	});

	condition.wait;
	doClick.if({
		click.();
	});
	"leaving boot".postln;
};


// We can use the OSC messaging near the very top of this file to see if sound is still coming out and booting if necessary. Let's also keep track of the last time we received an OSC message.

	osc_listener = OSCFunc({ |msg, time|
		var rms;
		last_rms_time = time;
		rms = msg[4].asFloat.max(msg[6].asFloat);
		lastrms.removeAt(0);
		lastrms.add(rms);
		(lastrms.sum <= 0.0001).if ({
			"too quiet".postln;
			{
				boot.(); // restart server if it's stopped
				p.resume; // Be careful of duplicating stuff from the watchdog thread
			}.fork;
		});
	}, '/loudnessMonitoringForInstallation');


// It's not (very) feasible to have the Pbin reboot the server, but we can use the watchdog function to see if it's been a long time since we last got an OSC message

{ //watchdog
	while {true} {
		20.wait; // lengthened for demo reasons
		isAlive = isAlive -1;


		case
		{isAlive ==0} {
			"Not alive!".postln;
			p.notNil.if({
				p.resume
			})
		}
		{isAlive == -1} {
			"uhoh".postln;
			p.notNil.if({
				p.start
			})
		}
		{isAlive == -2} {
			"last chance".postln;
			p.notNil.if({
				p.reset;
				p.start;
			})
		}
		{isAlive < -2} {
			"give up!".postln;
			1.exit
		};

		// and check the server
		last_rms_time.notNil.if({
			((Date.gmtime().rawSeconds - last_rms_time).abs > 10).if({ // has it been longer than 10 seconds?
				boot.();
			})
			}, { // or never??
				boot.();
		});


	}
}.fork;

// Note the doClick argument to boot. It's very important that we never call click from our watchdog thread.


// We could use a variable to check if last_rms_time stays nil across multiple attempts to boot and quit sclang if it fails

// the boot function will quit sclang if booting fails.
// however, when the server won't boot, it's rarely sclang that's the problem
// Often it's because a previous server crash is clinging to a port or other resource

// possible solutions:
// open jack from the script. If jack fails, reboot the computer.
// We can do this in bash with the || operator
// ex:  command1 || command 2
// command2 is only executed if command1 fails
// In the following line, we try to open jack twice. If it fails the second time, the system reboots:
( jackd -T -p 32 -d alsa -d hw:0,0 -r 44100 -p 1024 -n3  -s -i 0 -P || ( killall jackd ; sleep 10 ; jackd -T -p 32 -d alsa -d hw:0,0 -r 44100 -p 1024 -n3  -s -i 0 -P || sudo shutdown -r now )) &

// you would need to modify this line to reflect your system configuration

// Other ways to check the server:
// Increment the server port every time we restart sclang

// We'll need to take another argument to our program and tell the server to use it.
port = thisProcess.argv[1];
Server.default = Server(\Local, NetAddr("localhost", port.asInteger));
s = Server.default;

// and have our script keep track of the port number
#!/bin/bash

port=57110

while :
    do
        sclang installation_v5.scd installation_v5.config $port&
        pid=$!

        ./keepAlive_v5.sh $pid &
        alive_pid=$!

        wait $pid
        kill $alive_pid

        sleep 5
        port=$((port+1))
done

// We also need to make sure that all our synths get reloaded if we do have a server crash and reboot

//This calls for a new function:

load_synths = {
	SynthDef(\stereoListenForSilence, {|in=0, out=0|
		var input;
		input = In.ar(in, Server.default.options.numOutputBusChannels);
		SendPeakRMS.kr(input, 1, 3, '/loudnessMonitoringForInstallation');
		ReplaceOut.ar(out, LeakDC.ar(input).tanh); //Limiter
	}).add;

	SynthDef(\long, {|out=0, amp=0.2, freq=440, dur=1, pan=0|

		var env, sin, panner;
		env = EnvGen.kr(Env.sine(dur), timeScale:10, doneAction:2);
		sin = SinOsc.ar(freq, 0, amp);
		panner = Pan2.ar(sin, pan, env);
		Out.ar(out, panner);
	}).add;

	Server.default.sync;
	Synth(\stereoListenForSilence,  nil, RootNode(Server.default), \addToTail);
};

// which we'll call from our watchdog thread:

		// and check the server
		last_rms_time.notNil.if({
			((Date.gmtime().rawSeconds - last_rms_time).abs > 10).if({
				"no rms".postln;
				boot.();
				load_synths.();
			})
			}, {
				"never rms".postln;
				boot.();
				load_synths.();
		});
