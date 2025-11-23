// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Direction preview canvas for custom marking designer //
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component, createRef } from 'inferno';
import { Box } from '../../../components';
import type { PreviewLayerEntry } from '../../../utils/character-preview';

export type DirectionPreviewCanvasProps = {
  layers?: PreviewLayerEntry[];
  pixelSize: number;
  width: number;
  height: number;
};

export class DirectionPreviewCanvas extends Component<DirectionPreviewCanvasProps> {
  private canvasRef = createRef<HTMLCanvasElement>();

  componentDidMount() {
    this.draw();
  }

  componentDidUpdate(prevProps: DirectionPreviewCanvasProps) {
    if (
      prevProps.layers !== this.props.layers ||
      prevProps.pixelSize !== this.props.pixelSize ||
      prevProps.width !== this.props.width ||
      prevProps.height !== this.props.height
    ) {
      this.draw();
    }
  }

  draw() {
    const canvas = this.canvasRef.current;
    if (!canvas) {
      return;
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      return;
    }
    const pixelSize = Math.max(1, this.props.pixelSize || 1);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingEnabled = false;
    const layers = Array.isArray(this.props.layers) ? this.props.layers : [];
    for (const layer of layers) {
      this.drawLayer(ctx, layer?.grid, pixelSize);
    }
  }

  drawLayer(
    ctx: CanvasRenderingContext2D,
    grid?: string[][],
    pixelSize?: number
  ) {
    if (!Array.isArray(grid) || !pixelSize) {
      return;
    }
    for (let x = 0; x < grid.length; x++) {
      const column = grid[x];
      if (!Array.isArray(column)) {
        continue;
      }
      for (let y = 0; y < column.length; y++) {
        const color = column[y];
        if (!color || color === '#00000000') {
          continue;
        }
        ctx.fillStyle = color;
        ctx.fillRect(x * pixelSize, y * pixelSize, pixelSize, pixelSize);
      }
    }
  }

  render() {
    const { layers, pixelSize, width, height } = this.props;
    const fallbackWidth = Math.max(1, width || 1);
    const fallbackHeight = Math.max(1, height || 1);
    const layerWidths = Array.isArray(layers)
      ? layers
        .map((layer) => (Array.isArray(layer?.grid) ? layer.grid.length : 0))
        .filter((value) => typeof value === 'number' && value > 0)
      : [];
    const layerHeights = Array.isArray(layers)
      ? layers
        .map((layer) => {
          const grid = layer?.grid;
          if (!Array.isArray(grid)) {
            return 0;
          }
          let maxHeight = 0;
          for (const column of grid) {
            if (Array.isArray(column) && column.length > maxHeight) {
              maxHeight = column.length;
            }
          }
          return maxHeight;
        })
        .filter((value) => typeof value === 'number' && value > 0)
      : [];
    const gridWidth = layerWidths.length
      ? Math.max(fallbackWidth, ...layerWidths)
      : fallbackWidth;
    const gridHeight = layerHeights.length
      ? Math.max(fallbackHeight, ...layerHeights)
      : fallbackHeight;
    const size = Math.max(1, pixelSize);
    const canvasWidth = gridWidth * size;
    const canvasHeight = gridHeight * size;
    const cropWidthUnits = Math.min(32, gridWidth);
    const cropHeightUnits = Math.min(32, gridHeight);
    const cropWidth = cropWidthUnits * size;
    const cropHeight = cropHeightUnits * size;
    const offsetLeft = (cropWidth - canvasWidth) / 2;
    const offsetTop = cropHeight - canvasHeight;
    return (
      <Box textAlign="center" className="RogueStar__previewCanvas">
        <Box
          className="RogueStar__previewCanvasFrame"
          style={{
            width: `${cropWidth}px`,
            height: `${cropHeight}px`,
            margin: '0 auto',
            position: 'relative',
          }}>
          <canvas
            ref={this.canvasRef}
            width={canvasWidth}
            height={canvasHeight}
            style={{
              imageRendering: 'pixelated',
              position: 'absolute',
              left: `${offsetLeft}px`,
              top: `${offsetTop}px`,
            }}
          />
        </Box>
      </Box>
    );
  }
}
