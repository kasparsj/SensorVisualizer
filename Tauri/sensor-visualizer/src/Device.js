import { MahonyFusion } from './MahonyFusion.js';
import { MadgwickFusion } from './MadgwickFusion.js';
import { KalmanFusion } from './KalmanFusion.js';
import { FusionType } from './SensorFusion.js';
import { AccDisplay } from './AccDisplay.js';
import { GyroDisplay } from './GyroDisplay.js';
import { MagDisplay } from './MagDisplay.js';
import { QuatDisplay } from './QuatDisplay.js';
import { EulerDisplay } from './EulerDisplay.js';
import { HRDisplay } from './HRDisplay.js';
import { ECGDisplay } from './ECGDisplay.js';
import { AltitudeDisplay } from './AltitudeDisplay.js';
import { CompDisplay } from './CompDisplay.js';

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
  constructor(p, id, inPrefix, outPrefix, sensors = new Map(), fusionType = FusionType.NONE) {
    this.p = p;
    this.id = id;
    this.inPrefix = inPrefix;
    this.outPrefix = outPrefix;
    this.sensors = sensors;
    
    this.ip = '';
    this.lastUps = 0;
    this.curSensor = null;
    this.fusion = null;
    this.recorders = new Map();
    this.isRecording = false;
    
    this.currentTab = "overview";
    this.tabHeight = 20;
    this.availableTabs = [];
    this.loadedTables = new Map();
    this.nextRowCursor = new Map();
    this.isPlaying = false;
    this.lastMs = 0;
    this.playPos = 0;
    this.playMinMs = -1;
    this.playMaxMs = -1;
    this.isPaused = false;
    this.x = 0;
    this.y = 0;
    this.w = 200;
    this.h = 18;
    this.idx = 0;
    this.battery = null;

    for (const sensor of this.sensors.values()) {
      sensor.device = this;
    }
    
    this.setFusionType(fusionType);
  }
  
  addSensor(sensorType, sensor) {
      this.sensors.set(sensorType, sensor);
      sensor.device = this;
  }

  update() {
    if (this.isPlaying && !this.isPaused) {
      this.playEvent();
    }
    const updateUps = this.p.millis() - this.lastUps >= 1000;
    for (const sensor of this.sensors.values()) {
      if (updateUps) {
        sensor.updateUps();
      }
    }
    if (updateUps) {
      this.lastUps = this.p.millis();
    }
  }

  draw(idx, isActive) {
    this.idx = idx;
    this.x = idx * this.w;
    this.y = 0;
    this.drawTab(isActive);
  }

  drawTab(isActive) {
    this.p.push();
    this.p.translate(this.x, this.y);
    this.p.stroke(255);
    if (isActive) {
      this.p.fill(0, 0, 255);
    } else {
      this.p.noFill();
    }
    this.p.rect(0, 0, this.w, this.h);
    this.p.fill(255);
    this.p.textAlign(this.p.LEFT);
    this.p.textSize(13);
    this.p.text((this.idx + 1), 10, 13);
    this.p.textAlign(this.p.CENTER);
    this.p.text(`${this.id}${this.battery !== null ? ` ${this.battery}V` : ''}`, this.w / 2, 13);
    
    if (this.isRecording || this.isPlaying) {
      this.p.fill(this.isRecording ? 255 : 0, this.isPlaying ? (this.isPaused ? 127 : 255) : 0, 0);
      this.p.ellipse(10, 10, 10, 10);
    }
    this.p.pop();
  }

  drawSensors() {
    if (this.currentTab === "overview") {
      for (const sensor of this.sensors.values()) {
        if (sensor.visible) {
          sensor.draw();
        }
      }
    } else {
      this.drawSingleSensor(this.currentTab);
    }
    this.drawTabs();
  }

  getEulerAngles() {
    if (!(this.isPlaying && this.isPaused)) {
      if (this.fusion && this.hasAccelerometer() && this.hasGyroscope()) {
        return this.fusion.getEulerAngles();
      }
    }
    if (this.hasEuler() && this.getEuler().value) {
      return this.getEuler().val();
    }
    if (this.hasQuat() && this.getQuat().value) {
      return this.getQuat().getOrigEulerAngles();
    }
    if (this.hasAccelerometer()) {
      return this.getAccelerometer().getOrigEulerAngles();
    }
    return null;
  }

  oscEvent(msg) {
    if (this.isPlaying) return;
    
    try {
      let sensor = null;
      const addr = msg.addr;
      const len = this.inPrefix.length;
      const slash2 = addr.indexOf("/", len + 1);
      const which = slash2 > -1 ? addr.substring(len, slash2) : addr.substring(len);
      let param = slash2 > -1 ? addr.substring(slash2 + 1) : null;

      let sensorType;
      switch (which) {
        case "/acc": case "/accel": case "/accelerometer": sensorType = SensorType.ACC; break;
        case "/gyro": case "/gyro_deg": case "/gyro_rad": sensorType = SensorType.GYRO; break;
        case "/mag": sensorType = SensorType.MAG; break;
        case "/comp": sensorType = SensorType.COMP; break;
        case "/euler": case "/euler_rad": case "/euler_deg": sensorType = SensorType.EULER; break;
        case "/hr": sensorType = SensorType.HR; break;
        case "/ecg": sensorType = SensorType.ECG; break;
        case "/altitude": case "/alt": sensorType = SensorType.ALTITUDE; break;
        case "/quat": sensorType = SensorType.QUAT; break;
        case "/ppg": sensorType = SensorType.PPG; break;
        case "/ppi": sensorType = SensorType.PPI; break;
        case "/battery": this.battery = msg.args[0].value; break;
      }

      if (sensorType) {
        sensor = this.getOrCreateSensor(sensorType);
        if (param === null) {
          sensor.oscEvent(msg);
          if (this.isRecording) sensor.record(msg);
        } else {
          sensor.oscEventParam(msg, param);
          if (this.isRecording) sensor.recordParam(msg, param);
        }
      }
    } catch (e) {
      console.error(e);
    }
  }

  playEvent() {
    // ... to be implemented
  }

  getOrCreateSensor(st) {
    if (!this.sensors.has(st)) {
      const sensor = this.createSensor(st);
      this.addSensor(st, sensor);
    }
    return this.sensors.get(st);
  }

  createSensor(st) {
    let sensor;
    switch (st) {
      case SensorType.ACC: 
        sensor = new AccDisplay(this.p, this, 0, 20, this.p.width / 2, this.p.height / 2 - 20);
        break;
      case SensorType.GYRO: 
        sensor = new GyroDisplay(this.p, this, this.p.width / 2, 20, this.p.width / 4, this.p.height / 2 - 20);
        break;
      case SensorType.MAG: 
        sensor = new MagDisplay(this.p, this, this.p.width / 4 * 3, 20, this.p.width / 4, this.p.height / 2 - 20);
        break;
      case SensorType.EULER: 
        sensor = new EulerDisplay(this.p, this, this.p.width / 2, 20, this.p.width / 2, this.p.height - 40);
        break;
      case SensorType.HR: 
        sensor = new HRDisplay(this.p, this, 0, this.p.height / 2, this.p.width / 4, this.p.height / 2 - 20);
        break;
      case SensorType.ECG: 
        sensor = new ECGDisplay(this.p, this, this.p.width / 4, this.p.height / 2, this.p.width / 4, this.p.height / 2 - 20);
        break;
      case SensorType.ALTITUDE: 
        sensor = new AltitudeDisplay(this.p, this, this.p.width / 2, this.p.height / 2, this.p.width / 4, this.p.height / 2 - 20);
        break;
      case SensorType.QUAT: 
        sensor = new QuatDisplay(this.p, this, this.p.width / 4 * 3, 20, this.p.width / 4, this.p.height - 40);
        break;
      case SensorType.COMP: 
        sensor = new CompDisplay(this.p, this, this.p.width / 4 * 3, this.p.height / 2, this.p.width / 4, this.p.height / 2 - 20);
        break;
      default:
        return null;
    }
    
    if (sensor) {
      sensor.resize(); // Apply layout after creation
    }
    return sensor;
  }

  hasAccelerometer() { return this.sensors.has(SensorType.ACC); }
  getAccelerometer() { return this.sensors.get(SensorType.ACC); }
  hasGyroscope() { return this.sensors.has(SensorType.GYRO); }
  getGyroscope() { return this.sensors.get(SensorType.GYRO); }
  hasMagnetometer() { return this.sensors.has(SensorType.MAG); }
  getMagnetometer() { return this.sensors.get(SensorType.MAG); }
  hasEuler() { return this.sensors.has(SensorType.EULER); }
  getEuler() { return this.sensors.get(SensorType.EULER); }
  hasQuat() { return this.sensors.has(SensorType.QUAT); }
  getQuat() { return this.sensors.get(SensorType.QUAT); }

  mouseClicked() {
    if (this.handleTabClick(this.p.mouseX, this.p.mouseY)) return true;
    for (const sensor of this.sensors.values()) {
      if (sensor.mouseClicked()) return true;
    }
    return false;
  }

  keyPressed() {
    if (this.p.key === ' ') { this.togglePaused(); return true; }
    if (this.p.key === 'u') { this.setFusionType(FusionType.next(this.fusion ? this.fusion.type : FusionType.NONE)); return true; }
    if (this.p.key === 'e') {
      const vis = this.toggleVisible(SensorType.EULER);
      if (vis && this.hasQuat()) this.getQuat().visible = false;
      return true;
    }
    if (this.p.key === 'q') {
      const vis = this.toggleVisible(SensorType.QUAT);
      if (vis && this.hasEuler()) this.getEuler().visible = false;
      return true;
    }
    // ... other key presses
    
    if (this.curSensor && this.curSensor.keyPressed()) return true;
    for (const sensor of this.sensors.values()) {
      if (sensor.keyPressed()) return true;
    }
    return false;
  }

  setFusionType(ft) {
    switch (ft) {
      case FusionType.MAHONY: this.fusion = new MahonyFusion(this); break;
      case FusionType.MADGWICK: this.fusion = new MadgwickFusion(this); break;
      case FusionType.KALMAN: this.fusion = new KalmanFusion(this); break;
      default: this.fusion = null; break;
    }
  }

  toggleVisible(st) {
    let sensor = this.sensors.get(st);
    if (!sensor) {
      sensor = this.getOrCreateSensor(st);
    } else {
      sensor.visible = !sensor.visible;
    }
    return sensor.visible;
  }

  updateAvailableTabs() {
    this.availableTabs = ['overview'];
    for (const [sensorType, sensor] of this.sensors.entries()) {
      if (sensor.visible) {
        this.availableTabs.push(sensorType.toString().toLowerCase());
      }
    }
  }

  drawTabs() {
    this.updateAvailableTabs();
    this.p.push();
    this.p.translate(0, this.p.height - this.tabHeight);
    const tabWidth = this.p.width / this.availableTabs.length;

    for (let i = 0; i < this.availableTabs.length; i++) {
      const tab = this.availableTabs[i];
      const isActive = (tab === this.currentTab);

      this.p.push();
      if (isActive) {
        this.p.fill(100);
      } else {
        this.p.fill(50);
      }
      this.p.rect(i * tabWidth, 0, tabWidth, this.tabHeight);
      this.p.fill(255);
      this.p.textAlign(this.p.CENTER, this.p.CENTER);
      this.p.textSize(12);
      this.p.text(tab, i * tabWidth + tabWidth / 2, this.tabHeight / 2);
      this.p.pop();
    }
    this.p.pop();
  }

  drawSingleSensor(sensorName) {
    const sensorType = Object.keys(SensorType).find(key => key.toLowerCase() === sensorName);
    if (sensorType && this.sensors.has(sensorType)) {
      const sensor = this.sensors.get(sensorType);
      if (sensor.visible) {
        this.p.push();
        this.p.translate(0, 20);
        sensor.drawBorder(this.p.width / 4, this.p.height - 40, false);
        sensor.drawContent(this.p.width / 4, this.p.height - 40);
        this.p.pop();
      }
    }
  }

  handleTabClick(mouseX, mouseY) {
    if (mouseY >= this.p.height - this.tabHeight && mouseY <= this.p.height) {
      this.updateAvailableTabs();
      const tabWidth = this.p.width / this.availableTabs.length;
      const tabIndex = Math.floor(mouseX / tabWidth);

      if (tabIndex >= 0 && tabIndex < this.availableTabs.length) {
        this.currentTab = this.availableTabs[tabIndex];
        return true;
      }
    }
    return false;
  }
  
  handleDeviceTabClick(mouseX, mouseY) {
      if (mouseY >= this.y && mouseY <= this.y + this.h &&
          mouseX >= this.x && mouseX <= this.x + this.w) {
          return true;
      }
      return false;
  }
  
  resizeSensors() {
      for(const sensor of this.sensors.values()) {
          sensor.resize();
      }
  }
}