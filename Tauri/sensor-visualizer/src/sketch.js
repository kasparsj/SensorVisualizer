import p5 from 'p5';
import { Device, SensorType } from './Device.js';
import { AccDisplay } from './AccDisplay.js';
import { GyroDisplay } from './GyroDisplay.js';
import { MagDisplay } from './MagDisplay.js';
import { EulerDisplay } from './EulerDisplay.js';
import { QuatDisplay } from './QuatDisplay.js';
import { HRDisplay } from './HRDisplay.js';
import { ECGDisplay } from './ECGDisplay.js';
import { AltitudeDisplay } from './AltitudeDisplay.js';
import { CompDisplay } from './CompDisplay.js';
import { MahonyFusion } from './MahonyFusion.js';
import { MadgwickFusion } from './MadgwickFusion.js';
import { KalmanFusion } from './KalmanFusion.js';
import { eulerAngles, plot3D, compass2D, squircle, plot2D, plotVectors, plotMagnitude, drawCommands, drawInfo } from './utils/drawing.js';
import { buildBoxShape } from './utils/shapes.js';

const sketch = (p) => {
  let devs = new Map();
  let cur = "";
  let listenIP = "0.0.0.0";
  let listenPort = 57121;
  
  let noDraw = false;
  let showFps = false;
  let showInfo = false;

  let font;

  p.preload = () => {
    font = p.loadFont('assets/Roboto-VariableFont_wdth,wght.ttf');
  }

  p.setup = () => {
    p.createCanvas(p.windowWidth, p.windowHeight, p.WEBGL);
    p.ortho(0, p.windowWidth, -p.windowHeight, 0, -1000, 1000);
    p.textFont(font);
    
    loadData();
    setupOsc();
    //setupGui();
    setupLocalIP();
  };

  const setupLocalIP = () => {
    if (window.__TAURI__) {
      window.__TAURI__.invoke('get_local_ip_address').then(ip => {
        listenIP = ip;
      });
    }
  };

  const setupGui = () => {
    document.getElementById('info-btn').addEventListener('click', () => {
      showInfo = !showInfo;
    });
    document.getElementById('fps-btn').addEventListener('click', () => {
      showFps = !showFps;
    });
    document.getElementById('record-btn').addEventListener('click', () => {
      if (devs.size > 0 && cur !== "") {
        devs.get(cur).toggleRecording();
      }
    });
    document.getElementById('play-btn').addEventListener('click', () => {
      if (devs.size > 0 && cur !== "") {
        devs.get(cur).startPlaying();
      }
    });
  };

  const loadData = () => {
    // load last saved config
    // // Polar H10
    // const polarDevice = new Device(p, "7E37D222", "/7E37D222", "/out");
    // polarDevice.addSensor(SensorType.ACC, new AccDisplay(p, polarDevice, 0, 20, p.width / 2, p.height / 2 - 20));
    // const euler = new EulerDisplay(p, polarDevice, p.width / 2, 20, p.width / 2, p.height - 40);
    // polarDevice.addSensor(SensorType.EULER, euler);
    // const quat = new QuatDisplay(p, polarDevice, p.width / 2, 20, p.width / 2, p.height - 40);
    // quat.visible = false;
    // polarDevice.addSensor(SensorType.QUAT, quat);
    // polarDevice.addSensor(SensorType.HR, new HRDisplay(p, polarDevice, 0, p.height / 2, p.width / 4, p.height / 2 - 20));
    // polarDevice.addSensor(SensorType.ECG, new ECGDisplay(p, polarDevice, p.width / 4, p.height / 2, p.width / 4, p.height / 2 - 20));
    // devs.set("7E37D222", polarDevice);
    //
    // if (devs.size > 0) {
    //   cur = devs.keys().next().value;
    // }
  };

  const setupOsc = () => {
    if (window.__TAURI__) {
      console.log("Setting up OSC...");
      window.__TAURI__.invoke('start_osc_listener', { port: listenPort })
        .catch(err => console.error("Failed to start OSC listener:", err));
      window.__TAURI__.event.listen('osc-message', event => {
        //console.log('OSC message received on frontend:', event.payload);
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
    const prefix = getOscPrefix(msg.addr);
    const deviceId = prefix.replace(/^\//, "");
    if (deviceId === "") {
      console.log("Received an osc message without an address");
      return;
    }
    // The remote address is not available in the new payload
    const ip = "unknown"; 
    try {
      getOrCreateDevice(deviceId, prefix, ip).oscEvent(msg);
    } catch (e) {
      console.error(e);
    }
  };

  const update = () => {
    for (const dev of devs.values()) {
      dev.update();
    }
  };

  p.draw = () => {
    p.background(0);
    update();

    if (noDraw) return;

    if (devs.size > 0 && cur !== "") {
      const dev = devs.get(cur);
      p.push();
      p.textSize(13);
      dev.drawSensors();
      p.pop();
      
      let i = 0;
      for (const dev1 of devs.values()) {
          dev1.draw(i, dev1 === dev);
          i++;
      }
    } else {
      p.push();
      p.fill(255);
      p.textSize(36);
      p.textAlign(p.CENTER);
      p.text(`Waiting for data on ${listenIP}:${listenPort}`, p.width / 2, p.height / 2);
      p.textSize(14);
      p.text("'/deviceId/acc' (x y z)", p.width/2, p.height/2+40);
      p.text("'/deviceId/gyro' (x y z)", p.width/2, p.height/2+60);
      p.text("'/deviceId/mag' (x y z)", p.width/2, p.height/2+80);
      p.text("'/deviceId/altitude' (value)", p.width/2, p.height/2+100);
      p.text("'/deviceId/comp' (heading in radians)", p.width/2, p.height/2+120);
      p.text("'/deviceId/ecg' (value)", p.width/2, p.height/2+140);
      p.text("'/deviceId/hr' (heartrate)", p.width/2, p.height/2+160);
      p.text("'/deviceId/euler' (roll pitch yaw)", p.width/2, p.height/2+180);
      p.text("'/deviceId/quat' (w x y z)", p.width/2, p.height/2+200);
      p.pop();
    }
    
    if (showFps) drawFps();
    if (showInfo) drawInfo(p);
  };

  const drawFps = () => {
    p.push();
    p.fill(255);
    p.textSize(12);
    p.text(`${p.round(p.frameRate())}fps`, p.width - 50, p.height - 15);
    p.pop();
  };

  p.mouseClicked = () => {
    if (devs.size > 0) {
      // Check device tab clicks first
      for (const dev of devs.values()) {
        if (dev.handleDeviceTabClick(p.mouseX, p.mouseY)) {
          cur = dev.id;
          return;
        }
      }
      
      // Then check sensor and bottom tab clicks for current device
      devs.get(cur).mouseClicked();
    }
  };

  p.keyPressed = () => {
    const devKeys = Array.from(devs.keys());
    if (p.key >= '1' && p.key <= '9' && p.key - '1' < devKeys.length) {
      cur = devKeys[p.key - '1'];
      return;
    }
    if (p.key === 'i') {
      showInfo = !showInfo;
      return;
    }
    if (p.key === 'd') {
      showFps = !showFps;
      return;
    }
    if (p.key === 'n') {
      noDraw = !noDraw;
      return;
    }
    
    if (devs.size > 0 && cur !== "") {
      devs.get(cur).keyPressed();
    }
  };

  p.windowResized = () => {
    p.resizeCanvas(p.windowWidth, p.windowHeight);
    p.ortho(0, p.windowWidth, -p.windowHeight, 0, -1000, 1000);
    for (const dev of devs.values()) {
      dev.resizeSensors();
    }
  };
};

new p5(sketch);