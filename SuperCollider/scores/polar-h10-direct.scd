(
~onsetBus.free;
// ~onsetBus = Bus.control(Server.default, 1).set(0);
~onsetBus = Bus.control(Server.default, 4).set(0);
)
(
var prefix = "/polar";
var rootFreq = 80;
~ecg = [];
~acc = [];
OSCdef(\ecg, {|msg, time, addr, recvPort|
	~ecg = msg[2..];
	//~ecg.size.postln; // 73
	// AppClock.seconds.postln; // latency = 0.6
	// ("min: "++~ecg.minItem).postln; // -6000
	// ("max: "++~ecg.maxItem).postln; // 6000
	// 130hz
}, prefix++"/ecg");

OSCdef(\acc, {|msg, time, addr, recvPort|
	~acc = msg[2..];
	//~acc.size.postln; // 108
	//AppClock.seconds.postln; // latency = 0.2
	//("min: "++~acc.minItem).postln; // -2000
	//("max: "++~acc.maxItem).postln; // 2000
	// 200hz
}, prefix++"/acc");

OSCdef(\gyr, {|msg, time, addr, recvPort|
	msg.postln;
}, prefix++"/gyr");

OSCdef(\mag, {|msg, time, addr, recvPort|
	msg.postln;
}, prefix++"/mag");

~heartSin.free;
~heartSin = SynthDef(\heart_sin, { |out=0, aout = 0, mod = 0.0, amp = 0.1|
	var sig, chain, onset;
	sig = SinOsc.ar();
	sig = sig * mod;
	chain = FFT(LocalBuf(1024), sig);

	onset = Onsets.kr(chain, 0.25);
	Out.kr(out, onset);

	Out.ar(aout, sig!2*amp);
}).play(args: [\out, ~onsetBus.index, \amp, 0.2]);

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

~ecgValue = 0;
Tdef(\ecg_loop, { loop {
	if (~ecg.size > 0) {
		~ecg[0] = (~ecg[0].min(6000).max(-6000) / 6000).range(0, 1);
		~ecgValue = ~filter.value(~ecg[0], ~ecgValue, 0.75);
		~heartSin.set(\mod, ~ecgValue);
		~heartSound.set(\mod, ~ecgValue);
		~ecg = ~ecg[1..];
	};
	(1.0/130).wait;
} }).play;

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

~accValues = [0, 0, 0];
~accMag = 0;
~accPitch = 0;
~accRoll = 0;
Tdef(\acc_loop, { loop {
	if (~acc.size > 2) {
		~accValues = ~filter.value(~acc[0..2], ~accValues, 0.75);

		~accMag = (~accValues[0].pow(2) + ~accValues[1].pow(2) + ~accValues[2].pow(2)).sqrt;
		~accPitch = 180 * atan2(~accValues[0], (~accValues[1].pow(2) + ~accValues[2].pow(2)).sqrt) / pi;
		~accRoll = 180 * atan2(~accValues[1], (~accValues[0].pow(2) + ~accValues[2].pow(2)).sqrt) / pi;

		// accelerometer data comes on with three axises x,y and z. The unit is millig and it includes gravity.

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

		~motionSyn.set(\mag, (((~accMag - 980).abs / 980)-0.025).min(1).max(0));
		~motionSyn.set(\x, ((~accValues[0] + 2000) / 4000).min(1).max(0));
		~motionSyn.set(\y, ((~accValues[1] + 2000) / 4000).min(1).max(0));
		~motionSyn.set(\z, ((~accValues[2] + 2000) / 4000).min(1).max(0));
		~acc = ~acc[3..];
	};
	(1.0/200).wait;
} }).play;

~filter = { |value, prevValue, coef|
	var returnArray = true;
	if (value.isSequenceableCollection.not, {
		value = [value];
		prevValue = [prevValue];
		returnArray = false;
	});
	value.do { |val, i|
		value[i] = prevValue[i] + ((val - prevValue[i]) * coef);
		// value[i] = (~prevValue[i] * (1.0 - coef)) + (val * coef);
	};
	if (returnArray, { value }, { value[0] });
};
)
