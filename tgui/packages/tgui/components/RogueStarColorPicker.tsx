// ///////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Hex-ring + triangle RS color picker widget //
// ///////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Make custom colors optional /////////////////
// ///////////////////////////////////////////////////////////////////////////////////////////

import { clamp } from 'common/math';
import { Component, createRef } from 'inferno';
import { Box } from './Box';
import { Button } from './Button';
import { Input } from './Input';
import { NumberInput } from './NumberInput';
import {
  formatHex,
  hexToRgb,
  hsvToRgb,
  normalizeHex,
  rgbToHex,
  rgbToHsv,
} from '../utils/color';

type RogueStarColorPickerProps = {
  readonly color?: string;
  readonly currentColor?: string;
  readonly customColors?: (string | null)[];
  readonly onCustomColorsChange?: (colors: (string | null)[]) => void;
  readonly onChange?: (hex: string) => void;
  readonly onCommit?: (hex: string) => void;
  readonly showPreview?: boolean;
  readonly showCustomColors?: boolean;
};

type RgbState = {
  r: number;
  g: number;
  b: number;
};

type ColorState = {
  hue: number;
  saturation: number;
  value: number;
  hex: string;
  hexInput: string;
  rgb: RgbState;
  customSelection: number;
};

type DragTarget = 'ring' | 'triangle' | null;

type Point = {
  x: number;
  y: number;
};

type TriangleVertices = {
  hue: Point;
  white: Point;
  black: Point;
};

type BarycentricWeights = {
  hue: number;
  white: number;
  black: number;
};

const RING_SIZE = 280;
const RING_THICKNESS = 26;
const RING_INNER_RADIUS = RING_SIZE / 2 - RING_THICKNESS;
const TRIANGLE_SIZE = RING_INNER_RADIUS * 2;
const TRIANGLE_HEIGHT = TRIANGLE_SIZE;
const CUSTOM_COLOR_SLOTS = 16;
const DEFAULT_COLOR = '#ffffff';
const DISPLAY_HUE_OFFSET = -180;

const clamp255 = (value: number): number =>
  Math.round(Math.min(255, Math.max(0, Number.isFinite(value) ? value : 0)));

const toRgbState = (tuple: [number, number, number]): RgbState => ({
  r: clamp255(tuple[0]),
  g: clamp255(tuple[1]),
  b: clamp255(tuple[2]),
});

export class RogueStarColorPicker extends Component<
  RogueStarColorPickerProps,
  ColorState
> {
  public state: ColorState;

  private ringRef = createRef<HTMLDivElement>();
  private triangleRef = createRef<HTMLDivElement>();
  private triangleCanvasRef = createRef<HTMLCanvasElement>();
  private dragTarget: DragTarget = null;
  private previewFrame: number | null = null;
  private pendingPreviewHex: string | null = null;

  constructor(props: RogueStarColorPickerProps) {
    super(props);
    this.state = {
      ...this.buildColorState(props.color),
      customSelection: 0,
    };
  }

  componentDidMount() {
    this.renderTriangleCanvas();
  }

  componentDidUpdate(
    prevProps: RogueStarColorPickerProps,
    prevState: ColorState
  ) {
    if (prevProps.color !== this.props.color) {
      const incoming = normalizeHex(this.props.color) || DEFAULT_COLOR;
      if (incoming !== this.state.hex) {
        const nextState = this.buildColorState(incoming);
        this.setState((prev) => ({
          ...nextState,
          customSelection: prev.customSelection,
        }));
        return;
      }
    }
    if (prevState.hue !== this.state.hue) {
      this.renderTriangleCanvas();
    }
  }

  componentWillUnmount() {
    this.detachDrag();
    if (this.previewFrame !== null) {
      window.cancelAnimationFrame(this.previewFrame);
      this.previewFrame = null;
    }
  }

  render() {
    const {
      currentColor,
      onCustomColorsChange,
      showPreview,
      showCustomColors,
    } = this.props;
    const { hue, saturation, value, hex, rgb, hexInput, customSelection } =
      this.state;
    const displayRotation = this.getDisplayRotation();
    const triangleRotation = this.getTriangleRotation();
    const hueRgb = hsvToRgb(hue, 1, 1);
    const hueHex = rgbToHex(hueRgb[0], hueRgb[1], hueRgb[2]);
    const ringHandleRadius = RING_SIZE / 2 - RING_THICKNESS * 0.5;
    const ringHandle = polarToCartesian(displayRotation, ringHandleRadius);
    const trianglePointer = this.getTrianglePointer();
    const previewCurrent =
      normalizeHex(currentColor) ||
      normalizeHex(this.props.color) ||
      DEFAULT_COLOR;
    const shouldRenderPreview = showPreview !== false;
    const shouldRenderCustomColors = showCustomColors !== false;
    const customColors = shouldRenderCustomColors ? this.getCustomColors() : [];

    return (
      <Box className="RogueStarColorPicker">
        <div className="RogueStarColorPicker__layout">
          <div className="RogueStarColorPicker__wheelColumn">
            <div className="RogueStarColorPicker__wheelShell">
              <div
                ref={this.ringRef}
                className="RogueStarColorPicker__ring"
                style={{
                  width: `${RING_SIZE}px`,
                  height: `${RING_SIZE}px`,
                }}
                onMouseDown={this.handleRingMouseDown}>
                <div
                  className="RogueStarColorPicker__ringHandle"
                  style={{
                    left: `${ringHandle.x + RING_SIZE / 2}px`,
                    top: `${ringHandle.y + RING_SIZE / 2}px`,
                  }}
                />
              </div>
              <div
                ref={this.triangleRef}
                className="RogueStarColorPicker__triangle"
                style={{
                  width: `${TRIANGLE_SIZE}px`,
                  height: `${TRIANGLE_HEIGHT}px`,
                  transform: `translate(-50%, -50%) rotate(${triangleRotation}deg)`,
                }}
                onMouseDown={this.handleTriangleMouseDown}>
                <canvas
                  ref={this.triangleCanvasRef}
                  className="RogueStarColorPicker__triangleCanvas"
                  width={TRIANGLE_SIZE}
                  height={TRIANGLE_HEIGHT}
                />
                <div
                  className="RogueStarColorPicker__triangleHandle"
                  style={{
                    left: `${trianglePointer.x}px`,
                    top: `${trianglePointer.y}px`,
                  }}
                />
              </div>
            </div>
          </div>
          {shouldRenderCustomColors ? (
            <div className="RogueStarColorPicker__customRow">
              {customColors.map((color, index) => (
                <button
                  key={`custom-${index}`}
                  type="button"
                  className={[
                    'RogueStarColorPicker__swatch',
                    customSelection === index
                      ? 'RogueStarColorPicker__swatch--selected'
                      : '',
                  ]
                    .filter(Boolean)
                    .join(' ')}
                  style={{
                    background: color || 'transparent',
                  }}
                  onClick={() => this.handleCustomSwatchSelect(index, color)}
                />
              ))}
              <Button
                icon="plus"
                content="Save"
                className="RogueStarColorPicker__saveButton"
                disabled={!onCustomColorsChange}
                onClick={() => this.handleAddCustomColor()}
              />
            </div>
          ) : null}
        </div>

        <div className="RogueStarColorPicker__controlColumn">
          {shouldRenderPreview ? (
            <div className="RogueStarColorPicker__previewStack">
              <div className="RogueStarColorPicker__previewBox">
                <div
                  className="RogueStarColorPicker__previewSwatch"
                  style={{ background: hex }}
                />
                <div className="RogueStarColorPicker__previewLabel">New</div>
              </div>
              <div className="RogueStarColorPicker__previewBox">
                <div
                  className="RogueStarColorPicker__previewSwatch"
                  style={{ background: previewCurrent }}
                />
                <div className="RogueStarColorPicker__previewLabel">
                  Current
                </div>
              </div>
            </div>
          ) : null}
          <div className="RogueStarColorPicker__inputs">
            <div className="RogueStarColorPicker__inputRow">
              <div className="RogueStarColorPicker__inputLabel">Hex</div>
              <Input
                className="RogueStarColorPicker__hexInput"
                maxLength={7}
                value={hexInput}
                onInput={(_, value) => this.handleHexInput(value)}
                onChange={(_, value) => this.handleHexCommit(value)}
              />
            </div>
            <div className="RogueStarColorPicker__inputRow">
              <div className="RogueStarColorPicker__inputLabel">RGB</div>
              <div className="RogueStarColorPicker__rgbGrid">
                <NumberInput
                  width="70px"
                  minValue={0}
                  maxValue={255}
                  step={1}
                  value={rgb.r}
                  onChange={(_, value) =>
                    this.handleRgbFieldChange('r', value ?? 0)
                  }
                />
                <NumberInput
                  width="70px"
                  minValue={0}
                  maxValue={255}
                  step={1}
                  value={rgb.g}
                  onChange={(_, value) =>
                    this.handleRgbFieldChange('g', value ?? 0)
                  }
                />
                <NumberInput
                  width="70px"
                  minValue={0}
                  maxValue={255}
                  step={1}
                  value={rgb.b}
                  onChange={(_, value) =>
                    this.handleRgbFieldChange('b', value ?? 0)
                  }
                />
              </div>
            </div>
          </div>
        </div>
      </Box>
    );
  }

  private buildColorState(color?: string): Omit<ColorState, 'customSelection'> {
    const normalized = normalizeHex(color) || DEFAULT_COLOR;
    const rgbTuple = hexToRgb(normalized) ||
      hexToRgb(DEFAULT_COLOR) || [255, 255, 255];
    const hsv = rgbToHsv(rgbTuple[0], rgbTuple[1], rgbTuple[2]);
    return {
      hue: hsv.h,
      saturation: hsv.s,
      value: hsv.v,
      hex: normalized,
      hexInput: formatHex(normalized),
      rgb: toRgbState(rgbTuple),
    };
  }

  private emitPreview(hex: string) {
    if (!this.props.onChange) {
      return;
    }
    this.pendingPreviewHex = hex;
    if (this.previewFrame !== null) {
      return;
    }
    this.previewFrame = window.requestAnimationFrame(() => {
      this.previewFrame = null;
      const next = this.pendingPreviewHex;
      this.pendingPreviewHex = null;
      if (next && this.props.onChange) {
        this.props.onChange(next);
      }
    });
  }

  private renderTriangleCanvas() {
    const canvas = this.triangleCanvasRef.current;
    if (!canvas) {
      return;
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      return;
    }
    const width = canvas.width || TRIANGLE_SIZE;
    const height = canvas.height || TRIANGLE_HEIGHT;
    if (canvas.width !== width) {
      canvas.width = width;
    }
    if (canvas.height !== height) {
      canvas.height = height;
    }
    const imageData = ctx.createImageData(width, height);
    const vertices = buildTriangleVertices(width, height);
    const hue = this.state.hue;
    let offset = 0;
    for (let y = 0; y < height; y += 1) {
      for (let x = 0; x < width; x += 1) {
        const point: Point = { x: x + 0.5, y: y + 0.5 };
        const bary = computeBarycentric(point, vertices);
        if (bary.hue < 0 || bary.white < 0 || bary.black < 0) {
          imageData.data[offset + 3] = 0;
        } else {
          const { saturation, value } = barycentricToSaturationValue(bary);
          const rgbTuple = hsvToRgb(hue, saturation, value);
          imageData.data[offset] = clamp255(rgbTuple[0]);
          imageData.data[offset + 1] = clamp255(rgbTuple[1]);
          imageData.data[offset + 2] = clamp255(rgbTuple[2]);
          imageData.data[offset + 3] = 255;
        }
        offset += 4;
      }
    }
    ctx.putImageData(imageData, 0, 0);
  }

  private startDrag(target: DragTarget) {
    this.detachDrag();
    this.dragTarget = target;
    window.addEventListener('mousemove', this.handleGlobalMove);
    window.addEventListener('mouseup', this.handleGlobalUp);
  }

  private detachDrag() {
    if (!this.dragTarget) {
      return;
    }
    window.removeEventListener('mousemove', this.handleGlobalMove);
    window.removeEventListener('mouseup', this.handleGlobalUp);
    this.dragTarget = null;
  }

  private handleGlobalMove = (event: MouseEvent) => {
    if (this.dragTarget === 'ring') {
      this.updateHueFromPointer(event);
    } else if (this.dragTarget === 'triangle') {
      this.updateTriangleFromPointer(event);
    }
  };

  private handleGlobalUp = () => {
    const hadDragTarget = this.dragTarget;
    const hex = this.state.hex;
    this.detachDrag();
    if (hadDragTarget && this.props.onCommit) {
      this.props.onCommit(hex);
    }
  };

  private handleRingMouseDown = (event: MouseEvent) => {
    event.preventDefault();
    this.startDrag('ring');
    this.updateHueFromPointer(event);
  };

  private handleTriangleMouseDown = (event: MouseEvent) => {
    event.preventDefault();
    this.startDrag('triangle');
    this.updateTriangleFromPointer(event);
  };

  private updateHueFromPointer(event: MouseEvent) {
    const ring = this.ringRef.current;
    if (!ring) {
      return;
    }
    const rect = ring.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const dx = event.clientX - cx;
    const dy = event.clientY - cy;
    if (dx === 0 && dy === 0) {
      return;
    }
    const angle = (Math.atan2(dy, dx) * 180) / Math.PI;
    const hue = normalizeHue(angle - DISPLAY_HUE_OFFSET);
    this.applyHsv({ hue });
  }

  private updateTriangleFromPointer(event: MouseEvent) {
    const triangle = this.triangleRef.current;
    if (!triangle) {
      return;
    }
    const canonicalPoint = toCanonicalTrianglePoint(
      event,
      triangle,
      this.getTriangleRotation()
    );
    const width = triangle.offsetWidth || TRIANGLE_SIZE;
    const height = triangle.offsetHeight || TRIANGLE_HEIGHT;
    const clampedPoint = {
      x: clamp(canonicalPoint.x, 0, width),
      y: clamp(canonicalPoint.y, 0, height),
    };
    const bary = clampPointToTriangle(
      clampedPoint,
      buildTriangleVertices(width, height)
    );
    const { saturation, value } = barycentricToSaturationValue(bary);
    this.applyHsv({ saturation, value });
  }

  private getTrianglePointer(): Point {
    const triangle = this.triangleRef.current;
    const width = triangle?.offsetWidth || TRIANGLE_SIZE;
    const height = triangle?.offsetHeight || TRIANGLE_HEIGHT;
    const vertices = buildTriangleVertices(width, height);
    const bary = saturationValueToBarycentric(
      this.state.saturation,
      this.state.value
    );
    const point = barycentricToPoint(bary, vertices);
    return {
      x: point.x,
      y: point.y,
    };
  }

  private applyHsv(
    partial: Partial<{ hue: number; saturation: number; value: number }>
  ) {
    this.setState(
      (prev) => {
        const hue =
          partial.hue !== undefined ? normalizeHue(partial.hue) : prev.hue;
        const saturation =
          partial.saturation !== undefined
            ? clamp(partial.saturation, 0, 1)
            : prev.saturation;
        const value =
          partial.value !== undefined ? clamp(partial.value, 0, 1) : prev.value;
        const rgbTuple = hsvToRgb(hue, saturation, value);
        const hexValue = rgbToHex(rgbTuple[0], rgbTuple[1], rgbTuple[2]);
        return {
          hue,
          saturation,
          value,
          rgb: toRgbState(rgbTuple),
          hex: hexValue,
          hexInput: formatHex(hexValue),
          customSelection: prev.customSelection,
        };
      },
      () => this.emitPreview(this.state.hex)
    );
  }

  private handleHexInput(value?: string) {
    const sanitized = (value || '')
      .toUpperCase()
      .replace(/[^0-9A-F]/g, '')
      .slice(0, 6);
    this.setState({
      hexInput: `#${sanitized}`,
    });
  }

  private handleHexCommit(value?: string) {
    const normalized = normalizeHex(value);
    if (normalized) {
      this.applyHex(normalized);
    } else {
      this.setState((prev) => ({
        hexInput: formatHex(prev.hex),
      }));
    }
  }

  private applyHex(hex: string) {
    const normalized = normalizeHex(hex);
    if (!normalized) {
      return;
    }
    const rgbTuple = hexToRgb(normalized);
    if (!rgbTuple) {
      return;
    }
    const hsv = rgbToHsv(rgbTuple[0], rgbTuple[1], rgbTuple[2]);
    this.setState(
      (prev) => ({
        hue: hsv.h,
        saturation: hsv.s,
        value: hsv.v,
        rgb: toRgbState(rgbTuple),
        hex: normalized,
        hexInput: formatHex(normalized),
        customSelection: prev.customSelection,
      }),
      () => this.emitPreview(normalized)
    );
  }

  private handleRgbFieldChange(channel: keyof RgbState, value: number) {
    const clamped = clamp(value, 0, 255);
    this.setState(
      (prev) => {
        const nextRgb: RgbState = {
          ...prev.rgb,
          [channel]: clamp255(clamped),
        };
        const hsv = rgbToHsv(nextRgb.r, nextRgb.g, nextRgb.b);
        const hexValue = rgbToHex(nextRgb.r, nextRgb.g, nextRgb.b);
        return {
          hue: hsv.h,
          saturation: hsv.s,
          value: hsv.v,
          rgb: nextRgb,
          hex: hexValue,
          hexInput: formatHex(hexValue),
          customSelection: prev.customSelection,
        };
      },
      () => this.emitPreview(this.state.hex)
    );
  }

  private handleCustomSwatchSelect(index: number, color: string | null) {
    this.setState({
      customSelection: index,
    });
    if (color) {
      this.applyHex(color);
    }
  }

  private handleAddCustomColor() {
    const { onCustomColorsChange } = this.props;
    if (!onCustomColorsChange) {
      return;
    }
    const next = this.getCustomColors();
    next[this.state.customSelection] = this.state.hex;
    onCustomColorsChange(next);
  }

  private getCustomColors(): (string | null)[] {
    const provided = Array.isArray(this.props.customColors)
      ? this.props.customColors
      : [];
    const colors: (string | null)[] = [];
    for (let i = 0; i < CUSTOM_COLOR_SLOTS; i += 1) {
      const entry = provided[i];
      colors.push(
        typeof entry === 'string' ? normalizeHex(entry) : (entry ?? null)
      );
    }
    return colors;
  }

  private getDisplayRotation(): number {
    return this.state.hue + DISPLAY_HUE_OFFSET;
  }

  private getTriangleRotation(): number {
    return this.getDisplayRotation() + 90;
  }
}

const toCanonicalTrianglePoint = (
  event: MouseEvent,
  triangle: HTMLDivElement,
  triangleRotation: number
): Point => {
  const rect = triangle.getBoundingClientRect();
  const center = {
    x: rect.left + rect.width / 2,
    y: rect.top + rect.height / 2,
  };
  const local = {
    x: event.clientX - center.x,
    y: event.clientY - center.y,
  };
  const radians = (-triangleRotation * Math.PI) / 180;
  const rotated = rotatePoint(local, radians);
  const width = triangle.offsetWidth || TRIANGLE_SIZE;
  const height = triangle.offsetHeight || TRIANGLE_HEIGHT;
  return {
    x: rotated.x + width / 2,
    y: rotated.y + height / 2,
  };
};

const rotatePoint = (point: Point, radians: number): Point => {
  const cos = Math.cos(radians);
  const sin = Math.sin(radians);
  return {
    x: point.x * cos - point.y * sin,
    y: point.x * sin + point.y * cos,
  };
};

const normalizeHue = (value: number): number => ((value % 360) + 360) % 360;

const polarToCartesian = (hue: number, radius: number): Point => {
  const angle = (hue * Math.PI) / 180;
  return {
    x: radius * Math.cos(angle),
    y: radius * Math.sin(angle),
  };
};

const buildTriangleVertices = (
  width: number,
  height: number
): TriangleVertices => {
  const radius = Math.min(width, height) / 2;
  const centerX = width / 2;
  const centerY = height / 2;
  const offsetX = (Math.sqrt(3) / 2) * radius;
  const offsetY = 0.5 * radius;
  return {
    hue: { x: centerX, y: centerY - radius },
    white: { x: centerX - offsetX, y: centerY + offsetY },
    black: { x: centerX + offsetX, y: centerY + offsetY },
  };
};

const barycentricToPoint = (
  weights: BarycentricWeights,
  vertices: TriangleVertices
): Point => ({
  x:
    weights.hue * vertices.hue.x +
    weights.white * vertices.white.x +
    weights.black * vertices.black.x,
  y:
    weights.hue * vertices.hue.y +
    weights.white * vertices.white.y +
    weights.black * vertices.black.y,
});

const computeBarycentric = (
  point: Point,
  vertices: TriangleVertices
): BarycentricWeights => {
  const v0 = {
    x: vertices.white.x - vertices.hue.x,
    y: vertices.white.y - vertices.hue.y,
  };
  const v1 = {
    x: vertices.black.x - vertices.hue.x,
    y: vertices.black.y - vertices.hue.y,
  };
  const v2 = {
    x: point.x - vertices.hue.x,
    y: point.y - vertices.hue.y,
  };
  const d00 = dot(v0, v0);
  const d01 = dot(v0, v1);
  const d11 = dot(v1, v1);
  const d20 = dot(v2, v0);
  const d21 = dot(v2, v1);
  const denom = d00 * d11 - d01 * d01 || 1;
  const v = (d11 * d20 - d01 * d21) / denom;
  const w = (d00 * d21 - d01 * d20) / denom;
  const u = 1 - v - w;
  return { hue: u, white: v, black: w };
};

const clampPointToTriangle = (
  point: Point,
  vertices: TriangleVertices
): BarycentricWeights => {
  let bary = computeBarycentric(point, vertices);
  if (bary.hue >= 0 && bary.white >= 0 && bary.black >= 0) {
    return normalizeBarycentric(bary);
  }
  if (bary.hue < 0) {
    const clamped = projectToEdge(point, vertices.white, vertices.black);
    bary = computeBarycentric(clamped, vertices);
  } else if (bary.white < 0) {
    const clamped = projectToEdge(point, vertices.hue, vertices.black);
    bary = computeBarycentric(clamped, vertices);
  } else if (bary.black < 0) {
    const clamped = projectToEdge(point, vertices.hue, vertices.white);
    bary = computeBarycentric(clamped, vertices);
  }
  return normalizeBarycentric(bary);
};

const projectToEdge = (point: Point, a: Point, b: Point): Point => {
  const ab = { x: b.x - a.x, y: b.y - a.y };
  const ap = { x: point.x - a.x, y: point.y - a.y };
  const t = clamp(dot(ap, ab) / (dot(ab, ab) || 1), 0, 1);
  return {
    x: a.x + ab.x * t,
    y: a.y + ab.y * t,
  };
};

const normalizeBarycentric = (
  weights: BarycentricWeights
): BarycentricWeights => {
  const sum = weights.hue + weights.white + weights.black || 1;
  return {
    hue: weights.hue / sum,
    white: weights.white / sum,
    black: weights.black / sum,
  };
};

const saturationValueToBarycentric = (
  saturation: number,
  value: number
): BarycentricWeights => {
  const v = clamp(value, 0, 1);
  const s = clamp(saturation, 0, 1);
  const hueWeight = v * s;
  const whiteWeight = v * (1 - s);
  const blackWeight = 1 - v;
  return normalizeBarycentric({
    hue: hueWeight,
    white: whiteWeight,
    black: blackWeight,
  });
};

const barycentricToSaturationValue = (
  weights: BarycentricWeights
): { saturation: number; value: number } => {
  const normalized = normalizeBarycentric(weights);
  const value = 1 - normalized.black;
  const totalColor = normalized.hue + normalized.white;
  const saturation = totalColor <= 0 ? 0 : normalized.hue / totalColor;
  return {
    value,
    saturation,
  };
};

const dot = (a: Point, b: Point): number => a.x * b.x + a.y * b.y;
