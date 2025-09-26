// Sensor types used throughout the application
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

// Filter types for sensor data processing
export const FilterType = Object.freeze({
  NONE: { toString: () => "NONE" },
  LOWPASS: { toString: () => "LP" },
  KALMAN: { toString: () => "KALMAN" },
  next: (current) => {
    const values = Object.values(FilterType).filter(v => typeof v !== 'function');
    const currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % values.length];
  }
});

// Transform types for sensor data processing
export const TransformType = Object.freeze({
  NONE: { toString: () => "NONE" },
  SQUIRCLE: { toString: () => "SQUIRCLE" },
  next: (current) => {
    const values = Object.values(TransformType).filter(v => typeof v !== 'function');
    const currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % values.length];
  }
});