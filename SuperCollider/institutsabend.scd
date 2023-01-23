(
MasterFX.clear('localhost');

s.waitForBoot {
	~hrBus.free; // 40 - 180
	~hrBus = Bus.control(Server.default, 1);
	~ecgBus.free; // 0 - 1
	~ecgBus = Bus.control(Server.default, 1);
	~onsetBus.free; // 0, 1
	~onsetBus = Bus.control(Server.default, 4).set(0);
	~compassBus.free; // 0 - 360
	~compassBus = Bus.control(Server.default, 1);
	~recordBus.free;
	~recordBus = Bus.audio(Server.default, 7);

	"synths/*.scd".loadRelative;
	"master.scd".loadRelative;

	s.sync;

	"oscdefs.scd".loadRelative;

	"loaded!!!".postln;
};
)

(
Pdef(\heartSpawn, Pseq([
	Pfindur(300, Pspawn(Pbind(
		\pattern, Pfunc {
			var which = (0..2).choose;
			var instruments = [\SineDrone, \SawDrone, \PulseDrone];
			var dur = rrand((30/1.25), (180/1.25)).asInteger;
			var freq = (51..(51+rrand(1, 3))).scramble;
			var pan = [-1, 1].scramble;
			Pbind(
				\instrument, instruments[which],
				\freq, freq,
				\dur, Pseq([dur], 1),
				\pan, pan,
				\phase, Pwhite(0, 2pi, 1),
				\out, 0,
				\amp, 0.075
			)
		},
		\delta, Pwhite(32, 256, inf) * 0.25,
		\method, \par
)))], inf)).play;

~hw = Synth.after(~ht, \WhiteNoise);
)

~hw.free;
Pdef(\heartSpawn).stop;

Ndef(\heart_sin).set(\amp, 0.025);
Ndef(\heart_perc).set(\amp, 0.4);
Ndef(\heart_perc2).set(\amp, 0.4);
Ndef(\motion2_mi).set(\amp, 1);
Ndef(\motion3_mi).set(\amp, 0.75);

Ndef(\heart_sin).play(0, 2);
Ndef(\heart_perc).play(0, 2, addAction: \addToTail);
Ndef(\heart_perc2).play(0, 2, addAction: \addToTail);
//Ndef(\motion2).play(0, 2);
Ndef(\motion2_mi).play(0, 2);
//Ndef(\motion3).play(0, 2);
Ndef(\motion3_mi).play(0, 2);

Ndef(\heart_sin).stop(5);
Ndef(\heart_perc).stop(5);
Ndef(\heart_perc2).stop(5);
Ndef(\motion2).stop(5);
Ndef(\motion2_mi).stop(5);
Ndef(\motion3).stop(5);
Ndef(\motion3_mi).stop(5);

(
// create visuals sender
~visuals = OSCVisuals("127.0.0.1", 33333);

// initialize 1 layer
~visuals.send('/layers', 1, "stack");

// load RotStringsH shader into layer 1
~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
)

~visuals.send('/tex/color', 0, 1.0, 1.0, 1.0);
