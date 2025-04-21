(
if (~prefix.isNil) {
	"config.scd".loadRelative;
};

OSCdef(\ecg, {|msg, time, addr, recvPort|
	// deviceId, value, minValue, maxValue, percValue, avgValue
	~ecgBus.setn([msg[2], msg[5]]);
}, ~prefix++"/ecg");

OSCdef(\ecg_batch, {|msg, time, addr, recvPort|
	 // addr, deviceId, numArgs, arg1[, arg2]
	~numEcgBatchArgs = msg[2].asInteger;
	~ecg = msg[3..];
}, ~prefix++"/ecg/batch");

OSCdef(\hr, {|msg, time, addr, recvPort|
	~hrBus.set(msg[2]);
}, ~prefix++"/hr");

// OSCdef(\quat, {|msg, time, addr, recvPort|
// 	var data = msg[1..]; // deviceId, x, y, z, w, xz.x, xz.y, xz.mag, xz.heading, yz.x, yx.y, yx.mag, yx.heading, zy.x, zy.y, zy.mag, zy.heading
// 	if (data[0].asString() == ~polarId, {
// 		Ndef(\motion2_mi).set(\pan, 0.2-data[11]); // yx.mag
// 	});
// 	//if (data[0].asString() == ~lhId, {
// 	if (data[0].asString() == ~rhId, {
// 		Ndef(\motion3).set(\pan, data[11]*2);
// 		Ndef(\motion3_mi).set(\pan, data[11]*2);
// 	});
// }, ~prefix++"/quat");

OSCdef(\acc, {|msg, time, addr, recvPort|
	// adrr, deviceId, x, y, z, mag, magPerc, magDeltaSum, magDeltaSumPerc, heading
	if (msg[1].asString() == ~polarId, {
		var chestAcc = msg[2..6];
		var chestAccNorm = (chestAcc[0..2]/500).clip(-1, 1) ++ chestAcc[4];
		~chestAccBus.setn(chestAcc);
		~chestAccNormBus.setn(chestAccNorm);
		~chestTrigBus.set(if (chestAcc[4] > ~trigThresh, 1, 0));
	});
	if (msg[1].asString() == ~lhId, {
		var lhAcc = msg[2..6];
		var lhAccNorm = (lhAcc[0..2]/3).clip(-1, 1) ++ lhAcc[4];
		~lhAccBus.setn(lhAcc);
		~lhAccNormBus.setn(lhAccNorm);
		~lhTrigBus.set(if (lhAcc[4] > ~trigThresh, 1, 0));
	});
	if (msg[1].asString() == ~rhId, {
		var rhAcc = msg[2..6];
		var rhAccNorm = (rhAcc[0..2]/2).clip(-1, 1) ++ rhAcc[4];
		~rhAccBus.setn(rhAcc);
		~rhAccNormBus.setn(rhAccNorm);
		~rhTrigBus.set(if (rhAcc[4] > ~trigThresh, 1, 0));
	});
}, ~prefix++"/acc");

OSCdef(\acc_batch, {|msg, time, addr, recvPort|
	// addr, deviceId, numArgs, arg1
	if (msg[1].asString() == ~polarId, {
		~numAccBatchArgs = msg[2].asInteger;
		~acc = msg[3..];
	});
}, ~prefix++"/acc/batch");

OSCdef(\quat, {|msg, time, addr, recvPort|
	// addr, deviceId, w, x, y, z, xzx
	if (msg[1].asString() == ~rhId, {
		var values = msg[2..17];
		var quat = values[0..3];
		var projXZ = (values[4..5]+1)/2 ++ values[6..7];
		var projYX = (values[8..9]+1)/2 ++ values[10..11];
		var projZY = (values[12..13]+1)/2 ++ values[14..15];
		~rhQuatBus.setn(quat);
		~rhProjXZBus.setn(projXZ);
		~rhProjYXBus.setn(projYX);
		~rhProjZYBus.setn(projZY);
	});
	if (msg[1].asString() == ~lhId, {
		var values = msg[2..17];
		var quat = values[0..3];
		var projXZ = (values[4..5]+1)/2 ++ values[6..7];
		var projYX = (values[8..9]+1)/2 ++ values[10..11];
		var projZY = (values[12..13]+1)/2 ++ values[14..15];
		~lhQuatBus.setn(quat);
		~lhProjXZBus.setn(projXZ);
		~lhProjYXBus.setn(projYX);
		~lhProjZYBus.setn(projZY);
	});
	if (msg[1].asString() == ~polarId, {
		var values = msg[2..17];
		var quat = values[0..3];
		var projXZ = (values[4..5]+1)/2 ++ values[6..7];
		var projYX = (values[8..9]+1)/2 ++ values[10..11];
		var projZY = (values[12..13]+1)/2 ++ values[14..15];
		~chestQuatBus.setn(quat);
		~chestProjXZBus.setn(projXZ);
		~chestProjYXBus.setn(projYX);
		~chestProjZYBus.setn(projZY);
	});
}, ~prefix++"/quat");

// OSCdef(\gyro, {|msg, time, addr, recvPort|
// 	//msg.postln;
// }, ~prefix++"/gyro");
//
// OSCdef(\mag, {|msg, time, addr, recvPort|
// 	//msg.postln;
// }, ~prefix++"/mag");

OSCdef(\compass, {|msg, time, addr, recvPort|
	if (msg[1].asString == ~rhId) {
		var compNorm;

		if (msg[2] > 250) {
			compNorm = (msg[2] - 340).clip(0, 20) / 180;
		} {
			compNorm = (msg[2] + 20).clip(0, 180) / 180;
		};
		~compassBus.setn([msg[2], compNorm]);
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
		~ecgBus.setnSynchronous([val[0], val[1]]);
		~ecg = ~ecg[~numEcgBatchArgs..];
	};
	(1.0/130).wait;
} }).play;

Tdef(\acc_loop, { loop {
	if (~acc.size > 0) {
		var val = ~acc[0..(~numAccBatchArgs-1)];
		var valNorm = (val[0..2]/500).clip(-1, 1) ++ val[4];
		~chestAccBus.setnSynchronous(val);
		~chestAccNormBus.setnSynchronous(valNorm);
		~chestEulerBus.setnSynchronous(~eulerAngles.(val));
		~acc = ~acc[~numAccBatchArgs..];
	};
	(1.0/200).wait;
} }).play;

~eulerAngles = { |value, restrictPitch = false|
	var roll, pitch;
	// restrict pitch or roll to -90 to 90
	if (restrictPitch) {
		roll = value[1].atan2(value[2]);
		pitch = ((-1 * value[0]) / ((value[1] * value[1]) + (value[2] * value[2])).sqrt).atan;
	} {
		roll  = (value[1] / ((value[0] * value[0]) + (value[2] * value[2])).sqrt).atan;
		pitch = (-1 * value[0]).atan2(value[2]);
	};
	[roll, pitch];
};
)
