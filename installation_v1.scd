
var isAlive, click;

Server.default.waitForBoot({

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

})