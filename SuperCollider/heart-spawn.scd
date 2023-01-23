(
s.waitForBoot {

	~heart = Bus.control(s, 1);

	SynthDef(\heart, {
		Out.kr(~heart.index, SinOsc.kr(1));
		//Out.kr(~heart.index, Max30102.kr(0) * 0.1);
	}).add;

	SynthDef(\heartTrig, {
		var irAc = In.kr(~heart.index);
		SendReply.kr(Impulse.kr(1/2), '/trigVal', [irAc]);
	}).add;

	SynthDef(\WhiteNoise, {
		Out.ar(0, In.kr(~heart.index) * WhiteNoise.ar!2 * 0.01);
	}).add;

	SynthDef(\SineDrone, {
		arg out = 0, freq = 50, gate = 1.0, phase = 0, dur = 180, pan = 0, amp = 1.0;
		var env, noise, sig;
		env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur*1.25, doneAction: 2);
		sig = SinOsc.ar(freq * [1, 2, 3, 4], phase).sum * SinOsc.ar(1/11).range(0.1, 1);
		sig = sig * env;
		sig = Pan2.ar(sig, pan) * amp;
		Out.ar(out, sig * In.kr(~heart.index));
	}).add;

	SynthDef(\SawDrone, {
		arg out = 0, freq = 50, gate = 1.0, phase = 0, dur = 180, pan = 0, amp = 1.0;
		var env, noise, sig;
		env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur*1.25, doneAction: 2);
		sig = Saw.ar(freq * [1, 2, 3, 4], phase).sum * SinOsc.ar(1/11).range(0.1, 1);
		sig = sig * env;
		sig = Pan2.ar(sig, pan) * amp;
		Out.ar(out, sig * In.kr(~heart.index));
	}).add;

	SynthDef(\PulseDrone, {
		arg out = 0, freq = 50, gate = 1.0, phase = 0, dur = 180, pan = 0, amp = 1.0;
		var env, noise, sig;
		env = EnvGen.ar(Env([0, 0.01, 1.0, 0], [0.01, 0.98, 0.01]), gate, timeScale: dur*1.25, doneAction: 2);
		sig = Splay.ar(Pulse.ar(freq * [1, 1.5, 2, 2.5, 3], SinOsc.kr(2, phase, 0.5)).sum * SinOsc.ar(1/11).range(0.1, 1));
		sig = sig * env;
		sig = Pan2.ar(sig, pan) * amp;
		Out.ar(out, sig * In.kr(~heart.index));
	}).add;

	s.sync;

	Pdef(\heartSpawn, Pseq([
		Pfindur(300, Pspawn(Pbind(
			\pattern, Pfunc {
				var which = (0..2).choose;
				var instruments = [\SineDrone, \SawDrone, \PulseDrone];
				var dur = rrand((30/1.25), (180/1.25)).asInteger;
				var freq = (51..(51+rrand(1, 3))).scramble;
				var pan = [-1, 1].scramble;
				Pbind(
					\instrument, instruments[which],
					\freq, freq,
					\dur, Pseq([dur], 1),
					\pan, pan,
					\phase, Pwhite(0, 2pi, 1),
					\out, 0,
					\amp, 0.075
				)
			},
			\delta, Pwhite(32, 256, inf) * 0.25,
			\method, \par
	)))], inf)).play;

	//~hs = Synth(\heart);
	//~ht = Synth.after(~hs, \heartTrig);
	~ht = Synth(\heartTrig);
	Synth.after(~ht, \WhiteNoise);

	~net = NetAddr("127.0.0.1", 12345);

	~buffer = Buffer.alloc(s, 44100 / 64 * 10.0, 1); // 10 second 1 channel Buffer

	~oscr.remove;
	~oscr = OSCFunc({|msg, time, addr, port|
		//msg[3].postln;
		if ((msg[3] == 0), {
			~net.sendMsg("/pause");
		}, {
			~net.sendMsg("/resume");
		});
	}, '/trigVal');



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
	~phi8Master.add(\feedback, 1);
	~phi8Master.add(\gverb, 0.1);
	~phi8Master.add(\tanh, 1);
	~phi8Master.add(\limiter, 1);
}
)

MasterFX.clear('localhost')
Pdef(\heartSpawn).stop;