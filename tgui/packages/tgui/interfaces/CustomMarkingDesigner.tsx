// ///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings //
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Flex,
  LabeledList,
  NumberInput,
  Section,
  Tooltip,
} from '../components';
import { Window } from '../layouts';
import { PaintCanvas } from './Canvas';

const DOT_SIZE = 24;
const GENERIC_PART_KEY = 'generic';
const DEFAULT_GENERIC_REFERENCE_OPACITY = 0.4;
const DEFAULT_BODY_PART_REFERENCE_OPACITY = 0;

type DirectionEntry = {
  dir: number;
  label: string;
};

type BodyPartEntry = {
  id: string;
  label: string;
};

type DiffEntry = {
  x: number;
  y: number;
  color: string;
};

type CustomMarkingDesignerData = {
  marking_id?: string;
  active_dir: string;
  active_dir_key: number;
  active_body_part: string | null;
  active_body_part_label?: string;
  grid: string[][];
  reference?: (string | null)[][];
  reference_parts?: Record<string, (string | null)[][]>;
  body_part_layers?: Record<string, (string | null)[][]>;
  body_part_layer_order?: string[];
  body_part_layer_revision?: number;
  diff?: DiffEntry[];
  diff_seq?: number;
  brush_color: string;
  can_undo?: boolean;
  can_set_brush_color: boolean;
  limited: boolean;
  finalized: boolean;
  can_finalize: boolean;
  directions: DirectionEntry[];
  body_parts: BodyPartEntry[];
  selected_body_parts: string[];
  is_new?: boolean;
  width: number;
  height: number;
};

type CustomMarkingDesignerState = {
  tool: string;
  size: number;
  stroke: number;
};

export const CustomMarkingDesigner = (_props, context) => {
  const { act, data } = useBackend<CustomMarkingDesignerData>(context);
  const [tool, setTool] = useLocalState(context, 'tool', 'brush');
  const [size, setSize] = useLocalState(context, 'size', 1);
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
  const [referenceOpacityByPart, setReferenceOpacityByPart] = useLocalState<
    Record<string, number>
  >(context, 'referenceOpacityByPart', {});
  const limited = !!data.limited;
  const referenceParts = data.reference_parts || null;
  const layerParts = data.body_part_layers || null;
  const layerOrder = data.body_part_layer_order || null;

  const activePartKey = data.active_body_part || GENERIC_PART_KEY;
  const activePartLabel = data.active_body_part_label || 'Generic';

  const getDefaultReferenceOpacityForPart = (partId: string) =>
    partId === GENERIC_PART_KEY
      ? DEFAULT_GENERIC_REFERENCE_OPACITY
      : DEFAULT_BODY_PART_REFERENCE_OPACITY;

  const getReferenceOpacityForPart = (partId: string) => {
    const stored = referenceOpacityByPart[partId];
    if (typeof stored === 'number') {
      return stored;
    }
    return getDefaultReferenceOpacityForPart(partId);
  };

  const setReferenceOpacityForPart = (partId: string, value: number) => {
    const clamped = Math.min(1, Math.max(0, value));
    setReferenceOpacityByPart({
      ...referenceOpacityByPart,
      [partId]: clamped,
    });
  };

  const currentReferenceOpacity = getReferenceOpacityForPart(activePartKey);

  const referenceOpacityMap: Record<string, number> = {
    [GENERIC_PART_KEY]: getReferenceOpacityForPart(GENERIC_PART_KEY),
  };

  if (referenceParts) {
    for (const partId of Object.keys(referenceParts)) {
      referenceOpacityMap[partId] = getReferenceOpacityForPart(partId);
    }
  } else {
    for (const part of data.body_parts) {
      referenceOpacityMap[part.id] = getReferenceOpacityForPart(part.id);
    }
  }

  const onPaint = ({ x, y, stroke, brushSize }) => {
    act('paint', {
      x,
      y,
      size: brushSize || size,
      blend: tool === 'eraser' ? 'erase' : limited ? 'analog' : blendMode,
      stroke,
      strength: analogStrength,
    });
  };

  const onLine = ({ x1, y1, x2, y2, stroke, brushSize }) => {
    act('line', {
      x1,
      y1,
      x2,
      y2,
      size: brushSize || size,
      blend: tool === 'eraser' ? 'erase' : limited ? 'analog' : blendMode,
      stroke,
      strength: analogStrength,
    });
  };

  const onFill = ({ x, y }) => {
    act('fill', {
      x,
      y,
      blend: tool === 'eraser' ? 'erase' : limited ? 'analog' : blendMode,
      strength: analogStrength,
    });
  };

  const onEyedropper = ({ x, y }) => {
    act('eyedropper', {
      x,
      y,
    });
  };

  const onCommitStroke = (stroke) => {
    act('commit_stroke', { stroke });
  };

  const setBodyPart = (id: string) => {
    if (id === activePartKey) {
      return;
    }

    const previousPartKey = activePartKey;
    const previousOpacity = getReferenceOpacityForPart(previousPartKey);

    setReferenceOpacityByPart({
      ...referenceOpacityByPart,
      [previousPartKey]: 0,
      [id]: previousOpacity,
    });

    act('set_body_part', { part: id });
  };

  const brushColor = data.brush_color || '#FFFFFF';
  const canUndo = !!data.can_undo;
  const canSetBrush = data.can_set_brush_color;

  return (
    <Window width={860} height={720} resizable>
      <Window.Content scrollable>
        <Flex direction="column" fill>
          <Section title="Marking Information">
            <LabeledList>
              <LabeledList.Item label="Body Parts">
                <Flex wrap="wrap" gap={1}>
                  {data.body_parts.map((part) => {
                    const isActive = part.id === data.active_body_part;
                    const color = isActive ? 'good' : undefined;
                    return (
                      <Flex.Item key={part.id} basis="15%">
                        <Button
                          fluid
                          selected={isActive}
                          color={color}
                          onClick={() => setBodyPart(part.id)}>
                          {part.label}
                        </Button>
                      </Flex.Item>
                    );
                  })}
                </Flex>
              </LabeledList.Item>
              <LabeledList.Item label="Direction">
                <Flex wrap="wrap" gap={1}>
                  {data.directions.map((entry) => (
                    <Flex.Item key={entry.dir} basis="15%">
                      <Button
                        fluid
                        selected={entry.dir === data.active_dir_key}
                        onClick={() => act('set_dir', { dir: entry.dir })}>
                        {entry.label}
                      </Button>
                    </Flex.Item>
                  ))}
                </Flex>
              </LabeledList.Item>
            </LabeledList>
          </Section>

          <Section
            title={`Direction: ${data.active_dir} • Part: ${
              data.active_body_part_label || data.active_body_part || 'Generic'
            }`}
            fill>
            <Box mb={1} textAlign="center">
              <Button
                icon="paint-brush"
                selected={tool === 'brush'}
                onClick={() => setTool('brush')}>
                Brush
              </Button>
              <Button
                icon="eraser"
                selected={tool === 'eraser'}
                onClick={() => setTool('eraser')}>
                Eraser
              </Button>
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
                    <div>
                      <div>
                        <b>Classic:</b> Blend brush and canvas colors.
                      </div>
                      <br />
                      <div>
                        <b>Lighten:</b> Adds brush color to lighten pixels.
                      </div>
                      <br />
                      <div>
                        <b>Darken:</b> Multiplies colors to darken pixels.
                      </div>
                    </div>
                  }>
                  <Box inline color="label" mr={1}>
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
              <Box
                inline
                ml={2}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                }}>
                <Tooltip content="Weight of the selected color relative to the canvas.">
                  <Box inline color="label" mr={1}>
                    Strength:
                  </Box>
                </Tooltip>
                <NumberInput
                  minValue={1}
                  maxValue={100}
                  step={1}
                  unit="%"
                  width={5}
                  value={Math.round(analogStrength * 100)}
                  onChange={(e, value) => setAnalogStrength(value / 100)}
                />
              </Box>
              <Box
                inline
                ml={2}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                }}>
                <Box inline color="label" mr={1}>
                  Generic Fade:
                </Box>
                <NumberInput
                  minValue={0}
                  maxValue={100}
                  step={1}
                  unit="%"
                  width={5}
                  value={Math.round(
                    getReferenceOpacityForPart(GENERIC_PART_KEY) * 100
                  )}
                  onChange={(e, value) =>
                    setReferenceOpacityForPart(
                      GENERIC_PART_KEY,
                      (value ?? 0) / 100
                    )
                  }
                />
              </Box>
              {activePartKey !== GENERIC_PART_KEY ? (
                <Box
                  inline
                  ml={2}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}>
                  <Box inline color="label" mr={1}>
                    {activePartLabel} Fade:
                  </Box>
                  <NumberInput
                    minValue={0}
                    maxValue={100}
                    step={1}
                    unit="%"
                    width={5}
                    value={Math.round(
                      getReferenceOpacityForPart(activePartKey) * 100
                    )}
                    onChange={(e, value) =>
                      setReferenceOpacityForPart(
                        activePartKey,
                        (value ?? 0) / 100
                      )
                    }
                  />
                </Box>
              ) : null}
              <Tooltip content="Ctrl+Z or Cmd+Z also works.">
                <Button ml={2} disabled={!canUndo} onClick={() => act('undo')}>
                  Undo
                </Button>
              </Tooltip>
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
                <Box inline color="label">
                  Thickness:
                </Box>
                {[1, 2, 3, 4, 5].map((value) => (
                  <Button
                    key={value}
                    mb={0}
                    selected={size === value}
                    onClick={() => setSize(value)}>
                    {value}
                  </Button>
                ))}
              </Box>
              <Box
                inline
                ml={2}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                }}>
                <Box
                  inline
                  style={{
                    width: '16px',
                    height: '16px',
                    background: brushColor,
                    border: '1px solid #555',
                  }}
                />
                <Button
                  disabled={!canSetBrush}
                  onClick={() => act('pick_color_dialog')}>
                  Pick Color…
                </Button>
              </Box>
            </Box>

            <Box style={{ overflow: 'auto' }}>
              <Box
                style={{
                  display: 'inline-block',
                  border: '1px solid rgba(255, 255, 255, 0.3)',
                  borderRadius: '6px',
                  background: 'rgba(0, 0, 0, 0.15)',
                  padding: '6px',
                }}>
                <PaintCanvas
                  key={`${data.active_dir_key}-${
                    data.active_body_part || GENERIC_PART_KEY
                  }`}
                  value={data.grid || []}
                  reference={data.reference}
                  referenceParts={referenceParts}
                  referenceOpacity={
                    data.reference ? currentReferenceOpacity : undefined
                  }
                  referenceOpacityMap={referenceOpacityMap}
                  layerParts={layerParts}
                  layerOrder={layerOrder}
                  layerRevision={data.body_part_layer_revision || 0}
                  diff={data.diff}
                  diffSeq={data.diff_seq}
                  activeLayerKey={activePartKey}
                  otherLayerOpacity={getReferenceOpacityForPart(
                    GENERIC_PART_KEY
                  )}
                  dotsize={DOT_SIZE}
                  tool={tool === 'eyedropper' ? 'eyedropper' : tool}
                  size={size}
                  previewColor={data.brush_color}
                  finalized={false}
                  allowUndoShortcut
                  onUndo={() => act('undo')}
                  onCanvasClick={(x, y, s, stroke) =>
                    tool === 'fill'
                      ? onFill({ x, y })
                      : tool === 'eyedropper'
                        ? onEyedropper({ x, y })
                        : onPaint({ x, y, brushSize: s, stroke })
                  }
                  onCanvasLine={(x1, y1, x2, y2, s, stroke) =>
                    onLine({ x1, y1, x2, y2, brushSize: s, stroke })
                  }
                  onCanvasFill={(x, y) => onFill({ x, y })}
                  onEyedropper={(x, y) => onEyedropper({ x, y })}
                  onCommitStroke={(stroke) => onCommitStroke(stroke)}
                />
              </Box>
            </Box>
          </Section>

          <Section title="Session">
            <Flex justify="space-between" wrap>
              {/*
                Import temporarily disabled; uncomment to restore.
                <Flex.Item>
                  <Button icon="file-arrow-up" onClick={() => act('import_png')}>
                    Import PNG
                  </Button>
                </Flex.Item>
                <Flex.Item>
                  <Button icon="file-import" onClick={() => act('import_dmi')}>
                    Import DMI
                  </Button>
                </Flex.Item>
              */}
              <Flex.Item>
                <Button icon="file-image" onClick={() => act('export_png')}>
                  Export PNG
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button icon="file" onClick={() => act('export_dmi')}>
                  Export DMI
                </Button>
              </Flex.Item>
            </Flex>
          </Section>
        </Flex>
      </Window.Content>
    </Window>
  );
};
