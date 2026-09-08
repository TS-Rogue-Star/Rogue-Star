// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Character preview asset helpers for custom markings //
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings ////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ///////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ///////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import { resolveAsset } from '../../assets';

export type GearColorTransform = string | number[];

export type IconAssetPayload = {
  token: string;
  png?: string;
  atlas?: string;
  atlas_x?: number;
  atlas_y?: number;
  width: number;
  height: number;
  tone?: number | null;
  shift_x?: number | null;
  shift_y?: number | null;
  colors?: GearColorTransform[] | null;
};

export type IconAssetReference = IconAssetPayload | string;

export type IconAssetFamilyManifest = {
  requested: number;
  reused: number;
  frames: number;
  sheets: string[];
};

export type IconAtlasPayload = {
  png: string;
  width?: number | null;
  height?: number | null;
};

export type ProstheticCatalogState = {
  assets: Record<number, IconAssetReference>;
  transparent_dirs?: number[];
};

export type ProstheticGalleryComposite = {
  assets: Record<number, IconAssetReference>;
};

export type ProstheticCatalogModel = {
  id: string;
  name: string;
  description?: string | null;
  parts: string[];
  skin_tone?: boolean;
  skin_color?: boolean;
  can_be_digitigrade?: boolean;
  includes_tail?: boolean;
  includes_ears?: boolean;
  includes_wing?: boolean;
  states: Record<string, ProstheticCatalogState>;
  gallery_composites?: Record<string, ProstheticGalleryComposite>;
};

export type ProstheticCatalog = {
  models: Record<string, ProstheticCatalogModel>;
};

export type IconAssetRegistry = {
  revision: number;
  assets: Record<string, IconAssetPayload>;
  atlases?: Record<string, IconAtlasPayload>;
  families?: Record<string, IconAssetFamilyManifest>;
  prosthetics?: ProstheticCatalog;
};

export type IconAssetRegistryAsset = {
  asset: string;
  revision: number;
};

export type GearAppearanceAsset = {
  asset: IconAssetPayload;
  colors?: GearColorTransform[] | null;
  alpha?: number | null;
  shift_x?: number | null;
  shift_y?: number | null;
  blend?: 'add' | 'overlay' | null;
};

export type GearAppearanceAssetReference = {
  asset: IconAssetReference;
  colors?: GearColorTransform[] | null;
  alpha?: number | null;
  shift_x?: number | null;
  shift_y?: number | null;
  blend?: 'add' | 'overlay' | null;
};

export type GearOverlayAsset = GearAppearanceAsset & {
  slot?: string | null;
  layer?: number | null;
  overlays?: GearAppearanceAsset[] | null;
  mask_asset?: IconAssetPayload | null;
};

export type GearOverlayAssetReference = GearAppearanceAssetReference & {
  slot?: string | null;
  layer?: number | null;
  overlays?: GearAppearanceAssetReference[] | null;
  mask_asset?: IconAssetReference | null;
};

export type CharacterPreviewWorkPriority = 'visible' | 'background';

export type CharacterPreviewWorkHandle = Readonly<{
  cancel: () => void;
  promote: () => void;
}>;

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

type ScheduledPreviewWork = {
  work: () => void;
  priority: CharacterPreviewWorkPriority;
  cancelled: boolean;
  completed: boolean;
};

const PREVIEW_WORK_BUDGET_MS = 4;
const PREVIEW_WORK_MAX_TASKS_PER_BATCH = 24;
const PREVIEW_BACKGROUND_DELAY_MS = 32;
const MAX_DECODED_ASSETS = 4096;
const MAX_ATLAS_SCRATCH_CANVASES = 8;
const MAX_DYNAMIC_ATLAS_SOURCES = 64;

const visiblePreviewWorkQueue: ScheduledPreviewWork[] = [];
const backgroundPreviewWorkQueue: ScheduledPreviewWork[] = [];
let previewWorkTimer: ReturnType<typeof setTimeout> | null = null;
let previewWorkFrame: number | null = null;
let previewWorkScheduledPriority: CharacterPreviewWorkPriority | null = null;

const decodedAssetCache = new Map<string, IconDecodedAsset>();
const decodingAssetPromises: Record<string, Promise<void> | undefined> = {};
const decodingAssetSignatures: Record<string, string> = {};
const decodingAssetPriorities: Record<
  string,
  CharacterPreviewWorkPriority | undefined
> = {};
const decodingAssetWorkHandles: Record<
  string,
  CharacterPreviewWorkHandle | undefined
> = {};
const assetUpdateListeners: Record<string, Set<() => void> | undefined> = {};
const lastSignatureByToken = new Map<string, string>();
const atlasImagePromises: Record<
  string,
  Promise<HTMLImageElement> | undefined
> = {};
const dynamicAtlasSources = new Map<string, string>();
const atlasScratchCanvases = new Map<string, HTMLCanvasElement>();
const payloadSignatureCache = new WeakMap<IconAssetPayload, string>();
const pendingAssetUpdateCallbacks = new Set<() => void>();
let assetUpdateFlushTimer: ReturnType<typeof setTimeout> | null = null;
let assetUpdateFlushFrame: number | null = null;
let staticIconAssetRegistry: IconAssetRegistry | null = null;
let staticIconAssetRegistrySource: string | null = null;
let staticIconAssetRegistryLoadKey: string | null = null;
let staticIconAssetRegistryLoad: Promise<IconAssetRegistry> | null = null;

const dataUriPrefix = 'data:image/png;base64,';
const STATIC_REGISTRY_FETCH_ATTEMPTS = 8;
const STATIC_REGISTRY_FETCH_RETRY_MS = 250;

const storeDynamicAtlasSource = (token: string, png: string) => {
  const existing = dynamicAtlasSources.get(token);
  if (existing === png) {
    dynamicAtlasSources.delete(token);
    dynamicAtlasSources.set(token, png);
    return;
  }
  dynamicAtlasSources.delete(token);
  dynamicAtlasSources.set(token, png);
  delete atlasImagePromises[token];
  while (dynamicAtlasSources.size > MAX_DYNAMIC_ATLAS_SOURCES) {
    const oldestToken = dynamicAtlasSources.keys().next().value as
      | string
      | undefined;
    if (!oldestToken) {
      break;
    }
    dynamicAtlasSources.delete(oldestToken);
    delete atlasImagePromises[oldestToken];
  }
};

export const registerIconAssetRegistry = (
  registry?: IconAssetRegistry | null
) => {
  if (!registry?.atlases) {
    return;
  }
  Object.entries(registry.atlases).forEach(([token, atlas]) => {
    if (token && atlas?.png) {
      storeDynamicAtlasSource(token, atlas.png);
    }
  });
};

export const registerStaticIconAssetRegistry = (
  registry?: IconAssetRegistry | null,
  source?: string | null
) => {
  if (!registry) {
    staticIconAssetRegistry = null;
    staticIconAssetRegistrySource = null;
    return;
  }
  if (
    staticIconAssetRegistry === registry ||
    (staticIconAssetRegistry?.revision === registry.revision &&
      staticIconAssetRegistry.assets === registry.assets)
  ) {
    staticIconAssetRegistrySource = source || staticIconAssetRegistrySource;
    return;
  }
  staticIconAssetRegistry = registry;
  staticIconAssetRegistrySource = source || null;
  registerIconAssetRegistry(registry);
};

export const getStaticProstheticCatalog = (): ProstheticCatalog | null =>
  staticIconAssetRegistry?.prosthetics || null;

const getStaticIconAssetRegistryLoadKey = (
  reference?: IconAssetRegistryAsset | null
) =>
  reference?.asset && typeof reference.revision === 'number'
    ? `${reference.revision}:${reference.asset}`
    : null;

export const isStaticIconAssetRegistryLoaded = (
  reference?: IconAssetRegistryAsset | null
) => {
  const loadKey = getStaticIconAssetRegistryLoadKey(reference);
  return (
    !!loadKey &&
    staticIconAssetRegistry?.revision === reference?.revision &&
    staticIconAssetRegistrySource === reference?.asset
  );
};

const fetchStaticIconAssetRegistry = (
  url: string,
  attempt = 1
): Promise<unknown> =>
  fetch(url, { cache: 'force-cache' })
    .then((response) => {
      if (response.ok === false && response.status !== 0) {
        throw new Error(
          `Atlas registry request failed with status ${response.status}.`
        );
      }
      return response.json();
    })
    .catch((error) => {
      if (attempt >= STATIC_REGISTRY_FETCH_ATTEMPTS) {
        throw error;
      }
      return new Promise<unknown>((resolve, reject) => {
        setTimeout(() => {
          fetchStaticIconAssetRegistry(url, attempt + 1).then(resolve, reject);
        }, STATIC_REGISTRY_FETCH_RETRY_MS * attempt);
      });
    });

export const loadStaticIconAssetRegistry = (
  reference: IconAssetRegistryAsset
): Promise<IconAssetRegistry> => {
  const loadKey = getStaticIconAssetRegistryLoadKey(reference);
  if (!loadKey) {
    return Promise.reject(
      new Error('The atlas registry reference is invalid.')
    );
  }
  if (
    staticIconAssetRegistryLoadKey === loadKey &&
    staticIconAssetRegistryLoad
  ) {
    return staticIconAssetRegistryLoad;
  }
  const load = fetchStaticIconAssetRegistry(resolveAsset(reference.asset))
    .then((registry) => {
      const resolved = registry as IconAssetRegistry;
      if (
        !resolved ||
        resolved.revision !== reference.revision ||
        !resolved.assets ||
        typeof resolved.assets !== 'object' ||
        Array.isArray(resolved.assets)
      ) {
        throw new Error(
          `Atlas registry revision ${reference.revision} was invalid.`
        );
      }
      return resolved;
    })
    .catch((error) => {
      if (staticIconAssetRegistryLoadKey === loadKey) {
        staticIconAssetRegistryLoadKey = null;
        staticIconAssetRegistryLoad = null;
      }
      throw error;
    });
  staticIconAssetRegistryLoadKey = loadKey;
  staticIconAssetRegistryLoad = load;
  return load;
};

export const resolveIconAssetReference = (
  reference?: IconAssetReference | null,
  registry?: IconAssetRegistry | null
): IconAssetPayload | undefined => {
  if (!reference) {
    return undefined;
  }
  registerIconAssetRegistry(registry);
  if (typeof reference === 'string') {
    return (
      registry?.assets?.[reference] ||
      staticIconAssetRegistry?.assets?.[reference]
    );
  }
  return reference;
};

export const resolveIconAssetReferenceMap = (
  references?: Record<string, IconAssetReference> | null,
  registry?: IconAssetRegistry | null
): Record<string, IconAssetPayload> | undefined => {
  if (!references) {
    return undefined;
  }
  const resolved: Record<string, IconAssetPayload> = {};
  Object.entries(references).forEach(([key, reference]) => {
    const payload = resolveIconAssetReference(reference, registry);
    if (key && payload) {
      resolved[key] = payload;
    }
  });
  return Object.keys(resolved).length ? resolved : undefined;
};

export const resolveGearOverlayAssetReferences = (
  references?: Array<GearOverlayAssetReference | IconAssetReference> | null,
  registry?: IconAssetRegistry | null
): Array<GearOverlayAsset | IconAssetPayload> | undefined => {
  if (!Array.isArray(references)) {
    return undefined;
  }
  const resolved: Array<GearOverlayAsset | IconAssetPayload> = [];
  references.forEach((entry) => {
    if (!entry) {
      return;
    }
    if (typeof entry === 'string' || !('asset' in entry)) {
      const payload = resolveIconAssetReference(
        entry as IconAssetReference,
        registry
      );
      if (payload) {
        resolved.push(payload);
      }
      return;
    }
    const payload = resolveIconAssetReference(entry.asset, registry);
    if (payload) {
      const overlays: GearAppearanceAsset[] = [];
      for (const overlay of entry.overlays || []) {
        const overlayPayload = resolveIconAssetReference(
          overlay.asset,
          registry
        );
        if (!overlayPayload) {
          return;
        }
        overlays.push({ ...overlay, asset: overlayPayload });
      }
      const maskAsset = resolveIconAssetReference(entry.mask_asset, registry);
      if (entry.mask_asset && !maskAsset) {
        return;
      }
      resolved.push({
        ...entry,
        asset: payload,
        overlays: overlays.length ? overlays : undefined,
        mask_asset: maskAsset,
      });
    }
  });
  return resolved.length ? resolved : undefined;
};

const createPayloadSignature = (payload: IconAssetPayload): string => {
  const cached = payloadSignatureCache.get(payload);
  if (cached) {
    return cached;
  }
  const signature = [
    payload.width,
    payload.height,
    normalizeShift(payload.shift_x),
    normalizeShift(payload.shift_y),
    payload.png || '',
    payload.atlas || '',
    payload.atlas_x || 0,
    payload.atlas_y || 0,
    normalizeShift(payload.tone),
  ].join(':');
  payloadSignatureCache.set(payload, signature);
  return signature;
};

export const getIconAssetRasterIdentity = (
  reference?: IconAssetReference | null
): string | null => {
  const payload = resolveIconAssetReference(reference);
  if (!payload?.token) {
    return null;
  }
  return [
    'icon-raster-v1',
    payload.token,
    createPayloadSignature(payload),
    `colors:${JSON.stringify(payload.colors || [])}`,
  ].join('|');
};

const buildGearAppearanceRasterIdentity = (
  entry: GearAppearanceAsset
): string | null => {
  const assetIdentity = getIconAssetRasterIdentity(entry.asset);
  if (!assetIdentity) {
    return null;
  }
  return [
    assetIdentity,
    `colors:${JSON.stringify(entry.colors || [])}`,
    `alpha:${entry.alpha ?? 255}`,
    `shift:${entry.shift_x ?? 0},${entry.shift_y ?? 0}`,
    `blend:${entry.blend || 'overlay'}`,
  ].join('|');
};

export const getGearPreviewRasterIdentity = (
  entry?: GearOverlayAsset | IconAssetPayload | null
): string | null => {
  if (!entry) {
    return null;
  }
  if (!('asset' in entry)) {
    return getIconAssetRasterIdentity(entry);
  }
  const baseIdentity = buildGearAppearanceRasterIdentity(entry);
  if (!baseIdentity) {
    return null;
  }
  const overlayIdentities = (entry.overlays || []).map(
    buildGearAppearanceRasterIdentity
  );
  if (overlayIdentities.some((identity) => !identity)) {
    return null;
  }
  const maskIdentity = entry.mask_asset
    ? getIconAssetRasterIdentity(entry.mask_asset)
    : null;
  if (entry.mask_asset && !maskIdentity) {
    return null;
  }
  return [
    'gear-raster-v1',
    baseIdentity,
    `overlays:${overlayIdentities.join(';')}`,
    `mask:${maskIdentity || 'none'}`,
  ].join('|');
};

const payloadMatchesCache = (
  cached: IconDecodedAsset | undefined,
  payload: IconAssetPayload,
  signature: string
): boolean => !!cached && createPayloadSignature(cached.payload) === signature;

const buildCacheKey = (token: string, signature: string) =>
  `${token}:${signature}`;

const getPreviewWorkTime = () =>
  typeof performance !== 'undefined' && performance.now
    ? performance.now()
    : Date.now();

const discardInactivePreviewWork = (queue: ScheduledPreviewWork[]) => {
  while (queue.length && (queue[0].cancelled || queue[0].completed)) {
    queue.shift();
  }
};

const hasQueuedPreviewWork = (priority: CharacterPreviewWorkPriority) => {
  const queue =
    priority === 'visible'
      ? visiblePreviewWorkQueue
      : backgroundPreviewWorkQueue;
  discardInactivePreviewWork(queue);
  return queue.length > 0;
};

const cancelScheduledPreviewWorkRun = () => {
  if (previewWorkTimer !== null) {
    clearTimeout(previewWorkTimer);
    previewWorkTimer = null;
  }
  if (
    previewWorkFrame !== null &&
    typeof window !== 'undefined' &&
    window.cancelAnimationFrame
  ) {
    window.cancelAnimationFrame(previewWorkFrame);
    previewWorkFrame = null;
  }
  previewWorkScheduledPriority = null;
};

const dequeuePreviewWork = (): ScheduledPreviewWork | null => {
  const dequeue = (
    queue: ScheduledPreviewWork[],
    priority: CharacterPreviewWorkPriority
  ) => {
    while (queue.length) {
      const entry = queue.shift() as ScheduledPreviewWork;
      if (!entry.cancelled && !entry.completed && entry.priority === priority) {
        return entry;
      }
    }
    return null;
  };
  return (
    dequeue(visiblePreviewWorkQueue, 'visible') ||
    dequeue(backgroundPreviewWorkQueue, 'background')
  );
};

const requestPreviewWorkRun = () => {
  const nextPriority = hasQueuedPreviewWork('visible')
    ? 'visible'
    : hasQueuedPreviewWork('background')
      ? 'background'
      : null;
  if (!nextPriority) {
    cancelScheduledPreviewWorkRun();
    return;
  }
  if (previewWorkScheduledPriority === nextPriority) {
    return;
  }
  cancelScheduledPreviewWorkRun();
  previewWorkScheduledPriority = nextPriority;
  const scheduleTimer = () => {
    previewWorkFrame = null;
    previewWorkTimer = setTimeout(
      processPreviewWorkQueue,
      nextPriority === 'visible' ? 0 : PREVIEW_BACKGROUND_DELAY_MS
    );
  };
  if (
    typeof window !== 'undefined' &&
    typeof window.requestAnimationFrame === 'function'
  ) {
    previewWorkFrame = window.requestAnimationFrame(scheduleTimer);
    return;
  }
  scheduleTimer();
};

const processPreviewWorkQueue = () => {
  previewWorkTimer = null;
  previewWorkScheduledPriority = null;
  const startedAt = getPreviewWorkTime();
  let processed = 0;
  while (processed < PREVIEW_WORK_MAX_TASKS_PER_BATCH) {
    const entry = dequeuePreviewWork();
    if (!entry) {
      break;
    }
    entry.completed = true;
    try {
      entry.work();
    } catch (error) {
      setTimeout(() => {
        throw error;
      }, 0);
    }
    processed += 1;
    if (getPreviewWorkTime() - startedAt >= PREVIEW_WORK_BUDGET_MS) {
      break;
    }
  }
  requestPreviewWorkRun();
};

export const scheduleCharacterPreviewWork = (
  work: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
): CharacterPreviewWorkHandle => {
  const entry: ScheduledPreviewWork = {
    work,
    priority,
    cancelled: false,
    completed: false,
  };
  const queue =
    priority === 'visible'
      ? visiblePreviewWorkQueue
      : backgroundPreviewWorkQueue;
  queue.push(entry);
  requestPreviewWorkRun();
  return {
    cancel: () => {
      if (entry.completed || entry.cancelled) {
        return;
      }
      entry.cancelled = true;
      requestPreviewWorkRun();
    },
    promote: () => {
      if (entry.completed || entry.cancelled || entry.priority === 'visible') {
        return;
      }
      entry.priority = 'visible';
      visiblePreviewWorkQueue.push(entry);
      requestPreviewWorkRun();
    },
  };
};

const flushAssetUpdateCallbacks = () => {
  assetUpdateFlushTimer = null;
  assetUpdateFlushFrame = null;
  const callbacks = Array.from(pendingAssetUpdateCallbacks);
  pendingAssetUpdateCallbacks.clear();
  for (const callback of callbacks) {
    callback();
  }
};

const requestAssetUpdateFlush = () => {
  if (assetUpdateFlushTimer !== null || assetUpdateFlushFrame !== null) {
    return;
  }
  const scheduleTimer = () => {
    assetUpdateFlushFrame = null;
    assetUpdateFlushTimer = setTimeout(flushAssetUpdateCallbacks, 0);
  };
  if (
    typeof window !== 'undefined' &&
    typeof window.requestAnimationFrame === 'function'
  ) {
    assetUpdateFlushFrame = window.requestAnimationFrame(scheduleTimer);
    return;
  }
  scheduleTimer();
};

const queueAssetUpdateCallbacks = (callbacks?: Set<() => void>) => {
  if (!callbacks?.size) {
    return;
  }
  callbacks.forEach((callback) => pendingAssetUpdateCallbacks.add(callback));
  requestAssetUpdateFlush();
};

const registerAssetUpdateListener = (
  cacheKey: string,
  onUpdated: () => void
) => {
  if (!assetUpdateListeners[cacheKey]) {
    assetUpdateListeners[cacheKey] = new Set();
  }
  assetUpdateListeners[cacheKey]?.add(onUpdated);
};

const getCachedDecodedAsset = (cacheKey: string) => {
  const cached = decodedAssetCache.get(cacheKey);
  if (!cached) {
    return undefined;
  }
  decodedAssetCache.delete(cacheKey);
  decodedAssetCache.set(cacheKey, cached);
  return cached;
};

const storeDecodedAsset = (cacheKey: string, asset: IconDecodedAsset) => {
  decodedAssetCache.delete(cacheKey);
  decodedAssetCache.set(cacheKey, asset);
  while (decodedAssetCache.size > MAX_DECODED_ASSETS) {
    const oldestKey = decodedAssetCache.keys().next().value as
      | string
      | undefined;
    if (!oldestKey) {
      break;
    }
    const oldest = decodedAssetCache.get(oldestKey);
    decodedAssetCache.delete(oldestKey);
    if (oldest) {
      const token = oldest.payload.token;
      const signature = createPayloadSignature(oldest.payload);
      if (
        lastSignatureByToken.get(token) === signature &&
        !decodingAssetPromises[oldestKey]
      ) {
        lastSignatureByToken.delete(token);
      }
    }
  }
};

const preferPreviewWorkPriority = (
  current: CharacterPreviewWorkPriority | undefined,
  requested: CharacterPreviewWorkPriority
): CharacterPreviewWorkPriority =>
  current === 'visible' || requested === 'visible' ? 'visible' : 'background';

const getAtlasScratchCanvas = (width: number, height: number) => {
  const key = `${width}x${height}`;
  const existing = atlasScratchCanvases.get(key);
  if (existing) {
    atlasScratchCanvases.delete(key);
    atlasScratchCanvases.set(key, existing);
    return existing;
  }
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  atlasScratchCanvases.set(key, canvas);
  while (atlasScratchCanvases.size > MAX_ATLAS_SCRATCH_CANVASES) {
    const oldestKey = atlasScratchCanvases.keys().next().value as
      | string
      | undefined;
    if (!oldestKey) {
      break;
    }
    atlasScratchCanvases.delete(oldestKey);
  }
  return canvas;
};

const hashPayloadSignature = (signature: string) => {
  let hash = 2166136261;
  for (let index = 0; index < signature.length; index += 1) {
    hash ^= signature.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(36);
};

export const getIconAssetReadinessSignature = (
  payloads: Array<IconAssetReference | null | undefined>
) => {
  const seen = new Set<string>();
  const signatureParts: string[] = [];
  for (const reference of payloads) {
    const payload = resolveIconAssetReference(reference);
    if (!payload?.token || (!payload.png && !payload.atlas)) {
      continue;
    }
    const payloadSignature = createPayloadSignature(payload);
    const cacheKey = buildCacheKey(payload.token, payloadSignature);
    if (seen.has(cacheKey)) {
      continue;
    }
    seen.add(cacheKey);
    const cached = decodedAssetCache.get(cacheKey);
    const status = payloadMatchesCache(cached, payload, payloadSignature)
      ? 'ready'
      : decodingAssetPromises[cacheKey]
        ? 'pending'
        : 'idle';
    signatureParts.push(
      `${payload.token}:${hashPayloadSignature(payloadSignature)}:${status}`
    );
  }
  return signatureParts.join('|');
};

export const areIconAssetsReady = (
  payloads: Array<IconAssetReference | null | undefined>
) => {
  for (const reference of payloads) {
    const payload = resolveIconAssetReference(reference);
    if (!payload?.token || (!payload.png && !payload.atlas)) {
      continue;
    }
    const signature = createPayloadSignature(payload);
    const cached = decodedAssetCache.get(
      buildCacheKey(payload.token, signature)
    );
    if (!payloadMatchesCache(cached, payload, signature)) {
      return false;
    }
  }
  return true;
};

export const getReferenceGridFromAsset = (
  reference: IconAssetReference | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
): string[][] | null => {
  const payload = resolveIconAssetReference(reference);
  const asset = ensureDecodedAsset(payload, onUpdated, priority);
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
  reference: IconAssetReference | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
): string[][] | null => {
  const payload = resolveIconAssetReference(reference);
  const asset = ensureDecodedAsset(payload, onUpdated, priority);
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
  assets: IconAssetReference[] | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
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
      onUpdated,
      priority
    );
    if (grid) {
      layers.push(grid as string[][]);
    }
  }
  return layers.length ? layers : null;
};

const gearPreviewGridCache = new WeakMap<
  GearOverlayAsset,
  Map<string, string[][]>
>();

const gearNamedColors: Record<string, string> = {
  aqua: '#00ffff',
  black: '#000000',
  blue: '#0000ff',
  fuchsia: '#ff00ff',
  gray: '#808080',
  green: '#00c000',
  grey: '#808080',
  lime: '#00ff00',
  maroon: '#800000',
  navy: '#000080',
  olive: '#808000',
  orange: '#ffa500',
  purple: '#800080',
  red: '#ff0000',
  silver: '#c0c0c0',
  teal: '#008080',
  transparent: '#00000000',
  white: '#ffffff',
  yellow: '#ffff00',
};

const parseGearColor = (
  value?: string | null
): [number, number, number, number] | null => {
  if (!value || typeof value !== 'string') {
    return null;
  }
  const normalized = value.startsWith('#')
    ? value
    : gearNamedColors[value.toLowerCase()];
  if (!normalized) {
    return null;
  }
  let raw = normalized.slice(1);
  if (raw.length === 3 || raw.length === 4) {
    raw = raw
      .split('')
      .map((channel) => `${channel}${channel}`)
      .join('');
  }
  if (raw.length !== 6 && raw.length !== 8) {
    return null;
  }
  const channels = [
    parseInt(raw.slice(0, 2), 16),
    parseInt(raw.slice(2, 4), 16),
    parseInt(raw.slice(4, 6), 16),
    raw.length === 8 ? parseInt(raw.slice(6, 8), 16) : 255,
  ];
  return channels.some((channel) => Number.isNaN(channel))
    ? null
    : (channels as [number, number, number, number]);
};

const parseGridColor = (
  value?: string | null
): [number, number, number, number] | null => {
  if (!value || typeof value !== 'string') {
    return null;
  }
  return parseGearColor(value);
};

const cloneGearGrid = (grid: string[][]): (string | null)[][] =>
  grid.map((column) => (Array.isArray(column) ? [...column] : []));

const clampGearChannel = (value: number): number =>
  Math.max(0, Math.min(255, Math.round(value)));

export const applyGearColorMatrix = (
  channels: [number, number, number, number],
  matrix: number[]
): [number, number, number, number] => {
  const [red, green, blue, alpha] = channels;
  if (matrix.length === 9 || matrix.length === 12) {
    const redOffset = matrix.length === 12 ? matrix[9] * 255 : 0;
    const greenOffset = matrix.length === 12 ? matrix[10] * 255 : 0;
    const blueOffset = matrix.length === 12 ? matrix[11] * 255 : 0;
    return [
      clampGearChannel(
        red * matrix[0] + green * matrix[3] + blue * matrix[6] + redOffset
      ),
      clampGearChannel(
        red * matrix[1] + green * matrix[4] + blue * matrix[7] + greenOffset
      ),
      clampGearChannel(
        red * matrix[2] + green * matrix[5] + blue * matrix[8] + blueOffset
      ),
      alpha,
    ];
  }
  if (matrix.length === 16 || matrix.length === 20) {
    const offsets =
      matrix.length === 20
        ? matrix.slice(16, 20).map((value) => value * 255)
        : [];
    return [
      clampGearChannel(
        red * matrix[0] +
          green * matrix[4] +
          blue * matrix[8] +
          alpha * matrix[12] +
          (offsets[0] || 0)
      ),
      clampGearChannel(
        red * matrix[1] +
          green * matrix[5] +
          blue * matrix[9] +
          alpha * matrix[13] +
          (offsets[1] || 0)
      ),
      clampGearChannel(
        red * matrix[2] +
          green * matrix[6] +
          blue * matrix[10] +
          alpha * matrix[14] +
          (offsets[2] || 0)
      ),
      clampGearChannel(
        red * matrix[3] +
          green * matrix[7] +
          blue * matrix[11] +
          alpha * matrix[15] +
          (offsets[3] || 0)
      ),
    ];
  }
  return channels;
};

const transformGearGrid = (
  source: string[][],
  component: GearAppearanceAsset
): (string | null)[][] => {
  let grid = cloneGearGrid(source);
  const colors = Array.isArray(component.colors) ? component.colors : [];
  const alpha =
    typeof component.alpha === 'number'
      ? Math.max(0, Math.min(255, component.alpha))
      : 255;
  if (colors.length || alpha < 255) {
    for (let x = 0; x < grid.length; x += 1) {
      const column = grid[x];
      for (let y = 0; y < column.length; y += 1) {
        const pixel = parseGridColor(column[y]);
        if (!pixel) {
          continue;
        }
        let transformed = pixel;
        for (const color of colors) {
          if (Array.isArray(color)) {
            transformed = applyGearColorMatrix(transformed, color);
            continue;
          }
          const tint = parseGearColor(color);
          if (!tint) {
            continue;
          }
          transformed = [
            Math.round((transformed[0] * tint[0]) / 255),
            Math.round((transformed[1] * tint[1]) / 255),
            Math.round((transformed[2] * tint[2]) / 255),
            Math.round((transformed[3] * tint[3]) / 255),
          ];
        }
        const [red, green, blue, transformedAlpha] = transformed;
        let pixelAlpha = transformedAlpha;
        pixelAlpha = Math.round((pixelAlpha * alpha) / 255);
        column[y] =
          pixelAlpha > 0 ? rgbaToHex(red, green, blue, pixelAlpha) : null;
      }
    }
  }
  const shiftX = normalizeShift(component.shift_x);
  const shiftY = normalizeShift(component.shift_y);
  if (shiftX || shiftY) {
    grid = translateGrid(grid, shiftX, -shiftY);
  }
  return grid;
};

const compositeGearPixel = (
  base?: string | null,
  overlay?: string | null
): string | null => {
  const source = parseGridColor(overlay);
  if (!source || source[3] <= 0) {
    return base || null;
  }
  const target = parseGridColor(base);
  if (!target || target[3] <= 0 || source[3] >= 255) {
    return overlay || null;
  }
  const [sourceRed, sourceGreen, sourceBlue, sourceAlphaRaw] = source;
  const [targetRed, targetGreen, targetBlue, targetAlphaRaw] = target;
  const sourceAlpha = sourceAlphaRaw / 255;
  const targetAlpha = targetAlphaRaw / 255;
  const outputAlpha = sourceAlpha + targetAlpha * (1 - sourceAlpha);
  if (outputAlpha <= 0) {
    return null;
  }
  return rgbaToHex(
    Math.round(
      (sourceRed * sourceAlpha + targetRed * targetAlpha * (1 - sourceAlpha)) /
        outputAlpha
    ),
    Math.round(
      (sourceGreen * sourceAlpha +
        targetGreen * targetAlpha * (1 - sourceAlpha)) /
        outputAlpha
    ),
    Math.round(
      (sourceBlue * sourceAlpha +
        targetBlue * targetAlpha * (1 - sourceAlpha)) /
        outputAlpha
    ),
    Math.round(outputAlpha * 255)
  );
};

const addGearPixel = (
  base?: string | null,
  overlay?: string | null
): string | null => {
  const source = parseGridColor(overlay);
  if (!source || source[3] <= 0) {
    return base || null;
  }
  const target = parseGridColor(base) || [0, 0, 0, 0];
  const alphaFactor = source[3] / 255;
  return rgbaToHex(
    Math.min(255, target[0] + Math.round(source[0] * alphaFactor)),
    Math.min(255, target[1] + Math.round(source[1] * alphaFactor)),
    Math.min(255, target[2] + Math.round(source[2] * alphaFactor)),
    Math.max(target[3], source[3])
  );
};

const mergeGearGrid = (
  target: (string | null)[][],
  source: (string | null)[][],
  blend?: GearAppearanceAsset['blend']
) => {
  for (let x = 0; x < source.length; x += 1) {
    const sourceColumn = source[x];
    if (!Array.isArray(sourceColumn)) {
      continue;
    }
    if (!Array.isArray(target[x])) {
      target[x] = [];
    }
    for (let y = 0; y < sourceColumn.length; y += 1) {
      target[x][y] =
        blend === 'add'
          ? addGearPixel(target[x][y], sourceColumn[y])
          : compositeGearPixel(target[x][y], sourceColumn[y]);
    }
  }
};

const applyGearMask = (target: (string | null)[][], mask: string[][]) => {
  for (let x = 0; x < target.length; x += 1) {
    const targetColumn = target[x];
    const maskColumn = mask[x];
    for (let y = 0; y < targetColumn.length; y += 1) {
      const targetPixel = parseGridColor(targetColumn[y]);
      const maskPixel = parseGridColor(maskColumn?.[y]);
      if (!targetPixel || !maskPixel || maskPixel[3] <= 0) {
        targetColumn[y] = null;
        continue;
      }
      targetColumn[y] = rgbaToHex(
        targetPixel[0],
        targetPixel[1],
        targetPixel[2],
        Math.round((targetPixel[3] * maskPixel[3]) / 255)
      );
    }
  }
};

export const composeGearPreviewGrid = (
  baseGrid: string[][],
  entry: GearAppearanceAsset,
  overlayGrids: Array<{
    component: GearAppearanceAsset;
    grid: string[][];
  }> = [],
  maskGrid?: string[][] | null
): string[][] => {
  const result = transformGearGrid(baseGrid, entry);
  for (const overlay of overlayGrids) {
    mergeGearGrid(
      result,
      transformGearGrid(overlay.grid, overlay.component),
      overlay.component.blend
    );
  }
  if (maskGrid) {
    applyGearMask(result, maskGrid);
  }
  return result as string[][];
};

export const getPreviewGridFromGearAsset = (
  entry: GearOverlayAsset | IconAssetPayload,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
): string[][] | null => {
  if (!entry || !('asset' in entry)) {
    return getPreviewGridFromAsset(
      entry as IconAssetPayload,
      canvasWidth,
      canvasHeight,
      onUpdated,
      priority
    );
  }
  const cacheKey = `${canvasWidth}x${canvasHeight}`;
  const cached = gearPreviewGridCache.get(entry)?.get(cacheKey);
  if (cached) {
    return cached;
  }
  const baseGrid = getPreviewGridFromAsset(
    entry.asset,
    canvasWidth,
    canvasHeight,
    onUpdated,
    priority
  );
  let hasPendingComponent = !baseGrid;
  const overlayGrids: Array<{
    component: GearAppearanceAsset;
    grid: string[][];
  }> = [];
  for (const component of entry.overlays || []) {
    const grid = getPreviewGridFromAsset(
      component.asset,
      canvasWidth,
      canvasHeight,
      onUpdated,
      priority
    );
    if (!grid) {
      hasPendingComponent = true;
      continue;
    }
    overlayGrids.push({ component, grid: grid as string[][] });
  }
  const maskGrid = entry.mask_asset
    ? getPreviewGridFromAsset(
        entry.mask_asset,
        canvasWidth,
        canvasHeight,
        onUpdated,
        priority
      )
    : null;
  if (entry.mask_asset && !maskGrid) {
    hasPendingComponent = true;
  }
  if (hasPendingComponent || !baseGrid) {
    return null;
  }
  const resolved = composeGearPreviewGrid(
    baseGrid as string[][],
    entry,
    overlayGrids,
    maskGrid as string[][] | null
  );
  let cache = gearPreviewGridCache.get(entry);
  if (!cache) {
    cache = new Map();
    gearPreviewGridCache.set(entry, cache);
  }
  cache.set(cacheKey, resolved);
  return resolved;
};

export const getPreviewGridMapFromGearAssets = (
  assets: Array<GearOverlayAsset | IconAssetPayload> | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
): Record<string, string[][]> | null => {
  if (!Array.isArray(assets) || !assets.length) {
    return null;
  }
  const map: Record<string, string[][]> = {};
  let counter = 0;
  for (const entry of assets) {
    const grid = getPreviewGridFromGearAsset(
      entry,
      canvasWidth,
      canvasHeight,
      onUpdated,
      priority
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

const partAppearanceGridCache = new WeakMap<
  IconAssetPayload,
  Map<string, string[][]>
>();

const applyPartAssetColors = (
  payload: IconAssetPayload,
  grid: string[][],
  cacheKey: string
): string[][] => {
  if (!Array.isArray(payload.colors) || !payload.colors.length) {
    return grid;
  }
  let cache = partAppearanceGridCache.get(payload);
  const cached = cache?.get(cacheKey);
  if (cached) {
    return cached;
  }
  const transformed = transformGearGrid(grid, {
    asset: payload,
    colors: payload.colors,
  }) as string[][];
  if (!cache) {
    cache = new Map();
    partAppearanceGridCache.set(payload, cache);
  }
  cache.set(cacheKey, transformed);
  return transformed;
};

export const getReferencePartMapFromAssets = (
  assets: Record<string, IconAssetPayload> | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
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
      onUpdated,
      priority
    );
    if (!grid) {
      continue;
    }
    result[partId] = applyPartAssetColors(
      payload,
      grid as string[][],
      `reference:${canvasWidth}x${canvasHeight}`
    );
    changed = true;
  }
  return changed ? result : null;
};

export const getPreviewPartMapFromAssets = (
  assets: Record<string, IconAssetPayload> | undefined,
  canvasWidth: number,
  canvasHeight: number,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority = 'visible'
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
      onUpdated,
      priority
    );
    if (!grid) {
      continue;
    }
    result[partId] = applyPartAssetColors(
      payload,
      grid as string[][],
      `preview:${canvasWidth}x${canvasHeight}`
    );
    changed = true;
  }
  return changed ? result : null;
};

const ensureDecodedAsset = (
  payload: IconAssetPayload | undefined,
  onUpdated: () => void,
  priority: CharacterPreviewWorkPriority
): IconDecodedAsset | null => {
  if (!payload || !payload.token || (!payload.png && !payload.atlas)) {
    return null;
  }
  const token = payload.token;
  const signature = createPayloadSignature(payload);
  const cacheKey = buildCacheKey(token, signature);
  const cached = getCachedDecodedAsset(cacheKey);
  if (cached && payloadMatchesCache(cached, payload, signature)) {
    return cached;
  }
  registerAssetUpdateListener(cacheKey, onUpdated);
  const previousSignature = lastSignatureByToken.get(token);
  if (previousSignature && previousSignature !== signature) {
    const previousKey = buildCacheKey(token, previousSignature);
    decodedAssetCache.delete(previousKey);
    delete decodingAssetPromises[previousKey];
    delete decodingAssetSignatures[previousKey];
    delete decodingAssetPriorities[previousKey];
    delete decodingAssetWorkHandles[previousKey];
    delete assetUpdateListeners[previousKey];
  }
  lastSignatureByToken.set(token, signature);
  decodingAssetPriorities[cacheKey] = preferPreviewWorkPriority(
    decodingAssetPriorities[cacheKey],
    priority
  );
  if (decodingAssetPriorities[cacheKey] === 'visible') {
    decodingAssetWorkHandles[cacheKey]?.promote();
  }
  if (!decodingAssetPromises[cacheKey]) {
    const expectedSignature = signature;
    decodingAssetSignatures[cacheKey] = expectedSignature;
    decodingAssetPromises[cacheKey] = decodeIconAsset(payload, cacheKey)
      .then((decoded) => {
        if (decodingAssetSignatures[cacheKey] === expectedSignature) {
          storeDecodedAsset(cacheKey, decoded);
        }
      })
      .catch(() => {})
      .finally(() => {
        const signatureMatch =
          decodingAssetSignatures[cacheKey] === expectedSignature &&
          lastSignatureByToken.get(token) === expectedSignature;
        const listeners = assetUpdateListeners[cacheKey];
        delete decodingAssetPromises[cacheKey];
        delete decodingAssetSignatures[cacheKey];
        delete decodingAssetPriorities[cacheKey];
        delete decodingAssetWorkHandles[cacheKey];
        delete assetUpdateListeners[cacheKey];
        if (signatureMatch) {
          queueAssetUpdateCallbacks(listeners);
          if (!decodedAssetCache.has(cacheKey)) {
            lastSignatureByToken.delete(token);
          }
        }
      });
  }
  return null;
};

const decodeIconAsset = (
  payload: IconAssetPayload,
  cacheKey: string
): Promise<IconDecodedAsset> => {
  if (payload.atlas) {
    return loadAtlasImage(payload.atlas).then(
      (image) =>
        new Promise<IconDecodedAsset>((resolve, reject) => {
          const handle = scheduleCharacterPreviewWork(() => {
            try {
              const width = Math.max(1, Math.floor(payload.width));
              const height = Math.max(1, Math.floor(payload.height));
              const sourceX = Math.max(0, Math.floor(payload.atlas_x || 0));
              const sourceY = Math.max(0, Math.floor(payload.atlas_y || 0));
              const canvas = getAtlasScratchCanvas(width, height);
              const ctx = canvas.getContext('2d');
              if (!ctx) {
                throw new Error('Failed to acquire 2D context');
              }
              ctx.clearRect(0, 0, width, height);
              ctx.drawImage(
                image,
                sourceX,
                sourceY,
                width,
                height,
                0,
                0,
                width,
                height
              );
              resolve({
                payload,
                imageData: applyPayloadTone(
                  ctx.getImageData(0, 0, width, height),
                  payload.tone
                ),
                shiftX: normalizeShift(payload.shift_x),
                shiftY: normalizeShift(payload.shift_y),
              });
            } catch (error) {
              reject(error);
            }
          }, decodingAssetPriorities[cacheKey] || 'visible');
          decodingAssetWorkHandles[cacheKey] = handle;
          if (decodingAssetPriorities[cacheKey] === 'visible') {
            handle.promote();
          }
        })
    );
  }
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
          imageData: applyPayloadTone(imageData, payload.tone),
          shiftX: normalizeShift(payload.shift_x),
          shiftY: normalizeShift(payload.shift_y),
        });
      } catch (error) {
        reject(error);
      }
    };
    image.onerror = () => reject(new Error('Failed to decode preview asset'));
    image.src = `${dataUriPrefix}${payload.png || ''}`;
  });
};

const applyPayloadTone = (
  imageData: ImageData,
  rawTone?: number | null
): ImageData => {
  const tone = normalizeShift(rawTone);
  if (!tone) {
    return imageData;
  }
  const data = imageData.data;
  for (let index = 0; index < data.length; index += 4) {
    if (!data[index + 3]) {
      continue;
    }
    data[index] = Math.max(0, Math.min(255, data[index] + tone));
    data[index + 1] = Math.max(0, Math.min(255, data[index + 1] + tone));
    data[index + 2] = Math.max(0, Math.min(255, data[index + 2] + tone));
  }
  return imageData;
};

const loadAtlasImage = (atlasName: string): Promise<HTMLImageElement> => {
  const dynamicSource = dynamicAtlasSources.get(atlasName);
  const url = dynamicSource
    ? `${dataUriPrefix}${dynamicSource}`
    : resolveAsset(atlasName);
  const cacheKey = dynamicSource ? atlasName : url;
  const existing = atlasImagePromises[cacheKey];
  if (existing) {
    return existing;
  }
  const promise = new Promise<HTMLImageElement>((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error('Failed to decode preview atlas'));
    image.src = url;
  }).catch((error) => {
    delete atlasImagePromises[cacheKey];
    throw error;
  });
  atlasImagePromises[cacheKey] = promise;
  return promise;
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
