(
SynthDef(\plaits_snare, { |out=0, amp=1.0, gate=1.0, dur=1.0, midinote=47, harm=0.5, timbre = 0.173, morph = 0.827, revtime=0.01|
	var sig, env;
	// todo: quickfix for the reverb to end
	env = EnvGen.ar(Env.perc(curve: -1), gate, timeScale: dur+2, doneAction: 2);
    sig = MiPlaits.ar(midinote, 14, harm, timbre, morph, gate, gate, fm_mod: 0.2, timb_mod: 0.43, decay: 0.1);
	sig = sig * env * amp;
	sig = MiVerb.ar(sig, revtime, 0.7);
	Out.ar(out, sig);
	Out.ar(36, sig);
	Out.ar(39, sig);
}).add;
)