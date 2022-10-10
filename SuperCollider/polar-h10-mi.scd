(
SynthDef(\heart_sin, { |out=0, rec_out, onset_out, freq=440, mod=0.0, amp=0.1, room=0.5|
	var sig, chain, onset, noise;
	noise = LFNoise0.ar(1/20) * Line.kr(0, 1, 90);
	sig = SinOsc.ar(freq * (1+noise));
	sig = sig * (1-mod);
	chain = FFT(LocalBuf(1024), sig);

	onset = Onsets.kr(chain, 0.25);
	Out.kr(onset_out, onset);

	sig = RHPF.ar(sig, rq: 0.01);
	sig = MiVerb.ar(sig);
	sig = Compander.ar(sig, sig);
	sig = sig * Line.kr(0, 1, 10);

	Out.ar(out, sig!2*amp);
	Out.ar(rec_out, sig*amp);
}).add;

SynthDef(\heart_perc, { |out=0, rec_out, hr=80, gate=0, mod=0, room=0.5, amp=1.0|
	var sig, env, fmul, mul, track;
	env = EnvGen.ar(Env.perc, gate);
	fmul = (mod*2);
	mul = mod * 3;
	sig = (SinOsc.ar(hr * fmul) * env * mul);
	sig = sig * Line.kr(0, 1, 90);
	//sig = FreeVerb.ar(sig, room: room);

	Out.ar(out, sig!2*amp);
	Out.ar(rec_out, sig*amp);
}).add;

// not working!!!
SynthDef(\heart_perc_mi, { |out=0, rec_out, hr=80, min_hr=40, max_hr=180, gate=0, mod=0, room=0.5, amp=1.0|
    var pit = mod.range(30, 50).round;
	var timb = 0.4 + ((hr-min_hr)/(max_hr-min_hr));
    var color = LFNoise1.kr(0.3,0.5,0.5);
	var sig = MiBraids.ar(pit, timb, color, 34, gate*2-1);

	Out.ar(out, sig!2*amp);
	Out.ar(rec_out, sig*amp);
}).add;

SynthDef(\heart_perc2, { |out=0, rec_out, hr = 80, gate=0, mod=0, room=0.5, amp=1.0|
	var sig, env, fmul, mul, track;

	env = EnvGen.ar(Env.perc, gate);

	fmul = 1.0 - mod;
	mul = mod * 3;
	sig = (SinOsc.ar(hr * fmul) * env * mul);
	sig = sig * Line.kr(0, 1, 120);
	sig = FreeVerb.ar(sig, room: room);

	Out.ar(out, sig!2*amp);
	Out.ar(rec_out, sig*amp);
}).add;

SynthDef(\motion2, { |out=0, rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1|
	var sig = 0;
	var fcar = ([x, y, z]) + (hr * [1, 2, 3]);
	var rel = 1+16*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = LFSaw.ar(fcar + amod);
	var acar2 = LFSaw.ar(fcar + amod*(1.01));
	sig = BPF.ar([acar1, acar2]*0.1, hr*rel);
	sig = GVerb.ar(sig);

	Out.ar(out, sig*amp);
	Out.ar(rec_out, sig*amp);
}).add;

SynthDef(\motion2_mi, { |out=0, rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1|
	var sig;
    var timb = 0.1+(mag/2)+(x/2);
    var color = 0.1+(mag/2)+(y/2);
    sig = MiBraids.ar(hr, timb, color, 28+(hr/12).floor, resamp: 1, ws: z) ! 2;
	//sig = BPF.ar(sig, hr.midicps*z);
	//sig = MiVerb.ar(sig);
	sig = sig * LFSaw.kr(1/20, 1).range(0.1, amp);
	sig = sig * Line.kr(0, 1.1, 180);

	Out.ar(out, sig*amp);
	Out.ar(rec_out, sig*amp);
}).add;

SynthDef(\motion3, { |out=0, rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1, pan=0|
	var sig = 0;
	var fcar = ([x, y, z]) + (hr * [1, 2, 3]);
	var rel = 1+16*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = SinOscFB.ar(fcar + amod, x);
	var acar2 = SinOscFB.ar(fcar + amod*(1.01), y);
	sig = BPF.ar([acar1, acar2]*0.1, hr*rel);
	sig = GVerb.ar(sig);

	Out.ar(out, Pan2.ar(sig*amp, pan));
	Out.ar(rec_out, sig*amp);
}).add;

SynthDef(\motion3_mi, { |out=0, rec_out, hr=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1, pan=0|
    var timbre = 0.1+(mag/2)+(x/2);
    var harm = 0.1+(mag/2)+(y/2);
    var morph = z;
	var sig = MiPlaits.ar(hr / 4, 5, harm, timbre, morph);
	//sig = BPF.ar(sig, hr.midicps*z);
	//sig = MiVerb.ar(sig);
	sig = sig * LFSaw.kr(1/20, 0).range(0.1, amp);
	sig = sig * Line.kr(0, 1.1, 180);

	Out.ar(out, Pan2.ar(sig*amp, pan));
	Out.ar(rec_out, sig*amp);
}).add;
)

(
r = nil;
StageLimiter.activate;

~prefix = "/out";
~recordBus.free;
~recordBus = Bus.audio(Server.default, 7);
~onsetBus.free;
~onsetBus = Bus.control(Server.default, 4).set(0);
~heartSin.free;
~heartSin = Synth(\heart_sin, [\rec_out, ~recordBus.index, \onset_out, ~onsetBus.index, \amp, 0.025]);
~heartPerc.free;
~heartPerc = Synth(\heart_perc, [\rec_out, ~recordBus.index+1, \gate, ~onsetBus.asMap, \amp, 0.4], ~heartSin, \addAfter);
~heartPerc2.free;
~heartPerc2 = Synth(\heart_perc2, [\rec_out, ~recordBus.index+2, \gate, ~onsetBus.asMap, \amp, 0.4], ~heartSin, \addAfter);
~motionSyn2.free;
~motionSyn2 = Synth(\motion2_mi, [\rec_out, ~recordBus.index+3, \amp, 0.5]);
~motionSyn3.free;
~motionSyn3 = Synth(\motion3_mi, [\rec_out, ~recordBus.index+5, \amp, 0.75]);

OSCdef(\ecg, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, value, minValue, maxValue, percValue, avgValue
	~heartSin.set(\mod, data[4]);
	~heartSin.set(\freq, data[3]);
	~heartPerc.set(\mod, data[4]);
	~heartPerc2.set(\mod, data[4]);
}, ~prefix++"/ecg");

OSCdef(\hr, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, value, minValue, maxValue, percValue, avgValue
	~heartSin.set(\hr, data[1]);
	~heartPerc.set(\hr, data[1]);
	~heartPerc2.set(\hr, data[1]);
	~motionSyn2.set(\hr, data[1]);
	~motionSyn3.set(\hr, data[1]);
}, ~prefix++"/hr");

OSCdef(\quat, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, x, y, z, w, xz.x, xz.y, xz.mag, xz.heading, yz.x, yx.y, yx.mag, yx.heading, zy.x, zy.y, zy.mag, zy.heading
	if (data[0].asString() == "7E37D222", {
		~motionSyn2.set(\pan, 0.2-data[11]);
	});
	if (data[0].asString() == "m5StickC", {
		~motionSyn3.set(\pan, data[11]*2);
	});
}, ~prefix++"/hr");

OSCdef(\acc, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, x, y, z, mag, magPerc, magDeltaSum, magDeltaSumPerc, heading

	// todo: https://github.com/KChen89/Accelerometer-Filtering
	// https://github.com/nerajbobra/embedded_pedometer

	// first combine and then introduce the next sensor
	// first introduce impredactibility
	// the performer has to think and react to the complex systems
	// sound synthesis that work very well with microphones -> try spectral delay

	// written documentation 4-6 pages
	if (data[0].asString() == "7E37D222", {
		~motionSyn2.set(\x, data[1], \y, data[2], \z, data[3], \mag, data[5]);
	});
	if (data[0].asString() == "m5StickC", {
		~motionSyn3.set(\x, data[1], \y, data[2], \z, data[3], \mag, data[5]);
	});
}, ~prefix++"/acc");

OSCdef(\gyro, {|msg, time, addr, recvPort|
	msg.postln;
}, ~prefix++"/gyro");

OSCdef(\mag, {|msg, time, addr, recvPort|
	msg.postln;
}, ~prefix++"/mag");

OSCdef(\record, {|msg, time, addr, recvPort|
	if (r.isNil, {
		r = Recorder(s);
		r.record(bus: ~recordBus, numChannels: ~recordBus.numChannels);
	});
}, ~prefix++"/resume");

)

~motionSyn2.set(\amp, 0.5);
~motionSyn3.set(\amp, 0);
~heartSin.set(\amp, 0.025); // 0.025
~heartPerc.set(\amp, 0); // 0.4
~heartPerc2.set(\amp, 0); // 0.4