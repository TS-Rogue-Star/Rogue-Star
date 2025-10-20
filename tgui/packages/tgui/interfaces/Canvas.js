// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2025 to make painting more authentic and add a new drawing tablet with a variety of advanced functions //
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component, createRef } from 'inferno';
import { useBackend, useLocalState } from '../backend'; // RS Edit: Add useLocalState (Lira, September 2025)
import { Box, Button, NumberInput, Tooltip } from '../components'; // RS Edit: Add NumberInput and Tooltip (Lira, September 2025)
import { Window } from '../layouts';

const PX_PER_UNIT = 24;

export class PaintCanvas extends Component {
  // RS Edit: Export canvas (Lira, September 2025)
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    // RS Add Start: New props to support painting enhancement (Lira, September 2025)
    this.lineStart = null;
    this.state = { hover: null };
    this.dragging = false;
    this.lastPos = null;
    this.strokeSeq = 0;
    this.currentStroke = null;
    this.overlayCache = null;
    this.gridBuffer = this.cloneGrid(props.value || []);
    this.lastDiffSeq = props.diffSeq || 0;
    this.handleGlobalMouseUp = this.handleGlobalMouseUp.bind(this);
    this.handleGlobalKeyDown = this.handleGlobalKeyDown.bind(this);
    this.isInside = false;
    // RS Add End
  }

  // RS Add: Custom marking support (Lira, September 2025)
  cloneGrid(source) {
    if (!Array.isArray(source)) {
      return [];
    }
    return source.map((column) =>
      Array.isArray(column) ? column.slice() : []
    );
  }

  // RS Add: Custom marking support (Lira, September 2025)
  applyDiff(diff) {
    if (!Array.isArray(diff) || !diff.length) {
      return;
    }
    if (!Array.isArray(this.gridBuffer) || !this.gridBuffer.length) {
      this.gridBuffer = this.cloneGrid(this.props.value || []);
    }
    diff.forEach((entry) => {
      if (!entry) {
        return;
      }
      const xi = (entry.x || 0) - 1;
      const yi = (entry.y || 0) - 1;
      if (xi < 0 || yi < 0) {
        return;
      }
      if (xi >= this.gridBuffer.length) {
        return;
      }
      const column = this.gridBuffer[xi];
      if (!Array.isArray(column) || yi >= column.length) {
        return;
      }
      column[yi] = entry.color || '#00000000';
    });
  }

  componentDidMount() {
    // RS Add: Custom marking support (Lira, September 2025)
    if (Array.isArray(this.props.diff) && this.props.diff.length) {
      this.applyDiff(this.props.diff);
      this.lastDiffSeq = this.props.diffSeq || 0;
    }
    this.drawCanvas(this.props);
    // RS Add Start: End brush strokes even if mouse is released outside the canvas (Lira, September 2025)
    window.addEventListener('mouseup', this.handleGlobalMouseUp);
    window.addEventListener('blur', this.handleGlobalMouseUp);
    // Keyboard shortcut for undo (Ctrl+Z)
    window.addEventListener('keydown', this.handleGlobalKeyDown);
    // RS Add End
  }

  componentDidUpdate(prevProps) {
    // RS Add Start: Custom marking support (Lira, September 2025)
    let shouldRedraw = false;

    const prevValue = prevProps.value || [];
    const nextValue = this.props.value || [];

    if (
      prevValue !== nextValue ||
      prevValue.length !== nextValue.length ||
      (Array.isArray(prevValue[0]) ? prevValue[0].length : 0) !==
        (Array.isArray(nextValue[0]) ? nextValue[0].length : 0)
    ) {
      this.gridBuffer = this.cloneGrid(nextValue);
      this.lastDiffSeq = this.props.diffSeq || 0;
      shouldRedraw = true;
    }

    const incomingDiffSeq = this.props.diffSeq;
    if (
      incomingDiffSeq !== undefined &&
      incomingDiffSeq !== null &&
      incomingDiffSeq !== this.lastDiffSeq &&
      Array.isArray(this.props.diff) &&
      this.props.diff.length
    ) {
      if (!Array.isArray(this.gridBuffer) || !this.gridBuffer.length) {
        this.gridBuffer = this.cloneGrid(
          this.props.value || prevProps.value || []
        );
      }
      this.applyDiff(this.props.diff);
      this.lastDiffSeq = incomingDiffSeq;
      shouldRedraw = true;
    }

    if (
      shouldRedraw ||
      prevProps.reference !== this.props.reference ||
      prevProps.referenceParts !== this.props.referenceParts ||
      prevProps.referenceOpacity !== this.props.referenceOpacity ||
      prevProps.referenceOpacityMap !== this.props.referenceOpacityMap ||
      prevProps.layerParts !== this.props.layerParts ||
      prevProps.layerRevision !== this.props.layerRevision ||
      prevProps.otherLayerOpacity !== this.props.otherLayerOpacity ||
      prevProps.tool !== this.props.tool ||
      prevProps.size !== this.props.size ||
      prevProps.previewColor !== this.props.previewColor
    ) {
      // RS Add End
      this.drawCanvas(this.props);
    }
  }

  // RS Add: Remove event listeners on unmount (Lira, September 2025)
  componentWillUnmount() {
    window.removeEventListener('mouseup', this.handleGlobalMouseUp);
    window.removeEventListener('blur', this.handleGlobalMouseUp);
    window.removeEventListener('keydown', this.handleGlobalKeyDown);
  }

  // RS Edit: Allow overlaying species reference guides when painting custom markings (Lira, September 2025)
  drawCanvas(propSource) {
    // RS Add Start: Custom marking support (Lira, September 2025)
    const canvas = this.canvasRef.current;
    if (!canvas) {
      return;
    }
    // RS Add End
    const ctx = canvas.getContext('2d'); // RS Edit: Custom marking support (Lira, September 2025)
    const grid =
      Array.isArray(this.gridBuffer) && this.gridBuffer.length
        ? this.gridBuffer
        : propSource.value || []; // RS Edit: Custom marking support (Lira, September 2025)

    // RS Add Start: Resolve part overlays so each slot can supply custom guidance art (Lira, September 2025)
    const reference = propSource.reference || null;
    const referenceParts = propSource.referenceParts || null;
    const layerParts = propSource.layerParts || null;
    const layerOrder = propSource.layerOrder || null;
    const activeLayerKey = propSource.activeLayerKey || null;
    const otherLayerOpacity = propSource.otherLayerOpacity;
    const referenceOpacityMap = propSource.referenceOpacityMap || null;
    const referencePartKeys = referenceParts ? Object.keys(referenceParts) : [];
    let fallbackReference = reference;
    if (referenceParts && referencePartKeys.length) {
      if (referenceParts.generic) {
        fallbackReference = referenceParts.generic;
      } else {
        for (const key of referencePartKeys) {
          const layer = referenceParts[key];
          if (layer && layer.length) {
            fallbackReference = layer;
            break;
          }
        }
      }
    }
    // RS Add Emd

    // RS Edit Start: Custom marking support (Lira, September 2025)
    let x_size = grid.length;
    let y_size = x_size && Array.isArray(grid[0]) ? grid[0].length : 0;
    if ((!x_size || !y_size) && fallbackReference && fallbackReference.length) {
      x_size = fallbackReference.length;
      y_size = fallbackReference[0] ? fallbackReference[0].length || 0 : 0;
    }
    if (!x_size || !y_size) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      this.overlayCache = null;
      return;
    }
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const x_scale = Math.max(1, Math.round(canvas.width / x_size));
    const y_scale = Math.max(1, Math.round(canvas.height / y_size));
    // RS Edit End

    // RS Add Start: Support user-tunable opacity per part while respecting sane defaults (Lira, September 2025)
    const defaultReferenceOpacity = clamp(
      propSource.referenceOpacity !== undefined
        ? propSource.referenceOpacity
        : 0.4,
      0,
      1
    );
    const resolvedGenericOpacity = resolveGenericOpacity(
      referenceOpacityMap,
      defaultReferenceOpacity
    );
    const layerOpacity = clamp(
      otherLayerOpacity !== undefined
        ? otherLayerOpacity
        : resolvedGenericOpacity,
      0,
      1
    );
    const overlayCanvas = this.getOverlayCanvas({
      source: propSource,
      canvas,
      xScale: x_scale,
      yScale: y_scale,
      ySize: y_size,
      reference,
      referenceParts,
      referencePartKeys,
      referenceOpacityMap,
      resolvedGenericOpacity,
      layerParts,
      layerOrder,
      activeLayerKey,
      layerOpacity,
    });
    if (overlayCanvas) {
      ctx.drawImage(overlayCanvas, 0, 0);
    }
    // RS Add End

    ctx.save();
    ctx.scale(x_scale, y_scale);
    ctx.imageSmoothingEnabled = false; // RS Add: Custom marking support (Lira, September 2025)
    for (let x = 0; x < grid.length; x++) {
      const element = grid[x];
      if (!element) continue; // RS Add: Custom marking support (Lira, September 2025)
      for (let y = 0; y < element.length; y++) {
        const color = element[y];
        ctx.fillStyle = color;
        ctx.fillRect(x, y, 1, 1);
      }
    }

    // RS Add: Overlay preview for line tool (Lira, September 2025)
    const tool = this.props.tool || 'brush';
    if (
      !this.props.finalized &&
      tool === 'line' &&
      this.lineStart &&
      this.state.hover
    ) {
      // Convert 1-based grid coords to 0-based for canvas rendering
      const x1 = this.lineStart.x - 1;
      const y1 = this.lineStart.y - 1;
      const [hx, hy] = this.state.hover;
      const x2 = hx - 1;
      const y2 = hy - 1;
      const size = this.props.size || 1;
      const color = this.props.previewColor || '#000000';
      const colorAlpha = toHexWithAlpha(color, '80');
      ctx.fillStyle = colorAlpha;
      drawLinePixels(x1, y1, x2, y2, (px, py) => {
        drawBrush(ctx, px, py, size);
      });
    }
    ctx.restore();
  }

  // RS Add: Custom marking support (Lira, Septembe 2025)
  getOverlayCanvas(options) {
    const {
      source,
      canvas,
      xScale,
      yScale,
      ySize,
      reference,
      referenceParts,
      referencePartKeys,
      referenceOpacityMap,
      resolvedGenericOpacity,
      layerParts,
      layerOrder,
      activeLayerKey,
      layerOpacity,
    } = options;
    const revision = source.layerRevision || 0;
    const opacitySignature = serializeOpacityMap(referenceOpacityMap);
    const normalizedOpacity = Number.isFinite(layerOpacity) ? layerOpacity : 0;
    const overlayKey = [
      revision,
      activeLayerKey || '',
      Math.round(normalizedOpacity * 1000) / 1000,
      opacitySignature,
      Math.round(resolvedGenericOpacity * 1000) / 1000,
      canvas.width,
      canvas.height,
      referencePartKeys.join(','),
    ].join('|');
    if (this.overlayCache && this.overlayCache.key === overlayKey) {
      return this.overlayCache.canvas;
    }
    if (
      !shouldRenderOverlay({
        reference,
        referenceParts,
        referenceOpacityMap,
        resolvedGenericOpacity,
        layerParts,
        layerOpacity: normalizedOpacity,
        activeLayerKey,
      })
    ) {
      this.overlayCache = { key: overlayKey, canvas: null };
      return null;
    }
    const overlayCanvas = document.createElement('canvas');
    overlayCanvas.width = canvas.width;
    overlayCanvas.height = canvas.height;
    const overlayCtx = overlayCanvas.getContext('2d');
    overlayCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);

    drawReferenceGuides(
      overlayCtx,
      reference,
      referenceParts,
      referencePartKeys,
      referenceOpacityMap,
      resolvedGenericOpacity,
      xScale,
      yScale,
      ySize,
      layerParts,
      layerOrder,
      activeLayerKey,
      normalizedOpacity
    );

    this.overlayCache = { key: overlayKey, canvas: overlayCanvas };
    return overlayCanvas;
  }

  // RS Add Start: Pulled out of clickwrapper and updated to support new painting system (Lira, September 2025)
  getGridCoord(event) {
    // RS Add End
    // RS Edit Start: Custom marking support (Lira, September 2025)
    const grid =
      Array.isArray(this.gridBuffer) && this.gridBuffer.length
        ? this.gridBuffer
        : this.props.value || [];
    const x_size = grid.length;
    // RS Edit End
    if (!x_size) {
      return null; // RS Edit: Add null (Lira, September 2025)
    }
    const y_size = Array.isArray(grid[0]) ? grid[0].length : 0; // RS Edit: Custom marking support (Lira, September 2025)
    const x_scale = this.canvasRef.current.width / x_size;
    const y_scale = this.canvasRef.current.height / y_size;
    const x = Math.floor(event.offsetX / x_scale) + 1;
    const y = Math.floor(event.offsetY / y_scale) + 1;
    // RS Add Start: Ignore outside of drawable grid (Lira< September 2025)
    if (x < 1 || x > x_size || y < 1 || y > y_size) {
      return null;
    }
    return [x, y];
    // RS Add End
  }

  // RS Add: New clickwrapper event to support new painting system (Lira, September 2025)
  clickwrapper(event) {
    const pos = this.getGridCoord(event);
    if (!pos) return;
    const [x, y] = pos;
    const tool = this.props.tool || 'brush';
    if (tool === 'fill' && this.props.onCanvasFill) {
      this.props.onCanvasFill(x, y);
      return;
    }
    if (tool === 'eyedropper' && this.props.onEyedropper) {
      this.props.onEyedropper(x, y);
    }
  }

  // RS Add: Process the start of a stroke (Lira, September 2025)
  mousedownwrapper(event) {
    const tool = this.props.tool || 'brush';
    const pos = this.getGridCoord(event);
    if (!pos) return;
    if (tool === 'line') {
      this.lineStart = { x: pos[0], y: pos[1] };
      return;
    }
    if (tool === 'brush' || tool === 'eraser') {
      this.strokeSeq = (this.strokeSeq || 0) + 1;
      this.currentStroke = this.strokeSeq;
      this.dragging = true;
      this.lastPos = { x: pos[0], y: pos[1] };
      if (this.props.onCanvasClick) {
        this.props.onCanvasClick(
          this.lastPos.x,
          this.lastPos.y,
          this.props.size || 1,
          this.currentStroke
        );
      }
    }
  }

  // RS Add: Process finishing of current tool action (Lira, September 2025)
  mouseupwrapper(event) {
    const tool = this.props.tool || 'brush';
    if (tool === 'line') {
      if (!this.lineStart) return;
      const pos = this.getGridCoord(event);
      if (!pos) return;
      const x1 = this.lineStart.x;
      const y1 = this.lineStart.y;
      const [x2, y2] = pos;
      this.lineStart = null;
      if (this.props.onCanvasLine) {
        this.props.onCanvasLine(
          x1,
          y1,
          x2,
          y2,
          this.props.size || 1,
          this.currentStroke
        );
      }
      return;
    }
    if (tool === 'brush' || tool === 'eraser') {
      if (this.currentStroke) {
        if (this.props.onCanvasClick) {
          const sid = this.currentStroke;
          this.props.onCanvasClick(0, 0, 0, sid);
        }
        if (this.props.onCommitStroke) {
          this.props.onCommitStroke(this.currentStroke);
        }
      }
      this.dragging = false;
      this.lastPos = null;
      this.currentStroke = null;
    }
  }

  // RS Add: Process movement of mouse (Lira, September 2025)
  mousemovewrapper(event) {
    const tool = this.props.tool || 'brush';
    const pos = this.getGridCoord(event);
    if (!pos) {
      if (tool === 'line') {
        this.setState({ hover: null });
      } else if (tool === 'brush' && this.dragging) {
        // Break the segment without ending the stroke
        this.lastPos = null;
      }
      return;
    }
    if (tool === 'line') {
      this.setState({ hover: pos });
      return;
    }
    if ((tool === 'brush' || tool === 'eraser') && this.dragging) {
      const [x2, y2] = pos;
      if (this.lastPos) {
        if (this.lastPos.x !== x2 || this.lastPos.y !== y2) {
          if (this.props.onCanvasLine) {
            this.props.onCanvasLine(
              this.lastPos.x,
              this.lastPos.y,
              x2,
              y2,
              this.props.size || 1,
              this.currentStroke
            );
          }
          this.lastPos = { x: x2, y: y2 };
        }
      } else {
        // Re-entered canvas while still dragging; no connecting line
        if (this.props.onCanvasClick) {
          this.props.onCanvasClick(
            x2,
            y2,
            this.props.size || 1,
            this.currentStroke
          );
        }
        this.lastPos = { x: x2, y: y2 };
      }
    }
  }

  // RS Add: Handle off-canvas mouseup (Lira, September 2025)
  handleGlobalMouseUp() {
    const tool = this.props.tool || 'brush';
    if (tool === 'line') {
      if (this.lineStart) {
        this.lineStart = null;
        this.setState({ hover: null });
      }
      return;
    }
    if (tool !== 'brush' && tool !== 'eraser') return;
    if (!this.dragging) return;
    if (this.currentStroke) {
      const sid = this.currentStroke;
      if (this.props.onCanvasClick) {
        this.props.onCanvasClick(0, 0, 0, sid);
      }
      if (this.props.onCommitStroke) {
        this.props.onCommitStroke(sid);
      }
    }
    this.dragging = false;
    this.lastPos = null;
    this.currentStroke = null;
  }

  // RS Add: Keyboard handler for Undo (Lira, September 2025)
  handleGlobalKeyDown(event) {
    if (this.props.finalized) return;
    if (!this.props.allowUndoShortcut) return;
    const isMod = event.ctrlKey || event.metaKey;
    if (!isMod) return;
    const key = (event.key || '').toLowerCase();
    if (key !== 'z' || event.shiftKey) return;
    const tag = ((event.target && event.target.tagName) || '').toLowerCase();
    const isForm =
      tag === 'input' ||
      tag === 'textarea' ||
      (event.target && event.target.isContentEditable);
    if (isForm && !this.isInside) return;
    event.preventDefault();
    if (this.dragging) {
      this.handleGlobalMouseUp();
    }
    if (this.props.onUndo) {
      this.props.onUndo();
    }
  }

  render() {
    const {
      res = 1,
      value,
      dotsize = PX_PER_UNIT,
      // RS Add Start: Reference support (Lira, September 2025)
      reference: _reference,
      referenceOpacity: _referenceOpacity,
      // RS Add End
      ...rest
    } = this.props;
    const [width, height] = getImageSize(value);
    return (
      <canvas
        ref={this.canvasRef}
        width={width * dotsize || 300}
        height={height * dotsize || 300}
        {...rest}
        onClick={(e) => this.clickwrapper(e)}
        // RS Add Start: Additional tracking for enhanced painting (Lira, September 2025)
        onMouseDown={(e) => this.mousedownwrapper(e)}
        onMouseUp={(e) => this.mouseupwrapper(e)}
        onMouseMove={(e) => this.mousemovewrapper(e)}
        onMouseEnter={() => {
          this.isInside = true;
        }}
        onMouseLeave={(e) => {
          this.setState({ hover: null });
          // Do not commit the stroke, just break the segment
          this.lastPos = null;
          this.isInside = false;
          // RS Add End
        }}>
        Canvas failed to render.
      </canvas>
    );
  }
}

const getImageSize = (value) => {
  const width = value.length;
  const height = width !== 0 ? value[0].length : 0;
  return [width, height];
};

// RS Add: Utility to keep reference opacity inputs within sane bounds (Lira, September 2025)
const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

export const Canvas = (props, context) => {
  const { act, data } = useBackend(context);
  const dotsize = PX_PER_UNIT;
  const [width, height] = getImageSize(data.grid);
  // RS Add Start: Updated for new painting system (Lira, September 2025)
  const limited = !!data.limited;
  const [tool, setTool] = useLocalState(context, 'tool', 'brush');
  const [blendMode, setBlendMode] = useLocalState(
    context,
    'blendMode',
    'analog'
  );
  const [analogStrength, setAnalogStrength] = useLocalState(
    context,
    'analogStrength',
    1
  );
  const activeLayer = data.active_layer || 1;
  const [size, setSize] = useLocalState(context, 'size', 1);
  const brushColor = data.brush_color || null;
  const canSetBrush = data.can_set_brush_color;
  const previewColor = brushColor || data.held_color || '#000000';
  const capW = 760;
  const capH = 900;
  const uiExtra = data.finalized ? 70 : limited ? 140 : 140;
  // RS Add End
  return (
    <Window
      resizable // RS Add: Window size tweaks (Lira, September 2025)
      // RS Edit Start: Window size tweaks (Lira, September 2025)
      width={Math.min(capW, width * dotsize + 72)}
      height={Math.min(capH, height * dotsize + uiExtra)}>
      {/* RS Edit End */}
      <Window.Content>
        <Box textAlign="center">
          {/* RS Add Start: New paint window layout (Lira, September 2025) */}
          {!data.finalized && (
            <Box mb={1}>
              <Button
                icon="paint-brush"
                selected={tool === 'brush'}
                onClick={() => setTool('brush')}>
                Brush
              </Button>
              {!limited && (
                <Button
                  icon="eraser"
                  selected={tool === 'eraser'}
                  onClick={() => setTool('eraser')}>
                  Eraser
                </Button>
              )}
              <Button
                icon="slash"
                selected={tool === 'line'}
                onClick={() => setTool('line')}>
                Line
              </Button>
              <Button
                icon="fill-drip"
                selected={tool === 'fill'}
                onClick={() => setTool('fill')}>
                Fill
              </Button>
              <Button
                icon="eye-dropper"
                selected={tool === 'eyedropper'}
                onClick={() => setTool('eyedropper')}>
                Eyedropper
              </Button>
              {!limited && (
                <Box
                  inline
                  ml={2}
                  style={{ display: 'inline-flex', alignItems: 'center' }}>
                  <Tooltip
                    content={
                      <div>
                        <div>
                          <b>Classic:</b> Blend selected color onto canvas
                          color, averaging between them.
                        </div>
                        <br />
                        <div>
                          <b>Lighten:</b> Lightens through matrix addition
                          between selected and canvas color.
                        </div>
                        <br />
                        <div>
                          <b>Darken:</b> Darkens through matrix multiplication
                          between selected and canvas color.
                        </div>
                      </div>
                    }>
                    <Box inline mr={1} color="label">
                      Mode:
                    </Box>
                  </Tooltip>
                  <Button
                    mb={0}
                    selected={blendMode === 'analog'}
                    onClick={() => setBlendMode('analog')}>
                    Classic
                  </Button>
                  <Button
                    mb={0}
                    selected={blendMode === 'add'}
                    onClick={() => setBlendMode('add')}>
                    Lighten
                  </Button>
                  <Button
                    mb={0}
                    selected={blendMode === 'multiply'}
                    onClick={() => setBlendMode('multiply')}>
                    Darken
                  </Button>
                </Box>
              )}
              <Box
                inline
                ml={2}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                }}>
                <Tooltip
                  content={
                    'Weight of selected color relative to canvas color.'
                  }>
                  <Box inline mr={1} color="label">
                    Strength:
                  </Box>
                </Tooltip>
                <NumberInput
                  minValue={1}
                  maxValue={100}
                  step={1}
                  value={Math.round(analogStrength * 100)}
                  unit="%"
                  width={6}
                  onChange={(e, value) => setAnalogStrength(value / 100)}
                />
              </Box>
              {!limited && (
                <>
                  <Button
                    ml={2}
                    disabled={!data.can_undo}
                    tooltip="Ctrl+Z can also be used."
                    onClick={() => act('undo')}>
                    Undo
                  </Button>
                  <Button
                    ml={1}
                    tooltip="Clear the entire canvas."
                    onClick={() => act('clear_confirm')}>
                    Clear
                  </Button>
                  <Box
                    inline
                    ml={2}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}>
                    <Box inline mr={1} color="label">
                      Layers:
                    </Box>
                    <Button
                      selected={activeLayer === 1}
                      onClick={() => act('set_layer', { layer: 1 })}>
                      1
                    </Button>
                    <Button
                      icon={data.layer_visible?.[0] ? 'eye' : 'eye-slash'}
                      selected={!!data.layer_visible?.[0]}
                      content=""
                      compact
                      circular
                      tooltip="Toggle visibility of layer 1"
                      onClick={() =>
                        act('set_layer_visible', {
                          layer: 1,
                          visible: !data.layer_visible?.[0],
                        })
                      }
                    />
                    <Button
                      selected={activeLayer === 2}
                      onClick={() => act('set_layer', { layer: 2 })}>
                      2
                    </Button>
                    <Button
                      icon={data.layer_visible?.[1] ? 'eye' : 'eye-slash'}
                      selected={!!data.layer_visible?.[1]}
                      content=""
                      compact
                      circular
                      tooltip="Toggle visibility of layer 2"
                      onClick={() =>
                        act('set_layer_visible', {
                          layer: 2,
                          visible: !data.layer_visible?.[1],
                        })
                      }
                    />
                    <Button
                      selected={activeLayer === 3}
                      onClick={() => act('set_layer', { layer: 3 })}>
                      3
                    </Button>
                    <Button
                      icon={data.layer_visible?.[2] ? 'eye' : 'eye-slash'}
                      selected={!!data.layer_visible?.[2]}
                      content=""
                      compact
                      circular
                      tooltip="Toggle visibility of layer 3"
                      onClick={() =>
                        act('set_layer_visible', {
                          layer: 3,
                          visible: !data.layer_visible?.[2],
                        })
                      }
                    />
                  </Box>
                </>
              )}
              <Box
                inline
                ml={2}
                style={{ display: 'inline-flex', alignItems: 'center' }}>
                <Box inline mr={1} color="label">
                  Thickness:
                </Box>
                <Button mb={0} selected={size === 1} onClick={() => setSize(1)}>
                  1
                </Button>
                <Button mb={0} selected={size === 2} onClick={() => setSize(2)}>
                  2
                </Button>
                <Button mb={0} selected={size === 3} onClick={() => setSize(3)}>
                  3
                </Button>
                <Button mb={0} selected={size === 4} onClick={() => setSize(4)}>
                  4
                </Button>
                <Button mb={0} selected={size === 5} onClick={() => setSize(5)}>
                  5
                </Button>
              </Box>
              <Box
                inline
                ml={2}
                style={{ display: 'inline-flex', alignItems: 'center' }}>
                <Box
                  inline
                  style={{
                    width: '16px',
                    height: '16px',
                    display: 'inline-block',
                    background: previewColor,
                    border: '1px solid #555',
                  }}
                />
                <Button
                  ml={1}
                  disabled={!canSetBrush}
                  onClick={() => act('pick_color_dialog')}>
                  Pick Color…
                </Button>
              </Box>
            </Box>
          )}
          {/* RS Add End */}
          <PaintCanvas
            value={data.grid}
            dotsize={dotsize}
            // RS Add Start: Updated for paint enhancements (Lira, September 2025)
            tool={data.finalized ? 'none' : tool}
            size={size}
            previewColor={previewColor}
            finalized={data.finalized}
            allowUndoShortcut={!limited}
            onUndo={() => act('undo')}
            onCanvasClick={(x, y, s, sid) =>
              act('paint', {
                x,
                y,
                size: s,
                blend:
                  tool === 'eraser' ? 'erase' : limited ? 'analog' : blendMode,
                stroke: sid,
                strength: analogStrength,
              })
            }
            onCanvasLine={(x1, y1, x2, y2, s, sid) =>
              act('line', {
                x1,
                y1,
                x2,
                y2,
                size: s,
                blend:
                  tool === 'eraser' ? 'erase' : limited ? 'analog' : blendMode,
                stroke: sid,
                strength: analogStrength,
              })
            }
            onCommitStroke={(sid) => act('commit_stroke', { stroke: sid })}
            onCanvasFill={(x, y) =>
              act('fill', {
                x,
                y,
                blend: limited ? 'analog' : blendMode,
                strength: analogStrength,
              })
            }
            onEyedropper={(x, y) => act('eyedropper', { x, y })}
            // RS Add End
          />
          <Box>
            {!data.finalized &&
              !!data.can_finalize && ( // RS Edit: Adjusted for paint enhancements (Lira, September 2025)
                <Button.Confirm
                  onClick={() => act('finalize')}
                  content="Finalize"
                />
              )}
            {/* RS Edit: Adjusted for paint enhancements (Lira, September 2025) */}
            {data.finalized ? data.name : null}{' '}
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};

// RS Add Start: Helpers for preview rendering (Lira, September 2025)
const toHexWithAlpha = (hex, alpha2) => {
  if (!hex || typeof hex !== 'string') return '#00000080';
  if (hex.length === 7) {
    return hex + alpha2; // #RRGGBB -> #RRGGBBAA
  }
  return hex;
};

const drawBrush = (ctx, x, y, size) => {
  const r = Math.floor((size - 1) / 2);
  const startX = x - r;
  const startY = y - r;
  ctx.fillRect(startX, startY, size, size);
};

const drawLinePixels = (x1, y1, x2, y2, plot) => {
  let dx = Math.abs(x2 - x1);
  let dy = Math.abs(y2 - y1);
  const sx = x1 < x2 ? 1 : -1;
  const sy = y1 < y2 ? 1 : -1;
  let err = dx - dy;
  let cx = x1;
  let cy = y1;
  while (true) {
    plot(cx, cy);
    if (cx === x2 && cy === y2) break;
    const e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      cx += sx;
    }
    if (e2 < dx) {
      err += dx;
      cy += sy;
    }
  }
};
// RS Add End

// RS Add Start: Custom marking support (Lira, September 2025)
const resolveGenericOpacity = (opacityMap, fallback) => {
  if (opacityMap && opacityMap.generic !== undefined) {
    return clamp(opacityMap.generic, 0, 1);
  }
  return fallback;
};
const buildLayerOrder = (prioritizedOrder, referenceKeys, layerParts) => {
  const order = [];
  const seen = new Set();
  const push = (key) => {
    if (!key || seen.has(key)) {
      return;
    }
    seen.add(key);
    order.push(key);
  };

  push('generic');
  if (Array.isArray(prioritizedOrder)) {
    for (const key of prioritizedOrder) {
      push(key);
    }
  }
  if (Array.isArray(referenceKeys)) {
    for (const key of referenceKeys) {
      push(key);
    }
  }
  if (layerParts) {
    for (const key of Object.keys(layerParts)) {
      push(key);
    }
  }
  return order;
};

const serializeOpacityMap = (opacityMap) => {
  if (!opacityMap) {
    return '';
  }
  const keys = Object.keys(opacityMap).sort();
  return keys.map((key) => `${key}:${opacityMap[key]}`).join(',');
};

const shouldRenderOverlay = ({
  reference,
  referenceParts,
  referenceOpacityMap,
  resolvedGenericOpacity,
  layerParts,
  layerOpacity,
  activeLayerKey,
}) => {
  if (reference && resolvedGenericOpacity > 0) {
    return true;
  }
  if (referenceParts) {
    for (const key of Object.keys(referenceParts)) {
      const grid = referenceParts[key];
      if (!grid || !grid.length) {
        continue;
      }
      let opacity = resolvedGenericOpacity;
      if (referenceOpacityMap && referenceOpacityMap[key] !== undefined) {
        opacity = clamp(referenceOpacityMap[key], 0, 1);
      }
      if (opacity > 0) {
        return true;
      }
    }
  }
  if (!layerParts || layerOpacity <= 0) {
    return false;
  }
  const keys = Object.keys(layerParts);
  for (const key of keys) {
    if (key === activeLayerKey) {
      continue;
    }
    const grid = layerParts[key];
    if (grid && grid.length) {
      return true;
    }
  }
  return false;
};

const drawGridLayer = (ctx, grid, yLimit) => {
  if (!grid) {
    return;
  }
  for (let x = 0; x < grid.length; x++) {
    const column = grid[x];
    if (!column) continue;
    const limit = Math.min(column.length, yLimit);
    for (let y = 0; y < limit; y++) {
      const color = column[y];
      if (!color) continue;
      ctx.fillStyle = color;
      ctx.fillRect(x, y, 1, 1);
    }
  }
};

const drawReferenceGuides = (
  ctx,
  reference,
  referenceParts,
  referencePartKeys,
  opacityMap,
  resolvedGenericOpacity,
  xScale,
  yScale,
  yLimit,
  layerParts,
  layerOrder,
  activeLayerKey,
  layerOpacity
) => {
  const orderedKeys = buildLayerOrder(
    layerOrder,
    referencePartKeys,
    layerParts
  );
  if (!orderedKeys.length && !referenceParts && !reference && !layerParts) {
    return;
  }

  ctx.save();
  ctx.scale(xScale, yScale);
  ctx.imageSmoothingEnabled = false;

  for (const key of orderedKeys) {
    const refGrid = referenceParts
      ? key === 'generic'
        ? referenceParts.generic
        : referenceParts[key]
      : null;
    if (refGrid) {
      const opacity =
        opacityMap && opacityMap[key] !== undefined
          ? clamp(opacityMap[key], 0, 1)
          : resolvedGenericOpacity;
      if (opacity > 0) {
        ctx.globalAlpha = opacity;
        drawGridLayer(ctx, refGrid, yLimit);
      }
    } else if (key === 'generic' && reference && reference.length) {
      ctx.globalAlpha = resolvedGenericOpacity;
      drawGridLayer(ctx, reference, yLimit);
    }

    if (
      layerParts &&
      key !== activeLayerKey &&
      layerOpacity > 0 &&
      layerParts[key]
    ) {
      ctx.globalAlpha = layerOpacity;
      drawGridLayer(ctx, layerParts[key], yLimit);
    }
  }

  if (
    (!orderedKeys.length || orderedKeys[0] !== 'generic') &&
    reference &&
    reference.length &&
    (!layerParts || layerOpacity <= 0)
  ) {
    ctx.globalAlpha = resolvedGenericOpacity;
    drawGridLayer(ctx, reference, yLimit);
  }

  ctx.restore();
};
// RS Add End
