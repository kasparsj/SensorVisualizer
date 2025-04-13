(
r = nil;
~record = false;
~prefix = "/out";
~numEcgBatchArgs = 2;
~numAccBatchArgs = 5;
~polarId = "7E37D222";
~rhId = "gyrosc";
~lhId = "m5StickC";
~motionGrainsAmp = 0.5;
~trigThresh = 0.02;

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
~chestTrigBus.free;
~chestTrigBus = Bus.control(Server.default, 1);
~chestEulerBus.free;
~chestEulerBus = Bus.control(Server.default, 2);
~chestQuatBus.free;
~chestQuatBus = Bus.control(Server.default, 4);
~chestProjXZBus.free;
~chestProjXZBus = Bus.control(Server.default, 4);
~chestProjYXBus.free;
~chestProjYXBus = Bus.control(Server.default, 4);
~chestProjZYBus.free;
~chestProjZYBus = Bus.control(Server.default, 4);

~rhAccBus.free;
~rhAccBus = Bus.control(Server.default, 5);
~rhAccNormBus.free;
~rhAccNormBus = Bus.control(Server.default, 4);
~rhTrigBus.free;
~rhTrigBus = Bus.control(Server.default, 1);
~rhQuatBus.free;
~rhQuatBus = Bus.control(Server.default, 4);
~rhProjXZBus.free;
~rhProjXZBus = Bus.control(Server.default, 4);
~rhProjYXBus.free;
~rhProjYXBus = Bus.control(Server.default, 4);
~rhProjZYBus.free;
~rhProjZYBus = Bus.control(Server.default, 4);

~lhAccBus.free;
~lhAccBus = Bus.control(Server.default, 5);
~lhAccNormBus.free;
~lhAccNormBus = Bus.control(Server.default, 4);
~lhTrigBus.free;
~lhTrigBus = Bus.control(Server.default, 1);
~lhQuatBus.free;
~lhQuatBus = Bus.control(Server.default, 4);
~lhProjXZBus.free;
~lhProjXZBus = Bus.control(Server.default, 4);
~lhProjYXBus.free;
~lhProjYXBus = Bus.control(Server.default, 4);
~lhProjZYBus.free;
~lhProjZYBus = Bus.control(Server.default, 4);

~breathEnabled = true;
~showBreath = true;
~breathBus.free;
~breathBus = Bus.control(Server.default, 1);

~recordBus.free;
~recordBus = Bus.audio(Server.default, 7);
~scale = Scale.major;
// ~scale = Scale.minorPentatonic;
// ~scale = Scale.majorPentatonic;
~root = 24;
// ~scale = Scale.phrygian;
)

// ~scale.degrees
// ~scale.degrees.size
