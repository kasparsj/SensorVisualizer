import p5 from 'p5';
import { Device, SensorType } from './Device.js';
import { AccDisplay } from './AccDisplay.js';

const sketch = (p) => {
  let devs = new Map();
  let cur = "";
  let listenIP = "0.0.0.0";
  let listenPort = 57121;
  let font;

  p.setup = () => {
    p.createCanvas(p.windowWidth, p.windowHeight);
    p.textFont('Georgia');
    
    // Mock device for now
    const device = new Device(p, "7E37D222", "/7E37D222", "/out");
    device.sensors.set(SensorType.ACC, new AccDisplay(p, device, 0, 20, p.width/2, p.height/2 - 20));
    devs.set("7E37D222", device);
    //cur = "7E37D222";

    setupOsc();
  };

  const setupOsc = () => {
    console.log('Setting up OSC...');
    if (window.__TAURI__) {
      console.log('Tauri API available, starting OSC listener');
      window.__TAURI__.invoke('start_osc_listener');

      window.__TAURI__.event.listen('osc-message', event => {
        oscEvent(event.payload);
      });
    } else {
      console.log('Tauri API not available - running in browser mode');
    }
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
    
    // Debug: log once to verify draw is running
    if (p.frameCount === 1) {
      console.log('Draw function started, devs.size:', devs.size, 'cur:', cur);
    }

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
      p.text("Waiting for data on " + listenIP + ":" + listenPort, p.width/2, p.height/2 - 100);
      p.textSize(14);
      p.text("'/deviceId/acc' (x y z)", p.width/2, p.height/2 - 60);
      p.text("'/deviceId/gyro' (x y z)", p.width/2, p.height/2 - 40);
      p.text("'/deviceId/mag' (x y z)", p.width/2, p.height/2 - 20);
      p.text("'/deviceId/altitude' (value)", p.width/2, p.height/2);
      p.text("'/deviceId/comp' (heading in radians)", p.width/2, p.height/2 + 20);
      p.text("'/deviceId/ecg' (value)", p.width/2, p.height/2 + 40);
      p.text("'/deviceId/hr' (heartrate)", p.width/2, p.height/2 + 60);
      p.text("'/deviceId/euler' (roll pitch yaw)", p.width/2, p.height/2 + 80);
      p.text("'/deviceId/quat' (w x y z)", p.width/2, p.height/2 + 100);
      p.pop();
    }
  };

  p.windowResized = () => {
    p.resizeCanvas(p.windowWidth, p.windowHeight);
  };
};

new p5(sketch);