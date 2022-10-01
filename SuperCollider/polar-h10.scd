(
~onsetBus.free;
// ~onsetBus = Bus.control(Server.default, 1).set(0);
~onsetBus = Bus.control(Server.default, 4).set(0);
)

(
var rootFreq = 80;
~heartSin.free;
~heartSin = SynthDef(\heart_sin, { |out=0, aout = 0, mod = 0.0, amp = 0.1|
	var sig, chain, onset;
	sig = SinOsc.ar();
	sig = sig * (1-mod);
	chain = FFT(LocalBuf(1024), sig);

	onset = Onsets.kr(chain, 0.25);
	Out.kr(out, onset);

	Out.ar(aout, sig!2*amp);
}).play(args: [\out, ~onsetBus.index, \amp, 0.1]);

~heartSound.free;
~heartSound = SynthDef(\heart_perc, { |out=0, gate=0, mod=0, room=0.5, amp=1.0|
	var sig, env, fmul, mul, track;

	env = EnvGen.ar(Env.perc, gate);

	// todo: link with motion, so that different samples trigger

	fmul = (1.0 - (mod*2));
	mul = mod * 3;
	sig = (SinOsc.ar(rootFreq * fmul) * env * mul);
	sig = FreeVerb.ar(sig, room: room);
	Out.ar(out, sig!2*amp);
}).play(target: ~heartSin, args: [\gate, ~onsetBus.asMap, \amp, 1.0], addAction: \addAfter);

~motionSyn.free;
~motionSyn = SynthDef(\motion, { |out = 0, x = 0, y = 0, z = 0, mag = 0, room=0.5, amp = 0.5|
	var sig = 0;

	// x.poll; // liekties uz visam pusem, default 0.25
	// y.poll; // liekties uz saniem, default 0.5
	// z.poll; // liekties uz prieks/atpakal, default 0.5

	// MiPlaits.ar(rootFreq * [1, 2, 3], (x*10).asInteger, y, z, mag).sum * (0.1+mag);

	//sig = Formants.ar(([1, 2, 3, 4] * rootFreq * [x.min(0.003), y.min(0.003), z.min(0.003)]).flat, Vowel([\u, \e], [\soprano]),
	//	freqMods: LFNoise2.ar(0.1*[0.1, 0.2, 0.3, 0.4, 0.5].scramble, 0.1), unfold: true).sum * 0.3 * (1.0+mag);
	//sig = GVerb.ar(sig, room * 10);
	//Out.ar(out, sig!2 * amp);

	// combine pulse and movement
	// more sensors (like mike)
	// introduce more unpredactability -> performer thinks i am doing this, but the sound is not as expected
	// fm instrument -> try swapping the axis parameters
	// introduce samples -> when things reach some higher limits

	var fcar = y * 240 + 40;
	var rel = 1+16*x;
	var fmod = fcar * rel.round;
	var amod = LFNoise0.ar(fmod);
	var acar1 = LFSaw.ar(fcar + amod);
	var acar2 = LFSaw.ar(fcar + amod*(1+z));
	sig = GVerb.ar([acar1, acar2]*0.1);

	Out.ar(out, sig * amp * mag);
}).play;
)

(
var prefix = "/out";
OSCdef(\ecg, {|msg, time, addr, recvPort|
	var data = msg[1..];
	~heartSin.set(\mod, data[4]);
	~heartSound.set(\mod, data[4]);
}, prefix++"/ecg");

OSCdef(\acc, {|msg, time, addr, recvPort|
	var data = msg[1..];
	// todo: https://github.com/KChen89/Accelerometer-Filtering
	// todo: 9.8g acceleration of gravity
	// todo: when jumping, magnitude goes down to 0g
	// todo: when falling, e.g. squatting, magnitude goes up to 3000 (gravity + 20.2g)
	// todo: can be used to calculate pitch and roll
	// todo: should be able to detect impacts, that is sudden stops or reverses
	// todo: should be able to detect change of speed along an axis
	// todo: can integrate to know the absolute speed, movement along an axis
	// todo: can be trained to recognize gestures, like walking, running etc?
	// https://github.com/nerajbobra/embedded_pedometer

	// first combine and then introduce the next sensor
	// first introduce impredactibility
	// the performer has to think and react to the complex systems
	// sound synthesis that work very well with microphones -> try spectral delay

	// written documentation 4-6 pages
	if (data[0].asString() == "7E37D222", {
		~motionSyn.set(\mag, data[5]);
		~motionSyn.set(\x, ((data[1] + 2000) / 4000).min(1).max(0));
		~motionSyn.set(\y, ((data[2] + 2000) / 4000).min(1).max(0));
		~motionSyn.set(\z, ((data[3] + 2000) / 4000).min(1).max(0));
	});
}, prefix++"/acc");

OSCdef(\gyro, {|msg, time, addr, recvPort|
	msg.postln;
}, prefix++"/gyro");

OSCdef(\mag, {|msg, time, addr, recvPort|
	msg.postln;
}, prefix++"/mag");

)
