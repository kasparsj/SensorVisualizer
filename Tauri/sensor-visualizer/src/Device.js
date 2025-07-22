import { Sensor } from './Sensor.js';
import { AccDisplay } from './AccDisplay.js';
import { GyroDisplay } from './GyroDisplay.js';
import { MagDisplay } from './MagDisplay.js';
import { QuatDisplay } from './QuatDisplay.js';
import { EulerDisplay } from './EulerDisplay.js';
import { HRDisplay } from './HRDisplay.js';
import { ECGDisplay } from './ECGDisplay.js';
import { AltitudeDisplay } from './AltitudeDisplay.js';

export const SensorType = {
  ACC: 'ACC',
  GYRO: 'GYRO',
  MAG: 'MAG',
  QUAT: 'QUAT',
  EULER: 'EULER',
  ALTITUDE: 'ALTITUDE',
  ECG: 'ECG',
  HR: 'HR',
  COMP: 'COMP',
  PPG: 'PPG',
  PPI: 'PPI',
};

export class Device {
  constructor(p, id, inPrefix, outPrefix, sensors = new Map(), fusionType = 'NONE') {
    this.p = p;
    this.id = id;
    this.inPrefix = inPrefix;
    this.outPrefix = outPrefix;
    this.sensors = sensors;
    this.fusionType = fusionType;
    
    this.ip = '';
    this.lastUps = 0;
    this.curSensor = null;
    this.fusion = null;
    this.recorders = new Map();
    this.isRecording = false;
    
    this.currentTab = "overview";
    this.availableTabs = [];
    this.loadedTables = new Map();
    this.nextRowCursor = new Map();
    this.isPlaying = false;
    this.lastMs = 0;
    this.playPos = 0;
    this.playMinMs = -1;
    this.playMaxMs = -1;
    this.isPaused = false;
    this.battery = null;

    for (const sensor of this.sensors.values()) {
      sensor.device = this;
    }
  }

  update() {
    if (this.isPlaying && !this.isPaused) {
      this.playEvent();
    }
    const updateUps = this.p.millis() - this.lastUps >= 1000;
    for (const sensor of this.sensors.values()) {
      if (updateUps) {
        // sensor.updateUps();
      }
    }
    if (updateUps) {
      this.lastUps = this.p.millis();
    }
  }

  drawSensors() {
    if (this.currentTab === "overview") {
      for (const sensor of this.sensors.values()) {
        if (sensor.visible) {
          sensor.draw(sensor.w, sensor.h);
        }
      }
    } else {
      // drawSingleSensor(this.currentTab);
    }
    // drawTabs();
  }
  
  oscEvent(msg) {
    if (this.isPlaying) {
      return;
    }
    try {
      let sensor = null;
      const addr = msg.address;
      const len = this.inPrefix.length;
      const slash2 = addr.indexOf("/", len + 1);
      const which = slash2 > -1 ? addr.substring(len, slash2) : addr.substring(len);
      let param = null;
      if (slash2 > -1) {
        param = addr.substring(slash2 + 1);
      }

      let sensorType;
      switch (which) {
        case "/acc":
        case "/accel":
        case "/accelerometer":
          sensorType = SensorType.ACC;
          break;
        case "/gyro":
        case "/gyro_deg":
        case "/gyro_rad":
          sensorType = SensorType.GYRO;
          break;
        case "/mag":
          sensorType = SensorType.MAG;
          break;
        case "/comp":
          sensorType = SensorType.COMP;
          break;
        case "/euler":
        case "/euler_rad":
        case "/euler_deg":
          sensorType = SensorType.EULER;
          break;
        case "/hr":
          sensorType = SensorType.HR;
          break;
        case "/ecg":
          sensorType = SensorType.ECG;
          break;
        case "/altitude":
        case "/alt":
          sensorType = SensorType.ALTITUDE;
          break;
        case "/quat":
          sensorType = SensorType.QUAT;
          break;
        case "/ppg":
          sensorType = SensorType.PPG;
          break;
        case "/ppi":
          sensorType = SensorType.PPI;
          break;
        case "/battery":
          this.battery = msg.args[0];
          break;
      }
      
      if (sensorType) {
        sensor = this.getOrCreateSensor(sensorType);
        if (param === null) {
          sensor.oscEvent(msg);
          if (this.isRecording) {
            // sensor.record(msg);
          }
        } else {
          // sensor.oscEventParam(msg, param);
          if (this.isRecording) {
            // sensor.recordParam(msg, param);
          }
        }
      }
    } catch (e) {
      console.error(e);
    }
  }
  
  playEvent() {
    // To be implemented
  }
  
  getOrCreateSensor(st) {
    if (!this.sensors.has(st)) {
      const sensor = this.createSensor(st);
      sensor.device = this;
      this.sensors.set(st, sensor);
    }
    return this.sensors.get(st);
  }
  
  createSensor(st) {
    switch (st) {
      case SensorType.ACC:
        return new AccDisplay(this.p, this);
      case SensorType.GYRO:
        return new GyroDisplay(this.p, this);
      case SensorType.MAG:
        return new MagDisplay(this.p, this);
      case SensorType.QUAT:
        return new QuatDisplay(this.p, this);
      case SensorType.EULER:
        return new EulerDisplay(this.p, this);
      case SensorType.HR:
        return new HRDisplay(this.p, this);
      case SensorType.ECG:
        return new ECGDisplay(this.p, this);
      case SensorType.ALTITUDE:
        return new AltitudeDisplay(this.p, this);
    }
    return null;
  }
}