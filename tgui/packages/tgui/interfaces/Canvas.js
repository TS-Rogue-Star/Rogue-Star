// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2025 to make painting more authentic and add a new drawing tablet with a variety of advanced functions //
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025 to support Custom Marking Designer Interface ////////////////////////////////////////////////////////
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component, createRef } from 'inferno';
import { useBackend, useLocalState } from '../backend'; // RS Edit: Add useLocalState (Lira, September 2025)
import { Box, Button, NumberInput, Tooltip } from '../components'; // RS Edit: Add NumberInput and Tooltip (Lira, September 2025)
import { Window } from '../layouts';

// RS Add Start: Dynamic tool cursor rendering for painting UI (Lira, November 2025)
const PX_PER_UNIT = 24;
const DEFAULT_CURSOR = 'crosshair';
const FONT_AWESOME_CURSOR_FONT = '"Font Awesome 6 Free","FontAwesome"';
const CURSOR_UPDATE_EVENT = 'custom_marking_cursor_update';

const TOOL_CURSOR_SPECS = {
  brush: {
    codePoint: 0xf1fc,
    size: 24,
    hotX: 6,
    hotY: 20,
  },
  'mirror-brush': {
    codePoint: 0xf07e,
    size: 24,
    hotX: 2,
    hotY: 12,
  },
  eraser: {
    codePoint: 0xf12d,
    size: 24,
    hotX: 7,
    hotY: 22,
    fontSize: 19,
  },
  line: {
    codePoint: 0xf715,
    size: 24,
    hotX: 12,
    hotY: 12,
    fontSize: 20,
  },
  fill: {
    codePoint: 0xf576,
    size: 100,
    hotX: 58,
    hotY: 58,
    fontSize: 18,
  },
  eyedropper: {
    codePoint: 0xf1fb,
    size: 24,
    hotX: 4,
    hotY: 18,
    fontSize: 18,
  },
};
const TOOL_CURSOR_CACHE = {};
const CANVAS_CURSOR_SIZE = 100;
const PENDING_FONT_LOADS = {};
const dispatchCursorUpdate = () => {
  if (
    typeof window === 'undefined' ||
    typeof window.dispatchEvent !== 'function'
  ) {
    return;
  }
  const evt =
    typeof CustomEvent === 'function'
      ? new CustomEvent(CURSOR_UPDATE_EVENT)
      : new Event(CURSOR_UPDATE_EVENT);
  window.dispatchEvent(evt);
};

const buildCursorValue = (tool, spec, skipFontCheck = false) => {
  if (
    typeof document === 'undefined' ||
    typeof document.createElement !== 'function'
  ) {
    return DEFAULT_CURSOR;
  }
  const canvas = document.createElement('canvas');
  if (!canvas) {
    return DEFAULT_CURSOR;
  }
  const size = spec.size || CANVAS_CURSOR_SIZE;
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    return DEFAULT_CURSOR;
  }
  ctx.clearRect(0, 0, size, size);
  const fontSize = spec.fontSize || size * 0.75;
  const fontWeight = spec.fontWeight || 900;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';
  const fontSpec = `${fontWeight} ${fontSize}px ${FONT_AWESOME_CURSOR_FONT}`;
  const glyph =
    spec.glyph ||
    (spec.codePoint !== undefined
      ? String.fromCodePoint(spec.codePoint)
      : null);
  if (!glyph) {
    return DEFAULT_CURSOR;
  }
  if (!skipFontCheck) {
    const fontSetAvailable =
      typeof document !== 'undefined' &&
      document.fonts &&
      typeof document.fonts.check === 'function';
    const loadAvailable =
      fontSetAvailable && typeof document.fonts.load === 'function';
    if (fontSetAvailable) {
      const fontReady = document.fonts.check(fontSpec, glyph);
      if (!fontReady) {
        if (!PENDING_FONT_LOADS[tool] && loadAvailable) {
          PENDING_FONT_LOADS[tool] = true;
          document.fonts
            .load(fontSpec, glyph)
            .then(() => {
              PENDING_FONT_LOADS[tool] = false;
              const refreshed = buildCursorValue(tool, spec, true);
              if (refreshed && refreshed !== DEFAULT_CURSOR) {
                TOOL_CURSOR_CACHE[tool] = refreshed;
                dispatchCursorUpdate();
              }
            })
            .catch(() => {
              PENDING_FONT_LOADS[tool] = false;
            });
        } else if (!loadAvailable && !PENDING_FONT_LOADS[tool]) {
          PENDING_FONT_LOADS[tool] = true;
          setTimeout(() => {
            PENDING_FONT_LOADS[tool] = false;
            const refreshed = buildCursorValue(tool, spec, true);
            if (refreshed && refreshed !== DEFAULT_CURSOR) {
              TOOL_CURSOR_CACHE[tool] = refreshed;
              dispatchCursorUpdate();
            }
          }, 150);
        }
        return DEFAULT_CURSOR;
      }
    } else if (!PENDING_FONT_LOADS[tool]) {
      PENDING_FONT_LOADS[tool] = true;
      setTimeout(() => {
        PENDING_FONT_LOADS[tool] = false;
        const refreshed = buildCursorValue(tool, spec, true);
        if (refreshed && refreshed !== DEFAULT_CURSOR) {
          TOOL_CURSOR_CACHE[tool] = refreshed;
          dispatchCursorUpdate();
        }
      }, 150);
      return DEFAULT_CURSOR;
    }
  }
  ctx.save();
  if (spec.flipX) {
    ctx.translate(size, 0);
    ctx.scale(-1, 1);
  }
  ctx.font = fontSpec;
  ctx.lineWidth = spec.strokeWidth || Math.max(1, fontSize * 0.08);
  ctx.strokeStyle = spec.stroke || 'rgba(5, 5, 5, 0.9)';
  ctx.fillStyle = spec.fill || '#ffffff';
  const glyphMetrics = ctx.measureText(glyph);
  const glyphWidth =
    (glyphMetrics && glyphMetrics.width) || Math.max(1, fontSize);
  const halfGlyphWidth = glyphWidth / 2;
  const margin = 2;
  let centerX = size / 2 + (spec.glyphOffsetX || 0);
  const minCenterX = margin + halfGlyphWidth;
  const maxCenterX = size - margin - halfGlyphWidth;
  if (maxCenterX > minCenterX) {
    centerX = Math.min(Math.max(centerX, minCenterX), maxCenterX);
  }
  const glyphAscent =
    (glyphMetrics && glyphMetrics.actualBoundingBoxAscent) || fontSize * 0.7;
  const glyphDescent =
    (glyphMetrics && glyphMetrics.actualBoundingBoxDescent) || fontSize * 0.3;
  const halfGlyphHeight = (glyphAscent + glyphDescent) / 2;
  let centerY = size / 2 + (spec.glyphOffsetY || 0);
  const minCenterY = margin + halfGlyphHeight;
  const maxCenterY = size - margin - halfGlyphHeight;
  if (maxCenterY > minCenterY) {
    centerY = Math.min(Math.max(centerY, minCenterY), maxCenterY);
  }
  ctx.strokeText(glyph, centerX, centerY);
  ctx.fillText(glyph, centerX, centerY);
  ctx.restore();
  const hotX = spec.hotX ?? Math.floor(size / 2);
  const hotY = spec.hotY ?? Math.floor(size / 2);
  const markerOuterRadius = Math.max(1.5, (spec.markerRadius || 2) + 0.5);
  const markerInnerRadius = Math.max(1, (spec.markerRadius || 2) - 0.5);
  ctx.beginPath();
  ctx.arc(hotX, hotY, markerOuterRadius, 0, Math.PI * 2, false);
  ctx.strokeStyle = 'rgba(0, 0, 0, 0.95)';
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(hotX, hotY, markerInnerRadius, 0, Math.PI * 2, false);
  ctx.fillStyle = 'rgba(244, 201, 111, 0.98)';
  ctx.fill();
  const dataUrl = canvas.toDataURL('image/png');
  return `url(${dataUrl}) ${hotX} ${hotY}, crosshair`;
};

const getCursorForTool = (tool) => {
  if (TOOL_CURSOR_CACHE[tool]) {
    return TOOL_CURSOR_CACHE[tool];
  }
  const spec = TOOL_CURSOR_SPECS[tool];
  if (!spec) {
    return DEFAULT_CURSOR;
  }
  const cursor = buildCursorValue(tool, spec);
  if (cursor !== DEFAULT_CURSOR) {
    TOOL_CURSOR_CACHE[tool] = cursor;
  }
  return cursor;
};

// RS Add End

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
    this.currentStrokeTool = null;
    this.currentStrokeButton = null;
    this.pendingStrokeSegments = 0;
    this.overlayCache = null;
    this.gridBuffer = this.cloneGrid(props.value || []);
    this.lastDiffSeq = props.diffSeq || 0;
    this.seedStrokeSequence(props);
    this.handleGlobalMouseUp = this.handleGlobalMouseUp.bind(this);
    this.handleGlobalKeyDown = this.handleGlobalKeyDown.bind(this);
    this.handleCursorUpdate = this.handleCursorUpdate.bind(this);
    this.isInside = false;
    this.cursorReady = false;
    this.backgroundImageCache = null; // RS Add: Cache decoded background image (Nov 2025)
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
    window.addEventListener(CURSOR_UPDATE_EVENT, this.handleCursorUpdate);
    // RS Add End

    // RS Add: Delay cursor initialization slightly to ensure fonts are loaded (Lira, November 2025)
    setTimeout(() => {
      this.cursorReady = true;
      this.forceUpdate();
    }, 150);
  }

  componentDidUpdate(prevProps, prevState) {
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
    const hasDiffPayload =
      Array.isArray(this.props.diff) && this.props.diff.length;
    if (
      incomingDiffSeq !== undefined &&
      incomingDiffSeq !== null &&
      incomingDiffSeq !== this.lastDiffSeq &&
      hasDiffPayload
    ) {
      if (!Array.isArray(this.gridBuffer) || !this.gridBuffer.length) {
        this.gridBuffer = this.cloneGrid(
          this.props.value || prevProps.value || []
        );
      }
      this.applyDiff(this.props.diff);
      this.lastDiffSeq = incomingDiffSeq;
      shouldRedraw = true;
      if (this.props.onDiffApplied) {
        this.props.onDiffApplied(this.props.diffStroke);
      }
    } else if (
      incomingDiffSeq !== undefined &&
      incomingDiffSeq !== null &&
      incomingDiffSeq !== this.lastDiffSeq
    ) {
      this.lastDiffSeq = incomingDiffSeq;
      if (this.props.onDiffApplied) {
        this.props.onDiffApplied(this.props.diffStroke);
      }
    }

    if (prevProps.dotsize !== this.props.dotsize) {
      shouldRedraw = true;
    }

    const hoverChanged = !!prevState && prevState.hover !== this.state.hover;

    if (
      shouldRedraw ||
      hoverChanged ||
      prevProps.reference !== this.props.reference ||
      prevProps.referenceParts !== this.props.referenceParts ||
      prevProps.referenceOpacity !== this.props.referenceOpacity ||
      prevProps.referenceOpacityMap !== this.props.referenceOpacityMap ||
      prevProps.layerParts !== this.props.layerParts ||
      prevProps.layerRevision !== this.props.layerRevision ||
      prevProps.otherLayerOpacity !== this.props.otherLayerOpacity ||
      prevProps.legacyGridGuideSize !== this.props.legacyGridGuideSize ||
      prevProps.tool !== this.props.tool ||
      prevProps.size !== this.props.size ||
      prevProps.previewColor !== this.props.previewColor ||
      prevProps.strokeDrafts !== this.props.strokeDrafts ||
      prevProps.strokeDraftSession !== this.props.strokeDraftSession
    ) {
      // RS Add End
      this.drawCanvas(this.props);
    }
    // RS Add Start: Custom marking support (Lira, November 2025)
    if (
      prevProps.strokeDrafts !== this.props.strokeDrafts ||
      prevProps.strokeDraftSession !== this.props.strokeDraftSession
    ) {
      const sessionChanged =
        prevProps.strokeDraftSession !== this.props.strokeDraftSession;
      this.seedStrokeSequence(this.props, !sessionChanged);
    }

    if (prevProps.strokeJoinLimit !== this.props.strokeJoinLimit) {
      this.handleStrokeJoinLimitChange();
    }

    const prevTool = prevProps.tool || 'brush';
    const nextTool = this.props.tool || 'brush';
    if (this.isBrushTool(prevTool) && !this.isBrushTool(nextTool)) {
      this.flushPendingStroke();
    }

    if (prevProps.flushToken !== this.props.flushToken) {
      this.flushPendingStroke();
    }
    // RS Add End
  }

  // RS Add: Remove event listeners on unmount (Lira, September 2025)
  componentWillUnmount() {
    window.removeEventListener('mouseup', this.handleGlobalMouseUp);
    window.removeEventListener('blur', this.handleGlobalMouseUp);
    window.removeEventListener('keydown', this.handleGlobalKeyDown);
    window.removeEventListener(CURSOR_UPDATE_EVENT, this.handleCursorUpdate);
    this.flushPendingStroke();
  }

  // RS Add Start: Helpers for batching brush strokes and enforcing join limits (Lira, November 2025)
  isBrushTool(tool) {
    const normalized = tool || 'brush';
    return (
      normalized === 'brush' ||
      normalized === 'mirror-brush' ||
      normalized === 'eraser' ||
      normalized === 'line'
    );
  }

  getStrokeJoinLimit() {
    const raw = Number(this.props.strokeJoinLimit);
    if (!Number.isFinite(raw) || raw <= 0) {
      return 0;
    }
    return Math.floor(raw);
  }

  ensureStrokeId() {
    if (this.currentStroke) {
      return this.currentStroke;
    }
    this.strokeSeq = (this.strokeSeq || 0) + 1;
    this.currentStroke = this.strokeSeq;
    this.pendingStrokeSegments = 0;
    return this.currentStroke;
  }

  handleStrokeSegmentComplete(forceCommit = false) {
    if (!this.currentStroke) {
      return;
    }
    this.pendingStrokeSegments = (this.pendingStrokeSegments || 0) + 1;
    const joinLimit = this.getStrokeJoinLimit();
    if (forceCommit) {
      this.commitCurrentStroke();
      return;
    }
    if (joinLimit > 0 && this.pendingStrokeSegments >= joinLimit) {
      this.commitCurrentStroke();
    }
  }

  commitCurrentStroke() {
    if (!this.currentStroke) {
      return;
    }
    if (this.props.onCommitStroke) {
      this.props.onCommitStroke(this.currentStroke);
    }
    this.currentStroke = null;
    this.pendingStrokeSegments = 0;
  }

  flushPendingStroke() {
    if (this.dragging && this.currentStroke) {
      if (this.props.onCanvasClick) {
        this.props.onCanvasClick(0, 0, 0, this.currentStroke);
      }
      this.dragging = false;
      this.lastPos = null;
      this.handleStrokeSegmentComplete(true);
    }
    if (this.currentStroke) {
      this.commitCurrentStroke();
    }
  }

  handleStrokeJoinLimitChange() {
    if (!this.currentStroke) {
      return;
    }
    const joinLimit = this.getStrokeJoinLimit();
    if (joinLimit > 0 && this.pendingStrokeSegments >= joinLimit) {
      this.commitCurrentStroke();
    }
    // RS Add End
  }

  // RS Add: Stroke management (Lira, November 2025)
  seedStrokeSequence(props, allowRaiseOnly = false) {
    const sessionKey = props && props.strokeDraftSession;
    const drafts = props && props.strokeDrafts;
    if (!sessionKey || !drafts) {
      return;
    }
    let maxSeq = 0;
    for (const entry of Object.values(drafts)) {
      if (!entry || entry.session !== sessionKey) {
        continue;
      }
      const strokeVal = Number(entry.stroke);
      const seqVal = Number(entry.sequence);
      const candidate = Number.isFinite(strokeVal)
        ? strokeVal
        : Number.isFinite(seqVal)
          ? seqVal
          : 0;
      if (candidate > maxSeq) {
        maxSeq = candidate;
      }
    }
    if (allowRaiseOnly) {
      this.strokeSeq = Math.max(this.strokeSeq || 0, maxSeq);
    } else {
      this.strokeSeq = maxSeq;
    }
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
    // RS Add Start: Custom markings support (Lira, November 2025)
    const bgColor = propSource.backgroundColor || 'rgba(0,0,0,0)';
    const bgImageSrc = propSource.backgroundImage || null;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    // RS Add End
    const grid =
      Array.isArray(this.gridBuffer) && this.gridBuffer.length
        ? this.gridBuffer
        : propSource.value || []; // RS Edit: Custom marking support (Lira, September 2025)

    // RS Add Start: Custom markings support (Lira, November 2025)
    const renderNudgePxX = 0;
    const renderNudgePxY = 0;
    // RS Add End
    // RS Add Start: Resolve part overlays so each slot can supply custom guidance art (Lira, September 2025)
    const reference = propSource.reference || null;
    const referenceParts = propSource.referenceParts || null;
    const layerParts = propSource.layerParts || null;
    const layerOrder = propSource.layerOrder || null;
    const activeLayerKey = propSource.activeLayerKey || null;
    const otherLayerOpacity = propSource.otherLayerOpacity;
    const referenceOpacityMap = propSource.referenceOpacityMap || null;
    const referencePartKeys = referenceParts ? Object.keys(referenceParts) : [];
    const fallbackReference = resolveFallbackReference(
      referenceParts,
      referencePartKeys,
      reference
    );
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
    // RS Add End

    ctx.save();
    ctx.scale(x_scale, y_scale);
    // RS Add Start: Custom markings support (Lira, November 2025)
    if (renderNudgePxX || renderNudgePxY) {
      const tx = x_scale ? renderNudgePxX / x_scale : 0;
      const ty = y_scale ? renderNudgePxY / y_scale : 0;
      if (tx || ty) {
        ctx.translate(tx, ty);
      }
    }
    // RS Add End
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

    // RS Add Start: Custom marking support (Lira, November 2025)
    this.renderStrokeDrafts(ctx, propSource, x_size, y_size);
    this.renderLinePreview(ctx);
    ctx.restore();
    if (overlayCanvas) {
      ctx.save();
      if (renderNudgePxX || renderNudgePxY) {
        ctx.translate(renderNudgePxX, renderNudgePxY);
      }
      ctx.save();
      ctx.globalCompositeOperation = 'destination-over';
      ctx.drawImage(overlayCanvas, 0, 0);
      ctx.restore();
      ctx.restore();
    }
    ctx.save();
    if (renderNudgePxX || renderNudgePxY) {
      ctx.translate(renderNudgePxX, renderNudgePxY);
    }
    this.renderLegacyGridGuide(
      ctx,
      propSource,
      x_scale,
      y_scale,
      x_size,
      y_size
    );
    ctx.restore();
    ctx.save();
    ctx.globalCompositeOperation = 'destination-over';
    if (bgImageSrc) {
      const img = this.ensureBackgroundImage(bgImageSrc, () => {
        this.drawCanvas(propSource);
      });
      if (img && img.complete && img.naturalWidth > 0) {
        const pattern = ctx.createPattern(img, 'repeat');
        if (pattern) {
          ctx.fillStyle = pattern;
          ctx.fillRect(0, 0, canvas.width, canvas.height);
        }
      } else {
        ctx.fillStyle = bgColor;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
      }
    } else {
      ctx.fillStyle = bgColor;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }
    ctx.restore();
    // RS Add End
  }

  // RS Add: Custom markings support (Lira, November 2025)
  ensureBackgroundImage(src, onLoad) {
    if (!src) {
      this.backgroundImageCache = null;
      return null;
    }
    const cached = this.backgroundImageCache;
    if (cached && cached.src === src && cached.image) {
      return cached.image;
    }
    const image = new Image();
    image.onload = () => {
      if (this.backgroundImageCache?.src !== src) {
        this.backgroundImageCache = { src, image };
      }
      if (typeof onLoad === 'function') {
        onLoad();
      }
    };
    image.onerror = () => {
      this.backgroundImageCache = null;
    };
    image.src = src;
    this.backgroundImageCache = { src, image };
    return image;
  }

  // RS Add: Render uncommitted draft pixels for multi-segment strokes (Lira, November 2025)
  renderStrokeDrafts(ctx, propSource, xSize, ySize) {
    const strokeDrafts = extractDraftPixels(
      propSource.strokeDrafts,
      propSource.strokeDraftSession
    );
    if (!strokeDrafts.length) {
      return;
    }
    for (const draftPixel of strokeDrafts) {
      if (!draftPixel) continue;
      const px = (draftPixel.x || 0) - 1;
      const py = (draftPixel.y || 0) - 1;
      if (px < 0 || py < 0 || px >= xSize || py >= ySize) {
        continue;
      }
      const colorValue = draftPixel.color;
      if (!colorValue || colorValue === '#00000000') {
        ctx.clearRect(px, py, 1, 1);
        continue;
      }
      ctx.fillStyle = colorValue;
      ctx.fillRect(px, py, 1, 1);
    }
  }

  // RS Add: Separate line preview rendering for clarity (Lira, November 2025)
  renderLinePreview(ctx) {
    if (this.props.finalized) {
      return;
    }
    const tool = this.currentStrokeTool || this.props.tool || 'brush';
    if (tool !== 'line' || !this.lineStart || !this.state.hover) {
      return;
    }
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

  // RS Add: Custom markings support (Lira, November 2025)
  renderLegacyGridGuide(ctx, propSource, xScale, yScale, xSize, ySize) {
    const guideSize = Number(propSource.legacyGridGuideSize);
    if (!Number.isFinite(guideSize) || guideSize <= 0) {
      return;
    }
    if (xSize < guideSize || ySize < guideSize) {
      return;
    }
    const guideWidth = Math.min(guideSize, xSize);
    const guideHeight = Math.min(guideSize, ySize);
    const startX = Math.floor((xSize - guideWidth) / 2) * xScale;
    const startY = (ySize - guideHeight) * yScale; // Bottom-center anchor
    const guideWidthPx = guideWidth * xScale;
    const guideHeightPx = guideHeight * yScale;
    if (guideWidthPx <= 1 || guideHeightPx <= 1) {
      return;
    }
    const strokeX = startX + 0.5;
    const strokeY = startY + 0.5;
    const strokeW = guideWidthPx - 1;
    const strokeH = guideHeightPx - 1;
    const dashLength = Math.max(4, Math.round(Math.min(xScale, yScale) / 2));
    ctx.save();
    ctx.lineWidth = 1;
    ctx.strokeStyle = 'rgba(0, 0, 0, 0.45)';
    ctx.strokeRect(strokeX, strokeY, strokeW, strokeH);
    ctx.setLineDash([dashLength, dashLength]);
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.7)';
    ctx.strokeRect(strokeX, strokeY, strokeW, strokeH);
    ctx.restore();
  }

  // RS Add: Custom marking support (Lira, September 2025)
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
      Math.round(xScale * 1000) / 1000,
      Math.round(yScale * 1000) / 1000,
      ySize,
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
    // RS Edit Start: Custom markings support (Lira, November 2025)
    const rect = this.canvasRef.current.getBoundingClientRect();
    const x_scale = rect.width / x_size;
    const y_scale = rect.height / y_size;
    if (!x_scale || !y_scale) {
      return null;
    }
    const x = Math.floor((event.clientX - rect.left) / x_scale) + 1;
    const y = Math.floor((event.clientY - rect.top) / y_scale) + 1;
    // RS Edit End
    // RS Add Start: Ignore outside of drawable grid (Lira< September 2025)
    if (x < 1 || x > x_size || y < 1 || y > y_size) {
      return null;
    }
    return [x, y];
    // RS Add End
  }

  // RS Add: Custom markings support (Lira, November 2025)
  resolveToolForEvent(event) {
    const button =
      event && typeof event.button === 'number' ? event.button : undefined;
    if (typeof this.props.resolveToolForButton === 'function') {
      const resolved = this.props.resolveToolForButton(button);
      if (resolved) {
        return resolved;
      }
    }
    if (button === 2 && this.props.secondaryTool) {
      return this.props.secondaryTool;
    }
    return this.props.tool || 'brush';
  }

  // RS Add: Custom markings support (Lira, November 2025)
  resolveButton(event) {
    return event && typeof event.button === 'number' ? event.button : undefined;
  }

  // RS Add: New clickwrapper event to support new painting system (Lira, September 2025)
  clickwrapper(event) {
    const pos = this.getGridCoord(event);
    if (!pos) return;
    const [x, y] = pos;
    const tool = this.resolveToolForEvent(event);
    const button = this.resolveButton(event);
    if (tool === 'fill' || tool === 'eyedropper') {
      return;
    }
  }

  // RS Add: Process the start of a stroke (Lira, September 2025)
  mousedownwrapper(event) {
    const tool = this.resolveToolForEvent(event);
    const button = this.resolveButton(event);
    const pos = this.getGridCoord(event);
    if (!pos) {
      this.currentStrokeTool = null;
      this.currentStrokeButton = null;
      return;
    }
    this.currentStrokeTool = tool;
    this.currentStrokeButton = button;
    if (tool === 'fill') {
      if (this.props.onCanvasFill) {
        this.props.onCanvasFill(pos[0], pos[1], tool, button);
      }
      return;
    }
    if (tool === 'eyedropper') {
      if (this.props.onEyedropper) {
        this.props.onEyedropper(pos[0], pos[1], tool, button);
      }
      return;
    }
    if (tool === 'line') {
      this.lineStart = { x: pos[0], y: pos[1] };
      const strokeId = this.ensureStrokeId();
      this.currentStroke = strokeId;
      return;
    }
    if (tool === 'brush' || tool === 'mirror-brush' || tool === 'eraser') {
      const strokeId = this.ensureStrokeId();
      this.currentStroke = strokeId;
      this.dragging = true;
      this.lastPos = { x: pos[0], y: pos[1] };
      if (this.props.onCanvasClick) {
        this.props.onCanvasClick(
          this.lastPos.x,
          this.lastPos.y,
          this.props.size || 1,
          strokeId,
          tool,
          button
        );
      }
    }
  }

  // RS Add: Process finishing of current tool action (Lira, September 2025)
  mouseupwrapper(event) {
    const tool = this.currentStrokeTool || this.resolveToolForEvent(event);
    const button =
      this.resolveButton(event) ?? this.currentStrokeButton ?? undefined;
    if (tool === 'line') {
      if (!this.lineStart) {
        this.currentStrokeTool = null;
        this.currentStrokeButton = null;
        return;
      }
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
          this.currentStroke,
          tool,
          button
        );
      }
      if (this.currentStroke) {
        this.handleStrokeSegmentComplete(true);
      }
      this.currentStrokeTool = null;
      this.currentStrokeButton = null;
      return;
    }
    if (tool === 'brush' || tool === 'mirror-brush' || tool === 'eraser') {
      if (this.dragging && this.currentStroke) {
        if (this.props.onCanvasClick) {
          this.props.onCanvasClick(0, 0, 0, this.currentStroke, tool, button);
        }
        this.handleStrokeSegmentComplete(true);
      } else if (this.currentStroke) {
        this.commitCurrentStroke();
      }
      this.dragging = false;
      this.lastPos = null;
      this.currentStrokeTool = null;
      this.currentStrokeButton = null;
    }
    if (
      tool !== 'line' &&
      tool !== 'brush' &&
      tool !== 'mirror-brush' &&
      tool !== 'eraser'
    ) {
      this.currentStrokeTool = null;
      this.currentStrokeButton = null;
    }
  }

  // RS Add: Process movement of mouse (Lira, September 2025)
  mousemovewrapper(event) {
    const tool =
      this.currentStrokeTool || this.resolveToolForEvent(event) || 'brush';
    const button =
      this.currentStrokeButton ?? this.resolveButton(event) ?? undefined;
    const pos = this.getGridCoord(event);
    if (!pos) {
      if (tool === 'line') {
        this.setState({ hover: null });
      } else if (
        (tool === 'brush' || tool === 'mirror-brush' || tool === 'eraser') &&
        this.dragging
      ) {
        // Break the segment without ending the stroke
        this.lastPos = null;
      }
      return;
    }
    if (tool === 'line') {
      this.setState({ hover: pos });
      return;
    }
    if (
      (tool === 'brush' || tool === 'mirror-brush' || tool === 'eraser') &&
      this.dragging
    ) {
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
              this.currentStroke,
              tool,
              button
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
            this.currentStroke,
            tool,
            button
          );
        }
        this.lastPos = { x: x2, y: y2 };
      }
    }
  }

  // RS Add: Handle off-canvas mouseup (Lira, September 2025)
  handleGlobalMouseUp() {
    const tool = this.currentStrokeTool || this.props.tool || 'brush';
    const button = this.currentStrokeButton ?? undefined;
    if (tool === 'line') {
      if (this.currentStroke) {
        this.commitCurrentStroke();
      }
      if (this.lineStart) {
        this.lineStart = null;
        this.setState({ hover: null });
      }
      this.currentStrokeTool = null;
      this.currentStrokeButton = null;
      return;
    }
    if (tool !== 'brush' && tool !== 'mirror-brush' && tool !== 'eraser') {
      this.currentStrokeTool = null;
      this.currentStrokeButton = null;
      return;
    }
    if (!this.dragging) {
      this.currentStrokeTool = null;
      this.currentStrokeButton = null;
      return;
    }
    if (this.currentStroke) {
      const sid = this.currentStroke;
      if (this.props.onCanvasClick) {
        this.props.onCanvasClick(0, 0, 0, sid, tool, button);
      }
      this.handleStrokeSegmentComplete(true);
    }
    this.dragging = false;
    this.lastPos = null;
    this.currentStrokeTool = null;
    this.currentStrokeButton = null;
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

  // RS Add: Force cursor update (Lira, November 2025)
  handleCursorUpdate() {
    this.forceUpdate();
  }

  // RS Add: Use custom-drawn tool cursors once fonts are ready (Lira, November 2025)
  resolveCursorStyle() {
    if (!this.cursorReady) {
      return DEFAULT_CURSOR;
    }
    const tool = (this.props.tool || 'brush').toLowerCase();
    return getCursorForTool(tool);
  }

  render() {
    const {
      res = 1,
      value,
      dotsize = PX_PER_UNIT,
      // RS Add Start: Reference support (Lira, September 2025)
      secondaryTool: _secondaryTool,
      resolveToolForButton: _resolveToolForButton,
      reference: _reference,
      referenceOpacity: _referenceOpacity,
      strokeDrafts: _strokeDrafts,
      diffStroke: _diffStroke,
      onDiffApplied: _onDiffApplied,
      strokeDraftSession: _strokeDraftSession,
      legacyGridGuideSize: _legacyGridGuideSize,
      // RS Add End
      ...rest
    } = this.props;
    const [width, height] = getImageSize(value);
    // RS Add Start: Cursor style (Lira, November 2025)
    const cursorStyle = this.resolveCursorStyle();
    const { style: incomingStyle, ...canvasProps } = rest || {};
    const canvasStyle = {
      ...(incomingStyle || {}),
      cursor: cursorStyle,
    };
    // RS Add End
    return (
      <canvas
        ref={this.canvasRef}
        width={width * dotsize || 300}
        height={height * dotsize || 300}
        {...canvasProps} // RS Edit: Custom marking support (November 2025)
        style={canvasStyle} // RS Add: Custom marking support (November 2025)
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
  const stateToken =
    data.state_token ||
    data.session_token ||
    data.session ||
    context?.windowId ||
    'canvas';
  const key = (suffix) => `canvas-${suffix}-${stateToken}`;
  const [tool, setTool] = useLocalState(context, key('tool'), 'brush');
  const [blendMode, setBlendMode] = useLocalState(
    context,
    key('blendMode'),
    'analog'
  );
  const [analogStrength, setAnalogStrength] = useLocalState(
    context,
    key('analogStrength'),
    1
  );
  const activeLayer = data.active_layer || 1;
  const [size, setSize] = useLocalState(context, key('size'), 1);
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
  const preferredOverlayKeys = ['gear_job', 'gear_loadout', 'overlay'];
  for (const key of preferredOverlayKeys) {
    if (
      (Array.isArray(referenceKeys) && referenceKeys.includes(key)) ||
      (layerParts && Object.prototype.hasOwnProperty.call(layerParts, key))
    ) {
      push(key);
    }
  }
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

// Gather draft pixels for the active session to preview strokes (Lira, November 2025)
const extractDraftPixels = (draftMap, sessionKey) => {
  if (!draftMap || !sessionKey) {
    return [];
  }
  const pixels = [];
  for (const key of Object.keys(draftMap)) {
    const entry = draftMap[key];
    if (!entry || entry.session !== sessionKey) {
      continue;
    }
    if (Array.isArray(entry.pixels)) {
      pixels.push(...entry.pixels);
    }
  }
  return pixels;
};

// Set fallback reference layer when specific parts are missing (Lira, November 2025)
const resolveFallbackReference = (
  referenceParts,
  referencePartKeys,
  reference
) => {
  if (referenceParts && referencePartKeys.length) {
    if (referenceParts.generic) {
      return referenceParts.generic;
    }
    for (const key of referencePartKeys) {
      const layer = referenceParts[key];
      if (layer && layer.length) {
        return layer;
      }
    }
  }
  return reference;
};

const drawGridLayer = (ctx, grid, yLimit, mask) => {
  if (!grid) {
    return;
  }
  for (let x = 0; x < grid.length; x++) {
    const column = grid[x];
    if (!column) continue;
    const limit = Math.min(column.length, yLimit);
    for (let y = 0; y < limit; y++) {
      if (mask && mask[x] && mask[x][y]) {
        continue;
      }
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
  const overlayMask =
    referenceParts && referenceParts.overlay ? referenceParts.overlay : null;
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
        const mask = key === 'generic' ? overlayMask : null;
        drawGridLayer(ctx, refGrid, yLimit, mask);
      }
    } else if (key === 'generic' && reference && reference.length) {
      ctx.globalAlpha = resolvedGenericOpacity;
      const mask = overlayMask;
      drawGridLayer(ctx, reference, yLimit, mask);
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
    const mask = overlayMask;
    drawGridLayer(ctx, reference, yLimit, mask);
  }

  ctx.restore();
};

// RS Add End
