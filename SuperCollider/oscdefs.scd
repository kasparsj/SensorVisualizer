(
if (~prefix.isNil) {
	"config.scd".loadRelative;
};

OSCdef(\ecg, {|msg, time, addr, recvPort|
	// deviceId, value, minValue, maxValue, percValue, avgValue
	~ecgBus.set(msg[2]);
	~ecgNormBus.set(msg[5]);
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
// 	if (data[0].asString() == "7E37D222", {
// 		Ndef(\motion2_mi).set(\pan, 0.2-data[11]); // yx.mag
// 	});
// 	//if (data[0].asString() == "m5StickC", {
// 	if (data[0].asString() == "GyrOSC", {
// 		Ndef(\motion3).set(\pan, data[11]*2);
// 		Ndef(\motion3_mi).set(\pan, data[11]*2);
// 	});
// }, ~prefix++"/quat");

OSCdef(\acc, {|msg, time, addr, recvPort|
	// adrr, deviceId, x, y, z, mag, magPerc, magDeltaSum, magDeltaSumPerc, heading
	if (msg[1].asString() == "7E37D222", {
		var chestAcc = msg[2..6];
		var chestAccNorm = (chestAcc[0..2]/500).clip(-1, 1) ++ chestAcc[4];
		~chestAccBus.setn(chestAcc);
		~chestAccNormBus.setn(chestAccNorm);
	});
	if (msg[1].asString() == "m5StickC", {
		var lhAcc = msg[2..6];
		var lhAccNorm = (lhAcc[0..2]/3).clip(-1, 1) ++ lhAcc[4];
		~lhAccBus.setn(lhAcc);
		~lhAccNormBus.setn(lhAccNorm);
	});
	if (msg[1].asString() == "GyrOSC", {
		var rhAcc = msg[2..6];
		var rhAccNorm = (rhAcc[0..2]/2).clip(-1, 1) ++ rhAcc[4];
		~rhAccBus.setn(rhAcc);
		~rhAccNormBus.setn(rhAccNorm);
	});
}, ~prefix++"/acc");

OSCdef(\acc_batch, {|msg, time, addr, recvPort|
	// addr, deviceId, numArgs, arg1
	if (msg[1].asString() == "7E37D222", {
		~numAccBatchArgs = msg[2].asInteger;
		~acc = msg[3..];
	});
}, ~prefix++"/acc/batch");

OSCdef(\quat, {|msg, time, addr, recvPort|
	// addr, deviceId, x, y, z, w, xzx
	if (msg[1].asString() == "GyrOSC", {
		var rhQuat = msg[2..14];
		~rhQuatBus.setn(rhQuat);
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
	if (msg[1].asString == "GyrOSC") {
		var compNorm;
		~compassBus.set(msg[2]);
		if (msg[2] > 250) {
			compNorm = (msg[2] - 340).clip(0, 20) / 180;
		} {
			compNorm = (msg[2] + 20).clip(0, 180) / 180;
		};
		~compNormBus.set(compNorm);
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
		~ecgBus.setSynchronous(val[0]);
		~ecgNormBus.setSynchronous(val[1]);
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
		~acc = ~acc[~numAccBatchArgs..];
	};
	(1.0/200).wait;
} }).play;
)