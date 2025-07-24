import { SensorDisplay } from './SensorDisplay.js';
import { SensorType } from './Device.js';
import { plotMagnitude } from './utils/drawing.js';

export class AltitudeDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h, avgLen = 2, histLen = 50) {
    super(p, x, y, w, h);
    this.device = device;
    this.type = SensorType.ALTITUDE;
    this.addr = "/altitude";
    this.enableHistory(histLen);
    this.enableAverage(avgLen);
  }

  updateAvg(value) {
    if (!this.values || this.avgLen <= 0) return;
    
    let sum = 0;
    let count = 0;
    for (let i = this.avgLen - 1; i >= 0; i--) {
      const index = i > this.histCursor ? this.histLen + (this.histCursor - i) : this.histCursor - i;
      const val = this.values[index];
      if (val !== null && val !== undefined) {
        sum += val;
        count++;
      }
    }
    this.avgValue = count > 0 ? sum / count : null;
  }

  drawContent(w, h) {
    this.drawHeader(w, h);
    
    if (!this.perc || this.perc[this.histCursor] == null) return;
    
    this.p.push();
    this.p.fill(255);
    this.p.stroke(255);
    this.p.line(20, 33, 20 + this.perc[this.histCursor] * (w - 40), 33);
    this.p.text(this.perc[this.histCursor].toFixed(2), 20, 55);
    this.p.pop();

    this.p.push();
    this.p.translate(20, h - 20);
    plotMagnitude(this.p, this.perc, w - 40, -h + 80, this.histCursor);
    this.p.pop();
  }
  
  drawHeader(w, h) {
    this.p.push();
    this.p.fill(255);
    this.p.textSize(16);
    
    if (this.perc && this.perc[this.histCursor] != null) {
      let avgMinMax = "";
      if (this.avgLen > 0 && this.avgValue !== null) {
        avgMinMax += `avg/${this.avgLen} ${this.avgValue.toFixed(2)}`;
      }
      if (this.ups > 0 && this.minValue !== null && this.maxValue !== null) {
        avgMinMax += ` (${this.minValue.toFixed(2)}, ${this.maxValue.toFixed(2)})`;
      }
      this.p.text(`altitude ${avgMinMax}`, 20, 20);
      this.p.text(`${this.ups} hz`, w - 50, 20);
    } else {
      this.p.text("altitude", 20, 20);
      this.p.text("no data", w - 50, 20);
    }
    
    this.p.pop();
  }
  
  update(val) {
    super.update(val);
    this.updateAvg(val);
  }

  oscEvent(msg) {
    const val = msg.args[0].value;
    this.update(val);
  }

  parse(msg, i) {
    return msg.args[this.firstArg + i].value;
  }

  parseFromRow(row) {
    // For CSV/table data - assuming altitude is in column 2
    return parseFloat(row[2]);
  }
}
