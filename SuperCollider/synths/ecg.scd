(
SynthDef(\ecg_WhiteNoise, {
	var ecg = In.kr(~ecgBus.index, 2);
	Out.ar(0, ecg[1] * WhiteNoise.ar!2 * 0.01);
}).add;

SynthDef(\ecg_SineDrone, {
	arg out = 0, freq = 50, gate = 1.0, phase = 0, dur = 180, pan = 0, amp = 1.0;
	var env, noise, sig;
	var ecg = In.kr(~ecgBus.index, 2);
	env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur*1.25, doneAction: 2);
	sig = SinOsc.ar(freq * [1, 2, 3, 4], phase).sum * SinOsc.ar(1/11).range(0.1, 1);
	sig = sig * env;
	sig = Pan2.ar(sig, pan) * amp;
	Out.ar(out, sig * ecg[1]);
}).add;

SynthDef(\ecg_SawDrone, {
	arg out = 0, freq = 50, gate = 1.0, phase = 0, dur = 180, pan = 0, amp = 1.0;
	var env, noise, sig;
	var ecg = In.kr(~ecgBus.index, 2);
	env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur*1.25, doneAction: 2);
	sig = Saw.ar(freq * [1, 2, 3, 4], phase).sum * SinOsc.ar(1/11).range(0.1, 1);
	sig = sig * env;
	sig = Pan2.ar(sig, pan) * amp;
	Out.ar(out, sig * ecg[1]);
}).add;

SynthDef(\ecg_PulseDrone, {
	arg out = 0, freq = 50, gate = 1.0, phase = 0, dur = 180, pan = 0, amp = 1.0;
	var env, noise, sig;
	var ecg = In.kr(~ecgBus.index, 2);
	env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur*1.25, doneAction: 2);
	sig = Splay.ar(Pulse.ar(freq * [1, 1.5, 2, 2.5, 3], SinOsc.kr(2, phase, 0.5)).sum * SinOsc.ar(1/11).range(0.1, 1));
	sig = sig * env;
	sig = Pan2.ar(sig, pan) * amp;
	Out.ar(out, sig * ecg[1]);
}).add;
)
