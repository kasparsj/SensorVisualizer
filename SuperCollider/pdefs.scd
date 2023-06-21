(
Pdef(\motionGrains, Pspawn(Pbind(
	\pattern, Pfunc {
		var instruments = [\motion1];
		var dur = rrand(0.01, 3.0);
		//var pan = [-1, 1].scramble;
		var pan = rrand(-1.0, 1.0);
		Pbind(
			\instrument, instruments.choose,
			\dur, Pseq([dur], 1),
			\pan, pan,
			// \amp, 0.2,
			\amp, 0.5,
		)
	},
	// \delta, Pwhite(32, 128, inf) * 0.00125,
	\delta, Pwhite(32, 128, inf) * 0.0125,
	\method, \par
)));
//Pdef(\motionGrains).play;
//Pdef(\motionGrains).stop;

Pdef(\snare, Pbind(
	\instrument, \plaits_snare,
	\dur, Pseq([10.0], 1),
	\amp, 1.0,
	\harm, 0.25,
	\midinote, 47,
	\revtime, 0.9,
));
//Pdef(\snare).play;

Pdef(\snare_final, Pbind(
	\instrument, \plaits_snare,
	\dur, Pseq([10.0], 1),
	\amp, 1.3,
	\harm, 0.25,
	\midinote, [40, 47, 54],
	\revtime, 0.9,
));
//Pdef(\snare_final).play;

Pdef(\snare2, Pbind(
	\instrument, \plaits_snare,
	\dur, 1.5,
	\amp, 1.1,
	\harm, 0.25,
	//\midinote, Pseq(47+12+~scale.degrees[0..1], 1),
	\midinote, Pseq([47, 54], 1),
	\revtime, 0.7,
));
//Pdef(\snare2).play;

Pdef(\snare3, Pbind(
	\instrument, \plaits_snare,
	\dur, 1.5,
	\amp, 1.1,
	\harm, 0.25,
	\midinote, Pseq([54, 61], 1),
	\revtime, 0.7,
));
//Pdef(\snare3).play;

Pdef(\snare4, Pbind(
	\instrument, \plaits_snare,
	\dur, 1.5,
	\amp, 1.1,
	\harm, 0.25,
	\midinote, Pseq([47, 40], 1),
	\revtime, 0.7,
));
//Pdef(\snare4).play;
)
