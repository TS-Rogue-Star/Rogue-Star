// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Expression //
// /////////////////////////////////////////////////////////////////////////////////

import { Box, Button, Flex, Icon, Input, NoticeBox } from '../../../components';
import {
  createBlankGrid,
  getPreviewGridFromAsset,
} from '../../../utils/character-preview';
import { CHIP_BUTTON_CLASS } from '../constants';
import type { SpeechBubbleStyle } from '../types';
import { DirectionPreviewCanvas } from './DirectionPreviewCanvas';

type SpeechBubbleGalleryProps = Readonly<{
  styles: SpeechBubbleStyle[];
  selectedId: string;
  disabled: boolean;
  onSelect: (id: string) => void;
  search: string;
  onSearch: (value: string) => void;
  page: number;
  onPageChange: (page: number) => void;
  onAssetReady: () => void;
}>;

const centeredGrids = new WeakMap<string[][], string[][]>();
const croppedGrids = new WeakMap<string[][], string[][]>();

export const centerSpeechBubbleGrid = (
  grid: string[][],
  crop = false
): string[][] => {
  const cache = crop ? croppedGrids : centeredGrids;
  const cached = cache.get(grid);
  if (cached) {
    return cached;
  }
  const width = grid.length;
  const height = grid[0]?.length || 0;
  let minX = width;
  let minY = height;
  let maxX = -1;
  let maxY = -1;
  grid.forEach((column, x) => {
    column.forEach((color, y) => {
      if (color) {
        minX = Math.min(minX, x);
        minY = Math.min(minY, y);
        maxX = Math.max(maxX, x);
        maxY = Math.max(maxY, y);
      }
    });
  });
  const targetWidth = crop ? Math.max(1, maxX - minX + 1) : width;
  const targetHeight = crop ? Math.max(1, maxY - minY + 1) : height;
  const centered = createBlankGrid(targetWidth, targetHeight);
  const offsetX = Math.floor((targetWidth - (maxX - minX + 1)) / 2) - minX;
  const offsetY = Math.floor((targetHeight - (maxY - minY + 1)) / 2) - minY;
  for (let x = minX; x <= maxX; x++) {
    for (let y = minY; y <= maxY; y++) {
      centered[x + offsetX][y + offsetY] = grid[x][y];
    }
  }
  cache.set(grid, centered);
  return centered;
};

export const SpeechBubblePreview = ({
  style,
  onAssetReady,
  pixelSize = 4,
  compact = false,
}: Readonly<{
  style: SpeechBubbleStyle;
  onAssetReady: () => void;
  pixelSize?: number;
  compact?: boolean;
}>) => {
  if (style.id === 'default') {
    return <Icon name="comment-dots" size={2} />;
  }
  const grid = getPreviewGridFromAsset(
    style.icon || undefined,
    32,
    32,
    onAssetReady
  );
  if (!grid) {
    return compact ? (
      <Icon name="spinner" size={2} spin />
    ) : (
      <Box color="label">Loading preview…</Box>
    );
  }
  const previewGrid = centerSpeechBubbleGrid(grid, compact);
  const width = previewGrid.length;
  const height = previewGrid[0]?.length || 1;
  const preview = (
    <DirectionPreviewCanvas
      layers={[
        {
          type: 'overlay',
          key: `speech-bubble-${style.id}`,
          grid: previewGrid,
        },
      ]}
      pixelSize={pixelSize}
      width={width}
      height={height}
    />
  );
  const dimensions = {
    width: `${width * pixelSize}px`,
    height: `${height * pixelSize}px`,
  };
  if (compact) {
    const scale = 24 / (Math.max(width, height) * pixelSize);
    return (
      <Box className="RogueStar__speechBubbleInline">
        <Box
          style={{
            ...dimensions,
            position: 'absolute',
            left: '50%',
            top: '50%',
            transform: `translate(-50%, -50%) scale(${scale})`,
          }}>
          {preview}
        </Box>
      </Box>
    );
  }
  return <Box style={dimensions}>{preview}</Box>;
};

export const speechBubbleName = (id: string) =>
  (id === 'posessed' ? 'possessed' : id)
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

export const SpeechBubbleGallery = ({
  styles,
  selectedId,
  disabled,
  onSelect,
  search,
  onSearch,
  page,
  onPageChange,
  onAssetReady,
}: SpeechBubbleGalleryProps) => {
  const needle = search.trim().toLowerCase();
  const filtered = styles
    .filter(
      ({ id }) =>
        id.toLowerCase().includes(needle) ||
        speechBubbleName(id).toLowerCase().includes(needle)
    )
    .sort((a, b) => {
      if (a.id === b.id) {
        return 0;
      }
      if (a.id === 'default') {
        return -1;
      }
      if (b.id === 'default') {
        return 1;
      }
      return speechBubbleName(a.id).localeCompare(speechBubbleName(b.id));
    });
  const pageSize = 20;
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const currentPage = Math.max(0, Math.min(page, totalPages - 1));
  const startIndex = currentPage * pageSize;

  return (
    <>
      <Box mb={1}>
        <Input
          fluid
          value={search}
          placeholder="Search speech bubbles…"
          onInput={(_event, value) => onSearch(value)}
        />
      </Box>
      <Box className="RogueStar__markingGrid">
        {filtered.slice(startIndex, startIndex + pageSize).map((style) => {
          const { id } = style;
          return (
            <Box
              key={id}
              as="button"
              type="button"
              className={`RogueStar__markingTile${
                selectedId === id ? ' RogueStar__markingTile--selected' : ''
              }${disabled ? ' RogueStar__markingTile--disabled' : ''}`}
              style={{
                color: 'inherit',
                font: 'inherit',
              }}
              disabled={disabled}
              title={
                id === 'default'
                  ? 'Let the game choose your bubble automatically.'
                  : speechBubbleName(id)
              }
              aria-label={speechBubbleName(id)}
              aria-pressed={selectedId === id}
              onClick={() => {
                if (!disabled) {
                  onSelect(id);
                }
              }}>
              <Box className="RogueStar__markingTilePreviewGrid RogueStar__markingTilePreviewGrid--single">
                <Box className="RogueStar__markingTilePreview">
                  <SpeechBubblePreview
                    style={style}
                    onAssetReady={onAssetReady}
                  />
                </Box>
              </Box>
              <Box className="RogueStar__markingTileLabel">
                {speechBubbleName(id)}
              </Box>
            </Box>
          );
        })}
        {!filtered.length && (
          <NoticeBox>No speech bubbles match this search.</NoticeBox>
        )}
      </Box>
      {totalPages > 1 && (
        <Flex
          mt={1}
          align="center"
          justify="space-between"
          wrap="nowrap"
          style={{ gap: '0.75rem' }}>
          <Flex.Item shrink={0}>
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="chevron-left"
              disabled={currentPage === 0}
              onClick={() => onPageChange(currentPage - 1)}>
              Prev
            </Button>
          </Flex.Item>
          <Flex.Item grow>
            <Box nowrap textAlign="center">
              Page {currentPage + 1} / {totalPages} · Showing {startIndex + 1}-
              {Math.min(startIndex + pageSize, filtered.length)} of{' '}
              {filtered.length}
            </Box>
          </Flex.Item>
          <Flex.Item shrink={0}>
            <Button
              className={CHIP_BUTTON_CLASS}
              icon="chevron-right"
              disabled={currentPage === totalPages - 1}
              onClick={() => onPageChange(currentPage + 1)}>
              Next
            </Button>
          </Flex.Item>
        </Flex>
      )}
    </>
  );
};
