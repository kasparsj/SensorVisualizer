(
if (~ecgBus.isNil) {
	"../config.scd".loadRelative;
};

Ndef(\heart_sin, { |amp=0.1, room=0.5|
	var sig, chain, onset, noise, ecg, vbap;
	ecg = In.kr(~ecgBus.index, 2);
	noise = LFNoise2.ar(1/10);
	sig = SinOsc.ar(ecg[0] * (1+noise));
	sig = sig * (1-ecg[1]);
	chain = FFT(LocalBuf(1024), sig);

	onset = Onsets.kr(chain, 0.25);
	Out.kr(~onsetBus.index, onset);
	SendReply.kr(onset, '/heart_onset');

	// sig = RHPF.ar(sig, rq: 0.01);
	sig = MiVerb.ar(sig, drywet: room);
	//sig = Compander.ar(sig, sig);
	sig = sig * amp;

	//Out.ar(~recordBus.index, sig);
	//Out.ar(9 + (25 * LFNoise2.kr(1/4)).round, sig);
	//vbap = VBAP.ar(~vbapList.size, sig, ~vbapBuf.bufnum, LFNoise2.kr(1/3)*180, 30, 30);
	//Out.ar(0, vbap);
	//Out.ar(35, sig[0]);
	//Out.ar(38, sig[1]);

	sig;
});
Ndef(\heart_sin).fadeTime = 5;
//Ndef(\heart_sin).play(0, 2);
//Ndef(\heart_sin).stop;

Ndef(\heart_perc, { |room=0.5, amp=0.25|
	var sig, env, hr, onset, vbap;
	ecg = In.kr(~ecgBus.index, 2);
	hr = In.kr(~hrBus.index);
	onset = In.kr(~onsetBus.index);
	env = EnvGen.ar(Env.perc, onset);
	sig = (SinOsc.ar(hr * ecg[1] * 5) * env * ecg[1] * 4);
	//sig = sig * Line.kr(0, 1, 90);
	sig = HPF.ar(sig, 400);
	// sig = FreeVerb.ar(sig, room: room)!2;
	sig = MiVerb.ar(sig, drywet: room);
	sig = sig * amp;
	//sig = sig * LFNoise2.kr(1/5).range(0.7, 1.0);

	// todo: fix - changed to output 2 channels
	//Out.ar(~recordBus.index+1, sig);

	//Out.ar(9 + (25 * LFNoise2.kr(1/4)).round, sig);
	//vbap = VBAP.ar(~vbapList.size, sig, ~vbapBuf.bufnum, LFNoise2.kr(1/3)*180, 30, 30);
	//Out.ar(0, vbap);
	// Out.ar(35, sig);
	// Out.ar(38, sig);

	sig;
});
//Ndef(\heart_perc).fadeTime = 1;
//Ndef(\heart_perc).play(0, 2, addAction: \addToTail);
//Ndef(\heart_perc).stop;

// // not working!!!
// Ndef(\heart_perc_mi, { |min_hr=40, max_hr=180, room=0.5, amp=1.0|
//  var ecg = In.kr(~ecgBus.index, 2);
//  var hr = In.kr(~hrBus.index);
//  var onset = In.kr(~onsetBus.index);
// 	var pit = ecg[1].range(30, 50).round;
// 	var timb = 0.4 + ((hr-min_hr)/(max_hr-min_hr));
// 	var color = LFNoise1.kr(0.3,0.5,0.5);
// 	var sig = MiBraids.ar(pit, timb, color, 34, onset*2-1);
//
// 	Out.ar(~recordBus.index, sig*amp);
// 	sig*amp;
// });
// Ndef(\heart_perc_mi).fadeTime = ~fadeTime;

Ndef(\heart_sub).fadeTime = 10;
Ndef(\heart_sub, { |room=0.25, amp=1.0|
	var sig, env, fmul, mul, ecg, hr, onset;
	ecg = In.kr(~ecgBus.index, 2);
	hr = In.kr(~hrBus.index);
	onset = In.kr(~onsetBus.index);
	env = EnvGen.ar(Env.perc, onset);

	// fmul = ecg[1];
	fmul = 1.0 - ecg[1];
	mul = ecg[1];
	sig = (SinOsc.ar(hr * fmul * 2) * env * mul);
	sig = LPF.ar(sig, 60, 2);

	// sig = FreeVerb.ar(sig, room: room)!2;
	//sig = MiVerb.ar(sig, drywet: room);
	sig = sig * amp;
	//sig = sig * LFNoise2.kr(1/5).range(0.7, 1.0);
	//sig = sig * Line.kr(0, 1, 120);

	// todo: fix - changed to output 2 channels
	//Out.ar(~recordBus.index+2, sig);
	sig;
});
//Ndef(\heart_sub).fadeTime = 1;
//Ndef(\heart_sub).play(0, 2, addAction: \addToTail);
//Ndef(\heart_sub).stop;

Ndef(\heart_beat, { |room=0.5, amp=0.25|
	var sig, env, ecg, hr, onset, vbap;
	var a, b, pitch, trig, engine;
	var acc, chain;
	ecg = In.kr(~ecgBus.index, 2);
	hr = In.kr(~hrBus.index);
	onset = In.kr(~onsetBus.index);
	env = EnvGen.ar(Env.perc, onset);
	pitch = 30;

	acc = In.kr(~rhAccNormBus.index, 4);
	chain = FFT(LocalBuf(128), acc[3]);
	// var trigger = Onsets.kr(chain, 0.3+(LFNoise2.kr(1/20)*0.2), \rcomplex, 0.01, 0.1, 1);
	onset = Onsets.kr(chain, 0.9, \rcomplex, 0.01, 0.1, 1);

	a = Dseq([34, 36, Drand([34, 38], 1), 34, 36, Drand([3, 36], 1), 34, 36, Drand([42, 36], 1)], inf);
	b = Dseq(Drand([30, 37], 4), inf);
    engine = Demand.kr(onset, 0, a);
	// pitch = Demand.kr(onset, 0, b);

	sig = (MiBraids.ar(pitch, 0.1, 1-ecg[1], engine, onset) * 2);
	// sig = MiVerb.ar(sig, drywet: room);
	sig = sig * amp;

	sig;
});


Ndef(\motion1, { |room=0.5, amp=1.0, pan=0|
	var sig;
	var hr = In.kr(~hrBus.index);
	var acc = In.kr(~chestAccNormBus.index, 4);
	var timb = (acc[0]+1)/2;
	var color = (acc[1]+1)/2;

	// sig = MiBraids.ar(hr/2, timb.clip(0, 1), color.clip(0, 1), 28+(hr/6).floor, resamp: 0, ws: z.abs.clip(0, 1));
	//sig = MiBraids.ar(12+(timb*60), timb.clip(0, 1), color.clip(0, 1), 28+(hr/6).floor, resamp: 0);
	// sig = MiBraids.ar(hr, timb.clip(0, 1), color.clip(0, 1), 28+(hr/12).floor, resamp: 1, ws: z.abs.clip(0, 1));

	sig = MiPlaits.ar(12+(color*12), (7-(hr/16).floor).clip(0, 15), color, timb, (acc[3]+1)/2);
	// sig = MiPlaits.ar(24+(color*12), 2, color, timb, z.abs.clip(0, 1));

	// sig = BPF.ar(sig, hr.midicps*z); // do NOT
	sig = MiVerb.ar(sig);

	// try this out:
	//sig = sig * LFSaw.kr(1/20, 1).range(0.01, acc[3]*amp);
	//sig = sig * Line.kr(0, 1.1, 180);

	sig = Balance2.ar(sig[0], sig[1], pan, amp*acc[3]);

	Out.ar(~recordBus.index+3, sig);
	sig;
});

Ndef(\motion2, { |x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1|
	var hr = In.kr(~hrBus.index);
	var sig = 0;
	//var fcar = ([x, y, z]+200) + (hr * [1, 2, 3, 4, 5]);
	var fcar = ([x, y, z]-(hr*1)) * [1, 2, 3, 4, 5];
	var rel = 1+16*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise2.ar(fmod);
	var acar1 = LFSaw.ar(fcar + amod).sum;
	var acar2 = LFSaw.ar(fcar + amod*(1.01)).sum;
	//sig = BPF.ar([acar1, acar2]*0.1, hr*rel);
	sig = LPF.ar([acar1, acar2]*0.1, hr*rel);
	//sig = GVerb.ar(sig[0]) + GVerb.ar(sig[1]);
	sig = sig*amp;

	Out.ar(~recordBus.index+3, sig);
	sig;
});

Ndef(\motion3, { |x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1, pan=0|
	var hr = In.kr(~hrBus.index);
	var sig = 0;
	var fcar = (([x, y, z]) * 2000) + (hr * [1, 2, 3]);
	var rel = 1+16*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = SinOscFB.ar(fcar + amod, x).sum;
	var acar2 = SinOscFB.ar(fcar + amod*(1.01), y).sum;
	sig = BPF.ar([acar1, acar2]*0.1, hr*rel);
	//sig = LPF.ar([acar1, acar2]*0.1, hr*rel);
	//sig = GVerb.ar(sig[0]) + GVerb.ar(sig[1]);
	sig = sig*amp;

	sig = Balance2.ar(sig[0], sig[1], pan);
	Out.ar(~recordBus.index+5, sig);
	sig;
});

Ndef(\motion3_mi, { |x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1, pan=0|
	var hr = In.kr(~hrBus.index);
	var timbre = (x.clip(-1, 1)+1)/2;
	var harm = (y.clip(-1, 1)+1)/2;
    var morph = z.abs.clip(0, 1);
	var sig = MiPlaits.ar(hr / 4, 5, harm, timbre, morph);
	//sig = BPF.ar(sig, hr.midicps*z);
	//sig = MiVerb.ar(sig);
	//sig = sig * LFSaw.kr(1/20, 0).range(0.01, mag*amp);
	//sig = sig * Line.kr(0, 1.1, 180);

	sig = Balance2.ar(sig[0], sig[1], pan, amp);
	Out.ar(~recordBus.index+5, sig*amp);
	sig;
});

Ndef(\rhTrig, {
	var acc = In.kr(~rhAccNormBus.index, 4);
	var xz = In.kr(~rhProjXZBus.index, 4);
	var mag = 2;
	var trigger = 0;
	// trigger = Impulse.kr(2);
	//trigger = In.kr(~onsetBus.index);
	// trigger = In.kr(~rhTrigBus.index); // when moving
	// trigger = (In.kr(~rhTrigBus.index) - 1).abs; // when not moving
	// mag = Latch.kr((acc[3]*100).round.min(16), Impulse.kr(2));
	// mag = (xz[1] * 4).round * 2;
	// trigger = 1;
	// trigger = Impulse.kr(mag) * trigger;
	trigger;
});

Ndef(\rhEnv, {
	var env = 1, trigger = 0;
	trigger = Ndef.kr(\rhTrig, 1);
	// trigger = Impulse.kr(2);
	// trigger = In.kr(~onsetBus.index);
	// trigger = In.kr(~rhTrigBus.index);
	// trigger = (In.kr(~rhTrigBus.index) - 1).abs;
	// env = EnvGen.ar(Env.adsr, trigger);
	// env = EnvGen.ar(Exnv.perc, trigger);
	env;
}).fadeTime_(3);

// start with color only
// add octave
// add degree
// add adsr env

Ndef(\rhPitch, {
	var degrees = ~scale.degrees;
	var xz = In.kr(~rhProjXZBus.index, 4);
	var yx = In.kr(~rhProjYXBus.index, 4);
	var trigger = Ndef.kr(\rhTrig, 1);
	var degree = 0, pitch = 0, octave = 2; // 0 - 4, then hr
	octave = (xz[1] * 4).round;
	// degree = (xz[0] * degrees.size).round;
	degree = Demand.kr(trigger, 0, Dseq([0, 5, 0, 7], inf));
	// todo: add more progressions
	pitch = ~root + degree + (octave * 12);
	//pitch = In.kr(~hrBus.index);
	pitch;
}).fadeTime_(3);

Ndef(\control1, { |room=0.5, amp=1.0, pan=0|
	var sig;
	var xz = In.kr(~rhProjXZBus.index, 4);
	var yx = In.kr(~rhProjYXBus.index, 4);
	var zy = In.kr(~rhProjZYBus.index, 4);
	var acc = In.kr(~rhAccNormBus.index, 4);
	var trigger = Ndef.kr(\rhTrig, 1);
	var env = Ndef.ar(\rhEnv, 1);
	var pitch = Ndef.kr(\rhPitch, 1);

	sig = MiBraids.ar(pitch, xz[0], xz[1], 12, trigger) * env;
	sig = sig + MiBraids.ar(pitch+4, yx[0], yx[1], 14, trigger) * env;
	sig = sig + MiBraids.ar(pitch+7, zy[0], zy[1], 44, trigger) * env;

	// sig = MiPlaits.ar(12+(color*12), (7-(hr/16).floor).clip(0, 15), color, timb, (acc[3]+1)/2);
	// sig = MiPlaits.ar(24+(color*12), 2, color, timb, z.abs.clip(0, 1));

	sig = sig / 3 * 2;

	// sig = MiVerb.ar(sig);
	sig = MiVerb.ar(sig, acc[3] * 10);
	// sig = sig!2;

	sig = Balance2.ar(sig[0], sig[1], pan, amp);

	sig;
});
Ndef(\control1).fadeTime = 0;
// Ndef(\control1).play(0, 2);
// Ndef(\control1).xset(\amp, 0.3);
// Ndef(\control1).stop;

Ndef(\breath, { |amp=0.0|
	var sig = SoundIn.ar(0);
	sig = HPF.ar(sig, 500);
	sig = sig*amp*6;
	Out.kr(~breathBus.index, sig*6);
	// Out.ar(2, sig);
	// Out.ar(3, sig);
	(sig!2)*~breathEnabled.asInteger;
});
//Ndef(\breath).play(0, 2);
//Ndef(\breath).xset(\amp, 1.0);

Ndef(\rh_onsets, { |amp=0|
	var sig;
	var acc = In.kr(~rhAccNormBus.index, 4);
	//var comp = In.kr(~compassBus.index, 2);
	// var harm = LFNoise2.kr(0.3,0.25,0.25);
	// var timbre = LFNoise1.kr(0.4,0.5,0.5);
	// var timbre = (acc[0]+1)/2;
	// var harm = (acc[1]+1)/2;
	var quat = In.kr(~rhQuatBus.index, 16);
	var yx = (quat[8..11]+1)/2;
	var timbre = yx[0];
	var harm = yx[1];
	var dec = LFNoise2.kr(0.2).range(0.01,0.8);
	// var dec = acc[3];
	var chain = FFT(LocalBuf(128), acc[3]);
	// var trigger = Onsets.kr(chain, 0.3+(LFNoise2.kr(1/20)*0.2), \rcomplex, 0.01, 0.1, 1);
	var trigger = Onsets.kr(chain, 0.9, \rcomplex, 0.01, 0.1, 1);
	// var trigger = Onsets.kr(chain, 0.75);
	//var out = 10 + (25 * comp[1]);

	//sig = MiPlaits.ar([41-(acc[3]*24), 48-(acc[3]*24)], 13, harm, timbre, 0.6+(LFNoise2.kr(1/30)*0.3), decay: dec, mul: 0.75);
	// sig = MiVerb.ar(sig, drywet: LFNoise2.kr(1/30)*0.1);
	// sig = MiVerb.ar(sig, drywet: LFNoise2.kr(1/30)*0.05);
	// sig = MiPlaits.ar(60-(acc[3]*24), TChoose.kr(trigger, [6]), harm, timbre, 0.1, trigger, decay: dec, mul: 0.75);
	sig = MiPlaits.ar(60-(acc[3]*24), 6, harm, timbre, 0.1, trigger, decay: dec, mul: 0.75);
	sig = sig + MiPlaits.ar(36-(acc[3]*24), 13, harm, timbre, 0, trigger, decay: dec*2, mul: 0.25);
	//sig = HPF.ar(sig, 800);
	sig = MoogFF.ar(sig, 1200);
	// sig = CombC.ar(sig, mul: 0.1) + sig;
	sig = MiVerb.ar(sig, drywet: 0.1);
	// sig = LPF.ar(sig, 200, 0.3) + sig;
	// sig = FbC({ |fb| FreqShift.ar(sig + fb, 200).softclip * 0.1}, 4, 1);

	sig = sig*amp;
	//Out.ar(9 + (25 * comp[1]).round, sig);
	sig;
});
//Ndef(\rh_onsets).fadeTime = 8;
//Ndef(\rh_onsets).play(0, 2);
//Ndef(\rh_onsets).xset(\amp, 1.0);
//Ndef(\rh_onsets).stop

Ndef(\lhTrig, {
	var acc = In.kr(~lhAccNormBus.index, 4);
	var xz = In.kr(~lhProjXZBus.index, 4);
	var chain = FFT(LocalBuf(128), acc[3]);
	var mag = 2;
	var trigger = 0, trigger1 = 0, trigger2 = 0;

	// trigger = Onsets.kr(chain, 0.9, \rcomplex, 0.01, 0.1, 1);
	// trigger = Onsets.kr(chain, 0.75);
	trigger = In.kr(~lhTrigBus.index); // when moving
	// trigger = (In.kr(~lhTrigBus.index) - 1).abs; // when not moving
	// trigger = 1;

	mag = Latch.kr((acc[3]*50).round.min(16), Impulse.kr(2));
	mag = (xz[1] * 3).round;

	trigger = Impulse.kr(mag) * trigger;
	trigger1 = Impulse.kr(mag/3) * trigger;
	trigger2 = Impulse.kr(mag/8*5) * trigger;

	[trigger, trigger1, trigger2];
});

// todo: ScGrids not working with Ugens
// Ndef(\lhGrids, {
// 	var xz = In.kr(~lhProjXZBus.index, 4);
// 	var trigger, beat, mag = 2;
// 	var level1 = 0, level2 = 0, level3 = 0;
// 	trigger = Impulse.kr(mag);
// 	beat = Demand.kr(trigger, 0, Dseq((0..31), inf)).asInteger;
// 	level1 = ScGrids.calculateLevel(\kick, curBeat: beat, x: xz[0], y: xz[1], bias: 0.0);
// 	level2 = ScGrids.calculateLevel(\hihat, curBeat: beat, x: xz[0], y: xz[1], bias: 0.0);
// 	level3 = ScGrids.calculateLevel(\snare, curBeat: beat, x: xz[0], y: xz[1], bias: 0.0);
// 	[level1, level2, level3];
// });

Ndef(\lhPitch, {
	var acc = In.kr(~lhAccNormBus.index, 4);
	var xz = In.kr(~lhProjXZBus.index, 4);
	var yx = In.kr(~lhProjYXBus.index, 4);
	var pitch = 0, degree = 0, octave = 2;
	octave = (xz[1] * 4).round;
	// degree = (acc[3]*12);
	// degree = -1 * (acc[3]*24);
	pitch = octave*12 + degree;
	pitch;
});

Ndef(\lh_onsets, { |amp=0|
	var sig = 0, timbre, harm, dec, out, kick;
	var acc = In.kr(~lhAccNormBus.index, 4);
	var xz = In.kr(~lhProjXZBus.index, 4);
	var yx = In.kr(~lhProjYXBus.index, 4);
	var zy = In.kr(~lhProjZYBus.index, 4);
	var comp = In.kr(~compassBus.index, 2);
	var trigger = Ndef.kr(\lhTrig, 3);
	var pitch = Ndef.kr(\lhPitch, 1);

	// timbre = 0.5;
	// timbre = LFNoise1.kr(0.4,0.5,0.5);
	timbre = xz[0];

	// harm = 0.5;
	// harm = LFNoise2.kr(0.3,0.25,0.25);
	harm = zy[0];

	// dec = acc[3]*4;
	dec = LFNoise2.kr(0.2).range(0.01, 0.8);

	// 1, 13, 15, 6, 3, 9, before switching come back to 15
	kick = MiPlaits.ar(pitch, 13, harm, timbre, 0, Impulse.kr(2), decay: dec, mul: 1.1);
	// kick = MiPlaits.ar(pitch, 1, harm, timbre, 0, trigger[2], decay: dec, mul: 1.1);
	sig = kick;
	sig = sig + MiPlaits.ar(pitch, 15, harm, timbre, 0, Impulse.kr(4), mul: 0.75);

	// changes rhythm based on orientation
	sig = sig + MiPlaits.ar(pitch, 14, harm, timbre, 0, Impulse.kr((xz[0]*4).round), mul: 1.5);

	// sig = sig + MiPlaits.ar(pitch, 14, harm, timbre, 0, Impulse.kr(1), mul: 1.2);
	// sig = sig + MiPlaits.ar(pitch, 12, harm, timbre, 0, trigger[2], mul: 0.75);
	sig = sig / 4;

	sig = Compander.ar(sig, kick);

	// sig = MiPlaits.ar(pitch, 13, harm, timbre, 0.1, decay: dec, mul: 0.75);
	// sig = MiVerb.ar(sig, drywet: 0.4);
	// sig = sig + MiPlaits.ar(pitch, 13, harm, timbre, 0, trigger, decay: dec*2, mul: 0.25);
	// sig = MoogFF.ar(sig, 1200);
	// sig = CombC.ar(sig, mul: 0.2) + sig;
	// sig = LPF.ar(sig, 200, 0.2) + sig;
	sig = MiVerb.ar(sig, drywet: 0.3);
	// sig = FbC({ |fb| FreqShift.ar(sig + fb, 200).softclip * 0.8}, 4, 1);

	sig = sig*amp; // amp up to 4

	//out = 34 - (25 * comp[1]);
	// out = 4 * comp[1];
	//Out.ar(9 + (25 * comp[1]).round, sig);

	sig;
});
//Ndef(\lh_onsets).fadeTime = 8;
//Ndef(\lh_onsets).play(0, 2);
//Ndef(\lh_onsets).xset(\amp, 1.0);
//Ndef(\lh_onsets).stop
)
