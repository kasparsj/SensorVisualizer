(
~visuals = OSCVisuals("127.0.0.1", 33333);

~visuals.send('/layers', 12, "stack");

~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/bri', 0, 0);

~visuals.send('/tex', 1, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/bri', 1, 0);
~visuals.send('/tex/color', 1, [1.0, 0, 0]);

~visuals.send('/tex', 2, "shaders/scope2.frag");
~visuals.send('/layer/bri', 2, 0);
~visuals.send('/tex/color', 2, [1.0, 0, 0.0]);

~visuals.send('/tex', 3, "shaders/scope2.frag");
~visuals.send('/layer/bri', 3, 0);
~visuals.send('/tex/color', 3, [0, 1.0, 0]);

~visuals.send('/tex', 4, "shaders/scope2.frag");
~visuals.send('/layer/bri', 4, 0);
~visuals.send('/tex/color', 4, [0, 0, 1.0]);

~visuals.send('/tex', 5, "shaders/scope2.frag");
~visuals.send('/layer/bri', 5, 0);
~visuals.send('/tex/color', 5, [1.0, 0, 0.0]);

~visuals.send('/tex', 6, "shaders/scope2.frag");
~visuals.send('/layer/bri', 6, 0);
~visuals.send('/tex/color', 6, [0, 1.0, 0]);

~visuals.send('/tex', 7, "shaders/scope2.frag");
~visuals.send('/layer/bri', 7, 0);
~visuals.send('/tex/color', 7, [0, 0, 1.0]);

~visuals.send('/tex', 8, "shaders/scope2.frag");
~visuals.send('/layer/bri', 8, 0);
~visuals.send('/tex/color', 8, [1.0, 0, 0.0]);

~visuals.send('/tex', 9, "shaders/scope2.frag");
~visuals.send('/layer/bri', 9, 0);
~visuals.send('/tex/color', 9, [0, 1.0, 0]);

~visuals.send('/tex', 10, "shaders/scope2.frag");
~visuals.send('/layer/bri', 10, 0);
~visuals.send('/tex/color', 10, [0, 0, 1.0]);

~chestAccHist = (
	x: [],
	y: [],
	z: [],
	mag: [],
);

~chestAccHist.frame = { |self|
	var chestAcc = ~chestAccBus.getnSynchronous(4);
	self.x = self.x.add((chestAcc[0]/500).clip(-1, 1));
	self.y = self.y.add((chestAcc[1]/500).clip(-1, 1));
	self.z = self.z.add((chestAcc[2]/500).clip(-1, 1));
	self.mag = self.mag.add(chestAcc[4]);
	if (self.x.size > 32) {
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
);

~rhAccHist.frame = { |self|
	var rhAcc = ~rhAccNormBus.getnSynchronous(4);
	self.x = self.x.add(rhAcc[0]);
	self.y = self.y.add(rhAcc[1]);
	self.z = self.z.add(rhAcc[2]);
	self.mag = self.mag.add(rhAcc[3]);
	if (self.x.size > 32) {
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
);

~lhAccHist.frame = { |self|
	var lhAcc = ~lhAccNormBus.getnSynchronous(4);
	self.x = self.x.add(lhAcc[0]);
	self.y = self.y.add(lhAcc[1]);
	self.z = self.z.add(lhAcc[2]);
	self.mag = self.mag.add(lhAcc[3]);
	if (self.x.size > 32) {
		self.x.removeAt(0);
		self.y.removeAt(0);
		self.z.removeAt(0);
		self.mag.removeAt(0);
	};
};

Tdef(\visuals_loop, { loop {
	var chestAcc;

	~visuals.send('/tex/var', 0, "time", ~ecgNormBus.getSynchronous() * 2pi);
	~visuals.send('/tex/var', 1, "time", (pi/2) + (~breathBus.getSynchronous() * 2pi));

	~chestAccHist.frame();
	~rhAccHist.frame();
	~lhAccHist.frame();

	~visuals.send('/tex/var', 2, "data", *~chestAccHist.x);
	~visuals.send('/tex/var', 2, "dataSize", ~chestAccHist.x.size);
	~visuals.send('/tex/var', 3, "data", *~chestAccHist.y);
	~visuals.send('/tex/var', 3, "dataSize", ~chestAccHist.y.size);
	~visuals.send('/tex/var', 4, "data", *~chestAccHist.z);
	~visuals.send('/tex/var', 4, "dataSize", ~chestAccHist.z.size);

	~visuals.send('/tex/var', 5, "data", *~rhAccHist.x);
	~visuals.send('/tex/var', 5, "dataSize", ~rhAccHist.x.size);
	~visuals.send('/tex/var', 5, "y", 0.25);
	~visuals.send('/tex/var', 6, "data", *~rhAccHist.y);
	~visuals.send('/tex/var', 6, "dataSize", ~rhAccHist.y.size);
	~visuals.send('/tex/var', 6, "y", 0.25);
	~visuals.send('/tex/var', 7, "data", *~rhAccHist.z);
	~visuals.send('/tex/var', 7, "dataSize", ~rhAccHist.z.size);
	~visuals.send('/tex/var', 7, "y", 0.25);

	~visuals.send('/tex/var', 8, "data", *~lhAccHist.x);
	~visuals.send('/tex/var', 8, "dataSize", ~lhAccHist.x.size);
	~visuals.send('/tex/var', 8, "y", 0.75);
	~visuals.send('/tex/var', 9, "data", *~lhAccHist.y);
	~visuals.send('/tex/var', 9, "dataSize", ~lhAccHist.y.size);
	~visuals.send('/tex/var', 9, "y", 0.75);
	~visuals.send('/tex/var', 10, "data", *~lhAccHist.z);
	~visuals.send('/tex/var', 10, "dataSize", ~lhAccHist.z.size);
	~visuals.send('/tex/var', 10, "y", 0.75);
	(1.0/60).wait;
} }).play;
)

// ~visuals.send('/tex/color', 0, [1.0, 1.0, 1.0]);
// ~visuals.send('/tex/color', 0, [1.0, 0, 0]);
// ~visuals.send('/tex/color', 0, [0, 0, 0]);
