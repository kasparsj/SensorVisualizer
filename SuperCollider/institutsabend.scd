(
r = nil;
StageLimiter.activate;

~fadeTime = 0;
~record = false;
~prefix = "/out";
~recordBus.free;
~recordBus = Bus.audio(Server.default, 7);
~onsetBus.free;
~onsetBus = Bus.control(Server.default, 4).set(0);
~numAccBatchArgs = 5;

Ndef(\heart_sin, { |rec_out, onset_out, freq=440, mod=0.0, amp=0.1, room=0.5|
	var sig, chain, onset, noise;
	noise = LFNoise0.ar(1/20);
	//noise = noise * Line.kr(0, 1, 90);
	sig = SinOsc.ar(freq * (1+noise));
	//sig = SinOsc.ar(freq);
	sig = sig * (1-mod);
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

Ndef(\heart_perc, { |rec_out, hr=80, onset=0, mod=0, room=0.5, amp=1.0|
	var sig, env, mul, track;
	env = EnvGen.ar(Env.perc, onset);
	sig = (SinOsc.ar(hr * mod * 5) * env * mod * 4);
	//sig = sig * Line.kr(0, 1, 90);
	//sig = FreeVerb.ar(sig, room: room);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
Ndef(\heart_perc).fadeTime = ~fadeTime;

// not working!!!
Ndef(\heart_perc_mi, { |rec_out, hr=80, min_hr=40, max_hr=180, onset=0, mod=0, room=0.5, amp=1.0|
    var pit = mod.range(30, 50).round;
	var timb = 0.4 + ((hr-min_hr)/(max_hr-min_hr));
    var color = LFNoise1.kr(0.3,0.5,0.5);
	var sig = MiBraids.ar(pit, timb, color, 34, onset*2-1);

	Out.ar(rec_out, sig*amp);
	sig*amp;
});
Ndef(\heart_perc_mi).fadeTime = ~fadeTime;

Ndef(\heart_perc2, { |rec_out, hr = 80, onset=0, mod=0, room=0.5, amp=1.0|
	var sig, env, fmul, mul, track;

	env = EnvGen.ar(Env.perc, onset);

	fmul = 1.0 - mod;
	mul = mod * 3;
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
    var timbre = 0.1+(mag/2)+(x/2);
    var harm = 0.1+(mag/2)+(y/2);
    var morph = z;
	var sig = MiPlaits.ar(hr / 4, 5, harm, timbre, morph);
	//sig = BPF.ar(sig, hr.midicps*z);
	//sig = MiVerb.ar(sig);
	sig = sig * LFSaw.kr(1/20, 0).range(0.1, amp);
	//sig = sig * Line.kr(0, 1.1, 180);

	sig = Balance2.ar(sig[0], sig[1], pan, amp);
	Out.ar(rec_out, sig*amp);
	sig;
});
Ndef(\motion3_mi).fadeTime = ~fadeTime;

OSCdef(\ecg, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, value, minValue, maxValue, percValue, avgValue
	Ndef(\heart_sin).set(\freq, data[3], \mod, data[4]);
	Ndef(\heart_perc).set(\mod, data[4]);
	Ndef(\heart_perc2).set(\mod, data[4]);
}, ~prefix++"/ecg");

OSCdef(\ecg_batch, {|msg, time, addr, recvPort|
	 // addr, deviceId, numArgs, arg1[, arg2]
	~numEcgBatchArgs = msg[2].asInteger;
	~ecg = msg[3..];
}, ~prefix++"/ecg/batch");

OSCdef(\hr, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, value, minValue, maxValue, percValue, avgValue
	Ndef(\heart_sin).set(\hr, data[1]);
	Ndef(\heart_perc).set(\hr, data[1]);
	Ndef(\heart_perc2).set(\hr, data[1]);
	Ndef(\motion_mi2).set(\hr, data[1]);
	Ndef(\motion_mi3).set(\hr, data[1]);
}, ~prefix++"/hr");

OSCdef(\quat, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, x, y, z, w, xz.x, xz.y, xz.mag, xz.heading, yz.x, yx.y, yx.mag, yx.heading, zy.x, zy.y, zy.mag, zy.heading
	if (data[0].asString() == "7E37D222", {
		Ndef(\motion2_mi).set(\pan, 0.2-data[11]);
	});
	if (data[0].asString() == "m5StickC", {
		Ndef(\motion3_mi).set(\pan, data[11]*2);
	});
}, ~prefix++"/quat");

OSCdef(\acc, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, x, y, z, mag, magPerc, magDeltaSum, magDeltaSumPerc, heading
	if (data[0].asString() == "7E37D222", {
		Ndef(\motion2_mi).set(\x, data[1], \y, data[2], \z, data[3], \mag, data[5]);
	});
	if (data[0].asString() == "m5StickC", {
		Ndef(\motion3_mi).set(\x, data[1], \y, data[2], \z, data[3], \mag, data[5]);
	});
}, ~prefix++"/acc");

OSCdef(\acc_batch, {|msg, time, addr, recvPort|
	// addr, deviceId, numArgs, arg1
	if (msg[1].asString() == "7E37D222", {
		~numAccBatchArgs = msg[2].asInteger;
		~acc = msg[3..];
	});
}, ~prefix++"/acc/batch");

OSCdef(\gyro, {|msg, time, addr, recvPort|
	//msg.postln;
}, ~prefix++"/gyro");

OSCdef(\mag, {|msg, time, addr, recvPort|
	//msg.postln;
}, ~prefix++"/mag");

OSCdef(\record, {|msg, time, addr, recvPort|
	if (~record and: { r.isNil }, {
		r = Recorder(s);
		r.record(bus: ~recordBus, numChannels: ~recordBus.numChannels);
	});
}, ~prefix++"/resume");

Tdef(\ecg_loop, { loop {
	if (~ecg.size > 0) {
		var val = ~ecg[0];
		var perc = (val.min(3000).max(-3000) / 3000).range(0, 1);
		Ndef(\heart_sin).set(\freq, val, \mod, perc);
		Ndef(\heart_perc).set(\mod, perc);
		Ndef(\heart_perc2).set(\mod, perc);
		~heartBus.setSynchronous(perc);
		~ecg = ~ecg[1..];
	};
	(1.0/130).wait;
} }).play;

Tdef(\acc_loop, { loop {
	if (~acc.size > 0) {
		var val = ~acc[0..(~numAccBatchArgs-1)];
		Ndef(\motion2).set(\x, val[0], \y, val[1], \z, val[2], \mag, val[4]);
		Ndef(\motion2_mi).set(\x, val[0]/500, \y, val[1]/500, \z, val[2]/500, \mag, val[4]);
		~acc = ~acc[~numAccBatchArgs..];
	};
	(1.0/200).wait;
} }).play;

Ndef(\heart_sin).set(\rec_out, ~recordBus.index, \onset_out, ~onsetBus.index);
Ndef(\heart_perc).set(\rec_out, ~recordBus.index+1, \onset, ~onsetBus.asMap);
Ndef(\heart_perc2).set(\rec_out, ~recordBus.index+2, \onset, ~onsetBus.asMap);
Ndef(\motion2).set(\rec_out, ~recordBus.index+3);
Ndef(\motion2_mi).set(\rec_out, ~recordBus.index+3);
Ndef(\motion3).set(\rec_out, ~recordBus.index+5);
Ndef(\motion3_mi).set(\rec_out, ~recordBus.index+5);

)

(
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
Ndef(\motion3).play(0, 2);
//Ndef(\motion3_mi).play(0, 2);
)

Ndef(\heart_sin).stop(5);
Ndef(\heart_perc).stop(5);
Ndef(\heart_perc2).stop(5);
Ndef(\motion2).stop(5);
Ndef(\motion2_mi).stop(5);
Ndef(\motion3).stop(5);
Ndef(\motion3_mi).stop(5);
