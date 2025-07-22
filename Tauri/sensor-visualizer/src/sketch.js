import p5 from 'p5';
import { Device, SensorType } from './Device.js';
import { AccDisplay } from './AccDisplay.js';
import OSC from 'osc-js';

const sketch = (p) => {
  let devs = new Map();
  let cur = "";
  let listenIP;
  let listenPort = 57121;
  let osc;

  p.setup = () => {
    p.createCanvas(p.windowWidth, p.windowHeight, p.WEBGL);
    
    // Mock device for now
    const device = new Device(p, "7E37D222", "/7E37D222", "/out");
    device.sensors.set(SensorType.ACC, new AccDisplay(p, device, 0, 20, p.width/2, p.height/2 - 20));
    devs.set("7E37D222", device);
    cur = "7E37D222";

    setupOsc();
  };

  const setupOsc = () => {
    osc = new OSC({ plugin: new OSC.DatagramPlugin() });

    osc.on('open', () => {
      console.log('OSC socket open');
    });

    osc.on('*', msg => {
      oscEvent(msg);
    });

    osc.listen({ port: listenPort });
    console.log(`OSC listening on port ${listenPort}`);
  };

  const getOscPrefix = (addrPattern) => {
    const offset = addrPattern.charAt(0) === '/' ? 1 : 0;
    const index = addrPattern.indexOf("/", offset);
    if (index > -1) {
      return addrPattern.substring(0, index);
    }
    return addrPattern;
  };

  const getOrCreateDevice = (deviceId, inPrefix, ip) => {
    if (devs.has(deviceId) && devs.get(deviceId).ip && devs.get(deviceId).ip !== ip) {
      deviceId = `${deviceId}-${ip}`;
    }
    if (!devs.has(deviceId)) {
      const dev = new Device(p, deviceId, inPrefix, "/out");
      dev.ip = ip;
      devs.set(deviceId, dev);
      if (cur === "") {
        cur = deviceId;
      }
    }
    return devs.get(deviceId);
  };

  const oscEvent = (msg) => {
    const prefix = getOscPrefix(msg.address);
    const deviceId = prefix.replace(/^\//, "");
    if (deviceId === "") {
      console.log("Received an osc message without an address");
      return;
    }
    const ip = msg.remoteAddress;
    try {
      getOrCreateDevice(deviceId, prefix, ip).oscEvent(msg);
    } catch (e) {
      console.error(e);
    }
  };

  p.draw = () => {
    p.background(0);

    if (devs.size > 0 && cur !== "") {
      let dev = devs.get(cur);
      p.push();
      p.textSize(13);
      dev.drawSensors();
      p.pop();
    } else {
      p.push();
      p.fill(255);
      p.textSize(36);
      p.textAlign(p.CENTER);
      p.text("Waiting for data on " + listenIP + ":" + listenPort, 0, -100);
      p.textSize(14);
      p.text("'/deviceId/acc' (x y z)", 0, -60);
      p.text("'/deviceId/gyro' (x y z)", 0, -40);
      p.text("'/deviceId/mag' (x y z)", 0, -20);
      p.text("'/deviceId/altitude' (value)", 0, 0);
      p.text("'/deviceId/comp' (heading in radians)", 0, 20);
      p.text("'/deviceId/ecg' (value)", 0, 40);
      p.text("'/deviceId/hr' (heartrate)", 0, 60);
      p.text("'/deviceId/euler' (roll pitch yaw)", 0, 80);
      p.text("'/deviceId/quat' (w x y z)", 0, 100);
      p.pop();
    }
  };

  p.windowResized = () => {
    p.resizeCanvas(p.windowWidth, p.windowHeight);
  };
};

new p5(sketch);