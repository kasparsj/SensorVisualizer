(
// requires: https://github.com/kasparsj/redMst

MasterFX.clear('localhost');

s.waitForBoot {
	"../config.scd".loadRelative;

	if (s.options.device == "MADIface USB (23727305)") {
	// if (s.options.device == "Fireface UFX+ (23779252)") {
		//"../vbap/vbap_setup.scd".loadRelative;
		~subs = 60;
		// todo: vbap synths
		"../synths/*.scd".loadRelative;
	} {
		~subs = 0;

	};

	"../synths/*.scd".loadRelative;
	"../master.scd".loadRelative;

	s.sync;

	"../oscdefs.scd".loadRelative;
	"../pdefs.scd".loadRelative;
	"visuals/visuals.scd".loadRelative;

	"loaded!!!".postln;
};
)

(
RedMst.clear;
RedMst.clock = TempoClock(60/60);
RedMst.quant = 1;

RedTrack(\heart_spawn, Pdef(\heartSpawn, Pseq([
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
				\amp, 0.075
			)
		},
		\delta, Pwhite(32, 256, inf) * 0.25,
		\method, \par
)))], inf)));
//Pdef(\heartSpawn).play

RedTrack(\heart_noise, Synth(\ecg_WhiteNoise).run(false));

RedTrack(\heart_sin, RedVol(RedFn({
	Ndef(\heart_sin).fadeTime = 20;
	Ndef(\heart_sin).set(\amp, 0);
	Ndef(\heart_sin).play(0, 2);
	Ndef(\heart_sin).xset(\amp, 0.1);
}, {
	Ndef(\heart_sin).stop(5);
}), { |vol|
	Ndef(\heart_sin).vol = vol;
}, 0.5));

RedTrack(\heart_perc, RedVol(RedFn({ |vol|
	Ndef(\heart_perc).fadeTime = 10;
	Ndef(\heart_perc).set(\amp, 0);
	Ndef(\heart_perc).play(0, 2, addAction: \addToTail);
	Ndef(\heart_perc).xset(\amp, 0.2);
}, {
	Ndef(\heart_perc).stop(5);
}), { |vol|
	Ndef(\heart_perc).vol = vol;
}, 0.5));

RedTrack(\heart_sub, RedVol(RedFn({
	Ndef(\heart_sub).fadeTime = 30;
	Ndef(\heart_sub).set(\amp, 0);
	Ndef(\heart_sub).play(~subs, 2, addAction: \addToTail);
	Ndef(\heart_sub).xset(\amp, 0.4);
}, {
	Ndef(\heart_sub).stop(5);
}), { |vol|
	Ndef(\heart_sub).vol = vol;
}, 0.5));

RedTrack(\heart_beat, Ndef(\heart_beat));

RedTrack(\breath, RedVol(RedFn({
	Ndef(\breath).fadeTime = 10;
	Ndef(\breath).set(\amp, 0);
	Ndef(\breath).play(2, 2);
	Ndef(\breath).xset(\amp, 1.0);
}, {
	Ndef(\breath).stop(5);
}), { |vol|
	Ndef(\breath).vol = vol;
}, 1));

RedTrack(\quite_heart, RedVol(RedFn({
	Ndef(\heart_sin).fadeTime = 15;
	Ndef(\heart_sin).set(\amp, 0);
	Ndef(\heart_sub).fadeTime = 15;
	Ndef(\heart_sub).set(\amp, 0);
	Tdef(\quite_heart, { loop {
		(rrand(15, 30)).wait;
		// todo: maybe inverse of chestAcc?
		Ndef(\heart_sin).play;
		Ndef(\heart_sin).xset(\amp, 0.02.rand);
		Ndef(\heart_sub).play;
		Ndef(\heart_sub).xset(\amp, 0.2.rand);
	} }).play;
}, {
	Tdef(\quite_heart).stop;
	Ndef(\heart_sin).stop;
	Ndef(\heart_sub).stop;
}), { |vol|
	Ndef(\heart_sin).vol = vol;
	Ndef(\heart_sub).vol = vol;
}, 0));

RedTrack(\motion_grains, RedVol(Pdef(\motionGrains), { |vol|
	~motionGrainsAmp = vol;
}));

RedTrack(\motion1, RedVol(RedFn({
	Ndef(\motion1).fadeTime = 1;
	Ndef(\motion1).set(\amp, 0);
	Ndef(\motion1).play(0, 2);
	Ndef(\motion1).xset(\amp, 1.0);
}, {
	Ndef(\motion1).stop(5);
}), { |vol|
	Ndef(\motion1).vol = vol;
}, 0.5));

RedTrack(\control1, RedVol(RedFn({
	Ndef(\control1).fadeTime = 10;
	Ndef(\control1).set(\amp, 0);
	// Ndef(\control1).play(2, 2);
	Ndef(\control1).play(0, 2);
	Ndef(\control1).xset(\amp, 0.5);
}, {
	Ndef(\control1).stop(5);
}), { |vol|
	Ndef(\control1).vol = vol;
}, 0.5));

RedTrack(\rh_onsets, RedVol(RedFn({
	Ndef(\rh_onsets).fadeTime = 8;
	Ndef(\rh_onsets).set(\amp, 0);
	Ndef(\rh_onsets).play(0, 2);
	Ndef(\rh_onsets).xset(\amp, 1.0);
}, {
	Ndef(\rh_onsets).stop(5);
}), { |vol|
	Ndef(\rh_onsets).vol = vol;
}, 1));

RedTrack(\lh_onsets, RedVol(RedFn({
	Ndef(\lh_onsets).fadeTime = 8;
	Ndef(\lh_onsets).set(\amp, 0);
	Ndef(\lh_onsets).play(0, 2);
	Ndef(\lh_onsets).xset(\amp, 1.0);
}, {
	Ndef(\lh_onsets).stop(5);
}), { |vol|
	Ndef(\lh_onsets).vol = vol;
}, 0.5));

RedTrack(\snare, Pdef(\snare));

RedTrack(\snare2, Pdef(\snare2));

RedTrack(\snare3, Pdef(\snare3));

RedTrack(\snare4, Pdef(\snare4));

RedTrack(\snare_final, Pdef(\snare_final));

"visuals/vis_tracks.scd".loadRelative;

~score = RedScore([
	inf, [\heart_sub, \fadein0],
	inf, [\heart_sub, \breath, \fadein1],
	inf, [\heart_sub, \heart_perc, \breath],
	inf, [\heart_sin, \breath],
	inf, [\fadeout0, \fadeout1],
	inf, [\invert, \snare, \motion_grains, \line1, \quite_heart], // chest
	3, [\lines12, \quite_heart],
	inf, [\quite_heart, \control1], // right hand
	3, [\lines123, \quite_heart, \control1],
	inf, [\lh_onsets, \control1], // right + left hand
	3, [\lines123, \quite_heart, \lh_onsets, \control1],
	inf, [\control1, \lh_onsets, \motion_grains], // both
	inf, [\snare4, \lines23, \quite_heart],
	inf, [\heart_sub, \heart_sin, \no_lines, \no_invert, \breath, \fadein1],
	5, [\nothing],
	1, [\snare_final]
]);

~sound = ~score.createSeq(loop: false);
)

~sound.play;
~sound.next;
~sound.stop;

RedMstGUI(seq: ~sound)
RedMstSessionGUI(seq: ~sound)
