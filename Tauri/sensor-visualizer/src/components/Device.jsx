import React, {useState, useEffect, useRef, useMemo} from 'react';
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
    const sensorProps = {
      sensor,
      windowDimensions,
      width,
      height,
      displayClass: getSensorDisplayClass(sensorType),
      onSensorClick: () => setCurSensor(curSensor === sensorType ? null : sensorType),
      isSelected: curSensor === sensorType,
    };

    return <SensorDisplay key={sensorType} {...sensorProps} />;
  };

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
        </div>
      )}
    </div>
  );
};

export default Device;