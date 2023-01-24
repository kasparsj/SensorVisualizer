(
MasterFX.clear('localhost');

s.waitForBoot {
	"../config.scd".loadRelative;

	if (s.options.device == "MADIface USB (23727305)") {
	// if (s.options.device == "Fireface UFX+ (23779252)") {
		"../vbap/vbap_setup.scd".loadRelative;
		~chan = 43;
		~subs = 60;
	} {
		"../synths/*.scd".loadRelative;
		~chan = 0;
		~subs = 0;
	};

	"../master.scd".loadRelative;

	s.sync;

	"../oscdefs.scd".loadRelative;
	"visuals/visuals.scd".loadRelative;

	"loaded!!!".postln;
};
)

(
RedMst.clear;
RedMst.clock = TempoClock(60/60);
RedMst.quant = 1;

RedTrk2(\heart_spawn, Pdef(\heartSpawn, Pseq([
	Pfindur(300, Pspawn(Pbind(
		\pattern, Pfunc {
			var which = (0..2).choose;
			var instruments = [\ecg_SineDrone, \ecg_SawDrone, \ecg_PulseDrone];
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
)))], inf)));
//Pdef(\heartSpawn).play

RedTrk2(\heart_noise, Synth(\ecg_WhiteNoise, [\out, ~chan]).run(false));

RedTrk2(\start_heart_sin, Task({
	Ndef(\heart_sin).fadeTime = 5;
	Ndef(\heart_sin).set(\amp, 0);
	Ndef(\heart_sin).play(~chan, 2);
	Ndef(\heart_sin).xset(\amp, 0.025);
}));

RedTrk2(\stop_heart_sin, Task({
	Ndef(\heart_sin).stop(10);
}));

RedTrk2(\start_heart_perc, Task({
	Ndef(\heart_perc).fadeTime = 10;
	Ndef(\heart_perc).set(\amp, 0);
	Ndef(\heart_perc).play(~chan, 2, addAction: \addToTail);
	Ndef(\heart_perc).xset(\amp, 0.4);
}));

RedTrk2(\stop_heart_perc, Task({
	Ndef(\heart_perc).stop(10);
}));

RedTrk2(\start_heart_perc2, Task({
	Ndef(\heart_perc2).fadeTime = 30;
	Ndef(\heart_perc2).set(\amp, 0);
	Ndef(\heart_perc2).play(~subs, 2, addAction: \addToTail);
	Ndef(\heart_perc2).xset(\amp, 0.4);
}));

RedTrk2(\stop_heart_perc2, Task({
	Ndef(\heart_perc2).stop(5);
}));

RedTrk2(\start_breath, Task({
	Ndef(\breath).fadeTime = 10;
	Ndef(\breath).set(\amp, 0);
	Ndef(\breath).play(~chan, 2);
	Ndef(\breath).xset(\amp, 0.5);
}));

RedTrk2(\stop_breath, Task({
	Ndef(\breath).stop(5);
}));

RedTrk2(\motion_grains, Pdef(\motionGrains, Pspawn(Pbind(
	\pattern, Pfunc {
		var instruments = [\motion1];
		var dur = rrand(0.1, 1.0);
		var pan = [-1, 1].scramble;
		Pbind(
			\instrument, instruments.choose,
			\dur, Pseq([dur], 1),
			\pan, pan,
			\out, ~chan,
			\amp, 1
		)
	},
	\delta, Pwhite(32, 128, inf) * 0.0025,
	\method, \par
))));

RedTrk2(\start_motion1, Task({
	Ndef(\motion1).fadeTime = 8;
	Ndef(\motion1).set(\amp, 0);
	Ndef(\motion1).play(~chan, 2);
	Ndef(\motion1).xset(\amp, 1.0);
}));

RedTrk2(\stop_motion1, Task({
	Ndef(\motion1).stop(5);
}));

RedTrk2(\start_rh_onsets, Task({
	Ndef(\rh_onsets).fadeTime = 8;
	Ndef(\rh_onsets).set(\amp, 0);
	Ndef(\rh_onsets).play(~chan, 2);
	Ndef(\rh_onsets).xset(\amp, 1.0);
}));

RedTrk2(\stop_rh_onsets, Task({
	Ndef(\rh_onsets).stop(5);
}));

~score = RedScore([
	// inf, [\start_breath],
	// inf, [\start_heart_perc2, \fadein0],
	// inf, [\start_heart_perc, \stop_heart_perc2],
	// inf, [\start_heart_sin, \stop_heart_perc],
	// inf, [\stop_heart_sin, \fadeout0],
	// inf, [\stop_breath, \motion_grains],
	// inf, [\start_motion1],
	inf, [\start_rh_onsets],
]);

"visuals/fade_tracks.scd".loadRelative;

// todo: use RedSeq instead
~video = VideoOSC(NetAddr("127.0.0.1", 133333));
~sound = SoundTrack(~video, ~score.beats, \beats);
)

~sound.play(loop: false);
~sound.nextSection;
~sound.stop;

// Ndef(\motion2).play(~chan, 2);
// Ndef(\motion2).xset(\amp, 0.5);
// Ndef(\motion2).stop(5);
//
// Ndef(\motion3).play(~chan, 2);
// Ndef(\motion3).xset(\amp, 1);
// Ndef(\motion3).stop(5);
//
// Ndef(\motion3_mi).play(~chan, 2);
// Ndef(\motion3_mi).xset(\amp, 0.75);
// Ndef(\motion3_mi).stop(5);
