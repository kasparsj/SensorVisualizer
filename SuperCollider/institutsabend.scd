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
	~rhAccMagBus.free; // right hand accelerometer magnitude
	~rhAccMagBus = Bus.control(Server.default, 1);
	~recordBus.free;
	~recordBus = Bus.audio(Server.default, 7);

	"synths/*.scd".loadRelative;
	"master.scd".loadRelative;

	s.sync;

	~visuals = OSCVisuals("127.0.0.1", 33333);
	~visuals.send('/layers', 1, "stack");
	~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
	//~visuals.send('/tex', 0, "shaders/color.frag");

	~chan = 0;
	~subs = 0;
	//~chan = 43;
	//~subs = 60;

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
				\out, ~chan,
				\amp, 0.075
			)
		},
		\delta, Pwhite(32, 256, inf) * 0.25,
		\method, \par
)))], inf)).play;

~hw = Synth.after(~ht, \WhiteNoise, [\out, ~chan]);
)

~hw.free;
Pdef(\heartSpawn).stop;

Ndef(\heart_sin).play(~chan, 2);
Ndef(\heart_sin).xset(\amp, 0.025);
Ndef(\heart_sin).stop(5);

Ndef(\heart_perc).play(~chan, 2, addAction: \addToTail);
Ndef(\heart_perc).xset(\amp, 0.4);
Ndef(\heart_perc).stop(10);

Ndef(\heart_perc2).play(~subs, 2, addAction: \addToTail);
Ndef(\heart_perc2).xset(\amp, 0.4);
Ndef(\heart_perc2).stop(5);

Ndef(\motion2).play(~chan, 2);
Ndef(\motion2).xset(\amp, 0.5);
Ndef(\motion2).stop(5);

Ndef(\motion2_mi).play(~chan, 2);
Ndef(\motion2_mi).xset(\amp, 0.5);
Ndef(\motion2_mi).stop(5);

Ndef(\motion3).play(~chan, 2);
Ndef(\motion3).xset(\amp, 1);
Ndef(\motion3).stop(5);

Ndef(\motion3_mi).play(~chan, 2);
Ndef(\motion3_mi).xset(\amp, 0.75);
Ndef(\motion3_mi).stop(5);

Ndef(\breath).play(~chan, 2);
Ndef(\breath).xset(\amp, 0.5);

(
// create visuals sender
~visuals = OSCVisuals("127.0.0.1", 33333);

// initialize 1 layer
~visuals.send('/layers', 1, "stack");

// load RotStringsH shader into layer 1
~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
)

~visuals.send('/tex/color', 0, 1.0, 1.0, 1.0);
~visuals.send('/tex/color', 0, 1.0, 0, 0);
~visuals.send('/tex/color', 0, 0, 0, 0);
