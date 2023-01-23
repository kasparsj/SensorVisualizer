(
r = nil;
~record = false;
~prefix = "/out";
~numEcgBatchArgs = 2;
~numAccBatchArgs = 5;

OSCdef(\ecg, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, value, minValue, maxValue, percValue, avgValue
	~ecgBus.set(data[4]);
	Ndef(\heart_sin).set(\freq, data[3]);
}, ~prefix++"/ecg");

OSCdef(\ecg_batch, {|msg, time, addr, recvPort|
	 // addr, deviceId, numArgs, arg1[, arg2]
	~numEcgBatchArgs = msg[2].asInteger;
	~ecg = msg[3..];
}, ~prefix++"/ecg/batch");

OSCdef(\hr, {|msg, time, addr, recvPort|
	~hrBus.set(msg[2]);
}, ~prefix++"/hr");

OSCdef(\quat, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, x, y, z, w, xz.x, xz.y, xz.mag, xz.heading, yz.x, yx.y, yx.mag, yx.heading, zy.x, zy.y, zy.mag, zy.heading
	if (data[0].asString() == "7E37D222", {
		Ndef(\motion2_mi).set(\pan, 0.2-data[11]);
	});
	if (data[0].asString() == "m5StickC", {
		Ndef(\motion3_mi).set(\pan, data[11]*2);
	});
}, ~prefix++"/quat");

OSCdef(\acc, {|msg, time, addr, recvPort|
	var data = msg[1..]; // deviceId, x, y, z, mag, magPerc, magDeltaSum, magDeltaSumPerc, heading
	if (data[0].asString() == "7E37D222", {
		Ndef(\motion2_mi).set(\x, data[1]/500, \y, data[2]/500, \z, data[3]/500, \mag, data[5]);
	});
	if (data[0].asString() == "m5StickC", {
		Ndef(\motion3_mi).set(\x, data[1]/2, \y, data[2]/2, \z, data[3]/2, \mag, data[5]);
	});
}, ~prefix++"/acc");

OSCdef(\acc_batch, {|msg, time, addr, recvPort|
	// addr, deviceId, numArgs, arg1
	if (msg[1].asString() == "7E37D222", {
		~numAccBatchArgs = msg[2].asInteger;
		~acc = msg[3..];
	});
}, ~prefix++"/acc/batch");

OSCdef(\gyro, {|msg, time, addr, recvPort|
	//msg.postln;
}, ~prefix++"/gyro");

OSCdef(\mag, {|msg, time, addr, recvPort|
	//msg.postln;
}, ~prefix++"/mag");

OSCdef(\compass, {|msg, time, addr, recvPort|
	if (msg[1].asString == "GyOSC") {
		~compassBus.set(msg[2]);
	};
}, ~prefix++"/comp");

OSCdef(\record, {|msg, time, addr, recvPort|
	if (~record and: { r.isNil }, {
		r = Recorder(s);
		r.record(bus: ~recordBus, numChannels: ~recordBus.numChannels);
	});
}, ~prefix++"/resume");

Tdef(\ecg_loop, { loop {
	if (~ecg.size > 0) {
		var val = ~ecg[0..(~numEcgBatchArgs-1)];
		//var perc = (val.min(3000).max(-3000) / 3000).clip(0, 1);
		var perc = val[1];
		Ndef(\heart_sin).set(\freq, val[0]);
		~ecgBus.setSynchronous(val[1]);
		~visuals.send('/tex/var', 0, "time", val[1] * 2pi);
		~ecg = ~ecg[~numEcgBatchArgs..];
	};
	(1.0/130).wait;
} }).play;

Tdef(\acc_loop, { loop {
	if (~acc.size > 0) {
		var val = ~acc[0..(~numAccBatchArgs-1)];
		Ndef(\motion2).set(\x, val[0], \y, val[1], \z, val[2], \mag, val[4]);
		Ndef(\motion2_mi).set(\x, val[0]/500, \y, val[1]/500, \z, val[2]/500, \mag, val[4]);
		~acc = ~acc[~numAccBatchArgs..];
	};
	(1.0/200).wait;
} }).play;
)