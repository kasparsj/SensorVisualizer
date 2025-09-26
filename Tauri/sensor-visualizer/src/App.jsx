import React, { useEffect, useState, useCallback, useRef } from 'react';
import { Device as DeviceComp, ErrorBoundary } from './components';
import Device from './Device';
import useEvent from "./hooks/useEvent.js";

const App = () => {
  const [devices, setDevices] = useState(new Map());
  const [currentDeviceId, setCurrentDeviceId] = useState('');
  const [listenIP, setListenIP] = useState('0.0.0.0');
  const [listenPort] = useState(57121);
  const [showFps, setShowFps] = useState(false);
  const [showInfo, setShowInfo] = useState(false);
  const [windowDimensions, setWindowDimensions] = useState({
    width: typeof window !== 'undefined' ? window.innerWidth : 1920,
    height: typeof window !== 'undefined' ? window.innerHeight : 1080
  });
  const [fps, setFps] = useState(60);
  const fpsCounterRef = useRef({ frames: 0, lastTime: Date.now() });

  // Animation loop for FPS tracking and device updates
  useEffect(() => {
    let animationFrame;
    
    const updateLoop = () => {
      const now = Date.now();
      fpsCounterRef.current.frames++;
      
      // Update FPS counter
      if (now - fpsCounterRef.current.lastTime >= 1000) {
        setFps(fpsCounterRef.current.frames);
        fpsCounterRef.current.frames = 0;
        fpsCounterRef.current.lastTime = now;
      }
      
      // Update all devices
      for (const device of devices.values()) {
        if (device.update) {
          device.update();
        }
      }
      
      animationFrame = requestAnimationFrame(updateLoop);
    };
    
    animationFrame = requestAnimationFrame(updateLoop);
    return () => cancelAnimationFrame(animationFrame);
  }, [devices]);

  // Window resize handler
  useEffect(() => {
    const handleResize = () => {
      setWindowDimensions({
        width: window.innerWidth,
        height: window.innerHeight
      });
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Keyboard event handler
  useEvent('keydown', (event) => {
    const devKeys = Array.from(devices.keys());

    if (event.key >= '1' && event.key <= '9' && event.key - '1' < devKeys.length) {
      setCurrentDeviceId(devKeys[event.key - '1']);
      return;
    }

    switch (event.key.toLowerCase()) {
      case 'i':
        setShowInfo(prev => !prev);
        break;
      case 'd':
        setShowFps(prev => !prev);
        break;
    }
  });

  const getOscPrefix = useCallback((addrPattern) => {
    const offset = addrPattern.charAt(0) === '/' ? 1 : 0;
    const index = addrPattern.indexOf("/", offset);
    if (index > -1) {
      return addrPattern.substring(0, index);
    }
    return addrPattern;
  }, []);

  const getOrCreateDevice = useCallback((deviceId, inPrefix, ip) => {
    setDevices(prevDevices => {
      const newDevices = new Map(prevDevices);
      let actualDeviceId = deviceId;
      
      if (newDevices.has(deviceId) && newDevices.get(deviceId).ip && newDevices.get(deviceId).ip !== ip) {
        actualDeviceId = `${deviceId}-${ip}`;
      }
      
      if (!newDevices.has(actualDeviceId)) {
        const device = new Device(actualDeviceId, ip, inPrefix);
        newDevices.set(device.id, device);
        
        if (currentDeviceId === '') {
          setCurrentDeviceId(actualDeviceId);
        }
      }
      
      return newDevices;
    });
    
    return devices.get(deviceId);
  }, [/*devices, */currentDeviceId]);

  const oscEvent = useCallback((msg) => {
    const prefix = getOscPrefix(msg.addr);
    const deviceId = prefix.replace(/^\//, "");
    if (deviceId === "") {
      console.log("Received an osc message without an address");
      return;
    }
    const ip = "unknown";
    try {
      const device = getOrCreateDevice(deviceId, prefix, ip);
      if (device && device.oscEvent) {
        device.oscEvent(msg);
      }
    } catch (e) {
      console.error(e);
    }
  }, [getOscPrefix, getOrCreateDevice]);

  const setupLocalIP = useCallback(async () => {
    if (window.__TAURI__) {
      try {
        const ip = await window.__TAURI__.invoke('get_local_ip_address');
        setListenIP(ip);
      } catch (error) {
        console.error('Failed to get local IP:', error);
      }
    }
  }, []);

  const setupOsc = useCallback(() => {
    if (window.__TAURI__) {
      console.log("Setting up OSC...");
      window.__TAURI__.invoke('start_osc_listener', { port: listenPort })
        .catch(err => console.error("Failed to start OSC listener:", err));
      window.__TAURI__.event.listen('osc-message', event => {
        oscEvent(event.payload);
      });
    } else {
      console.log('Tauri API not available - running in browser mode');
    }
  }, [listenPort, oscEvent]);

  // Initialize app
  useEffect(() => {
    setupLocalIP();
    setupOsc();
  }, [setupLocalIP, setupOsc]);

  return (
    <ErrorBoundary>
      <div 
        style={{ 
          position: 'relative', 
          width: '100vw', 
          height: '100vh', 
          overflow: 'hidden',
          backgroundColor: 'black',
          color: 'white',
          fontFamily: 'monospace'
        }}
        tabIndex={0} // Make div focusable for keyboard events
      >
      {/* Waiting Screen */}
      {devices.size === 0 && (
        <div style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          textAlign: 'center',
          zIndex: 2
        }}>
          <h1 style={{ fontSize: '36px', margin: '0 0 40px 0' }}>
            Waiting for data on {listenIP}:{listenPort}
          </h1>
          <div style={{ fontSize: '14px', lineHeight: '1.5' }}>
            <div>'/deviceId/acc' (x y z)</div>
            <div>'/deviceId/gyro' (x y z)</div>
            <div>'/deviceId/mag' (x y z)</div>
            <div>'/deviceId/altitude' (value)</div>
            <div>'/deviceId/comp' (heading in radians)</div>
            <div>'/deviceId/ecg' (value)</div>
            <div>'/deviceId/hr' (heartrate)</div>
            <div>'/deviceId/euler' (roll pitch yaw)</div>
            <div>'/deviceId/quat' (w x y z)</div>
          </div>
        </div>
      )}

      {/* FPS Counter */}
      {showFps && (
        <div style={{
          position: 'absolute',
          top: '0px',
          right: '5px',
          fontSize: '12px',
          color: 'white',
          zIndex: 10
        }}>
          {fps}fps
        </div>
      )}

      {/* Info Panel */}
      {showInfo && (
        <div style={{
          position: 'absolute',
          top: '15px',
          left: '15px',
          fontSize: '12px',
          color: 'white',
          backgroundColor: 'rgba(0,0,0,0.8)',
          padding: '10px',
          borderRadius: '4px',
          zIndex: 10
        }}>
          <div>Keyboard shortcuts:</div>
          <div>1-9: Select device</div>
          <div>i: Toggle info</div>
          <div>d: Toggle FPS</div>
          <div>Active devices: {devices.size}</div>
          <div>Window: {windowDimensions.width}x{windowDimensions.height}</div>
        </div>
      )}

      {/* Render React components for devices */}
      {Array.from(devices.entries()).map(([deviceId, device], index) => (
        <DeviceComp
          key={deviceId}
          device={device}
          windowDimensions={windowDimensions}
          isActive={deviceId === currentDeviceId}
          index={index}
          onDeviceSelect={() => setCurrentDeviceId(deviceId)}
        />
      ))}
      </div>
    </ErrorBoundary>
  );
};

export default App;