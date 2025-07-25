(
var width = 800, height = 400;
var window = Window("Bus Monitor", Rect(100, 100, width, height));
var userView = UserView(window, Rect(0, 0, width, height));
var bufferSize = 100;
var colors = [Color.red, Color.green, Color(173/255, 216/255, 230/255), Color.yellow, Color.magenta];
var maxChan = colors.size;
var histories = Array.fill(maxChan, { Array.fill(bufferSize, {0}) });  // Initialize with mid-range values
var synth, debugText, busMenu;
var currentBus = ~chestProjXZBus;
var busMap = (
	CHEST_XZ: ~chestProjXZBus,
	CHEST_YX: ~chestProjYXBus,
	CHEST_ZY: ~chestProjZYBus,
    RH_XZ: ~rhProjXZBus,
    RH_YX: ~rhProjYXBus,
    RH_ZY: ~rhProjZYBus,
    LH_XZ: ~lhProjXZBus,
    LH_YX: ~lhProjYXBus,
	LH_ZY: ~lhProjZYBus,
	COMPASS: ~compassBus,
	MAGNETIC: ~magNormBus,
	ECG: ~ecgBus,
);

// Add debug text display
debugText = StaticText(window, Rect(10, 10, width - 20, 25));
debugText.background = Color.black;
debugText.stringColor = Color.white;

busMenu = PopUpMenu(window, Rect(width - 100, 10, 90, 20));
busMenu.items = busMap.keys.asArray.sort;
busMenu.value = 0;
busMenu.action = {
    var selectedName = busMenu.items[busMenu.value];
    currentBus = busMap[selectedName];
    debugText.string = "Switched to Bus: " ++ selectedName ++ " (index: " ++ currentBus.index ++ ")";

    synth.free;
    synth = {
        var bus_data = In.kr(currentBus.index, currentBus.numChannels);
        SendReply.kr(Impulse.kr(30), '/bus_data', bus_data);
        0.0;
    }.play;
};

// ▶ Initial Synth
synth = {
    var bus_data = In.kr(currentBus.index, currentBus.numChannels);
    SendReply.kr(Impulse.kr(30), '/bus_data', bus_data);
    0.0;
}.play;

// Setup OSC responder
OSCdef(\busDataOSC, { |msg|
	var lastIdx = 2+currentBus.numChannels;
    var values = msg[3..6];

    // Update histories with new values
    currentBus.numChannels.do { |i|
        histories[i] = histories[i].rotate(-1);
        histories[i][bufferSize-1] = values[i];
    };

    {
        debugText.string = "Latest values: " + values.round(0.001);
        userView.refresh; // Request a redraw when new data arrives
    }.defer;
}, '/bus_data');

// Define drawing function for normalized values
userView.drawFunc = {
    // Background
    Pen.fillColor = Color.black;
    Pen.fillRect(Rect(0, 0, width, height));

	// Draw min/max reference lines
	Pen.strokeColor = Color.gray(0.3);
	Pen.width = 1;

	// Draw reference lines at 0, 0.5, and 1
	[0, 0.25, 0.5, 0.75, 1].do { |refValue|
		var y = (height * (1 - refValue));

		// Special handling for the 0.5 line - use dots
		if(refValue == 0.5) {
			// Draw a dotted line manually
			(width/10).asInteger.do { |j|
				var startX = j * 10;
				Pen.moveTo(Point(startX, y));
				Pen.lineTo(Point(startX + 5, y));
			};
		} {
			// Draw a solid line
			Pen.moveTo(Point(0, y));
			Pen.lineTo(Point(width, y));
		};

		Pen.stroke;
	};

    currentBus.numChannels.do { |i|
        Pen.strokeColor = colors[i];
        Pen.width = 1;

        // Connect points with lines
        if(histories[i].size > 0) {
            var x = 0;
            var y = height - (height/4 * histories[i][0]);

            Pen.moveTo(Point(x, y));

            bufferSize.do { |j|
                x = j * (width / bufferSize);
                y = height - (height/4 * histories[i][j]);
                Pen.lineTo(Point(x, y));
            };

            Pen.stroke;
        };
    };
};

// Set up a periodic refresh as a backup
Routine {
    while { window.isClosed.not } {
        {
            userView.refresh;
        }.defer;
        0.05.wait;
    }
}.play(AppClock);

window.onClose = {
    OSCdef(\busDataOSC).free;
    synth.free;
};

window.front;
)
