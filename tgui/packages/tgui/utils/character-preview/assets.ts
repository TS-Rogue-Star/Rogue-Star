// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Character preview asset helpers for custom markings //
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ///////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////

export type IconAssetPayload = {
  token: string;
  png: string;
  width: number;
  height: number;
  shift_x?: number | null;
  shift_y?: number | null;
};

export type GearOverlayAsset = {
  slot?: string | null;
  layer?: number | null;
  asset: IconAssetPayload;
};

type ColorGrid = (string | null)[][];

type IconDecodedAsset = {
  payload: IconAssetPayload;
  imageData: ImageData;
  shiftX: number;
  shiftY: number;
  referenceCache?: CachedGrid;
  previewCache?: PreviewCachedGrid;
};

type CachedGrid = {
  width: number;
  height: number;
  grid: ColorGrid;
};

type PreviewCachedGrid = CachedGrid;

type GridMap = Record<string, string[][]>;

const decodedAssetCache: Record<string, IconDecodedAsset> = {};
const decodingAssetPromises: Record<string, Promise<void> | undefined> = {};
const decodingAssetSignatures: Record<string, string> = {};
const lastSignatureByToken: Record<string, string> = {};

const dataUriPrefix = 'data:image/png;base64,';

const createPayloadSignature = (payload: IconAssetPayload): string =>
  [
    payload.width,
    payload.height,
    normalizeShift(payload.shift_x),
    normalizeShift(payload.shift_y),
    payload.png,
  ].join(':');

const payloadMatchesCache = (
  cached: IconDecodedAsset | undefined,
  payload: IconAssetPayload,
  signature: string
): boolean => !!cached && createPayloadSignature(cached.payload) === signature;

const buildCacheKey = (token: string, signature: string) =>
  `${token}:${signature}`;

export const getReferenceGridFromAsset = (
  payload: IconAssetPayload | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void
): string[][] | null => {
  const asset = ensureDecodedAsset(payload, onUpdated);
  if (!asset) {
    return null;
  }
  const width = Math.max(1, Math.floor(canvasWidth));
  const height = Math.max(1, Math.floor(canvasHeight));
  if (
    !asset.referenceCache ||
    asset.referenceCache.width !== width ||
    asset.referenceCache.height !== height
  ) {
    asset.referenceCache = {
      width,
      height,
      grid: buildReferenceGrid(asset, width, height),
    };
  }
  return asset.referenceCache.grid as string[][];
};

export const getPreviewGridFromAsset = (
  payload: IconAssetPayload | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void
): string[][] | null => {
  const asset = ensureDecodedAsset(payload, onUpdated);
  if (!asset) {
    return null;
  }
  const { width, height } = resolvePreviewDimensions(
    asset,
    canvasWidth,
    canvasHeight
  );
  if (
    !asset.previewCache ||
    asset.previewCache.width !== width ||
    asset.previewCache.height !== height
  ) {
    asset.previewCache = {
      width,
      height,
      grid: buildPreviewGrid(asset, width, height),
    };
  }
  return asset.previewCache.grid as string[][];
};

export const getPreviewGridListFromAssets = (
  assets: IconAssetPayload[] | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void
): string[][][] | null => {
  if (!Array.isArray(assets) || !assets.length) {
    return null;
  }
  const layers: string[][][] = [];
  for (const payload of assets) {
    const grid = getPreviewGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      onUpdated
    );
    if (grid) {
      layers.push(grid as string[][]);
    }
  }
  return layers.length ? layers : null;
};

export const getPreviewGridMapFromGearAssets = (
  assets: GearOverlayAsset[] | IconAssetPayload[] | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void
): Record<string, string[][]> | null => {
  if (!Array.isArray(assets) || !assets.length) {
    return null;
  }
  const map: Record<string, string[][]> = {};
  let counter = 0;
  for (const entry of assets) {
    const payload =
      (entry as GearOverlayAsset)?.asset || (entry as IconAssetPayload);
    if (!payload) {
      continue;
    }
    const grid = getPreviewGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      onUpdated
    );
    if (!grid) {
      continue;
    }
    const slotValue = (entry as GearOverlayAsset)?.slot;
    const slot =
      slotValue && String(slotValue).length
        ? String(slotValue)
        : `slot_${counter++}`;
    map[slot] = grid as string[][];
  }
  return Object.keys(map).length ? map : null;
};

export const getReferencePartMapFromAssets = (
  assets: Record<string, IconAssetPayload> | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void
): GridMap | null => {
  if (!assets) {
    return null;
  }
  const result: GridMap = {};
  let changed = false;
  for (const [partId, payload] of Object.entries(assets)) {
    if (!partId || !payload) {
      continue;
    }
    const grid = getReferenceGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      onUpdated
    );
    if (!grid) {
      continue;
    }
    result[partId] = grid as string[][];
    changed = true;
  }
  return changed ? result : null;
};

export const getPreviewPartMapFromAssets = (
  assets: Record<string, IconAssetPayload> | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void
): GridMap | null => {
  if (!assets) {
    return null;
  }
  const result: GridMap = {};
  let changed = false;
  for (const [partId, payload] of Object.entries(assets)) {
    if (!partId || !payload) {
      continue;
    }
    const grid = getPreviewGridFromAsset(
      payload,
      canvasWidth,
      canvasHeight,
      onUpdated
    );
    if (!grid) {
      continue;
    }
    result[partId] = grid as string[][];
    changed = true;
  }
  return changed ? result : null;
};

const ensureDecodedAsset = (
  payload: IconAssetPayload | undefined,
  onUpdated: () => void
): IconDecodedAsset | null => {
  if (!payload || !payload.token || !payload.png) {
    return null;
  }
  const token = payload.token;
  const signature = createPayloadSignature(payload);
  const cacheKey = buildCacheKey(token, signature);
  const cached = decodedAssetCache[cacheKey];
  if (payloadMatchesCache(cached, payload, signature)) {
    return cached;
  }
  const previousSignature = lastSignatureByToken[token];
  if (previousSignature && previousSignature !== signature) {
    const previousKey = buildCacheKey(token, previousSignature);
    delete decodedAssetCache[previousKey];
    delete decodingAssetPromises[previousKey];
    delete decodingAssetSignatures[previousKey];
  }
  lastSignatureByToken[token] = signature;
  if (!decodingAssetPromises[cacheKey]) {
    const expectedSignature = signature;
    decodingAssetSignatures[cacheKey] = expectedSignature;
    decodingAssetPromises[cacheKey] = decodeIconAsset(payload)
      .then((decoded) => {
        if (decodingAssetSignatures[cacheKey] === expectedSignature) {
          decodedAssetCache[cacheKey] = decoded;
        }
      })
      .catch(() => {})
      .finally(() => {
        const signatureMatch =
          decodingAssetSignatures[cacheKey] === expectedSignature &&
          lastSignatureByToken[token] === expectedSignature;
        delete decodingAssetPromises[cacheKey];
        delete decodingAssetSignatures[cacheKey];
        if (signatureMatch) {
          onUpdated();
        }
      });
  }
  return null;
};

const decodeIconAsset = (
  payload: IconAssetPayload
): Promise<IconDecodedAsset> => {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => {
      try {
        const canvas = document.createElement('canvas');
        canvas.width = Math.max(1, Math.floor(image.width));
        canvas.height = Math.max(1, Math.floor(image.height));
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          reject(new Error('Failed to acquire 2D context'));
          return;
        }
        ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        resolve({
          payload,
          imageData,
          shiftX: normalizeShift(payload.shift_x),
          shiftY: normalizeShift(payload.shift_y),
        });
      } catch (error) {
        reject(error);
      }
    };
    image.onerror = () => reject(new Error('Failed to decode preview asset'));
    image.src = `${dataUriPrefix}${payload.png}`;
  });
};

const normalizeShift = (value?: number | null): number =>
  typeof value === 'number' && !Number.isNaN(value) ? Math.round(value) : 0;

const buildReferenceGrid = (
  asset: IconDecodedAsset,
  width: number,
  height: number
): (string | null)[][] => {
  let grid = createBlankGrid(width, height);
  const iconWidth = asset.imageData.width;
  const iconHeight = asset.imageData.height;
  const xOffset = Math.round((iconWidth - width) / 2);
  const yOffset = Math.max(0, iconHeight - height);
  for (let x = 1; x <= width; x += 1) {
    const column = grid[x - 1];
    for (let y = 1; y <= height; y += 1) {
      const sourceX = x + xOffset;
      const sourceY = y + yOffset;
      const color = samplePixelColor(asset.imageData, sourceX, sourceY);
      if (!color) {
        continue;
      }
      const uiY = height - y + 1;
      column[uiY - 1] = color;
    }
  }
  const dx = -asset.shiftX;
  const dy = asset.shiftY;
  if (dx || dy) {
    grid = translateGrid(grid, dx, dy);
  }
  return grid;
};

const resolvePreviewDimensions = (
  asset: IconDecodedAsset,
  canvasWidth: number,
  canvasHeight: number
) => {
  const iconWidth = asset.imageData.width;
  const iconHeight = asset.imageData.height;
  const resultWidth = Math.max(
    Math.max(1, Math.floor(canvasWidth)),
    iconWidth + Math.abs(asset.shiftX)
  );
  const resultHeight = Math.max(
    Math.max(1, Math.floor(canvasHeight)),
    iconHeight + Math.abs(asset.shiftY)
  );
  return { width: resultWidth, height: resultHeight };
};

const buildPreviewGrid = (
  asset: IconDecodedAsset,
  width: number,
  height: number
): (string | null)[][] => {
  let grid = createBlankGrid(width, height);
  const iconWidth = asset.imageData.width;
  const iconHeight = asset.imageData.height;
  const xOffset = Math.round((width - iconWidth) / 2);
  const yOffset = Math.min(0, height - iconHeight);
  for (let x = 1; x <= width; x += 1) {
    const column = grid[x - 1];
    const sourceX = x - xOffset;
    if (sourceX < 1 || sourceX > iconWidth) {
      continue;
    }
    for (let y = 1; y <= height; y += 1) {
      const sourceY = y - yOffset;
      const color = samplePixelColor(asset.imageData, sourceX, sourceY);
      if (!color) {
        continue;
      }
      const uiY = height - y + 1;
      column[uiY - 1] = color;
    }
  }
  const dx = -asset.shiftX;
  const dy = asset.shiftY;
  if (dx || dy) {
    grid = translateGrid(grid, dx, dy);
  }
  return grid;
};

const translateGrid = (
  grid: (string | null)[][],
  dx: number,
  dy: number
): (string | null)[][] => {
  if (!dx && !dy) {
    return grid;
  }
  const width = grid.length;
  const height = width ? grid[0]?.length || 0 : 0;
  if (!width || !height) {
    return grid;
  }
  const translated = createBlankGrid(width, height);
  for (let x = 0; x < width; x += 1) {
    const column = grid[x];
    if (!Array.isArray(column)) {
      continue;
    }
    for (let y = 0; y < column.length; y += 1) {
      const value = column[y];
      if (!value) {
        continue;
      }
      const targetX = x + dx;
      const targetY = y + dy;
      if (targetX < 0 || targetX >= width || targetY < 0 || targetY >= height) {
        continue;
      }
      translated[targetX][targetY] = value;
    }
  }
  return translated;
};

const createBlankGrid = (
  width: number,
  height: number
): (string | null)[][] => {
  const clampedWidth = Math.max(0, Math.floor(width));
  const clampedHeight = Math.max(0, Math.floor(height));
  const grid: (string | null)[][] = new Array(clampedWidth);
  for (let x = 0; x < clampedWidth; x += 1) {
    grid[x] = new Array(clampedHeight);
  }
  return grid;
};

const samplePixelColor = (
  imageData: ImageData,
  x: number,
  y: number
): string | null => {
  const iconWidth = imageData.width;
  const iconHeight = imageData.height;
  const rawX = Math.floor(x);
  const rawY = Math.floor(y);
  if (rawX <= 0 || rawY <= 0) {
    return null;
  }
  const sampleX = rawX - 1;
  const sampleY = iconHeight - rawY;
  if (
    sampleX < 0 ||
    sampleX >= iconWidth ||
    sampleY < 0 ||
    sampleY >= iconHeight
  ) {
    return null;
  }
  const index = (sampleY * iconWidth + sampleX) * 4;
  const data = imageData.data;
  const r = data[index];
  const g = data[index + 1];
  const b = data[index + 2];
  const a = data[index + 3];
  if (a === 0) {
    return null;
  }
  return rgbaToHex(r, g, b, a);
};

const toHex = (value: number): string =>
  Math.max(0, Math.min(255, Math.round(value)))
    .toString(16)
    .padStart(2, '0');

const rgbaToHex = (r: number, g: number, b: number, a: number): string => {
  const red = toHex(r);
  const green = toHex(g);
  const blue = toHex(b);
  const alpha = toHex(a);
  return `#${red}${green}${blue}${alpha}`.toLowerCase();
};
