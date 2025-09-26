import React, { useCallback, useState, useEffect, useRef } from 'react';
import p5 from 'p5';
import { FilterType, TransformType } from '../types.js';
import {cn} from "../lib/utils.js";

const SensorDisplay = ({
  sensor,
  deviceData, 
  onSensorClick,
  windowDimensions,
  width,
  height,
  displayClass,
  children,
  isSelected = false
}) => {
  const [visible, setVisible] = useState(true);
  const [filterType, setFilterType] = useState(FilterType.NONE);
  const [transformType, setTransformType] = useState(TransformType.NONE);
  
  const canvasRef = useRef(null);
  const p5InstanceRef = useRef(null);
  const displayInstanceRef = useRef(null);

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

  const createDisplayInstance = useCallback((p5Instance) => {
    if (!p5Instance) return null;

    return new displayClass(
        p5Instance,
        sensor,
        windowDimensions.width / 4 * width,
        windowDimensions.height / 2 * height,
    );
  }, [sensor, displayClass]);

  // Initialize p5.js instance and display instance
  useEffect(() => {
    if (!canvasRef.current || p5InstanceRef.current) return;

    const sketch = (p) => {
      p.setup = async () => {
        const w = windowDimensions.width / 4 * width;
        const h = windowDimensions.height / 2 * height;
        p.createCanvas(w, h, p.WEBGL);
        p.ortho(0, w, -h, 0, -1000, 1000);
        // const font = await p.loadFont('assets/Roboto-VariableFont_wdth,wght.ttf');
        const font = await p.loadFont('assets/Inconsolata.otf');
        p.textFont(font);

        displayInstanceRef.current = createDisplayInstance(p);
      };

      p.draw = () => {
        p.background(0);
        displayInstanceRef.current.draw();
      };
    };

    p5InstanceRef.current = new p5(sketch, canvasRef.current);

    return () => {
      p5InstanceRef.current.remove();
    };
  }, [createDisplayInstance]);

  // Expose methods to parent component
  useEffect(() => {
    const sensorApi = {
      visible,
      setVisible,
      isSelected,
      filterType,
      setFilterType,
      transformType,
      setTransformType,
    };
    
    if (deviceData && deviceData.exposeSensor) {
      deviceData.exposeSensor(sensor.type, sensorApi);
    }
  }, [visible, isSelected, filterType, transformType, sensor, deviceData]);

  return (
    <div 
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

      {/* P5.js canvas container */}
      <div
        ref={canvasRef}
        className="absolute top-0 left-0 w-full h-full pointer-events-none"
      />

      {/* Custom sensor content */}
      {children}
    </div>
  );
};

export default SensorDisplay;