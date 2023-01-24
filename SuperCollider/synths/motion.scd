(
SynthDef(\motion1, { |out=0, room=0.5, amp=0.1, dur = 180, pan = 0, gate = 1.0|
	var sig, env;
	var hr = In.kr(~hrBus.index);
	var acc = In.kr(~chestAccNormBus.index, 4);
	var timb = (acc[0]+1)/2;
	var harm = 1.0 - (acc[1]+1)/2;
	var degrees = (~scale.degrees ++ ~scale.degrees*2 ++ ~scale.degrees*3);
	var engines = [4, 6, 7, 14];
	var pitch = 12 + Select.kr(((hr + (degrees.size*(1.0-acc[3]))) % degrees.size), degrees);
	var engine = Select.kr(LFNoise2.kr(1/8)*engines.size, engines);

	env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur, doneAction: 2);
	sig = MiPlaits.ar(pitch, engine, harm, timb, (acc[2]+1)/2);
	sig = sig*env*amp*acc[3];
	sig = MiVerb.ar(sig, drywet: room);

	// try this out:
	// sig = BPF.ar(sig, hr.midicps*z); // do not
	//sig = sig * LFSaw.kr(1/20, 1).range(0.01, acc[3]*amp);
	//sig = sig * Line.kr(0, 1.1, 180);

	Out.ar(22 + ((12 * pan).round), sig);
	Out.ar(~subs, LPF.ar(sig, 80, 0.5));
	Out.ar(out, Balance2.ar(sig[0], sig[1], pan));
}).add;
)
