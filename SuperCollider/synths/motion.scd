(
Ndef(\chestEngine, {
	//var engines = [4, 6, 7, 14];
	var engines = [6, 7, 14];
	var engine;
	// engine = 7; // for Plaits
	engine = 14; // for Braids
	// engine = Select.kr(LFNoise0.kr(1/20).range(0, engines.size).floor, engines);
	engine;
}).fadeTime_(10);

Ndef(\chestPitch, {
	var degrees = ~scale.degrees;
	//var degrees = ((~scale.degrees+12) ++ (~scale.degrees+24));
	var hr = In.kr(~hrBus.index);
	var acc = In.kr(~chestAccNormBus.index, 4);
	var xz = In.kr(~chestProjXZBus.index, 4);
	var yx = In.kr(~chestProjYXBus.index, 4);
	var octave = 2, degree = 0, pitch = 0;
	// octave = 1;
	// octave = ((2.0-(acc[3]*3))*2).round.abs;
	// octave = Latch.kr(octave, Impulse.kr(1/2));
	octave = (yx[1] * 4).round;

	//degree = Latch.kr((compNorm*degrees.size).floor, Impulse.kr(128));
	// degree = (harm*degrees.size).floor;
	degree = Select.kr((hr + degree) % degrees.size, degrees);

	pitch = ~root + (12*octave) + degree;
	// pitch = ~root + (harm * 12 * octave);
	// pitch = pitch + TChoose.kr(gate, [0, 7, 12]);

	pitch;
}).fadeTime_(3);

SynthDef(\motion1, { |out=0, room=0.4, amp=0.14, dur = 180, pan = 0, gate = 1.0|
	var sig, env;
	var acc = In.kr(~chestAccNormBus.index, 4);
	var compNorm = In.kr(~compNormBus.index);
	var xz = In.kr(~chestProjXZBus.index, 4);
	var pitch = Ndef.kr(\chestPitch, 1);
	var timb, timb_mod, harm, morph = 0;
	var engine = Ndef.kr(\chestEngine, 1);

	timb = (acc[0]+1)/2;
	harm = (acc[1]+1)/2;
	morph = (acc[2]+1)/2;

	dur = (acc[3] * 100).max(0.01).min(3);

	env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur, doneAction: 2);
	// sig = MiPlaits.ar(pitch, engine, harm, timb, morph, mul: 0.7);
	sig = MiBraids.ar(pitch, timb, harm, engine);
	sig = sig*env*amp*acc[3];
	sig = MiVerb.ar(sig, drywet: room);
	// sig = sig!2;

	// try this out:
	// sig = LPF.ar(sig, 200) + (sig * 0.3); // do not
	// sig = MoogFF.ar(sig, 200) + (sig * 0.7); // do not
	//sig = sig * Line.kr(0, 1.1, 180);

	//Out.ar(22 + ((12 * pan).round), sig);
	//Out.ar(~subs, LPF.ar(sig, 80));
	Out.ar(out, Balance2.ar(sig[0], sig[1], pan));
}).add;
)
