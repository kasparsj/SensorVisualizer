(
~visuals = OSCVisuals("127.0.0.1", 33333);

~visuals.send('/layers', 9, "stack");

~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/bri', 0, 0);

~visuals.send('/tex', 1, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/bri', 1, 0);
~visuals.send('/tex/color', 1, [1.0, 0, 0]);

~visuals.send('/tex', 2, "shaders/scope2.frag");
~visuals.send('/tex/color', 2, [1.0, 0, 0.0]);

~visuals.send('/tex', 3, "shaders/scope2.frag");
~visuals.send('/tex/color', 3, [0, 1.0, 0]);

~visuals.send('/tex', 4, "shaders/scope2.frag");
~visuals.send('/tex/color', 4, [0, 0, 1.0]);

~chestAccHist = (
	x: [],
	y: [],
	z: [],
	mag: [],
);

~chestAccHist.frame = { |self|
	var chestAcc = ~chestAccBus.getnSynchronous(5);
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

Tdef(\visuals_loop, { loop {
	var chestAcc;

	~visuals.send('/tex/var', 0, "time", ~ecgNormBus.getSynchronous() * 2pi);
	~visuals.send('/tex/var', 1, "time", (pi/2) + (~breathBus.getSynchronous() * 2pi));

	~chestAccHist.frame();

	~visuals.send('/tex/var', 2, "data", *~chestAccHist.x);
	~visuals.send('/tex/var', 3, "data", *~chestAccHist.y);
	~visuals.send('/tex/var', 4, "data", *~chestAccHist.z);
	// ~visuals.send('/shader/buffer', 5, "data", *~chestAccHist.mag);
	(1.0/60).wait;
} }).play;
)

// ~visuals.send('/tex/color', 0, [1.0, 1.0, 1.0]);
// ~visuals.send('/tex/color', 0, [1.0, 0, 0]);
// ~visuals.send('/tex/color', 0, [0, 0, 0]);
