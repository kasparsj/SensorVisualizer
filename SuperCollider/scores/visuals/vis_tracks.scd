(
if (~visuals.isNil) {
	"visuals.scd".loadRelative;
};

RedTrack(\invert, Task({
	// ~visuals.send('/tex', 0, "shaders/color.frag");
	~visuals.send('/tex/color', 0, [0.0, 1.0, 1.0]);
	~visuals.send('/tex', 0, "shaders/100fragments/OscCircle.frag");
	~visuals.send('/shading/passes', "invert");
	~visuals.send('/tex/var', 0, "minRadius", 0.075);
	~visuals.send('/tex/var', 0, "radius", 0.1);
	~visuals.send('/tex/var', 0, "minBorder", 0.1);
	~visuals.send('/tex/var', 0, "border", 0.2);
	~visuals.send('/layer/alpha', 0, "line(1, 5)");
	~ecgMult = 1;
}));

RedTrack(\no_invert, Task({
	~visuals.send('/tex/color', 0, [1.0, 1.0, 1.0]);
	~visuals.send('/shading/passes');
	~visuals.send('/tex/var', 0, "minRadius", 0.2);
	~visuals.send('/tex/var', 0, "radius", 0.1);
	~visuals.send('/tex/var', 0, "minBorder", 0.1);
	~visuals.send('/tex/var', 0, "border", 0.2);
	~visuals.send('/layer/alpha', 0, "line(1, 5)");
	~ecgMult = 2pi;
}));

RedTrack(\fadein0, Task({
	~visuals.send('/layer/alpha', 0, "line(1, 45)");
	//~visuals.send('/layer/alpha', 0, 1.0);
}));

RedTrack(\fadeout0, Task({
	~visuals.send('/layer/alpha', 0, "line(1, 0, 10)");
}));

RedTrack(\fadein1, Task({
	~visuals.send('/layer/alpha', 1, "line(1, 30)");
}));

RedTrack(\fadeout1, Task({
	~visuals.send('/layer/alpha', 1, "line(1, 0, 10)");
}));

RedTrack(\line1, Task({
	~visuals.send('/layer/alpha', 2, "line(1, 5)");
	~visuals.send('/layer/alpha', 3, "line(1, 5)");
	~visuals.send('/layer/alpha', 4, "line(1, 5)");
}));

RedTrack(\no_line1, Task({
	~visuals.send('/layer/alpha', 2, "line(1, 0, 10)");
	~visuals.send('/layer/alpha', 3, "line(1, 0, 10)");
	~visuals.send('/layer/alpha', 4, "line(1, 0, 10)");
}));

RedTrack(\lines12, Task({
	//~visuals.send('/tex/color', 0, [0.0, 1.0, 0.0]);

	~visuals.send('/tex/color', 2, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/color', 3, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/color', 4, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/var', 2, "y", 0.5);
	~visuals.send('/tex/var', 3, "y", 0.5);
	~visuals.send('/tex/var', 4, "y", 0.5);
	~visuals.send('/tex/var', 2, "scale", 0.25);
	~visuals.send('/tex/var', 3, "scale", 0.25);
	~visuals.send('/tex/var', 4, "scale", 0.25);

	~visuals.send('/layer/alpha', 5, 1.0);
	~visuals.send('/layer/alpha', 6, 1.0);
	~visuals.send('/layer/alpha', 7, 1.0);
	~visuals.send('/tex/color', 5, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/color', 6, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/color', 7, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/var', 5, "y", 0.5);
	~visuals.send('/tex/var', 6, "y", 0.5);
	~visuals.send('/tex/var', 7, "y", 0.5);
	~visuals.send('/tex/var', 5, "scale", 0.25);
	~visuals.send('/tex/var', 6, "scale", 0.25);
	~visuals.send('/tex/var', 7, "scale", 0.25);

	~visuals.send('/tex/var', 2, "y", "line(0.5, 0.25, 10)");
	~visuals.send('/tex/var', 3, "y", "line(0.5, 0.25, 10)");
	~visuals.send('/tex/var', 4, "y", "line(0.5, 0.25, 10)");
	~visuals.send('/tex/var', 5, "y", "line(0.5, 0.75, 10)");
	~visuals.send('/tex/var', 6, "y", "line(0.5, 0.75, 10)");
	~visuals.send('/tex/var', 7, "y", "line(0.5, 0.75, 10)");

	~visuals.send('/tex/color', 7, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/color', 8, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/color', 9, [1.0, 1.0, 1.0]);
}));

RedTrack(\lines123, Task({
	//~visuals.send('/tex/color', 0, [0.0, 0.0, 1.0]);

	// ~visuals.send('/tex/color', 2, [1.0, 0, 0.0]);
	// ~visuals.send('/tex/color', 3, [0, 1.0, 0]);
	// ~visuals.send('/tex/color', 4, [0, 0, 1.0]);
	~visuals.send('/tex/var', 2, "y", 0.25);
	~visuals.send('/tex/var', 3, "y", 0.25);
	~visuals.send('/tex/var', 4, "y", 0.25);
	~visuals.send('/tex/var', 2, "scale", 0.125);
	~visuals.send('/tex/var', 3, "scale", 0.125);
	~visuals.send('/tex/var', 4, "scale", 0.125);

	// ~visuals.send('/tex/color', 5, [1.0, 0, 0.0]);
	// ~visuals.send('/tex/color', 6, [0, 1.0, 0]);
	// ~visuals.send('/tex/color', 7, [0, 0, 1.0]);
	~visuals.send('/tex/var', 5, "y", 0.75);
	~visuals.send('/tex/var', 6, "y", 0.75);
	~visuals.send('/tex/var', 7, "y", 0.75);
	~visuals.send('/tex/var', 5, "scale", 0.125);
	~visuals.send('/tex/var', 6, "scale", 0.125);
	~visuals.send('/tex/var', 7, "scale", 0.125);

	// ~visuals.send('/tex/color', 8, [1.0, 0, 0.0]);
	// ~visuals.send('/tex/color', 9, [0, 1.0, 0]);
	// ~visuals.send('/tex/color', 10, [0, 0, 1.0]);
	~visuals.send('/layer/alpha', 8, "line(1, 5)");
	~visuals.send('/layer/alpha', 9, "line(1, 5)");
	~visuals.send('/layer/alpha', 10, "line(1, 5)");
	~visuals.send('/tex/var', 8, "y", 0.5);
	~visuals.send('/tex/var', 9, "y", 0.5);
	~visuals.send('/tex/var', 10, "y", 0.5);
	~visuals.send('/tex/var', 8, "scale", 0.125);
	~visuals.send('/tex/var', 9, "scale", 0.125);
	~visuals.send('/tex/var', 10, "scale", 0.125);
}));

RedTrack(\lines23, Task({
	//~visuals.send('/tex/color', 0, [0.0, 1.0, 1.0]);

	// ~visuals.send('/tex/color', 2, [1.0, 1.0, 1.0]);
	// ~visuals.send('/tex/color', 3, [1.0, 1.0, 1.0]);
	// ~visuals.send('/tex/color', 4, [1.0, 1.0, 1.0]);
	~visuals.send('/layer/alpha', 2, "line(1.0, 0.0, 5)");
	~visuals.send('/layer/alpha', 3, "line(1.0, 0.0, 5)");
	~visuals.send('/layer/alpha', 4, "line(1.0, 0.0, 5)");

	// ~visuals.send('/tex/color', 4, [1.0, 1.0, 1.0]);
	// ~visuals.send('/tex/color', 5, [1.0, 1.0, 1.0]);
	// ~visuals.send('/tex/color', 6, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/var', 5, "y", 0.75);
	~visuals.send('/tex/var', 6, "y", 0.75);
	~visuals.send('/tex/var', 7, "y", 0.75);

	// ~visuals.send('/tex/color', 7, [1.0, 1.0, 1.0]);
	// ~visuals.send('/tex/color', 8, [1.0, 1.0, 1.0]);
	// ~visuals.send('/tex/color', 9, [1.0, 1.0, 1.0]);
	~visuals.send('/tex/var', 8, "y", 0.5);
	~visuals.send('/tex/var', 9, "y", 0.5);
	~visuals.send('/tex/var', 10, "y", 0.5);
	~visuals.send('/tex/var', 8, "y", "line(0.5, 0.25, 5)");
	~visuals.send('/tex/var', 9, "y", "line(0.5, 0.25, 5)");
	~visuals.send('/tex/var', 10, "y", "line(0.5, 0.25, 5)");

}));

RedTrack(\no_lines, Task({
	9.do { |i|
		~visuals.send('/layer/alpha', i+2, 0);
	};
}));

RedTrack(\nothing, Task({
	~visuals.send('/layer/alpha', "*", 0);
}));
)