import React, { useCallback, useState } from 'react';
import { FilterType, TransformType } from '../types.js';
import {cn} from "../lib/utils.js";

const SensorDisplay = React.forwardRef(({
  sensor,
  deviceData, 
  onSensorClick,
  width,
  height,
  children,
  isSelected = false
}, ref) => {
  const [visible, setVisible] = useState(true);
  const [filterType, setFilterType] = useState(FilterType.NONE);
  const [transformType, setTransformType] = useState(TransformType.NONE);

  // Handle mouse clicks directly on the React div
  const handleClick = useCallback(() => {
    if (onSensorClick) {
      onSensorClick();
    }
  }, [onSensorClick]);

  // Handle key presses for the sensor (when focused)
  const handleKeyDown = useCallback((event) => {
    // Common sensor key bindings (matching original p5 implementation)
    switch (event.key.toLowerCase()) {
      case 'f':
        // Toggle filter type
        setFilterType(FilterType.next(filterType));
        console.log(`Filter changed to ${FilterType.next(filterType)} for ${sensor.type}`);
        break;
      case 't':
        // Toggle transform type
        setTransformType(TransformType.next(transformType));
        console.log(`Transform changed to ${TransformType.next(transformType)} for ${sensor.type}`);
        break;
      case 'v':
        // Toggle visibility
        setVisible(!visible);
        if (deviceData && deviceData.toggleVisible) {
          deviceData.toggleVisible(sensor.type);
        }
        break;
      case 'm':
        // Reset min/max
        console.log(`Reset min/max for ${sensor.type}`);
        break;
      default:
        break;
    }
  }, [sensor, visible, filterType, transformType, deviceData]);

  return (
    <div 
      ref={ref}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      tabIndex={0}
      className={cn('relative border text-white text-xs font-mono bg-black cursor-pointer outline-none', {
        'block': visible,
        'hidden': !visible,
        'border-red-500': isSelected,
        'border-gray-600': !isSelected,
        'col-span-2': width === 2,
        'col-span-3': width === 3,
        'col-span-4': width === 4,
        'row-span-2': height === 2,
      })}
    >
      {/* Sensor type label */}
      <div className="absolute top-1 left-1 text-xs opacity-70 z-1">
        <span>{sensor.type}</span>
        {sensor.info && sensor.info().map((item, i) => (
            <div key={i}>{item}</div>
        ))}
      </div>

      <div className="absolute top-1 right-1 text-xs opacity-70 z-1">
        {sensor.ups ? `${sensor.ups} hz` : "no data"}
      </div>

      {/* Filter and Transform indicators */}
      {(filterType !== FilterType.NONE || transformType !== TransformType.NONE) && (
        <div className="absolute top-1 right-1 text-xs opacity-60">
          {filterType !== FilterType.NONE && (
            <div>F: {filterType.toString()}</div>
          )}
          {transformType !== TransformType.NONE && (
            <div>T: {transformType.toString()}</div>
          )}
        </div>
      )}

      {/* Custom sensor content */}
      {children}
    </div>
  );
});

SensorDisplay.displayName = 'SensorDisplay';

export default SensorDisplay;