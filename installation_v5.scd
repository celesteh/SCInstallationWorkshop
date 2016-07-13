
var isAlive, click, alive_file, read_config, config, boot, max_silence_in_seconds, last_rms_time, port, load_synths;

// Get arguments , read config file
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

port = thisProcess.argv[1];
Server.default = Server(\Local, NetAddr("localhost", port.asInteger));
s = Server.default;
port.postln;


boot = { |doClick=false|
	var condition, bundle;

	"entering boot".postln;

	condition = Condition(false);

	Server.default.boot(onFailure:{});
	0.1.wait;
	Server.default.doWhenBooted(limit: 5000, onFailure:{1.exit}, // long limit
		onComplete: {
			condition.test = true;
			condition.signal;
	});

	condition.wait;
	doClick.if({
		click.();
	});
	"leaving boot".postln;
};

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

click = {
	isAlive = 3;
	"touch %".format(alive_file).postln.unixCmd;
};


click.value;
max_silence_in_seconds = 10; // for example


{ //watchdog
	10.wait; // give us a bit to get going
	while {true} {
		2.wait; // lengthened for demo reasons
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


	}
}.fork;




Task({
	var syn, lastrms, osc_listener;


	boot.(true);

	load_synths.();

	Server.default.sync;

	//syn = Synth(\stereoListenForSilence,  nil, RootNode(Server.default), \addToTail);

	lastrms=Array.fill(max_silence_in_seconds, {1});
	osc_listener = OSCFunc({ |msg, time|
		var rms;
		last_rms_time = time;
		rms = msg[4].asFloat.max(msg[6].asFloat);
		lastrms.removeAt(0);
		lastrms.add(rms);
		(lastrms.sum <= 0.0001).if ({
			"too quiet".postln;
			{
				load_synths.();
				p.resume; // Be careful of duplicating stuff from the watchdog thread
				lastrms=Array.fill(max_silence_in_seconds, {1}); // reset
			}.fork;
		});
	}, '/loudnessMonitoringForInstallation');


	p = Pseq([
		Pbind(
			\instrument, \long,
			\scale, Scale.choose,
			\degree, Pwhite(0, 7, 5),
			\dur, 0.2,
			\isalive, Pfunc({click.()})
		),
		Pbind(
			\instrument, \long,
			\scale, Scale.choose,
			\degree, Pwhite(0, 7, 5),
			\dur, 0.5,
			\isalive, Pfunc({click.()})
		)], 1
	).play;

}).play