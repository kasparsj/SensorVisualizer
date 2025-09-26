import {SensorType} from "./types.js";
import {FusionType, KalmanFusion, MadgwickFusion, MahonyFusion} from "./fusion";
import {factory} from "./sensors";

class Device {
    constructor(actualDeviceId, ip, inPrefix, outPrefix = '/out') {
        this.id = actualDeviceId;
        this.ip = ip;
        this.inPrefix = inPrefix;
        this.outPrefix = outPrefix;
        this.sensors = new Map();
        this.isPlaying = false;
        this.isRecording = false;
        this.isPaused = false;
        this.battery = null;
        this.fusion = null;
        this.fusionType = FusionType.NONE;
        this.lastUps = 0;
        this.loadedTables = new Map();
        this.playPos = 0;
        this.lastMs = 0;
        this.nextRowCursor = new Map();
    }

    hasSensor(sensorType) {
        return this.sensors.has(sensorType);
    }

    getOrCreateSensor(sensorType) {
        if (!this.hasSensor(sensorType)) {
            const sensor = factory(sensorType);
            if (sensor) {
                sensor.device = this;
                this.sensors.set(sensorType, sensor);
            }
        }
        return this.sensors.get(sensorType);
    }

    oscEvent(msg) {
        if (this.isPlaying) return;

        try {
            const addr = msg.addr;
            const len = this.inPrefix.length;
            const slash2 = addr.indexOf("/", len + 1);
            const which = slash2 > -1 ? addr.substring(len, slash2) : addr.substring(len);
            let param = slash2 > -1 ? addr.substring(slash2 + 1) : null;

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
                // case "/battery":
                //     setBattery(msg.args[0].value);
                //     break;
            }

            if (sensorType) {
                const sensor = this.getOrCreateSensor(sensorType);
                if (sensor) {
                    if (sensor.oscEvent) {
                        sensor.oscEvent(msg);
                        if (this.isRecording && sensor.record) {
                            sensor.record(msg);
                        }
                    }
                }
                // else {
                //     throw `Sensor ${sensorType} not found`;
                // }
            }
        } catch (e) {
            console.error(e);
        }
    }

    getEulerAngles() {
        // If not in playback mode (or not paused during playback), try fusion first
        if (!(this.isPlaying && this.isPaused)) {
            if (this.fusion &&
                this.hasSensor(SensorType.ACC) &&
                this.hasSensor(SensorType.GYRO)) {
                return this.fusion.getEulerAngles();
            }
        }

        // Try direct Euler sensor
        if (this.hasSensor(SensorType.EULER)) {
            const eulerSensor = this.sensors.get(SensorType.EULER);
            if (eulerSensor.value != null) {
                return eulerSensor.val();
            }
        }

        // Try Quaternion sensor fallback
        if (this.hasSensor(SensorType.QUAT)) {
            const quatSensor = this.sensors.get(SensorType.QUAT);
            if (quatSensor.value != null && quatSensor.getOrigEulerAngles) {
                return quatSensor.getOrigEulerAngles();
            }
        }

        // Try Accelerometer fallback
        if (this.hasSensor(SensorType.ACC)) {
            const accApi =this.sensors.get(SensorType.ACC);
            if (accApi.getOrigEulerAngles) {
                return accApi.getOrigEulerAngles();
            }
        }

        return null;
    }

    setFusionType(ft) {
        switch (ft) {
            case FusionType.MAHONY: this.fusion = new MahonyFusion(this); break;
            case FusionType.MADGWICK: this.fusion = new MadgwickFusion(this); break;
            case FusionType.KALMAN: this.fusion = new KalmanFusion(this); break;
            default: this.fusion = null; break;
        }
    }

    update() {
        // Handle playback if playing and not paused
        if (this.isPlaying && !this.isPaused) {
            this.playEvent();
        }

        // Update UPS (updates per second) for sensors every 1000ms
        const now = Date.now();
        const updateUps = now - this.lastUps >= 1000;
        
        if (updateUps) {
            for (const sensor of this.sensors.values()) {
                if (sensor.updateUps) {
                    sensor.updateUps();
                }
            }
            this.lastUps = now;
        }
    }

    playEvent() {
        // Placeholder for playback functionality
        // This would advance through loaded data tables and trigger sensor events
        // Implementation depends on how playback data is structured
        
        const now = Date.now();
        if (this.lastMs === 0) {
            this.lastMs = now;
            return;
        }
        
        const deltaMs = now - this.lastMs;
        this.playPos += deltaMs;
        this.lastMs = now;
        
        // TODO: Implement actual playback logic based on loadedTables
        // This would involve:
        // 1. Check if current playPos matches any data timestamps
        // 2. Trigger oscEvent for matching data points
        // 3. Advance playback position
    }
}

export default Device;