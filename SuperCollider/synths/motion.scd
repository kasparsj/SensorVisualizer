(
SynthDef(\motion1, { |out=0, room=0.5, amp=0.1, dur = 180, pan = 0, gate = 1.0|
	var sig, env;
	var hr = In.kr(~hrBus.index);
	var acc = In.kr(~chestAccBus.index, 5);
	var x = acc[0]/500;
	var y = acc[1]/500;
	var z = acc[2]/500;
	var mag = acc[4];
	var timb = (x.clip(-1, 1)+1)/2;
	var color = (y.clip(-1, 1)+1)/2;

	env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur, doneAction: 2);

	// sig = MiBraids.ar(hr/2, timb.clip(0, 1), color.clip(0, 1), 28+(hr/6).floor, resamp: 0, ws: z.abs.clip(0, 1));
	// sig = MiBraids.ar(12+(timb*60), timb, color, 28+(hr/6).floor, resamp: 0);
	// sig = MiBraids.ar(hr, timb.clip(0, 1), color.clip(0, 1), 28+(hr/12).floor, resamp: 1, ws: z.abs.clip(0, 1));
	// sig = sig*env;
	// sig = Pan2.ar(sig, pan, amp*mag);

	sig = MiPlaits.ar(24+(color*12), 2, color, timb, z.abs.clip(0, 1));
	sig = sig*env;
	sig = Balance2.ar(sig[0], sig[1], pan, amp*mag);

	// sig = BPF.ar(sig, hr.midicps*z); // do not
	sig = MiVerb.ar(sig);
	// try this out:
	//sig = sig * LFSaw.kr(1/20, 1).range(0.01, mag*amp);
	//sig = sig * Line.kr(0, 1.1, 180);
	Out.ar(out, sig);
}).add;
)
