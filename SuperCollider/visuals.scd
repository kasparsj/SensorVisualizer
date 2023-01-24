(
~visuals = OSCVisuals("127.0.0.1", 33333);
~visuals.send('/layers', 1, "stack");
~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
//~visuals.send('/tex', 0, "shaders/color.frag");

Tdef(\visuals_loop, { loop {
	~visuals.send('/tex/var', 0, "time", ~ecgNormBus.getSynchronous() * 2pi);
	(1.0/60).wait;
} }).play;
)