(
r = nil;
~record = false;
~prefix = "/out";
~numEcgBatchArgs = 2;
~numAccBatchArgs = 5;

~hrBus.free; // 40 - 180
~hrBus = Bus.control(Server.default, 1);
~ecgBus.free; // 0 - 1
~ecgBus = Bus.control(Server.default, 1);
~ecgNormBus.free; // 0 - 1
~ecgNormBus = Bus.control(Server.default, 1);
~onsetBus.free; // 0, 1
~onsetBus = Bus.control(Server.default, 4).set(0);
~compassBus.free; // 0 - 360
~compassBus = Bus.control(Server.default, 1);
~compNormBus.free; // 0 - 1 (180 degrees)
~compNormBus = Bus.control(Server.default, 1);
~chestAccBus.free;
~chestAccBus = Bus.control(Server.default, 5);
~chestAccNormBus.free;
~chestAccNormBus = Bus.control(Server.default, 4);
~rhAccBus.free;
~rhAccBus = Bus.control(Server.default, 5);
~rhAccNormBus.free;
~rhAccNormBus = Bus.control(Server.default, 4);
~lhAccBus.free;
~lhAccBus = Bus.control(Server.default, 5);
~lhAccNormBus.free;
~lhAccNormBus = Bus.control(Server.default, 4);
~breathBus.free;
~breathBus = Bus.control(Server.default, 1);
~recordBus.free;
~recordBus = Bus.audio(Server.default, 7);
// ~scale = Scale.minorPentatonic;
~scale = Scale.majorPentatonic;
~root = 24;
// ~scale = Scale.phrygian;
)