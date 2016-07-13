
var isAlive, click, alive_file, read_config, config;

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

click = {
	isAlive = 3;
	"touch %".format(alive_file).postln.unixCmd;
};


click.value;


Server.default.waitForBoot({


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

})