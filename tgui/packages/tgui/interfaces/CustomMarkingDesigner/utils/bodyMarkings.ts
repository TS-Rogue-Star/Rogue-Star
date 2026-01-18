// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Shared helpers for body markings gallery and parent interactions //
// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex } from '../../../utils/color';
import type {
  BodyMarkingColorTarget,
  BodyMarkingDefinition,
  BodyMarkingEntry,
  BodyMarkingPartState,
  BodyMarkingsPayload,
  BodyMarkingsSavedState,
} from '../types';

const BODY_MARKING_CHUNK_CHAR_BUDGET = 7000;
const BODY_MARKING_CHUNK_ENTRY_CAP = 16;
const BODY_MARKING_CHUNK_OVERHEAD = 256;

export const isBodyMarkingPartEnabled = (value: unknown) =>
  value !== false && value !== 0 && value !== '0';

export const deepCopyMarkings = (value?: Record<string, BodyMarkingEntry>) =>
  JSON.parse(JSON.stringify(value || {}));

export const cloneEntry = <T extends unknown>(entry?: T): T =>
  JSON.parse(JSON.stringify(entry || ({} as T)));

export const normalizeBodyParts = (parts: unknown): string[] => {
  const isPartKey = (key: string) =>
    typeof key === 'string' && key.toLowerCase() !== 'color';
  if (Array.isArray(parts)) {
    return parts.filter(
      (item): item is string => typeof item === 'string' && isPartKey(item)
    );
  }
  if (parts && typeof parts === 'object') {
    const entries = Object.entries(parts);
    const keys = entries
      .filter(
        ([, value]) => value !== null && value !== undefined && value !== false
      )
      .map(([key]) => key)
      .filter((key): key is string => isPartKey(key));
    if (keys.length) {
      return keys;
    }
    const values = entries
      .map(([, value]) => value)
      .filter(
        (value): value is string =>
          typeof value === 'string' && isPartKey(value)
      );
    if (values.length) {
      return values;
    }
  }
  return [];
};

export const buildBodyMarkingDefinitions = (
  payload?: BodyMarkingsPayload | null
): Record<string, BodyMarkingDefinition> =>
  (payload?.body_marking_definitions || []).reduce(
    (acc, def) => {
      acc[def.id] = {
        ...def,
        body_parts: normalizeBodyParts(def.body_parts),
      };
      return acc;
    },
    {} as Record<string, BodyMarkingDefinition>
  );

export const buildBodyPayloadSignature = (
  payload?: BodyMarkingsPayload | null
) => {
  if (!payload) {
    return null;
  }
  const defSignature = (payload.body_marking_definitions || [])
    .map((def) => def.id)
    .join('|');
  const orderSignature = (payload.order || []).join('|');
  const markingSignature = Object.keys(payload.body_markings || {})
    .sort()
    .join('|');
  const revision = payload.preview_revision || 0;
  const size = `${payload.preview_width || 0}x${payload.preview_height || 0}`;
  const digitigrade = payload.digitigrade ? 'd' : 'p';
  return `${revision}:${size}:${digitigrade}:${defSignature}:${orderSignature}:${markingSignature}`;
};

export const buildBodySavedStateFromPayload = (
  payload?: BodyMarkingsPayload | null
): BodyMarkingsSavedState => ({
  order: (payload?.order as string[]) || [],
  markings: deepCopyMarkings(payload?.body_markings),
  selectedId: (payload?.order?.[0] as string) || null,
});

export const buildBodyMarkingSavePayload = ({
  order,
  markings,
  definitions,
}: {
  order: string[];
  markings: Record<string, BodyMarkingEntry>;
  definitions: Record<string, BodyMarkingDefinition>;
}) => {
  const outgoing: Record<string, BodyMarkingEntry> = {};
  order.forEach((markId) => {
    const def = definitions[markId];
    const entry = cloneEntry(markings[markId]);
    if (!entry) {
      return;
    }
    const clean: BodyMarkingEntry = {};
    if (typeof entry.color === 'string') {
      clean.color = normalizeHex(entry.color);
    }
    if (def && def.body_parts) {
      def.body_parts.forEach((partId) => {
        const state = entry[partId] as BodyMarkingPartState;
        const partState: BodyMarkingPartState = {
          on: isBodyMarkingPartEnabled(state?.on),
        };
        if (def.do_colouration && typeof state?.color === 'string') {
          partState.color = normalizeHex(state.color);
        }
        clean[partId] = partState;
      });
      outgoing[markId] = clean;
      return;
    }
    for (const [partId, rawState] of Object.entries(entry)) {
      if (partId === 'color') {
        continue;
      }
      if (!rawState || typeof rawState !== 'object') {
        continue;
      }
      const state = rawState as BodyMarkingPartState;
      const partState: BodyMarkingPartState = {
        on: isBodyMarkingPartEnabled(state.on),
      };
      if (typeof state.color === 'string') {
        partState.color = normalizeHex(state.color);
      }
      clean[partId] = partState;
    }
    outgoing[markId] = clean;
  });
  return {
    order,
    body_markings: outgoing,
  };
};

const estimateChunkSize = (
  chunk: Record<string, BodyMarkingEntry>,
  includeOrder: boolean,
  order: string[]
) => {
  try {
    return (
      JSON.stringify({
        body_markings: chunk,
        ...(includeOrder ? { order } : {}),
      }).length + BODY_MARKING_CHUNK_OVERHEAD
    );
  } catch {
    return Number.MAX_SAFE_INTEGER;
  }
};

const createChunkId = () => {
  try {
    const maybeCrypto =
      typeof globalThis !== 'undefined'
        ? (globalThis as { crypto?: Crypto }).crypto
        : undefined;
    if (maybeCrypto && typeof maybeCrypto.randomUUID === 'function') {
      return maybeCrypto.randomUUID();
    }
  } catch {}
  return `bm-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
};

export const buildBodyMarkingChunkPlan = ({
  order,
  markings,
  maxPayloadChars = BODY_MARKING_CHUNK_CHAR_BUDGET,
  maxEntriesPerChunk = BODY_MARKING_CHUNK_ENTRY_CAP,
  chunkId,
}: {
  order: string[];
  markings: Record<string, BodyMarkingEntry>;
  maxPayloadChars?: number;
  maxEntriesPerChunk?: number;
  chunkId?: string;
}): { chunkId: string; chunks: Record<string, BodyMarkingEntry>[] } => {
  const entryLimit = Math.max(1, maxEntriesPerChunk || 1);
  const safeOrder =
    Array.isArray(order) && order.length
      ? order.filter((id): id is string => typeof id === 'string')
      : Object.keys(markings || {}).filter(
          (id): id is string => typeof id === 'string'
        );
  const chunks: Record<string, BodyMarkingEntry>[] = [];
  let current: Record<string, BodyMarkingEntry> = {};
  let entryCount = 0;
  let includeOrder = true;
  const pushChunk = () => {
    chunks.push(current);
    current = {};
    entryCount = 0;
    includeOrder = false;
  };
  for (const markId of safeOrder) {
    const entry = markings?.[markId];
    if (!entry) {
      continue;
    }
    const nextChunk = { ...current, [markId]: entry };
    const exceedsEntryLimit =
      Object.keys(nextChunk).length > entryLimit && entryCount > 0;
    const exceedsBudget =
      maxPayloadChars > 0 &&
      estimateChunkSize(nextChunk, includeOrder, safeOrder) > maxPayloadChars &&
      entryCount > 0;
    if (exceedsEntryLimit || exceedsBudget) {
      pushChunk();
    }
    current[markId] = entry;
    entryCount += 1;
  }
  if (entryCount > 0 || !chunks.length) {
    pushChunk();
  }
  return {
    chunkId: chunkId || createChunkId(),
    chunks,
  };
};

export const resolveBodyMarkingColorTarget = (
  target: BodyMarkingColorTarget | null,
  definitions: Record<string, BodyMarkingDefinition>,
  markings: Record<string, BodyMarkingEntry>
): BodyMarkingColorTarget | null => {
  if (target?.type === 'galleryPreview') {
    return target;
  }
  if (
    target?.type === 'mark' &&
    definitions[target.markId] &&
    markings[target.markId] &&
    definitions[target.markId].do_colouration &&
    (!target.partId ||
      definitions[target.markId].body_parts?.includes(target.partId))
  ) {
    return target;
  }
  return null;
};
