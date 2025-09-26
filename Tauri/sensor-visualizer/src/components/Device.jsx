import React, {useState, useEffect, useRef, useMemo, useCallback} from 'react';
import p5 from 'p5';
import { SensorType } from '../types.js';
import { Tabs, TabsList, TabsTrigger, TabsContent } from './ui/tabs.jsx';
import SensorDisplay from "./SensorDisplay.jsx";
import {AccDisplay, GyroDisplay, MagDisplay, EulerDisplay, HRDisplay, ECGDisplay, AltitudeDisplay, QuatDisplay, CompDisplay} from "../p5";

const Device = ({ device, windowDimensions, isActive, index, onDeviceSelect }) => {
  const [curSensor, setCurSensor] = useState(null);
  const [currentTab, setCurrentTab] = useState('overview');

  const tabHeight = 20;
  const deviceWidth = 200;
  const deviceHeight = 18;

  const recorders = useRef(new Map());
  const lastUps = useRef(0);
  const canvasRef = useRef(null);
  const p5InstanceRef = useRef(null);
  const displayInstanceRef = useRef(null);
  const sensorRefsMap = useRef(new Map());

  const getSensorDisplaySize = (sensorType) => {
    let width = 1, height = 1;
    switch (sensorType) {
      case SensorType.ACC:
        width = 2;
        break;
      case SensorType.EULER:
      case SensorType.QUAT:
        height = 2;
        break;
    };
    return {width, height};
  };

  const getSensorDisplayClass = (sensorType) => {
    switch (sensorType) {
      case SensorType.ACC:
        return AccDisplay;
      case SensorType.GYRO:
        return GyroDisplay;
      case SensorType.MAG:
        return MagDisplay;
      case SensorType.EULER:
        return EulerDisplay;
      case SensorType.HR:
        return HRDisplay;
      case SensorType.ECG:
        return ECGDisplay;
      case SensorType.ALTITUDE:
        return AltitudeDisplay;
      case SensorType.QUAT:
        return QuatDisplay;
      case SensorType.COMP:
        return CompDisplay;
    }
  };

  const createSensorDisplay = (sensorType) => {
    if (!windowDimensions) return null;

    const sensor = device.getOrCreateSensor(sensorType);
    const {width, height} = getSensorDisplaySize(sensorType);
    
    // Create or get existing ref for this sensor
    if (!sensorRefsMap.current.has(sensorType)) {
      sensorRefsMap.current.set(sensorType, React.createRef());
    }
    const sensorRef = sensorRefsMap.current.get(sensorType);
    
    const sensorProps = {
      ref: sensorRef,
      sensor,
      width,
      height,
      onSensorClick: () => setCurSensor(curSensor === sensorType ? null : sensorType),
      isSelected: curSensor === sensorType,
    };

    return <SensorDisplay key={sensorType} {...sensorProps} />;
  };

  const createDisplayInstance = (p5Instance, displayClass, sensor, width, height) => {
    if (!p5Instance) return null;
    return new displayClass(
        p5Instance,
        sensor,
        windowDimensions.width / 4 * width,
        windowDimensions.height / 2 * height,
    );
  };

  // Initialize p5.js instance and display instance
  useEffect(() => {
    if (!canvasRef.current || p5InstanceRef.current) return;

    const displayInstances = new Map();
    const sketch = (p) => {
      p.setup = async () => {
        p.createCanvas(windowDimensions.width, windowDimensions.height, p.WEBGL);
        p.ortho(0, windowDimensions.width, -windowDimensions.height, 0, -1000, 1000);
        // const font = await p.loadFont('assets/Roboto-VariableFont_wdth,wght.ttf');
        const font = await p.loadFont('assets/Inconsolata.otf');
        p.textFont(font);

        for (const [sensorType, sensor] of device.sensors.entries()) {
          // Assuming sensors have a visible property
          const {width, height} = getSensorDisplaySize(sensorType);
          displayInstances.set(sensorType, createDisplayInstance(p, getSensorDisplayClass(sensorType), sensor, width, height));
        }
      };

      p.draw = () => {
        p.background(0);
        for (const [sensorType, displayInstance] of displayInstances.entries()) {
          if (displayInstance && displayInstance.draw) {
            // Get screen coordinates from the sensor ref
            const sensorRef = sensorRefsMap.current.get(sensorType);
            let x = 0, y = 0;
            
            if (sensorRef && sensorRef.current) {
              const rect = sensorRef.current.getBoundingClientRect();
              x = rect.left;
              y = rect.top;
            }
            
            displayInstance.draw(x, y);
          }
        }
      };
    };

    p5InstanceRef.current = new p5(sketch, canvasRef.current);

    return () => {
      p5InstanceRef.current.remove();
    };
  }, [isActive]);

  const handleTabClick = (tabName) => {
    setCurrentTab(tabName);
  };

  const toggleVisible = (sensorType) => {
    // This would need to be implemented based on how sensors handle visibility
    return true;
  };

  const getTabs = () => {
    const tabs = ['overview'];
    for (const [sensorType] of device.sensors.entries()) {
      // Assuming sensors have a visible property
      tabs.push(sensorType.toString().toLowerCase());
    }
    const order = ['overview', 'acc', 'gyro', 'quat', 'euler', 'comp', 'altitude'];
    tabs.sort((a, b) => {
      return order.indexOf(a) - order.indexOf(b);
    });
    return tabs;
  };

  const tabs = getTabs();

  return (
    <div className="fixed top-0 left-0 w-full h-full z-10" style={{ left: index * deviceWidth }}>
      {/* Device Tab */}
      <button
        onClick={onDeviceSelect}
        className={`w-48 h-5 border border-white text-white flex items-center justify-center text-xs cursor-pointer relative ${
          isActive ? 'bg-blue-500' : 'bg-transparent'
        }`}
        style={{ width: deviceWidth, height: deviceHeight }}
      >
        <span className="absolute left-2">{index + 1}</span>
        <span>{device.id}{device.battery !== null ? ` ${device.battery}V` : ''}</span>
        {(device.isRecording || device.isPlaying) && (
          <div
            className={`absolute left-2 top-1/2 transform -translate-y-1/2 w-2 h-2 rounded-full ${
              device.isRecording ? 'bg-red-500' : device.isPaused ? 'bg-gray-500' : 'bg-green-500'
            }`}
          />
        )}
      </button>

      {/* Sensors with Tabs */}
      {isActive && (
        <div className="absolute w-screen h-screen" style={{ left: -index * deviceWidth }}>
          <Tabs value={currentTab} onValueChange={setCurrentTab} className="w-full h-full flex flex-col">
            {/* Tab Content */}
            <TabsContent value="overview" className="h-full">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 grid-rows-2 h-full pb-4">
                {Array.from(device.sensors.keys())
                    .sort((a, b) => {
                      const order = [
                        SensorType.ACC, SensorType.GYRO, SensorType.EULER, SensorType.QUAT, SensorType.GYRO,
                        SensorType.COMP, SensorType.ALTITUDE, SensorType.ECG, SensorType.HR, SensorType.MAG,
                        SensorType.PPG, SensorType.PPI
                      ];
                      return order.indexOf(a) - order.indexOf(b);
                    })
                    .map((sensorType) => createSensorDisplay(sensorType))}
              </div>
            </TabsContent>

            {tabs.filter(tab => tab !== 'overview').map(tab => (
              <TabsContent key={tab} value={tab} className="h-full">
                <div className="w-full h-full p-4">
                  {createSensorDisplay(tab.toUpperCase())}
                </div>
              </TabsContent>
            ))}

            {/* Bottom Tabs */}
            <div className="sticky bottom-0 w-full bg-white/10 backdrop-blur-sm">
              <TabsList className="w-full h-8 bg-gray-800 rounded-none">
                {tabs.map((tab) => (
                  <TabsTrigger
                    key={tab}
                    value={tab}
                    className="flex-1 text-xs data-[state=active]:bg-gray-600 data-[state=active]:text-white"
                  >
                    {tab}
                  </TabsTrigger>
                ))}
              </TabsList>
            </div>
          </Tabs>

          {/* P5.js canvas container */}
          <div
              ref={canvasRef}
              className="absolute top-0 left-0 w-full h-full pointer-events-none"
          />
        </div>
      )}
    </div>
  );
};

export default Device;