(
~ecgMult = 2pi;

~chestAccHist = (
	x: [],
	y: [],
	z: [],
	mag: [],
	length: 32,
);

~chestAccHist.frame = { |self|
	var chestAcc = ~chestAccBus.getnSynchronous(4);
	self.x = self.x.add((chestAcc[0]/500).clip(-1, 1));
	self.y = self.y.add((chestAcc[1]/500).clip(-1, 1));
	self.z = self.z.add((chestAcc[2]/500).clip(-1, 1));
	self.mag = self.mag.add(chestAcc[4]);
	if (self.x.size > self.length) {
		self.x.removeAt(0);
		self.y.removeAt(0);
		self.z.removeAt(0);
		self.mag.removeAt(0);
	};
};

~rhAccHist = (
	x: [],
	y: [],
	z: [],
	mag: [],
	length: 32,
);

~rhAccHist.frame = { |self|
	var rhAcc = ~rhAccNormBus.getnSynchronous(4);
	self.x = self.x.add(rhAcc[0]);
	self.y = self.y.add(rhAcc[1]);
	self.z = self.z.add(rhAcc[2]);
	self.mag = self.mag.add(rhAcc[3]);
	if (self.x.size > self.length) {
		self.x.removeAt(0);
		self.y.removeAt(0);
		self.z.removeAt(0);
		self.mag.removeAt(0);
	};
};

~lhAccHist = (
	x: [],
	y: [],
	z: [],
	mag: [],
	length: 32,
);

~lhAccHist.frame = { |self|
	var lhAcc = ~lhAccNormBus.getnSynchronous(4);
	self.x = self.x.add(lhAcc[0]);
	self.y = self.y.add(lhAcc[1]);
	self.z = self.z.add(lhAcc[2]);
	self.mag = self.mag.add(lhAcc[3]);
	if (self.x.size > self.length) {
		self.x.removeAt(0);
		self.y.removeAt(0);
		self.z.removeAt(0);
		self.mag.removeAt(0);
	};
};

~breathHist = (
	data: [],
	length: 32,
);

~breathHist.frame = { |self|
	var sample = ~breathBus.getSynchronous();
	self.data = self.data.add((sample).clip(-1, 1));
	if (self.data.size > self.length) {
		self.data.removeAt(0);
	};
};

~visuals = OSCVisuals("127.0.0.1", 33333);

~visuals.send('/layers', 16, "stack");

~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/alpha', 0, 0);

// microphone
// ~visuals.send('/tex', 1, "shaders/100fragments/OscCircle.frag");
~visuals.send('/tex', 1, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 1, 0);
~visuals.send('/tex/var', 1, "dataSize", ~breathHist.length);
~visuals.send('/tex/var', 1, "scale", 1.5);
~visuals.send('/tex/var', 1, "thickness", 3);
~visuals.send('/tex/color', 1, [1.0, 0, 0]);

~visuals.send('/tex', 2, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 2, 0);
~visuals.send('/tex/var', 2, "dataSize", ~chestAccHist.length);
~visuals.send('/tex/var', 2, "thickness", 2);
~visuals.send('/tex/var', 2, "scale", 0.5);

~visuals.send('/tex', 3, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 3, 0);
~visuals.send('/tex/var', 3, "dataSize", ~chestAccHist.length);
~visuals.send('/tex/var', 3, "thickness", 2);
~visuals.send('/tex/var', 3, "scale", 0.5);

~visuals.send('/tex', 4, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 4, 0);
~visuals.send('/tex/var', 4, "dataSize", ~chestAccHist.length);
~visuals.send('/tex/var', 4, "thickness", 2);
~visuals.send('/tex/var', 4, "scale", 0.5);

~visuals.send('/tex', 5, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 5, 0);
~visuals.send('/tex/var', 5, "dataSize", ~rhAccHist.length);
~visuals.send('/tex/var', 5, "thickness", 2);

~visuals.send('/tex', 6, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 6, 0);
~visuals.send('/tex/var', 6, "dataSize", ~rhAccHist.length);
~visuals.send('/tex/var', 6, "thickness", 2);

~visuals.send('/tex', 7, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 7, 0);
~visuals.send('/tex/var', 7, "dataSize", ~rhAccHist.length);
~visuals.send('/tex/var', 7, "thickness", 2);

~visuals.send('/tex', 8, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 8, 0);
~visuals.send('/tex/var', 8, "dataSize", ~lhAccHist.length);
~visuals.send('/tex/var', 8, "thickness", 2);

~visuals.send('/tex', 9, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 9, 0);
~visuals.send('/tex/var', 9, "dataSize", ~lhAccHist.length);
~visuals.send('/tex/var', 9, "thickness", 2);

~visuals.send('/tex', 10, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 10, 0);
~visuals.send('/tex/var', 10, "dataSize", ~lhAccHist.length);
~visuals.send('/tex/var', 10, "thickness", 2);

Tdef(\visuals_loop, { loop {
	~breathHist.frame();
	~chestAccHist.frame();
	~rhAccHist.frame();
	~lhAccHist.frame();

	~visuals.send('/tex/var', 0, "time", ~ecgNormBus.getSynchronous() * ~ecgMult);

	//~visuals.send('/tex/var', 1, "time", (pi/2) + (~breathBus.getSynchronous() * 2pi));
	~visuals.send('/tex/var/lifo', 1, "data", ~breathHist.data.last, ~breathHist.length);

	~visuals.send('/tex/var/lifo', 2, "data", ~chestAccHist.x.last, ~chestAccHist.length);
	~visuals.send('/tex/var/lifo', 3, "data", ~chestAccHist.y.last, ~chestAccHist.length);
	~visuals.send('/tex/var/lifo', 4, "data", ~chestAccHist.z.last, ~chestAccHist.length);
	~visuals.send('/tex/var/lifo', 5, "data", ~rhAccHist.x.last, ~rhAccHist.length);
	~visuals.send('/tex/var/lifo', 6, "data", ~rhAccHist.y.last, ~rhAccHist.length);
	~visuals.send('/tex/var/lifo', 7, "data", ~rhAccHist.z.last, ~rhAccHist.length);
	~visuals.send('/tex/var/lifo', 8, "data", ~lhAccHist.x.last, ~lhAccHist.length);
	~visuals.send('/tex/var/lifo', 9, "data", ~lhAccHist.y.last, ~lhAccHist.length);
	~visuals.send('/tex/var/lifo', 10, "data", ~lhAccHist.z.last, ~lhAccHist.length);

	//(1.0/60).wait; // needs a better GPU when using projector
	(1.0/30).wait;
} }).play;
)

// Tdef(\visuals_loop).stop;
// ~visuals.send('/tex/color', 0, [1.0, 1.0, 1.0]);
// ~visuals.send('/tex/color', 0, [1.0, 0, 0]);
// ~visuals.send('/tex/color', 0, [0, 0, 0]);
