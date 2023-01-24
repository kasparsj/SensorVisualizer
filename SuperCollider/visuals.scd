(
~visuals = OSCVisuals("127.0.0.1", 33333);

~visuals.send('/layers', 9, "stack");

~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/bri', 0, 0);

~visuals.send('/tex', 1, "shaders/100fragments/OscCircle.frag");
~visuals.send('/layer/bri', 1, 0);
~visuals.send('/tex/color', 1, [1.0, 0, 0]);

Tdef(\visuals_loop, { loop {
	~visuals.send('/tex/var', 0, "time", ~ecgNormBus.getSynchronous() * 2pi);
	~visuals.send('/tex/var', 1, "time", (pi/2) + (~breathBus.getSynchronous() * 2pi));
	(1.0/60).wait;
} }).play;
)

// ~visuals.send('/tex/color', 0, 1.0, 1.0, 1.0);
// ~visuals.send('/tex/color', 0, 1.0, 0, 0);
// ~visuals.send('/tex/color', 0, 0, 0, 0);
