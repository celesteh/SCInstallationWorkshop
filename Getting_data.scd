/*
Generally, there are a fee ways your installation can get data in:
It can use
MIDI
OSC
Read a file
Read a pipe
or HID
*/

// MIDI and OSC are very well documented, so we won't cover how to do them here.

// OSC is especially great, a lot of physical devices support it.
// If you can't access a device via SuperCollider, you can probably find (or possibly write) a helper app that translates it to OSC.
// Upsides: Easy, fast
// Downsides: Relies on a network or helper app, both of which are potentially unreliable

// Reading a file
// If you have a lot of data or need something to stick around between reboots, a file can be a good way to store data
// SC can read XML files
// Upsides: persistent, can also store waveforms and audio, good for large amounts of data
// Downsides: slow, doesn't know when to read, formatting can be slightly fiddly

// Reading a pipe
// This is when you call a 3rd party app to do something for you and it generates some text or otherwise.
// Upsides: Easy if you know some text commands, if the other program crashes you return to the sc thread immediately
// Downsides: Also potentially fiddly. Creates extra requirements for any system you want to run your installation on

// HID
// A widely supported format for a lot of consumer-level devices that your users will probably recognise and have an idea how to use.
// If you are building a sensor and want to get at the data very easily, HID chips are cheaper than arduinos and very widely supported. They are surperior if you just want to read input.
// Upsides: Lots of devices, good resolution, fast, cross-platform
// Downsides: Not great for really data-heavy stuff like video



// build the device list:
GeneralHID.buildDeviceList; // this is asynchronous

GeneralHID.postDevices;

// if you don't see anything, wait and try posting again


// get the device list:
d = GeneralHID.deviceList;

// which device is your joy stick?  Open that one:

// ex post window ouput:

HID devices at your disposal:
	0:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event0"]
	1:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event1"]
	2:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event10"]
	3:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event11"]
	4:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event12"]
	5:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event13"]
	6:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event14"]
	7:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event15"]
	8:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event16"]
	9:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event17"]
	10:	[GreenAsia Inc.      USB  Joystick  ], vendor: 3727, product: 18, locID: ["usb-0000:00:1d.0-1.2/input0"], path: ["/dev/input/event18"]
	11:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event2"]
	12:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event3"]
	13:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event4"]
	14:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event5"]
	15:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event6"]
	16:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event7"]
	17:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event8"]
	18:	[could not open device], vendor: 0, product: 0, locID: ["0"], path: ["/dev/input/event9"]



// open the joystick:
a = GeneralHID.open( d[10] );

// get info:
a.info;

// access the slots:
a.slots;

// HID slots are any data-creating part of an HID, so it could be an axis of a joystick, a button, a fader, etc

// post a readable list:
a.caps;

// debug: check incoming data:
a.debug_(true);


// stop debugging:
a.debug_(false);

// make a GUI

a.makeGui;

// the GUI and the debug mode are good ways to figure out what part of the stick has what ID

//You'll note that with my joystick, the buttons and sticks are in separate groups.  Buttons are in group one. The stick and 'hat' are in group 3.

//These items are called slots.  We can access them via two dimensional arrays.

a.slots[1][0].debug = true;
//Gives us debug information for the first button.

//We can get the button's state
a.slots[1][0].value;

//Or with the X axis of the stick:
a.slots[3][0].value;

//We can also set an action:
a.slots[3][0].action = {|slot| slot.value.postln; }


// to start polling the device, start the event loop:
GeneralHID.startEventLoop



// when we're done
GeneralHID.stopEventLoop


// Ok what about finding a joystick again and again, non-interactively?

(
var joystick, spec

GeneralHID.buildDeviceList.do({ arg dev, num;

	var name;

	name = dev[1].name;
	(name.asString.contains("Joystick")).if ({

		joystick = GeneralHID.open( dev);
	})

});


spec = GeneralHIDSpec.new(joystick);

spec.add(\b1,	[1,288]); // figure these out via the gui
spec.add(\b2,	[1,289]); // they won't change if you keep using the same joystick and OS
spec.add(\b3,	[1,290]); // If you switch operating systems, they WILL change
spec.add(\b4,	[1,291]);
spec.add(\b5,	[1,292]);
spec.add(\b6,	[1,293]);
spec.add(\b7,	[1,294]);
spec.add(\b8,	[1,295]);
spec.add(\b9,	[1,296]);
spec.add(\b10,	[1,297]);
spec.add(\hat,	[3,17]);
spec.add(\lx,	[3,0]);
spec.add(\ly,	[3,1]);
spec.add(\rx,	[3,5]);
spec.add(\ry,	[3,2]);

GeneralHID.startEventLoop;

spec[\b8].action_({|val|
	(val.value !=0).if({ // the item passed in has a value parameter
		// 1 is pressed down, 0 is let up
		Event.new.play
	})
});

spec[\rx].action_({|val| val.value.postln; });

)