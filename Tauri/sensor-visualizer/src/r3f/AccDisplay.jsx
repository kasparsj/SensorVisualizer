import React, { useMemo, useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Line, Text } from '@react-three/drei';
import * as THREE from 'three';

const VectorPlot = ({ values, maxValue, histCursor }) => {
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

const Plot3D = ({ size }) => {
  return (
    <group>
      {/* Axes */}
      <Line points={[[-size/2, 0, 0], [size/2, 0, 0]]} color="red" lineWidth={2} />
      <Line points={[[0, -size/2, 0], [0, size/2, 0]]} color="green" lineWidth={2} />
      <Line points={[[0, 0, -size/2], [0, 0, size/2]]} color="blue" lineWidth={2} />
      
      {/* Grid */}
      <gridHelper args={[size, 10]} />
    </group>
  );
};

const ForceVector = ({ value, maxValue, scaleFactor = 1 }) => {
  const vectorData = useMemo(() => {
    if (!value || !maxValue || !value.mag || !maxValue.mag) return null;
    
    let normMag = value.mag() / maxValue.mag();
    if (!isFinite(normMag)) normMag = 0;
    
    const magnitude = value.mag();
    if (!isFinite(magnitude) || magnitude === 0) return null;
    
    const scale = Math.max(normMag, 0.1) * scaleFactor;
    const force = value.copy().normalize().mult(scale);
    
    if (!isFinite(force.x) || !isFinite(force.y) || !isFinite(force.z)) return null;
    
    return {
      points: [[0, 0, 0], [force.y, force.x, force.z]], // p5 axis order
      magnitude: normMag
    };
  }, [value, maxValue, scaleFactor]);
  
  if (!vectorData) return null;
  
  return (
    <group>
      <Line
        points={vectorData.points}
        color="white"
        lineWidth={3}
      />
      <mesh position={vectorData.points[1]}>
        <sphereGeometry args={[0.05]} />
        <meshBasicMaterial color="white" />
      </mesh>
    </group>
  );
};

const VelocityDisplay = ({ sensor, width, height }) => {
  const velocityLines = useMemo(() => {
    if (!sensor.velocities || !sensor.maxVelocity) return [];
    
    const maxX = Math.abs(sensor.maxVelocity.x || 0);
    const maxY = Math.abs(sensor.maxVelocity.y || 0);
    const maxZ = Math.abs(sensor.maxVelocity.z || 0);
    const scalingFactor = Math.max(maxX, maxY, maxZ) || 1;
    
    const lines = [];
    const w = width - 40;
    const h = height / 2;
    
    for (let i = 0; i < sensor.velocities.length - 1; i++) {
      const curr = sensor.velocities[i];
      const next = sensor.velocities[i + 1];
      
      if (!curr || !next) continue;
      
      const x1 = (i / sensor.velocities.length) * w - w/2;
      const x2 = ((i + 1) / sensor.velocities.length) * w - w/2;
      
      lines.push({
        points: [
          [x1, (curr.x / scalingFactor) * h/2, 0],
          [x2, (next.x / scalingFactor) * h/2, 0]
        ],
        color: 'red'
      });
      
      lines.push({
        points: [
          [x1, (curr.y / scalingFactor) * h/2, 0],
          [x2, (next.y / scalingFactor) * h/2, 0]
        ],
        color: 'green'
      });
      
      lines.push({
        points: [
          [x1, (curr.z / scalingFactor) * h/2, 0],
          [x2, (next.z / scalingFactor) * h/2, 0]
        ],
        color: 'blue'
      });
    }
    
    return lines;
  }, [sensor.velocities, sensor.maxVelocity, width, height]);
  
  return (
    <group>
      {sensor.velocity && sensor.velocity.mag && (
        <Text
          position={[-2, 1, 0]}
          fontSize={0.15}
          color="white"
        >
          {`speed ${sensor.velocity.mag().toFixed(2)}`}
        </Text>
      )}
      
      {velocityLines.map((line, i) => (
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

const PositionDisplay = ({ sensor, width, height }) => {
  const positionSphere = useMemo(() => {
    if (!sensor.position || !sensor.maxPosition) return null;
    
    const maxPos = Math.max(
      Math.abs(sensor.maxPosition.x),
      Math.abs(sensor.maxPosition.y), 
      Math.abs(sensor.maxPosition.z)
    );
    
    if (maxPos === 0) return null;
    
    const scale = Math.min(width, height) / 4;
    
    return {
      position: [
        sensor.position.x / maxPos * scale,
        sensor.position.y / maxPos * scale,
        sensor.position.z / maxPos * scale
      ],
      maxScale: scale
    };
  }, [sensor.position, sensor.maxPosition, width, height]);
  
  if (!positionSphere) return null;
  
  return (
    <group>
      {sensor.position && (
        <Text
          position={[-2, 2, 0]}
          fontSize={0.15}
          color="white"
        >
          {`pos ${sensor.position.x.toFixed(2)}, ${sensor.position.y.toFixed(2)}, ${sensor.position.z.toFixed(2)}`}
        </Text>
      )}
      
      {/* Reference sphere */}
      <mesh position={[0, 0, 0]}>
        <sphereGeometry args={[positionSphere.maxScale]} />
        <meshBasicMaterial color="gray" wireframe opacity={0.2} transparent />
      </mesh>
      
      {/* Position sphere */}
      <mesh position={positionSphere.position}>
        <sphereGeometry args={[0.1]} />
        <meshBasicMaterial color="yellow" />
      </mesh>
    </group>
  );
};

export const AccDisplayR3F = ({ sensor, width = 400, height = 300 }) => {
  if (!sensor.value) return null;
  
  return (
    <div style={{ width, height }}>
      <Canvas orthographic camera={{ position: [3, 3, 3], zoom: 50 }}>
        <ambientLight intensity={0.6} />
        <pointLight position={[10, 10, 10]} />
        
        {width > height ? (
          <group>
            {/* 3D Plot */}
            <group position={[-1, 0, 0]} rotation={[-Math.PI/10, -Math.PI/10, 0]}>
              <Plot3D size={2} />
              <ForceVector 
                value={sensor.value}
                maxValue={sensor.maxValue}
                scaleFactor={1}
              />
            </group>
            
            {/* 2D Vector Plot */}
            <group position={[1, 1, 0]} scale={[0.5, 0.5, 0.5]}>
              <VectorPlot 
                values={sensor.values}
                maxValue={sensor.maxValue}
                histCursor={sensor.histCursor}
              />
            </group>
            
            {/* Velocity Display */}
            <group position={[1, -0.5, 0]} scale={[0.5, 0.5, 0.5]}>
              <VelocityDisplay sensor={sensor} width={width/2} height={height/4} />
            </group>
            
            {/* Position Display */}
            <group position={[2, 0, 0]} scale={[0.5, 0.5, 0.5]}>
              <PositionDisplay sensor={sensor} width={width/2} height={height} />
            </group>
          </group>
        ) : (
          <group>
            {/* Vertical layout */}
            <group position={[0, 2, 0]} rotation={[-Math.PI/10, -Math.PI/10, 0]}>
              <Plot3D size={2} />
              <ForceVector 
                value={sensor.value}
                maxValue={sensor.maxValue}
                scaleFactor={1}
              />
            </group>
            
            <group position={[0, 0.5, 0]} scale={[0.8, 0.8, 0.8]}>
              <VectorPlot 
                values={sensor.values}
                maxValue={sensor.maxValue}
                histCursor={sensor.histCursor}
              />
            </group>
            
            <group position={[0, -0.5, 0]} scale={[0.8, 0.8, 0.8]}>
              <VelocityDisplay sensor={sensor} width={width} height={height/4} />
            </group>
            
            <group position={[0, -2, 0]} scale={[0.8, 0.8, 0.8]}>
              <PositionDisplay sensor={sensor} width={width} height={height/2} />
            </group>
          </group>
        )}
      </Canvas>
    </div>
  );
};

export default AccDisplayR3F;