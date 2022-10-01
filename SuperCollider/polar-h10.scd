(
SynthDef(\heart_sin, { |out=0, freq=440, aout = 0, mod = 0.0, amp = 0.1, room = 0.5|
	var sig, chain, onset, noise;
	noise = LFNoise0.ar(1/14);
	sig = SinOsc.ar(freq * (1+noise));
	sig = sig * (1-mod);
	chain = FFT(LocalBuf(1024), sig);

	onset = Onsets.kr(chain, 0.25);
	Out.kr(out, onset);

	sig = RHPF.ar(sig, rq: 0.01);
	sig = Compander.ar(sig, sig);

	Out.ar(aout, sig!2*amp * LFPulse.ar(1/14) * noise);
}).add;

SynthDef(\heart_perc, { |out=0, freq=80, gate=0, mod=0, room=0.5, amp=1.0|
	var sig, env, fmul, mul, track;

	env = EnvGen.ar(Env.perc, gate);

	fmul = (mod*2);
	mul = mod * 3;
	sig = (SinOsc.ar(freq * fmul) * env * mul);
	//sig = FreeVerb.ar(sig, room: room);
	Out.ar(out, sig!2*amp * SinOsc.ar(1/13) * LFPulse.ar(1/13) * LFNoise0.ar(1/13));
}).add;

SynthDef(\heart_perc2, { |out=0, freq = 80, gate=0, mod=0, room=0.5, amp=1.0|
	var sig, env, fmul, mul, track;

	env = EnvGen.ar(Env.perc, gate);

	fmul = 1.0 - mod;
	mul = mod * 3;
	sig = (SinOsc.ar(freq * fmul) * env * mul);
	sig = FreeVerb.ar(sig, room: room);

	Out.ar(out, sig!2 * amp * LFPulse.ar(1/13, pi) * LFNoise0.ar(1/13));
}).add;

SynthDef(\motion2, { |out=0, freq=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1|
	var sig = 0;

	var fcar = ([x, y, z]) + (freq * [1, 2, 3]);
	var rel = 1+16*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = LFSaw.ar(fcar + amod);
	var acar2 = LFSaw.ar(fcar + amod*(1.01));
	sig = BPF.ar([acar1, acar2]*0.1, freq*rel);
	sig = GVerb.ar(sig);

	Out.ar(out, sig * amp * SinOsc.ar(1/12, pi));
}).add;

SynthDef(\motion3, { |out=0, freq=120, x=0, y=0, z=0, mag=0.5, room=0.5, amp=0.1|
	var sig = 0;

	var fcar = ([x, y, z]) + (freq * [1, 2, 3]);
	var rel = 1+16*mag;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = SinOscFB.ar(fcar + amod, x);
	var acar2 = SinOscFB.ar(fcar + amod*(1.01), y);
	sig = BPF.ar([acar1, acar2]*0.1, freq*rel);
	sig = GVerb.ar(sig);

	Out.ar(out, sig * amp * SinOsc.ar(1/11));
}).add;
)

(
var prefix = "/out";

~onsetBus.free;
~onsetBus = Bus.control(Server.default, 4).set(0);
~heartSin.free;
~heartSin = Synth(\heart_sin, [\out, ~onsetBus.index, \amp, 0.05]);
~heartPerc.free;
~heartPerc = Synth(\heart_perc, [\gate, ~onsetBus.asMap, \amp, 0.4], ~heartSin, \addAfter);
~heartPerc2.free;
~heartPerc2 = Synth(\heart_perc2, [\gate, ~onsetBus.asMap, \amp, 0.4], ~heartSin, \addAfter);
~motionSyn2.free;
~motionSyn2 = Synth(\motion2, [\amp, 0.2]);
~motionSyn3.free;
~motionSyn3 = Synth(\motion3, [\amp, 0.4]);

OSCdef(\ecg, {|msg, time, addr, recvPort|
	var data = msg[1..];
	~heartSin.set(\mod, data[4]);
	~heartSin.set(\freq, data[3] * rrand(1, 5));
	~heartPerc.set(\mod, data[4]);
	~heartPerc2.set(\mod, data[4]);
}, prefix++"/ecg");

OSCdef(\hr, {|msg, time, addr, recvPort|
	var data = msg[1..];
	~heartSin.set(\freq, data[1]*3);
	~heartPerc.set(\freq, data[1]);
	~heartPerc2.set(\freq, data[1]);
	~motionSyn2.set(\freq, data[1]*8);
	~motionSyn3.set(\freq, data[1]/2);
}, prefix++"/hr");

OSCdef(\acc, {|msg, time, addr, recvPort|
	var data = msg[1..];
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
}, prefix++"/acc");

OSCdef(\gyro, {|msg, time, addr, recvPort|
	msg.postln;
}, prefix++"/gyro");

OSCdef(\mag, {|msg, time, addr, recvPort|
	msg.postln;
}, prefix++"/mag");

)
