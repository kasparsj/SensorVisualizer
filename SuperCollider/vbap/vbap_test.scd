(
x = {
	var snd, azi, ele, amp, lag, pan;

	azi = MouseX.kr(-180, 180);
	ele = MouseY.kr(0, 90);
	amp = 1;
	lag = 0.01;
	snd = WhiteNoise.ar(mul: 0.1);
	// use elevaton 1/3 for second level row (since front row is missing)
	pan = VBAP.ar(~vbapList.size, snd, ~vbapBuf.bufnum, azi, 30, 1);
	//azi.poll;
	// snd = snd.collect({
	// 	arg snd;
	// 	snd.postln;
	// 	snd = BPF.ar(snd);
	// 	snd = VBAP.ar(~vbapList.size, snd, ~vbapBuf.bufnum, azi, ele, 20);
	// 	snd.postln;
	// });
	Out.ar(0, pan);
}.play;
)

x.free;

(
var time = 1;
fork{
	~vbapList.size.do{
		arg i;
		{Out.ar(i + 30, WhiteNoise.ar(0.1) * Line.kr(1, 0, time, doneAction: 2))}.play;
		// i.postln;
		time.wait;
	}
}
)

// starts with 10
// 26, 17

(
x = {
	Out.ar([26, 17], WhiteNoise.ar(mul: 0.1));
}.play;
)
x.free;