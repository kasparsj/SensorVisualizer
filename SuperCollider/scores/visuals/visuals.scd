(
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

~visuals.send('/layers', 12, "stack");

~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/alpha', 0, 0);

//~visuals.send('/tex/color', 0, [1.0, 0, 0.0]);
//~visuals.send('/tex/color', 0, [0.0, 1.0, 0.0]);
//~visuals.send('/tex/color', 0, [0.0, 0, 1.0]);
//~visuals.send('/tex/color', 0, [1.0, 1.0, 1.0]);

// ~visuals.send('/tex', 1, "shaders/100fragments/OscCircle.frag");
~visuals.send('/tex', 1, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 1, 0);
~visuals.send('/tex/var', 1, "dataSize", ~breathHist.length);
~visuals.send('/tex/var', 1, "scale", 1.5);
// ~visuals.send('/tex/color', 1, [1.0, 0, 0]);

~visuals.send('/tex', 2, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 2, 0);
~visuals.send('/tex/var', 2, "dataSize", ~chestAccHist.length);
// ~visuals.send('/tex/color', 2, [1.0, 0, 0.0]);

~visuals.send('/tex', 3, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 3, 0);
~visuals.send('/tex/var', 3, "dataSize", ~chestAccHist.length);
// ~visuals.send('/tex/color', 3, [0, 1.0, 0]);

~visuals.send('/tex', 4, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 4, 0);
~visuals.send('/tex/var', 4, "dataSize", ~chestAccHist.length);
// ~visuals.send('/tex/color', 4, [0, 0, 1.0]);

~visuals.send('/tex', 5, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 5, 0);
~visuals.send('/tex/var', 5, "dataSize", ~rhAccHist.length);
~visuals.send('/tex/var', 5, "y", 0.25);
// ~visuals.send('/tex/color', 5, [1.0, 0, 0.0]);

~visuals.send('/tex', 6, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 6, 0);
~visuals.send('/tex/var', 6, "dataSize", ~rhAccHist.length);
~visuals.send('/tex/var', 6, "y", 0.25);
// ~visuals.send('/tex/color', 6, [0, 1.0, 0]);

~visuals.send('/tex', 7, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 7, 0);
~visuals.send('/tex/var', 7, "dataSize", ~rhAccHist.length);
~visuals.send('/tex/var', 7, "y", 0.25);
// ~visuals.send('/tex/color', 7, [0, 0, 1.0]);

~visuals.send('/tex', 8, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 8, 0);
~visuals.send('/tex/var', 8, "dataSize", ~lhAccHist.length);
~visuals.send('/tex/var', 8, "y", 0.75);
// ~visuals.send('/tex/color', 8, [1.0, 0, 0.0]);

~visuals.send('/tex', 9, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 9, 0);
~visuals.send('/tex/var', 9, "dataSize", ~lhAccHist.length);
~visuals.send('/tex/var', 9, "y", 0.75);
// ~visuals.send('/tex/color', 9, [0, 1.0, 0]);

~visuals.send('/tex', 10, "shaders/scope2.frag");
~visuals.send('/layer/alpha', 10, 0);
~visuals.send('/tex/var', 10, "dataSize", ~lhAccHist.length);
~visuals.send('/tex/var', 10, "y", 0.75);
// ~visuals.send('/tex/color', 10, [0, 0, 1.0]);

Tdef(\visuals_loop, { loop {
	~breathHist.frame();
	~chestAccHist.frame();
	~rhAccHist.frame();
	~lhAccHist.frame();

	~visuals.send('/tex/var', 0, "time", ~ecgNormBus.getSynchronous() * 2pi);

	//~visuals.send('/tex/var', 1, "time", (pi/2) + (~breathBus.getSynchronous() * 2pi));
	~visuals.send('/tex/var', 1, "data", *~breathHist.data);

	~visuals.send('/tex/var', 2, "data", *~chestAccHist.x);
	~visuals.send('/tex/var', 3, "data", *~chestAccHist.y);
	~visuals.send('/tex/var', 4, "data", *~chestAccHist.z);
	~visuals.send('/tex/var', 5, "data", *~rhAccHist.x);
	~visuals.send('/tex/var', 6, "data", *~rhAccHist.y);
	~visuals.send('/tex/var', 7, "data", *~rhAccHist.z);
	~visuals.send('/tex/var', 8, "data", *~lhAccHist.x);
	~visuals.send('/tex/var', 9, "data", *~lhAccHist.y);
	~visuals.send('/tex/var', 10, "data", *~lhAccHist.z);

	(1.0/60).wait;
} }).play;
)

// ~visuals.send('/tex/color', 0, [1.0, 1.0, 1.0]);
// ~visuals.send('/tex/color', 0, [1.0, 0, 0]);
// ~visuals.send('/tex/color', 0, [0, 0, 0]);
