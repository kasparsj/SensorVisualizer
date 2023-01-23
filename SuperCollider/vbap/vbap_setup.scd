(
var document, speakerPosXMLFile, currentDir, xmlString, speakerList;

currentDir = thisProcess.nowExecutingPath.dirname;

document = DOMDocument.new;
// speakerPosXMLFile = File((currentDir +/+ "MUT210-hemisphere.xml").pathMatch[0], "rb+"); // fullsphere unfortunately doesn't work
// speakerPosXMLFile = File((currentDir +/+ "MUT210-fullsphere.xml").pathMatch[0], "rb+"); // fullsphere unfortunately doesn't work
// speakerPosXMLFile = File((currentDir +/+ "Speaker_Mut_Probe.xml").pathMatch[0], "rb+");
speakerPosXMLFile = File((currentDir +/+ "WRF_20180131.xml").pathMatch[0], "rb+");
xmlString = String.readNew(speakerPosXMLFile);
document.parseXML(xmlString);

speakerList = List.newClear(document.getDocumentElement.getElementsByTagName("Speaker").size);

document.getDocumentElement.getElementsByTagName("Speaker").do {
	arg tag, index;
	var x, y, z, azi, ele, dist;

	// x = tag.getAttribute("PositionX").asFloat;
	// y = tag.getAttribute("PositionY").asFloat;
	// z = tag.getAttribute("PositionZ").asFloat;
	x = tag.getAttribute("x").asFloat;
	y = tag.getAttribute("y").asFloat;
	z = tag.getAttribute("z").asFloat;

	dist = sqrt((x * x) + (y * y) + (z * z));

	ele = acos(z / dist).raddeg;

	azi = atan2(y, x).raddeg; // mathematically correct (azi = 0 right)

	// rotate for spat-standart (azi = 0 front)
	azi = azi - 90.0;
	if (azi < -180) { azi = azi % 180 };

	ele = ele - 90 * -1;

	//([azi, ele, dist]).postln;
	speakerList[index] = [azi, ele];
};
~vbapList = speakerList;
~vbapArr = VBAPSpeakerArray.new(3, ~vbapList);
~vbapBuf = Buffer.loadCollection(s, ~vbapArr.getSetsAndMatrices); // takes a while
~vbapSubs = [61, 62, 63, 64];
~vbapSubsCut = 80;

"\n###     VBAP loaded     ###".postln;

// 61, 62, (63, 64) => subwoofers

// L = 35 (45 deg, ele 0, for drones 90 + spread)
// R = 10 (45 deg ele 0)

)