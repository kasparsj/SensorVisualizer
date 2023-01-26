(
StageLimiter.activate;

ProxyChain.add(*[
	\in12, \mix -> {
		SoundIn.ar([0, 1]);
	},
	\lpf, \filter -> { |in, freq = 200, mul = 4|
		LPF.ar(in, freq, mul);
	},
	\moogVcf, \filter -> { |in, freq = 200, gain = 1|
		MoogFF.ar(in, freq, gain);
	},
	\freqShift, \filter -> { |in, freq = -200|
		FreqShift.ar(in, freq);
	},
	\feedback, \filter -> { |in, maxdelaytime=4, delaytime=1|
		//FbC({ |fb| FreqShift.ar(in + fb, 200).softclip * 0.1}, maxdelaytime, delaytime);
		in + (FbC({|fb| LPF.ar(in + (fb * 0.4), 3000)}, 4/8.0, 4/8.0, 2) * 0.2) +
		(FbC({|fb| LPF.ar(HPF.ar(in + (fb * 0.8), 2000), 6000) }, 6/8.0, 6/8.0, 2) * 0.1);
	},
	\delay, \filter -> { |in, maxdelaytime=0.25, delaytime=0.25|
		DelayN.ar(in, maxdelaytime, delaytime);
	},
	\comb, \filter -> { |in, maxdelaytime=0.1, delaytime=0.025, decaytime=2|
		CombN.ar(in, maxdelaytime, delaytime, decaytime);
	},
	\reverb, \filter -> { |in, preDelay=0.048, combDelay=0.1, combDecay=4, allpassDelay=0.050, allpassDecay=1|
		var z, y;
		// reverb predelay time :
		z = DelayN.ar(in, preDelay);
		// 7 length modulated comb delays in parallel :
		y = Mix.ar(Array.fill(7,{ CombL.ar(z, combDelay, LFNoise1.kr(combDelay.rand, 0.04, 0.05), combDecay) }));
		// two parallel chains of 4 allpass delays (8 total) :
		4.do({ y = AllpassN.ar(y, allpassDelay, [allpassDelay.rand, allpassDelay.rand], allpassDecay) });
		// add original sound to reverb and play it :
		y;
	},
	\gverb, \filter -> { |in, roomsize=50, revtime=3|
		GVerb.ar(in, roomsize, revtime);
	},
	\tanh, \filter -> { |in|
		in.tanh;
	},
	\limiter, \filter -> { |in, drive=1, ampLimit=1|
		Limiter.ar(in * drive, ampLimit);
	},
]);

~filterKeys = [\lpf, \moogVcf, \feedback, \delay, \comb, \reverb, \gverb, \tanh, \limiter];
~phi8Master = MasterFX(Server.default, 2, ~filterKeys);
~phi8Master.add(\lpf, 0.2);
~phi8Master.add(\moogVcf, 0.25);
//~phi8Master.add(\feedback, 1);
//~phi8Master.remove(\feedback);
~phi8Master.add(\gverb, 0.1);
//~phi8Master.add(\tanh, 1);
//~phi8Master.add(\limiter, 1);
//~phi8Master.gui;
)
