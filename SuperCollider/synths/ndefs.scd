(
if (~ecgBus.isNil) {
	"../config.scd".loadRelative;
};

Ndef(\heart_sin, { |amp=0.1, room=0.5|
	var sig, chain, onset, noise, ecg, ecgNorm, vbap;
	ecg = In.kr(~ecgBus.index);
	ecgNorm = In.kr(~ecgNormBus.index);
	noise = LFNoise0.ar(1/10);
	sig = SinOsc.ar(ecg * (1+noise));
	sig = sig * (1-ecgNorm);
	chain = FFT(LocalBuf(1024), sig);

	onset = Onsets.kr(chain, 0.25);
	Out.kr(~onsetBus.index, onset);

	sig = RHPF.ar(sig, rq: 0.01);
	sig = MiVerb.ar(sig, drywet: room);
	sig = Compander.ar(sig, sig);
	sig = sig * amp;

	//Out.ar(~recordBus.index, sig);
	//Out.ar(9 + (25 * LFNoise2.kr(1/4)).round, sig);
	//vbap = VBAP.ar(~vbapList.size, sig, ~vbapBuf.bufnum, LFNoise2.kr(1/3)*180, 30, 30);
	//Out.ar(0, vbap);
	//Out.ar(35, sig[0]);
	//Out.ar(38, sig[1]);

	sig;
});
//Ndef(\heart_sin).play(0, 2);
//Ndef(\heart_sin).stop;

Ndef(\heart_perc, { |room=0.5, amp=0.25|
	var sig, env, ecgNorm, hr, onset, vbap;
	ecgNorm = In.kr(~ecgNormBus.index);
	hr = In.kr(~hrBus.index);
	onset = In.kr(~onsetBus.index);
	env = EnvGen.ar(Env.perc, onset);
	sig = (SinOsc.ar(hr * ecgNorm * 5) * env * ecgNorm * 4);
	//sig = sig * Line.kr(0, 1, 90);
	// sig = HPF.ar(sig, 400);
	sig = FreeVerb.ar(sig, room: room)!2;
	// sig = MiVerb.ar(sig, drywet: room);
	sig = sig * amp;
	sig = sig * LFNoise2.kr(1/5).range(0.7, 1.0);

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
//  var ecgNorm = In.kr(~ecgNormBus.index);
//  var hr = In.kr(~hrBus.index);
//  var onset = In.kr(~onsetBus.index);
// 	var pit = ecgNorm.range(30, 50).round;
// 	var timb = 0.4 + ((hr-min_hr)/(max_hr-min_hr));
// 	var color = LFNoise1.kr(0.3,0.5,0.5);
// 	var sig = MiBraids.ar(pit, timb, color, 34, onset*2-1);
//
// 	Out.ar(~recordBus.index, sig*amp);
// 	sig*amp;
// });
// Ndef(\heart_perc_mi).fadeTime = ~fadeTime;

Ndef(\heart_perc2, { |room=0.25, amp=1.0|
	var sig, env, fmul, mul, ecgNorm, hr, onset;
	ecgNorm = In.kr(~ecgNormBus.index);
	hr = In.kr(~hrBus.index);
	onset = In.kr(~onsetBus.index);
	env = EnvGen.ar(Env.perc, onset);

	fmul = 1.0 - ecgNorm;
	mul = ecgNorm*3;
	sig = (SinOsc.ar(hr * fmul) * env * mul);
	sig = LPF.ar(sig, 80);
	sig = FreeVerb.ar(sig, room: room)!2;
	// sig = MiVerb.ar(sig, drywet: room);
	sig = sig * amp;
	sig = sig * LFNoise2.kr(1/5).range(0.7, 1.0);
	//sig = sig * Line.kr(0, 1, 120);

	// todo: fix - changed to output 2 channels
	//Out.ar(~recordBus.index+2, sig);
	sig;
});
//Ndef(\heart_perc2).fadeTime = 1;
//Ndef(\heart_perc2).play(0, 2, addAction: \addToTail);
//Ndef(\heart_perc2).stop;

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

Ndef(\control1, { |room=0.5, amp=1.0, pan=0|
	var sig;
	var hr = In.kr(~hrBus.index);
	var quat = In.kr(~rhQuatBus.index, 16);
	var xz = (quat[4..7]+1)/2;
	var yx = (quat[8..11]+1)/2;
	var zy = (quat[12..15]+1)/2;

	sig = MiBraids.ar(hr.max(60), xz[0], xz[1], 12);
	sig = sig + MiBraids.ar(hr.max(60)+4, yx[0], yx[1], 14);
	sig = sig + MiBraids.ar(hr.max(60)+7, zy[0], zy[1], 44);
	sig = sig / 3;

	// sig = MiPlaits.ar(12+(color*12), (7-(hr/16).floor).clip(0, 15), color, timb, (acc[3]+1)/2);
	// sig = MiPlaits.ar(24+(color*12), 2, color, timb, z.abs.clip(0, 1));

	sig = MiVerb.ar(sig);

	sig = Balance2.ar(sig[0], sig[1], pan, amp);

	sig;
});
// Ndef(\control1).play(0, 2);
// Ndef(\control1).xset(\amp, 0.5);
// Ndef(\control1).stop;

Ndef(\breath, { |amp=1.0|
	var sig = SoundIn.ar(0);
	sig = sig*amp;
	Out.kr(~breathBus.index, sig);
	//Out.ar(36, sig);
	//Out.ar(37, sig);
	(sig!2)*~breathEnabled;
});

Ndef(\rh_onsets, { |amp=0|
	var acc = In.kr(~rhAccNormBus.index, 4);
	var compNorm = In.kr(~compNormBus.index);
	// var harm = LFNoise2.kr(0.3,0.25,0.25);
	// var timbre = LFNoise1.kr(0.4,0.5,0.5);
	var timbre = (acc[0]+1)/2;
	var harm = (acc[1]+1)/2;
	//var dec = LFNoise2.kr(0.2).range(0.01,0.8);
	var dec = acc[3];
	var chain = FFT(LocalBuf(128), acc[3]);
	var trigger = Onsets.kr(chain, 0.75, \rcomplex, 0.01, 0.1, 1);
	//var trigger = Onsets.kr(chain, 0.75);
	var out = 10 + (25 * compNorm);
	var sig = MiPlaits.ar(80-(acc[3]*80), 6, harm, timbre, 0, trigger, decay: dec, mul: 0.75);
	//var sig = MiPlaits.ar(80-(acc[3]*80), compNorm*15, harm, timbre, 0, trigger, decay: dec, mul: 0.75);
	// sig = sig + MiPlaits.ar(36-(acc[3]*24), 13, harm, timbre, 0, trigger, decay: dec*2, mul: 0.25);
	Out.ar(9 + (25 * compNorm).round, sig*amp);
	sig*amp*0;
});

Ndef(\lh_onsets, { |amp=0|
	var acc = In.kr(~lhAccNormBus.index, 4);
	var compNorm = In.kr(~compNormBus.index);
	// var harm = LFNoise2.kr(0.3,0.25,0.25);
	// var timbre = LFNoise1.kr(0.4,0.5,0.5);
	var timbre = (acc[0]+1)/2;
	var harm = (acc[1]+1)/2;
	//var dec = LFNoise2.kr(0.2).range(0.01,0.8);
	var dec = acc[3];
	var chain = FFT(LocalBuf(128), acc[3]);
	var trigger = Onsets.kr(chain, 0.75, \rcomplex, 0.01, 0.1, 1);
	//var trigger = Onsets.kr(chain, 0.75);
	var out = 10 + (25 * compNorm);
	// var sig = MiPlaits.ar(80-(acc[3]*80), 6, harm, timbre, 0, trigger, decay: dec, mul: 0.75);
	var sig = MiPlaits.ar(80-(acc[3]*80), compNorm*15, harm, timbre, 0, trigger, decay: dec, mul: 0.75);
	// sig = sig + MiPlaits.ar(36-(acc[3]*24), 13, harm, timbre, 0, trigger, decay: dec*2, mul: 0.25);
	Out.ar(9 + (25 * compNorm).round, sig*amp);
	sig*amp*0;
});
)