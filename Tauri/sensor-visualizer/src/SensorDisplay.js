const FilterType = Object.freeze({
  NONE: { toString: () => "NONE" },
  LOWPASS: { toString: () => "LP" },
  KALMAN: { toString: () => "KALMAN" },
  next: (current) => {
    const values = Object.values(FilterType).filter(v => typeof v !== 'function');
    const currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % values.length];
  }
});

const TransformType = Object.freeze({
  NONE: { toString: () => "NONE" },
  SQUIRCLE: { toString: () => "SQUIRCLE" },
  next: (current) => {
    const values = Object.values(TransformType).filter(v => typeof v !== 'function');
    const currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % values.length];
  }
});

class SensorDisplay {
  
  constructor(p, x, y, w, h) {
    this.p = p;
    this.type = null; // Should be set by subclass
    this.device = null; // Should be set by subclass
    this.firstArg = 0;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.value = null;
    this.minMaxLen = 0;
    this.minValue = null;
    this.maxValue = null;
    this.values = null;
    this.rawValues = null;
    this.normValues = null;
    this.ups = 0;
    this.numUpdates = 0;
    this.avgLen = 0;
    this.avgValue = null;
    this.histLen = 0;
    this.histCursor = -1;
    this.filterType = FilterType.NONE;
    this.transformType = TransformType.NONE;
    this.numArgs = 1;
    this.supportBatch = false;
    this.makePlayRegular = true;
    this.visible = true;
    this.addr = null;
    this.curValue = null;
    this.parUpdIdx = 0;
  }

  enableHistory(histLen) {
    if (histLen > 0) {
      this.histLen = histLen;
      this.values = new Array(histLen).fill(null);
      this.rawValues = new Array(histLen).fill(null);
      this.normValues = new Array(histLen).fill(null);
    }
    return this;
  }

  enableAverage(avgLen) {
    if (avgLen > 0) {
      this.avgLen = avgLen;
      if (avgLen > this.histLen) {
        this.enableHistory(avgLen);
      }
    }
    return this;
  }

  setFilterType(ft) {
    this.filterType = ft;
    return this;
  }

  setTransformType(tt) {
    this.transformType = tt;
    return this;
  }

  updateUps() {
    this.ups = this.numUpdates;
    this.numUpdates = 0;
  }

  parse(msg, batchIndex) {
    throw new Error("Method 'parse()' must be implemented.");
  }

  parseFromRow(row) {
    throw new Error("Method 'parseFromRow()' must be implemented.");
  }

  parseParam(msg) {
    // This logic might need adjustment based on the OSC library used
    if (typeof msg.args[this.firstArg] === 'number') {
      return msg.args[this.firstArg];
    }
    return 0;
  }

  update(val) {
    switch (this.filterType) {
      case FilterType.KALMAN:
        this.value = this.kalman(val);
        break;
      case FilterType.LOWPASS:
        this.value = this.lowpass(val);
        break;
      case FilterType.NONE:
      default:
        this.value = val;
        break;
    }
    if (this.histLen > 0) {
      this.updateMinMax(this.value);
      this.updateHist(this.value, val);
    }
    this.transform();
    if (this.avgLen > 0) {
      this.updateAvg(this.value);
    }
    this.numUpdates++;
    this.curValue = val;
  }

  updateHist(value, rawVal) {
    const nextCursor = (this.histCursor + 1) % this.histLen;
    if (this.rawValues) {
      this.rawValues[nextCursor] = rawVal;
    }
    if (this.values) {
      this.values[nextCursor] = value;
    }
    if (typeof value === 'number' && Array.isArray(this.normValues)) {
      this.normValues[nextCursor] = this.normalize(value);
    }
    this.histCursor = nextCursor;
    if (this.minMaxLen > 0 && this.histCursor === (this.minMaxLen - 1)) {
      this.resetMinMax();
    }
  }

  updateMinMax(value) {
    if (typeof value === 'number') {
      if (this.minValue === null || value < this.minValue) {
        this.minValue = value;
      }
      if (this.maxValue === null || value > this.maxValue) {
        this.maxValue = value;
      }
    }
  }

  resetMinMax() {
    this.minValue = null;
    this.maxValue = null;
    for (let i = 0; i < this.histLen; i++) {
      this.updateMinMax(this.values[i]);
    }
  }

  normalize(value) {
    if (this.maxValue === this.minValue) return 0.5; // Avoid division by zero
    return (value - this.minValue) / (this.maxValue - this.minValue);
  }

  updateAvg(value) {
    if (!this.values || this.values.length === 0) {
      this.avgValue = value;
      return;
    }

    const relevantValues = this.values.slice(Math.max(0, this.histCursor - this.avgLen + 1), this.histCursor + 1);
    
    if (relevantValues.length === 0) {
        this.avgValue = value;
        return;
    }

    if (typeof value === 'number') {
      const sum = relevantValues.reduce((acc, val) => acc + (val || 0), 0);
      this.avgValue = sum / relevantValues.length;
    } else if (value instanceof this.p.constructor.Vector) {
      const sumVec = relevantValues.reduce((acc, val) => {
        if (val) {
          acc.add(val);
        }
        return acc;
      }, this.p.createVector(0, 0, 0));
      this.avgValue = sumVec.div(relevantValues.length);
    }
  }

  prevVal() {
    const prevIndex = this.histCursor > 0 ? this.histCursor - 1 : this.histLen + this.histCursor - 1;
    return this.values[prevIndex];
  }

  kalman(value) {
    console.log("kalman filter not implemented");
    return value;
  }

  lowpass(val, coef = 0.2, prevVal = this.value) {
    console.log("lowpass filter not implemented");
    return val;
  }

  transform() {
    // To be implemented by subclasses if needed
  }

  draw() {
    if (!this.visible) return;
    this.p.push();
    this.p.translate(this.x, this.y);
    this.drawBorder(this.w, this.h, this.device && this.device.curSensor === this);
    this.drawContent(this.w, this.h);
    this.p.pop();
  }

  drawBorder(w, h, isActive) {
    this.p.push();
    this.p.noFill();
    if (isActive) {
      this.p.stroke(127, 0, 0);
    } else {
      this.p.stroke(64);
    }
    this.p.rect(0, 0, w - 1, h - 1);
    this.p.pop();
  }

  drawContent(w, h) {
    throw new Error("Method 'drawContent()' must be implemented.");
  }

  oscEvent(msg) {
    let numValues = 1;
    if (this.supportBatch) {
      const msgArgs = msg.args.length;
      if ((msgArgs - this.firstArg) % this.numArgs === 0) {
        numValues = (msgArgs - this.firstArg) / this.numArgs;
      }
    }
    const parsedValues = [];
    for (let i = 0; i < numValues; i++) {
      this.update(this.parse(msg, i));
      parsedValues.push(this.value);
    }
    this.forward(parsedValues);
  }

  forward(values) {
    if (this.addr && this.addr.length > 0 && this.device) {
      if (values.length === 1) {
        this.forwardOne(values[0]);
      } else {
        this.forwardBatch(values);
      }
    }
  }

  async forwardOne(value) {
    if (!this.device.forwardAddr || !this.addr) return;
    
    const args = [this.device.id];
    
    if (typeof value === 'number') {
      args.push(value);
      if (this.histLen > 0 && this.normValues) {
        args.push(this.normValues[this.histCursor]);
        args.push(this.minValue);
        args.push(this.maxValue);
      }
      if (this.avgLen > 0 && this.avgValue !== null) {
        args.push(this.avgValue);
      }
    } else if (typeof value === 'string') {
      args.push(value);
    } else if (value && typeof value.x === 'number' && typeof value.y === 'number' && typeof value.z === 'number') {
      args.push(value.x);
      args.push(value.y);
      args.push(value.z);
    }
    
    try {
      await window.__TAURI__.invoke('send_osc_message', {
        address: this.device.outPrefix + this.addr,
        args: args,
        host: this.device.forwardAddr.host,
        port: this.device.forwardAddr.port
      });
    } catch (error) {
      console.error('Failed to send OSC message:', error);
    }
  }

  async forwardBatch(values) {
    if (!this.device.forwardAddr || !this.addr || values.length === 0) return;
    
    const args = [this.device.id];
    
    const firstValue = values[0];
    if (typeof firstValue === 'number') {
      args.push(1);
      for (let i = 0; i < values.length; i++) {
        args.push(values[i]);
      }
    } else if (typeof firstValue === 'string') {
      args.push(1);
      for (let i = 0; i < values.length; i++) {
        args.push(values[i]);
      }
    } else if (firstValue && typeof firstValue.x === 'number' && typeof firstValue.y === 'number' && typeof firstValue.z === 'number') {
      args.push(3);
      for (let i = 0; i < values.length; i++) {
        const val = values[i];
        args.push(val.x);
        args.push(val.y);
        args.push(val.z);
      }
    }
    
    try {
      await window.__TAURI__.invoke('send_osc_message', {
        address: this.device.outPrefix + this.addr + '/batch',
        args: args,
        host: this.device.forwardAddr.host,
        port: this.device.forwardAddr.port
      });
    } catch (error) {
      console.error('Failed to send OSC batch message:', error);
    }
  }
  
  mouseClicked() {
    if (this.visible && this.p.mouseX >= this.x && this.p.mouseX <= this.x + this.w && this.p.mouseY >= this.y && this.p.mouseY <= this.y + this.h) {
      if (this.device) {
        this.device.curSensor = this.device.curSensor !== this ? this : null;
      }
      return true;
    }
    return false;
  }

  keyPressed() {
    if (this.p.key === 'f') {
      this.setFilterType(FilterType.next(this.filterType));
      return true;
    }
    if (this.p.key === 't') {
      this.setTransformType(TransformType.next(this.transformType));
      return true;
    }
    if (this.p.key === 'v') {
      if (this.device) this.device.toggleVisible(this.type);
      return true;
    }
    if (this.p.key === 'm') {
      this.resetMinMax();
      return true;
    }
    return false;
  }
  
  resize() {
    if (!this.type || !this.p) return;
    
    const width = this.p.width;
    const height = this.p.height;
    
    // Apply the same layout logic as Processing version
    switch (this.type.toString()) {
      case 'ACC':
        this.x = 0;
        this.y = 20;
        this.w = width / 2;
        this.h = height / 2 - 20;
        break;
      case 'GYRO':
        this.x = width / 2;
        this.y = 20;
        this.w = width / 4;
        this.h = height / 2 - 20;
        break;
      case 'MAG':
        this.x = width / 4 * 3;
        this.y = 20;
        this.w = width / 4;
        this.h = height / 2 - 20;
        break;
      case 'HR':
        this.x = 0;
        this.y = height / 2;
        this.w = width / 4;
        this.h = height / 2 - 20;
        break;
      case 'ECG':
        this.x = width / 4;
        this.y = height / 2;
        this.w = width / 4;
        this.h = height / 2 - 20;
        break;
      case 'ALTITUDE':
        this.x = width / 2;
        this.y = height / 2;
        this.w = width / 4;
        this.h = height / 2 - 20;
        break;
      case 'COMP':
        this.x = width / 4;
        this.y = height / 2;
        this.w = width / 4;
        this.h = height / 2 - 20;
        break;
      case 'EULER':
        this.x = width / 2;
        this.y = 20;
        this.w = width / 2;
        this.h = height - 40;
        break;
      case 'QUAT':
        this.x = width / 4 * 3;
        this.y = 20;
        this.w = width / 4;
        this.h = height - 40;
        break;
      default:
        // Keep existing dimensions if no specific layout defined
        break;
    }
  }
}

export { SensorDisplay, FilterType, TransformType };
