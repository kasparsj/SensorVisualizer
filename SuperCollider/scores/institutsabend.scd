(
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
		"../synths/*.scd".loadRelative;
	};

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
				\amp, 0.075
			)
		},
		\delta, Pwhite(32, 256, inf) * 0.25,
		\method, \par
)))], inf)));
//Pdef(\heartSpawn).play

RedTrk2(\heart_noise, Synth(\ecg_WhiteNoise).run(false));

RedTrk2(\heart_sin, RedVol(RedFn({
	Ndef(\heart_sin).fadeTime = 20;
	Ndef(\heart_sin).set(\amp, 0);
	Ndef(\heart_sin).play(0, 2);
	Ndef(\heart_sin).xset(\amp, 0.1);
}, {
	Ndef(\heart_sin).stop(5);
}), { |vol|
	Ndef(\heart_sin).vol = vol;
}, 0.5));

RedTrk2(\heart_perc, RedVol(RedFn({ |vol|
	Ndef(\heart_perc).fadeTime = 10;
	Ndef(\heart_perc).set(\amp, 0);
	Ndef(\heart_perc).play(0, 2, addAction: \addToTail);
	Ndef(\heart_perc).xset(\amp, 0.2);
}, {
	Ndef(\heart_perc).stop(5);
}), { |vol|
	Ndef(\heart_perc).vol = vol;
}, 0.5));

RedTrk2(\heart_perc2, RedVol(RedFn({
	Ndef(\heart_perc2).fadeTime = 30;
	Ndef(\heart_perc2).set(\amp, 0);
	Ndef(\heart_perc2).play(~subs, 2, addAction: \addToTail);
	Ndef(\heart_perc2).xset(\amp, 0.1);
}, {
	Ndef(\heart_perc2).stop(5);
}), { |vol|
	Ndef(\heart_perc2).vol = vol;
}, 1));

RedTrk2(\breath, RedVol(RedFn({
	Ndef(\breath).fadeTime = 10;
	Ndef(\breath).set(\amp, 0);
	Ndef(\breath).play(0, 2);
	Ndef(\breath).xset(\amp, 1.0);
}, {
	Ndef(\breath).stop(5);
}), { |vol|
	Ndef(\breath).vol = vol;
}, 1));

RedTrk2(\quite_heart, RedVol(RedFn({
	Ndef(\heart_sin).fadeTime = 15;
	Ndef(\heart_sin).set(\amp, 0);
	Ndef(\heart_perc2).fadeTime = 15;
	Ndef(\heart_perc2).set(\amp, 0);
	Tdef(\quite_heart, { loop {
		(rrand(15, 30)).wait;
		// todo: maybe inverse of chestAcc?
		Ndef(\heart_sin).play;
		Ndef(\heart_sin).xset(\amp, 0.02.rand);
		Ndef(\heart_perc2).play;
		Ndef(\heart_perc2).xset(\amp, 0.2.rand);
		(rrand(15, 30)).wait;
		Ndef(\heart_sin).stop;
		Ndef(\heart_perc2).stop;
	} }).play;
}, {
	Tdef(\quite_heart).stop;
	Ndef(\heart_sin).stop;
	Ndef(\heart_perc2).stop;
}), { |vol|
	Ndef(\heart_sin).vol = vol;
	Ndef(\heart_perc2).vol = vol;
}, 1));

RedTrk2(\motion_grains, RedVol(Pdef(\motionGrains), { |vol|
	~motionGrainsAmp = vol;
}));

RedTrk2(\motion1, RedVol(RedFn({
	Ndef(\motion1).fadeTime = 1;
	Ndef(\motion1).set(\amp, 0);
	Ndef(\motion1).play(0, 2);
	Ndef(\motion1).xset(\amp, 1.0);
}, {
	Ndef(\motion1).stop(5);
}), { |vol|
	Ndef(\motion1).vol = vol;
}, 1));

RedTrk2(\control1, RedVol(RedFn({
	Ndef(\control1).fadeTime = 10;
	Ndef(\control1).set(\amp, 0);
	Ndef(\control1).play(0, 2);
	Ndef(\control1).xset(\amp, 0.5);
}, {
	Ndef(\control1).stop(5);
}), { |vol|
	Ndef(\control1).vol = vol;
}, 1));

RedTrk2(\rh_onsets, RedVol(RedFn({
	Ndef(\rh_onsets).fadeTime = 8;
	Ndef(\rh_onsets).set(\amp, 0);
	Ndef(\rh_onsets).play(0, 2);
	Ndef(\rh_onsets).xset(\amp, 1.0);
}, {
	Ndef(\rh_onsets).stop(5);
}, { |vol|
	Ndef(\rh_onsets).vol = vol;
}, 1));

RedTrk2(\lh_onsets, RedVol(RedFn({
	Ndef(\lh_onsets).fadeTime = 8;
	Ndef(\lh_onsets).set(\amp, 0);
	Ndef(\lh_onsets).play(0, 2);
	Ndef(\lh_onsets).xset(\amp, 1.0);
}, {
	Ndef(\lh_onsets).stop(5);
}), { |vol|
	Ndef(\lh_onsets).vol = vol;
}, 1));

RedTrk2(\snare, Pdef(\snare));

RedTrk2(\snare2, Pdef(\snare2));

RedTrk2(\snare3, Pdef(\snare3));

RedTrk2(\snare_final, Pdef(\snare_final));

"visuals/vis_tracks.scd".loadRelative;

~score = RedScore([
	inf, [\heart_perc2, \fadein0],
	inf, [\heart_perc2, \breath, \fadein1],
	inf, [\heart_perc2, \heart_perc, \breath],
	inf, [\heart_sin, \breath],
	inf, [\fadeout0, \fadeout1],
	inf, [\invert, \snare, \motion_grains, \line1, \quite_heart], // chest
	3, [\snare2, \lines12, \quite_heart],
	inf, [\control1], // right hand
	3, [\snare3, \lines123, \quite_heart],
	inf, [\lh_onsets, \control1], // right + left hand
	3, [\snare3, \lines123, \quite_heart],
	inf, [\rh_onsets, \lh_onsets], // both
	inf, [\snare2, \lines23, \quite_heart],
	inf, [\heart_perc2, \heart_sin, \no_lines, \no_invert, \breath, \fadein1],
	5, [\nothing],
	1, [\snare_final]
]);

// todo: use RedSeq instead
~video = VideoOSC(NetAddr("127.0.0.1", 133333));
~sound = SoundTrack(~video, ~score.beats, \beats);
)

~sound.play(loop: false);
~sound.nextSection;
~sound.stop;

RedMstGUI4()

//~phi8Master.add(\feedback, 1);
//~phi8Master.remove(\feedback);
//~phi8Master.gui;

// Ndef(\motion2).play(0, 2);
// Ndef(\motion2).xset(\amp, 0.5);
// Ndef(\motion2).stop(5);
//
// Ndef(\motion3).play(0, 2);
// Ndef(\motion3).xset(\amp, 1);
// Ndef(\motion3).stop(5);
//
// Ndef(\motion3_mi).play(0, 2);
// Ndef(\motion3_mi).xset(\amp, 0.75);
// Ndef(\motion3_mi).stop(5);
