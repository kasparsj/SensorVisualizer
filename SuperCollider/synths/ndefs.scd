(
~fadeTime = 0;

Ndef(\heart_sin, { |rec_out, onset_out, freq=440, ecg=0.0, amp=0.1, room=0.5|
	var sig, chain, onset, noise;
	noise = LFNoise0.ar(1/20);
	//noise = noise * Line.kr(0, 1, 90);
	sig = SinOsc.ar(freq * (1+noise));
	//sig = SinOsc.ar(freq);
	sig = sig * (1-ecg);
	chain = FFT(LocalBuf(1024), sig);

	onset = Onsets.kr(chain, 0.25);
	Out.kr(onset_out, onset);

	sig = RHPF.ar(sig, rq: 0.01);
	sig = MiVerb.ar(sig);
	sig = Compander.ar(sig, sig);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
Ndef(\heart_sin).fadeTime = ~fadeTime;

Ndef(\heart_perc, { |rec_out, hr=80, onset=0, ecg=0, room=0.5, amp=1.0|
	var sig, env, mul, track;
	env = EnvGen.ar(Env.perc, onset);
	sig = (SinOsc.ar(hr * ecg * 5) * env * ecg * 4);
	//sig = sig * Line.kr(0, 1, 90);
	//sig = FreeVerb.ar(sig, room: room);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
Ndef(\heart_perc).fadeTime = ~fadeTime;

// not working!!!
Ndef(\heart_perc_mi, { |rec_out, hr=80, min_hr=40, max_hr=180, onset=0, ecg=0, room=0.5, amp=1.0|
    var pit = ecg.range(30, 50).round;
	var timb = 0.4 + ((hr-min_hr)/(max_hr-min_hr));
    var color = LFNoise1.kr(0.3,0.5,0.5);
	var sig = MiBraids.ar(pit, timb, color, 34, onset*2-1);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
Ndef(\heart_perc_mi).fadeTime = ~fadeTime;

Ndef(\heart_perc2, { |rec_out, hr = 80, onset=0, ecg=0, room=0.5, amp=1.0|
	var sig, env, fmul, mul, track;

	env = EnvGen.ar(Env.perc, onset);

	fmul = 1.0 - ecg;
	mul = ecg * 3;
	sig = (SinOsc.ar(hr * fmul) * env * mul);
	//sig = sig * Line.kr(0, 1, 120);
	sig = FreeVerb.ar(sig, room: room);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
Ndef(\heart_perc2).fadeTime = ~fadeTime;

Ndef(\motion2, { |rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1|
	var sig = 0;
	var fcar = ([x, y, z]+500) + (hr * [1, 2, 3]);
	var rel = 1+64*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = LFSaw.ar(fcar + amod).sum;
	var acar2 = LFSaw.ar(fcar + amod*(1.01)).sum;
	sig = BPF.ar([acar1, acar2]*0.1, hr*rel);
	sig = GVerb.ar(sig[0]) + GVerb.ar(sig[1]);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
Ndef(\motion2).fadeTime = ~fadeTime;

Ndef(\motion2_mi, { |rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1|
	var sig;
	var timb = (x.clip(-1, 1)+2)/2;
	var color = (y.clip(-1, 1)+2)/2;
	sig = MiBraids.ar(hr, timb.clip(0, 1), color.clip(0, 1), 28+(hr/12).floor, resamp: 1, ws: z.abs.clip(0, 1));
	//sig = BPF.ar(sig, hr.midicps*z);
	//sig = MiVerb.ar(sig);
	sig = sig * LFSaw.kr(1/20, 1).range(0.01, mag*amp);
	//sig = sig * Line.kr(0, 1.1, 180);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
//Ndef(\motion2_mi).fadeTime = ~fadeTime;

Ndef(\motion3, { |rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1, pan=0|
	var sig = 0;
	var fcar = ([x, y, z]) + (hr * [1, 2, 3]);
	var rel = 1+16*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = SinOscFB.ar(fcar + amod, x).sum;
	var acar2 = SinOscFB.ar(fcar + amod*(1.01), y).sum;
	sig = BPF.ar([acar1, acar2]*0.1, hr*rel);
	sig = GVerb.ar(sig[0]) + GVerb.ar(sig[1]);

	sig = Balance2.ar(sig[0], sig[1], pan, amp);
	Out.ar(rec_out, sig*amp);
	sig;
});
Ndef(\motion3).fadeTime = ~fadeTime;

Ndef(\motion3_mi, { |rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1, pan=0|
	var timbre = (x.clip(-1, 1)+2)/2;
	var harm = (y.clip(-1, 1)+2)/2;
    var morph = z.abs.clip(0, 1);
	var sig = MiPlaits.ar(hr / 4, 5, harm, timbre, morph);
	//sig = BPF.ar(sig, hr.midicps*z);
	//sig = MiVerb.ar(sig);
	sig = sig * LFSaw.kr(1/20, 0).range(0.01, mag*amp);
	//sig = sig * Line.kr(0, 1.1, 180);

	sig = Balance2.ar(sig[0], sig[1], pan, amp);
	Out.ar(rec_out, sig*amp);
	sig;
});
Ndef(\motion3_mi).fadeTime = ~fadeTime;

Ndef(\heart_sin).set(\rec_out, ~recordBus.index, \onset_out, ~onsetBus.index, \ecg, ~ecgBus.asMap);
Ndef(\heart_perc).set(\rec_out, ~recordBus.index+1, \onset, ~onsetBus.asMap, \hr, ~hrBus.asMap, \ecg, ~ecgBus.asMap);
Ndef(\heart_perc2).set(\rec_out, ~recordBus.index+2, \onset, ~onsetBus.asMap, \hr, ~hrBus.asMap, \ecg, ~ecgBus.asMap);
Ndef(\motion2).set(\rec_out, ~recordBus.index+3, \hr, ~hrBus.asMap);
Ndef(\motion2_mi).set(\rec_out, ~recordBus.index+3, \hr, ~hrBus.asMap);
Ndef(\motion3).set(\rec_out, ~recordBus.index+5, \hr, ~hrBus.asMap);
Ndef(\motion3_mi).set(\rec_out, ~recordBus.index+5, \hr, ~hrBus.asMap);
)