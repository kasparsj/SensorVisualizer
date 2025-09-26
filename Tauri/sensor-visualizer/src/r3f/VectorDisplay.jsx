import React, { useMemo, useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Line, Text } from '@react-three/drei';
import * as THREE from 'three';

const VectorPlot = ({ values, maxValue, histCursor }) => {
  const linesRef = useRef();
  
  const lineData = useMemo(() => {
    if (!values || !maxValue) return [];
    
    const maxX = Math.max(Math.abs(maxValue.x), Math.abs(maxValue.x));
    const maxY = Math.max(Math.abs(maxValue.y), Math.abs(maxValue.y)); 
    const maxZ = Math.max(Math.abs(maxValue.z), Math.abs(maxValue.z));
    const scalingFactor = Math.max(maxX, maxY, maxZ) || 1;
    
    const lines = [];
    const width = 300;
    const height = 100;
    
    for (let i = 0; i < values.length - 1; i++) {
      const curr = values[i];
      const next = values[i + 1];
      
      if (!curr || !next) continue;
      
      const x1 = (i / values.length) * width - width/2;
      const x2 = ((i + 1) / values.length) * width - width/2;
      
      // X component (red)
      lines.push({
        points: [
          [x1, (curr.x / scalingFactor) * height/2, 0],
          [x2, (next.x / scalingFactor) * height/2, 0]
        ],
        color: 'red'
      });
      
      // Y component (green)  
      lines.push({
        points: [
          [x1, (curr.y / scalingFactor) * height/2, 0],
          [x2, (next.y / scalingFactor) * height/2, 0]
        ],
        color: 'green'
      });
      
      // Z component (blue)
      lines.push({
        points: [
          [x1, (curr.z / scalingFactor) * height/2, 0],
          [x2, (next.z / scalingFactor) * height/2, 0]
        ],  
        color: 'blue'
      });
    }
    
    return lines;
  }, [values, maxValue]);
  
  return (
    <group>
      {lineData.map((line, i) => (
        <Line
          key={i}
          points={line.points}
          color={line.color}
          lineWidth={2}
        />
      ))}
    </group>
  );
};

const MagnitudePlot = ({ magnitudes, histCursor }) => {
  const lineData = useMemo(() => {
    if (!magnitudes) return [];
    
    const points = [];
    const width = 300;
    const height = 50;
    
    for (let i = 0; i < magnitudes.length; i++) {
      const x = (i / magnitudes.length) * width - width/2;
      const y = magnitudes[i] * height;
      points.push([x, y, 0]);
    }
    
    return points;
  }, [magnitudes]);
  
  if (lineData.length === 0) return null;
  
  return (
    <Line
      points={lineData}
      color="white"
      lineWidth={2}
    />
  );
};

export const VectorDisplayR3F = ({ sensor, width = 400, height = 300 }) => {
  return (
    <div style={{ width, height }}>
      <Canvas orthographic camera={{ position: [0, 0, 5], zoom: 50 }}>
        <ambientLight intensity={0.5} />
        <pointLight position={[10, 10, 10]} />
        
        {/* 2D Vector Plot */}
        <group position={[0, 1, 0]}>
          <VectorPlot 
            values={sensor.values}
            maxValue={sensor.maxValue}
            histCursor={sensor.histCursor}
          />
        </group>
        
        {/* Magnitude Display */}
        <group position={[0, -1.5, 0]}>
          {sensor.value && (
            <Text
              position={[-2, 0.5, 0]}
              fontSize={0.2}
              color="white"
            >
              {`mag % ${sensor.normMag().toFixed(2)}`}
            </Text>
          )}
          <MagnitudePlot 
            magnitudes={sensor.normMags}
            histCursor={sensor.histCursor}
          />
        </group>
      </Canvas>
    </div>
  );
};

export default VectorDisplayR3F;