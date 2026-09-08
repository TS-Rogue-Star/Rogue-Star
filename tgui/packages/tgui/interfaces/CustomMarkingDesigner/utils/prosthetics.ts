// ///////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer prosthetics utilities //
// ///////////////////////////////////////////////////////////////////////////////////////

import {
  getStaticProstheticCatalog,
  gridHasPixels,
  resolveIconAssetReference,
  type GearColorTransform,
  type GearOverlayAssetReference,
  type IconAssetReference,
  type PreviewLayerEntry,
  type PreviewLayerGroup,
  type PreviewLayerRasterDependency,
  type PreviewDirectionSource,
  type ProstheticCatalog,
  type ProstheticCatalogModel,
} from '../../../utils/character-preview';
import type {
  BasicAppearanceState,
  BasicProstheticContext,
  InternalOrganProstheticDefinition,
  InternalOrganOperation,
  LimbOperation,
  LimbOverrideEntry,
  LimbOverrideState,
} from '../types';

export const PROSTHETIC_TARGETS = [
  'full_body',
  'torso',
  'groin',
  'l_leg',
  'r_leg',
  'l_arm',
  'r_arm',
  'l_foot',
  'r_foot',
  'l_hand',
  'r_hand',
  'head',
] as const;

export type ProstheticTarget = (typeof PROSTHETIC_TARGETS)[number];

export type ProstheticColorMode = 'none' | 'prosthetic' | 'body';

export const PROSTHETIC_COLOR_MODE_DETAILS: Record<
  ProstheticColorMode,
  { label: string; description: string }
> = {
  none: {
    label: 'No Recoloring',
    description: "Keeps the chassis's authored colors.",
  },
  prosthetic: {
    label: 'Prosthetic Color',
    description: 'Uses the selected prosthetic color when enabled.',
  },
  body: {
    label: 'Body Color',
    description: "Follows the character's skin tone or body color.",
  },
};

const followsBodyAppearance = (
  model: ProstheticCatalogModel | null | undefined
): boolean => !!(model?.skin_tone || model?.skin_color);

export const resolveProstheticColorMode = (
  model: ProstheticCatalogModel | null | undefined
): ProstheticColorMode => {
  if (followsBodyAppearance(model)) {
    return 'body';
  }
  return model ? 'prosthetic' : 'none';
};

export const resolveProstheticModelColorMode = (
  modelId: string | null | undefined,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): ProstheticColorMode =>
  resolveProstheticColorMode(modelId ? catalog?.models?.[modelId] : null);

export const PROSTHETIC_TARGET_LABELS: Record<ProstheticTarget, string> = {
  full_body: 'Full Body',
  torso: 'Torso',
  groin: 'Groin',
  l_leg: 'Left Leg',
  r_leg: 'Right Leg',
  l_arm: 'Left Arm',
  r_arm: 'Right Arm',
  l_foot: 'Left Foot',
  r_foot: 'Right Foot',
  l_hand: 'Left Hand',
  r_hand: 'Right Hand',
  head: 'Head',
};

export const INTERNAL_ORGAN_DEFINITIONS: readonly InternalOrganProstheticDefinition[] =
  [
    {
      id: 'heart',
      label: 'Heart',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'eyes',
      label: 'Eyes',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'voicebox',
      label: 'Larynx',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'lungs',
      label: 'Lungs',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'liver',
      label: 'Liver',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'kidneys',
      label: 'Kidneys',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'spleen',
      label: 'Spleen',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'intestine',
      label: 'Intestines',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'stomach',
      label: 'Stomach',
      allowed_states: ['normal', 'assisted', 'mechanical'],
    },
    {
      id: 'brain',
      label: 'Brain',
      allowed_states: ['normal', 'assisted', 'mechanical', 'digital'],
    },
  ];

export type InternalOrganId = string;

const EXTERNAL_PARTS = [
  'head',
  'torso',
  'groin',
  'l_leg',
  'r_leg',
  'l_arm',
  'r_arm',
  'l_foot',
  'r_foot',
  'l_hand',
  'r_hand',
] as const;

const PROSTHETIC_GALLERY_BODY_PARTS = [
  'torso',
  'head',
  'groin',
  'l_arm',
  'r_arm',
  'l_hand',
  'r_hand',
  'l_leg',
  'r_leg',
  'l_foot',
  'r_foot',
] as const;

export const PROSTHETIC_GALLERY_COMPOSITE_PART = 'prosthetic_gallery_body';
const PROSTHETIC_GALLERY_COMPOSITE_REVISION = 'gallery-v1';

const PARENT_CHILDREN: Record<string, readonly ProstheticTarget[]> = {
  torso: ['head', 'groin', 'l_arm', 'r_arm'],
  groin: ['l_leg', 'r_leg'],
  l_leg: ['l_foot'],
  r_leg: ['r_foot'],
  l_arm: ['l_hand'],
  r_arm: ['r_hand'],
};

const CHILD_PARENT: Partial<Record<ProstheticTarget, ProstheticTarget>> = {
  groin: 'torso',
  l_leg: 'groin',
  r_leg: 'groin',
  l_arm: 'torso',
  r_arm: 'torso',
  l_foot: 'l_leg',
  r_foot: 'r_leg',
  l_hand: 'l_arm',
  r_hand: 'r_arm',
};

const resolveProstheticAncestors = (
  target: ProstheticTarget
): ProstheticTarget[] => {
  const ancestors: ProstheticTarget[] = [];
  let parent = CHILD_PARENT[target];
  while (parent) {
    ancestors.push(parent);
    parent = CHILD_PARENT[parent];
  }
  return ancestors;
};

const CANONICAL_TARGET_ORDER: ProstheticTarget[] = [
  'torso',
  'groin',
  'l_leg',
  'r_leg',
  'l_arm',
  'r_arm',
  'l_foot',
  'r_foot',
  'l_hand',
  'r_hand',
  'head',
];

export type ProstheticGalleryDefinition = {
  id: string;
  name: string;
  description?: string | null;
  disabled?: boolean;
  disabledReason?: string | null;
  tooltip?: string | null;
  colorMode?: ProstheticColorMode;
};

export type ProstheticSelectionDefinition = ProstheticGalleryDefinition & {
  operationState: LimbOperation['state'];
  model?: string | null;
};

export type InternalOrganChoice = {
  id: string;
  label: string;
};

const INTERNAL_ORGAN_CYCLE_ORDER = [
  'normal',
  'mechanical',
  'assisted',
  'digital',
] as const;

export const resolveNextInternalOrganChoice = (
  choices: readonly InternalOrganChoice[],
  currentState: string
): InternalOrganChoice | null => {
  if (!choices.length) {
    return null;
  }
  const orderedChoices: InternalOrganChoice[] = [];
  for (const state of INTERNAL_ORGAN_CYCLE_ORDER) {
    const choice = choices.find((entry) => entry.id === state);
    if (choice) {
      orderedChoices.push(choice);
    }
  }
  for (const choice of choices) {
    if (!orderedChoices.some((entry) => entry.id === choice.id)) {
      orderedChoices.push(choice);
    }
  }
  const currentIndex = orderedChoices.findIndex(
    (entry) => entry.id === currentState
  );
  return orderedChoices[
    currentIndex < 0 ? 0 : (currentIndex + 1) % orderedChoices.length
  ];
};

export const resolveInternalOrganDefinitions = (
  context?: BasicProstheticContext | null
): InternalOrganProstheticDefinition[] => {
  if (context?.internal_organ_definitions?.length) {
    return context.internal_organ_definitions;
  }
  const allowedIds = new Set(context?.internal_organ_ids || []);
  return INTERNAL_ORGAN_DEFINITIONS.filter((definition) =>
    allowedIds.has(definition.id)
  ).map((definition) => ({
    ...definition,
    allowed_states: [...definition.allowed_states],
  }));
};

export const resolveLockedInternalOrganLabel = (
  definition: InternalOrganProstheticDefinition
): string => {
  if (definition.locked_state === 'mechanical') {
    return 'Mechanical';
  }
  if (definition.locked_state === 'assisted') {
    return 'Assisted';
  }
  return 'Native';
};

export const resolveInternalOrganStateDescription = (
  organ: InternalOrganId,
  state: string
): string => {
  if (organ === 'brain') {
    switch (state) {
      case 'normal':
        return 'A biological brain';
      case 'assisted':
        return 'A preserved organic brain housed in a machine interface (MMI)';
      case 'mechanical':
        return 'A synthetic positronic mind housed in an artificial brain';
      case 'digital':
        return 'A software-based intelligence running on a robotic circuit';
      case 'native':
        return 'The brain type native to this species';
      default:
        return "This species' natural brain type";
    }
  }
  switch (state) {
    case 'normal':
      return 'A biological organ with no mechanical augmentation';
    case 'assisted':
      return 'A biological organ supported or enhanced by machinery, such as a pacemaker';
    case 'mechanical':
      return 'A fully robotic replacement with no organic tissue';
    case 'native':
      return 'The organ type native to this species';
    default:
      return "This species' natural organ type";
  }
};

const normalizeEntry = (
  entry?: LimbOverrideEntry | null
): LimbOverrideEntry => {
  const status =
    entry?.status === 'amputated' || entry?.status === 'cyborg'
      ? entry.status
      : entry?.status || 'normal';
  return {
    status,
    model:
      status === 'cyborg' && typeof entry?.model === 'string'
        ? entry.model
        : null,
  };
};

export const cloneLimbOverrideState = (
  state?: LimbOverrideState | null
): LimbOverrideState => {
  const external: Record<string, LimbOverrideEntry> = {};
  const internal: Record<string, LimbOverrideEntry> = {};
  for (const part of EXTERNAL_PARTS) {
    external[part] = normalizeEntry(state?.external?.[part]);
  }
  for (const organ of INTERNAL_ORGAN_DEFINITIONS) {
    internal[organ.id] = normalizeEntry(state?.internal?.[organ.id]);
  }
  for (const [organ, entry] of Object.entries(state?.internal || {})) {
    if (!internal[organ]) {
      internal[organ] = normalizeEntry(entry);
    }
  }
  return { external, internal };
};

const setExternalEntry = (
  state: LimbOverrideState,
  part: string,
  status: LimbOverrideEntry['status'],
  model?: string | null
) => {
  state.external[part] = {
    status,
    model: status === 'cyborg' ? model || null : null,
  };
};

const resolveNaturalProstheticDescendants = (
  state: LimbOverrideState,
  parent: string
): ProstheticTarget[] => {
  const descendants: ProstheticTarget[] = [];
  for (const child of PARENT_CHILDREN[parent] || []) {
    const status = state.external[child]?.status || 'normal';
    if (status === 'cyborg' || status === 'amputated') {
      continue;
    }
    descendants.push(child);
    descendants.push(...resolveNaturalProstheticDescendants(state, child));
  }
  return descendants;
};

const resolveProstheticOperationParts = (
  state: LimbOverrideState,
  target: ProstheticTarget
): ProstheticTarget[] =>
  target === 'full_body'
    ? [...CANONICAL_TARGET_ORDER]
    : [target, ...resolveNaturalProstheticDescendants(state, target)];

const applyProstheticChassisOrganDefaults = (
  state: LimbOverrideState,
  context?: BasicProstheticContext | null
): LimbOverrideState => {
  const definitions = resolveInternalOrganDefinitions(context);
  if (!context) {
    if (!state.internal.brain || state.internal.brain.status === 'normal') {
      state.internal.brain = { status: 'assisted', model: null };
    }
    state.internal.heart = { status: 'mechanical', model: null };
    state.internal.eyes = { status: 'mechanical', model: null };
    return state;
  }
  for (const definition of definitions) {
    if (!definition.allowed_states.length) {
      if (definition.locked_state) {
        state.internal[definition.id] = {
          status: definition.locked_state,
          model: null,
        };
      }
      continue;
    }
    if (
      !definition.allowed_states.includes(
        state.internal[definition.id]?.status || 'normal'
      )
    ) {
      state.internal[definition.id] = { status: 'normal', model: null };
    }
  }
  const brain = definitions.find((definition) => definition.id === 'brain');
  if (
    brain?.allowed_states.includes('assisted') &&
    (!state.internal.brain || state.internal.brain.status === 'normal')
  ) {
    state.internal.brain = { status: 'assisted', model: null };
  }
  for (const organ of ['heart', 'eyes']) {
    const definition = definitions.find((entry) => entry.id === organ);
    if (definition?.allowed_states.includes('mechanical')) {
      state.internal[organ] = { status: 'mechanical', model: null };
    }
  }
  return state;
};

export const applyLimbOperation = (
  source: LimbOverrideState,
  operation: LimbOperation,
  context?: BasicProstheticContext | null
): LimbOverrideState => {
  const next = cloneLimbOverrideState(source);
  const { target, state, model } = operation;
  if (target === 'full_body') {
    if (state === 'normal') {
      for (const part of EXTERNAL_PARTS) {
        setExternalEntry(next, part, 'normal');
      }
      for (const organ of Object.keys(next.internal)) {
        next.internal[organ] = { status: 'normal', model: null };
      }
      for (const definition of resolveInternalOrganDefinitions(context)) {
        if (!definition.allowed_states.length && definition.locked_state) {
          next.internal[definition.id] = {
            status: definition.locked_state,
            model: null,
          };
        }
      }
      return next;
    }
    if (state !== 'prosthesis' || !model) {
      return next;
    }
    for (const part of EXTERNAL_PARTS) {
      setExternalEntry(next, part, 'cyborg', model);
    }
    return applyProstheticChassisOrganDefaults(next, context);
  }
  if (!CANONICAL_TARGET_ORDER.includes(target as ProstheticTarget)) {
    return next;
  }
  if (state === 'normal') {
    for (const currentTarget of [
      target as ProstheticTarget,
      ...resolveProstheticAncestors(target as ProstheticTarget),
    ]) {
      setExternalEntry(next, currentTarget, 'normal');
      if (currentTarget === 'torso') {
        setExternalEntry(next, 'head', 'normal');
        next.internal.brain = { status: 'normal', model: null };
      }
    }
    return next;
  }
  if (state === 'amputated') {
    if (target === 'torso' || target === 'groin' || target === 'head') {
      return next;
    }
    setExternalEntry(next, target, 'amputated');
    for (const child of PARENT_CHILDREN[target] || []) {
      setExternalEntry(next, child, 'amputated');
    }
    return next;
  }
  if (state !== 'prosthesis' || !model) {
    return next;
  }
  setExternalEntry(next, target, 'cyborg', model);
  for (const child of resolveNaturalProstheticDescendants(next, target)) {
    setExternalEntry(next, child, 'cyborg', model);
  }
  const parent = CHILD_PARENT[target];
  if (parent && next.external[parent]?.status === 'amputated') {
    setExternalEntry(next, parent, 'normal');
  }
  return target === 'torso'
    ? applyProstheticChassisOrganDefaults(next, context)
    : next;
};

export const applyInternalOrganOperation = (
  source: LimbOverrideState,
  operation: InternalOrganOperation
): LimbOverrideState => {
  const next = cloneLimbOverrideState(source);
  if (
    !INTERNAL_ORGAN_DEFINITIONS.some(
      (definition) => definition.id === operation.target
    )
  ) {
    return next;
  }
  next.internal[operation.target] = {
    status: operation.state || 'normal',
    model: null,
  };
  return next;
};

const entriesEqual = (
  left?: LimbOverrideEntry | null,
  right?: LimbOverrideEntry | null
) => {
  const a = normalizeEntry(left);
  const b = normalizeEntry(right);
  return (
    a.status === b.status && (a.status !== 'cyborg' || a.model === b.model)
  );
};

const externalStatesEqual = (
  left?: LimbOverrideState | null,
  right?: LimbOverrideState | null
) => {
  const a = cloneLimbOverrideState(left);
  const b = cloneLimbOverrideState(right);
  return EXTERNAL_PARTS.every((part) =>
    entriesEqual(a.external[part], b.external[part])
  );
};

export const limbOverrideStatesEqual = (
  left?: LimbOverrideState | null,
  right?: LimbOverrideState | null
) => {
  const a = cloneLimbOverrideState(left);
  const b = cloneLimbOverrideState(right);
  if (!externalStatesEqual(a, b)) {
    return false;
  }
  const organs = new Set([
    ...Object.keys(a.internal),
    ...Object.keys(b.internal),
  ]);
  return Array.from(organs).every((organ) =>
    entriesEqual(a.internal[organ], b.internal[organ])
  );
};

export const basicAppearanceStatesEqual = (
  left: BasicAppearanceState,
  right: BasicAppearanceState
) => {
  const normalize = (state: BasicAppearanceState) => {
    const {
      limb_operations: _limbOperations,
      organ_operations: _organOperations,
      ...appearance
    } = state;
    return {
      ...appearance,
      limbs: cloneLimbOverrideState(state.limbs),
    };
  };
  return JSON.stringify(normalize(left)) === JSON.stringify(normalize(right));
};

export const buildCanonicalLimbOperations = (
  saved: LimbOverrideState,
  desired: LimbOverrideState,
  context?: BasicProstheticContext | null
): LimbOperation[] => {
  if (externalStatesEqual(saved, desired)) {
    return [];
  }
  let working = cloneLimbOverrideState(saved);
  const target = cloneLimbOverrideState(desired);
  const operations: LimbOperation[] = [];
  const targetTorso = normalizeEntry(target.external.torso);
  const uniformFullBodyModel =
    targetTorso.status === 'cyborg' &&
    targetTorso.model &&
    EXTERNAL_PARTS.every((part) => {
      const entry = normalizeEntry(target.external[part]);
      return entry.status === 'cyborg' && entry.model === targetTorso.model;
    })
      ? targetTorso.model
      : null;
  const workingHead = normalizeEntry(working.external.head);
  const targetHead = normalizeEntry(target.external.head);
  if (uniformFullBodyModel) {
    const operation: LimbOperation = {
      target: 'full_body',
      state: 'prosthesis',
      model: uniformFullBodyModel,
    };
    operations.push(operation);
    working = applyLimbOperation(working, operation, context);
  } else if (
    targetHead.status === 'normal' &&
    !entriesEqual(workingHead, targetHead)
  ) {
    const operation: LimbOperation = {
      target: 'full_body',
      state: 'normal',
    };
    operations.push(operation);
    working = applyLimbOperation(working, operation, context);
  }
  for (const part of CANONICAL_TARGET_ORDER) {
    if (entriesEqual(working.external[part], target.external[part])) {
      continue;
    }
    const entry = target.external[part];
    const operation: LimbOperation =
      entry?.status === 'cyborg' && entry.model
        ? { target: part, state: 'prosthesis', model: entry.model }
        : {
            target: part,
            state: entry?.status === 'amputated' ? 'amputated' : 'normal',
          };
    operations.push(operation);
    working = applyLimbOperation(working, operation, context);
  }
  return operations.slice(0, 11);
};

export const buildCanonicalOrganOperations = (
  saved: LimbOverrideState,
  desired: LimbOverrideState,
  limbOperations?: LimbOperation[],
  context?: BasicProstheticContext | null
): InternalOrganOperation[] => {
  const resolvedLimbOperations =
    limbOperations || buildCanonicalLimbOperations(saved, desired, context);
  const working = resolvedLimbOperations.reduce(
    (state, operation) => applyLimbOperation(state, operation, context),
    saved
  );
  const target = cloneLimbOverrideState(desired);
  const operations: InternalOrganOperation[] = [];
  const definitions = context
    ? resolveInternalOrganDefinitions(context).filter(
        (definition) => definition.allowed_states.length
      )
    : INTERNAL_ORGAN_DEFINITIONS.map((definition) => ({
        ...definition,
        allowed_states: [...definition.allowed_states],
      }));
  for (const definition of definitions) {
    const targetStatus = target.internal[definition.id]?.status || 'normal';
    if (!definition.allowed_states.includes(targetStatus)) {
      continue;
    }
    if (
      entriesEqual(
        working.internal[definition.id],
        target.internal[definition.id]
      )
    ) {
      continue;
    }
    operations.push({
      target: definition.id,
      state: targetStatus,
    });
  }
  return operations.slice(0, 10);
};

export const buildCanonicalProstheticOperations = (
  saved: LimbOverrideState,
  desired: LimbOverrideState,
  context?: BasicProstheticContext | null
) => {
  const limb_operations = buildCanonicalLimbOperations(saved, desired, context);
  return {
    limb_operations,
    organ_operations: buildCanonicalOrganOperations(
      saved,
      desired,
      limb_operations,
      context
    ),
  };
};

export const buildProstheticSaveParams = (
  state: BasicAppearanceState,
  context?: BasicProstheticContext | null
) => {
  if (!context) {
    return {};
  }
  return {
    limb_operations: state.limb_operations,
    organ_operations: state.organ_operations,
    synth_color_enabled: state.synth_color_enabled ? 1 : 0,
    synth_color: state.synth_color,
    synth_markings: state.synth_markings ? 1 : 0,
  };
};

export const resolveProstheticGalleryDefinitions = (
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): ProstheticGalleryDefinition[] => {
  if (!context || !catalog?.models) {
    return [];
  }
  const definitions: ProstheticGalleryDefinition[] = [];
  const seen = new Set<string>();
  for (const modelId of context.allowed_model_ids || []) {
    const model = catalog.models[modelId];
    if (!model || seen.has(model.id)) {
      continue;
    }
    seen.add(model.id);
    definitions.push({
      id: model.id,
      name: model.name || model.id,
      description: model.description,
    });
  }
  return definitions;
};

export const attachProstheticColorModes = (
  definitions: readonly ProstheticGalleryDefinition[],
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): ProstheticGalleryDefinition[] =>
  definitions.map((definition) => {
    const colorMode = resolveProstheticModelColorMode(definition.id, catalog);
    const details = PROSTHETIC_COLOR_MODE_DETAILS[colorMode];
    return {
      ...definition,
      colorMode,
      tooltip: [
        definition.tooltip ||
          definition.disabledReason ||
          definition.description,
        `Color mode: ${details.label}. ${details.description}`,
      ]
        .filter(Boolean)
        .join('\n'),
    };
  });

export const resolveProstheticSelectionsForTarget = (
  target: ProstheticTarget,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): ProstheticSelectionDefinition[] => {
  if (!context || !catalog?.models) {
    return [];
  }
  const definitions: ProstheticSelectionDefinition[] = [];
  if (target !== 'head') {
    definitions.push({
      id: '__normal__',
      name: target === 'full_body' ? 'Organic Body' : 'Organic',
      operationState: 'normal',
    });
  }
  if (
    target !== 'head' &&
    target !== 'torso' &&
    target !== 'groin' &&
    target !== 'full_body'
  ) {
    definitions.push({
      id: '__amputated__',
      name: 'Amputated',
      operationState: 'amputated',
    });
  }
  const modelPart = target === 'full_body' ? 'torso' : target;
  for (const modelId of context.allowed_model_ids || []) {
    const model = catalog.models[modelId];
    if (!model?.parts?.includes(modelPart)) {
      continue;
    }
    definitions.push({
      id: model.id,
      name: model.name || model.id,
      description: model.description,
      operationState: 'prosthesis',
      model: model.id,
    });
  }
  return definitions;
};

export const operationForProstheticSelection = (
  target: ProstheticTarget,
  definition: ProstheticSelectionDefinition
): LimbOperation => ({
  target,
  state: definition.operationState,
  model: definition.model || null,
});

export const resolveSelectedProstheticId = (
  target: ProstheticTarget,
  state: LimbOverrideState
): string | null => {
  const part = target === 'full_body' ? 'torso' : target;
  const entry = state.external[part];
  if (entry?.status === 'cyborg') {
    return entry.model || null;
  }
  if (entry?.status === 'amputated') {
    return '__amputated__';
  }
  return target === 'head' ? null : '__normal__';
};

export const isProstheticTargetEditable = (
  target: ProstheticTarget,
  state: LimbOverrideState,
  context?: BasicProstheticContext | null,
  plannedTargets: readonly ProstheticTarget[] = []
) => {
  if (!context) {
    return false;
  }
  const locked = new Set(context.locked_parts || []);
  if (target === 'full_body') {
    return !!context.full_body_allowed && !locked.size;
  }
  const relatedParts = [
    ...resolveNaturalProstheticDescendants(state, target),
    ...resolveProstheticAncestors(target),
  ];
  if (locked.has(target) || relatedParts.some((part) => locked.has(part))) {
    return false;
  }
  if (target === 'head') {
    const normalizedPlannedTargets = normalizeProstheticTargets(plannedTargets);
    return (
      state.external.torso?.status === 'cyborg' ||
      normalizedPlannedTargets.includes('torso') ||
      normalizedPlannedTargets.includes('full_body')
    );
  }
  return !!context.part_states?.[target];
};

export const normalizeProstheticTargets = (
  targets: readonly ProstheticTarget[]
): ProstheticTarget[] => {
  if (targets.includes('full_body')) {
    return ['full_body'];
  }
  return PROSTHETIC_TARGETS.filter(
    (target) => target !== 'full_body' && targets.includes(target)
  );
};

export const resolveEditableProstheticTargets = (
  targets: readonly ProstheticTarget[],
  state: LimbOverrideState,
  context?: BasicProstheticContext | null
): ProstheticTarget[] => {
  let resolvedTargets = normalizeProstheticTargets(targets);
  while (resolvedTargets.length) {
    const editableTargets = resolvedTargets.filter((target) =>
      isProstheticTargetEditable(target, state, context, resolvedTargets)
    );
    if (editableTargets.length === resolvedTargets.length) {
      return resolvedTargets;
    }
    resolvedTargets = editableTargets;
  }
  return resolvedTargets;
};

export const resolveHighlightedProstheticTargets = (
  targets: readonly ProstheticTarget[]
): ProstheticTarget[] => {
  const normalized = normalizeProstheticTargets(targets);
  if (normalized.includes('full_body')) {
    return [...PROSTHETIC_TARGETS];
  }
  return normalized;
};

export const toggleProstheticTargetSelection = (
  targets: readonly ProstheticTarget[],
  target: ProstheticTarget,
  state: LimbOverrideState
): ProstheticTarget[] => {
  const normalized = normalizeProstheticTargets(targets);
  if (target === 'full_body') {
    return normalized.includes('full_body') ? [] : ['full_body'];
  }
  if (normalized.includes('full_body')) {
    if (target === 'head' && state.external.torso?.status !== 'cyborg') {
      return normalizeProstheticTargets(['torso', 'head']);
    }
    return [target];
  }
  if (normalized.includes(target)) {
    return normalizeProstheticTargets(
      normalized.filter((entry) => entry !== target)
    );
  }
  return normalizeProstheticTargets([...normalized, target]);
};

export const resolveApplicableProstheticTargets = (
  targets: readonly ProstheticTarget[],
  selectionId: string,
  state: LimbOverrideState,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): ProstheticTarget[] => {
  if (!context || !selectionId) {
    return [];
  }
  return normalizeProstheticTargets(targets).filter((target) => {
    if (!isProstheticTargetEditable(target, state, context, targets)) {
      return false;
    }
    const definition = resolveProstheticSelectionsForTarget(
      target,
      context,
      catalog
    ).find((entry) => entry.id === selectionId);
    if (!definition) {
      return false;
    }
    if (definition.operationState !== 'prosthesis') {
      return true;
    }
    const model = catalog?.models?.[definition.model || selectionId];
    return resolveProstheticOperationParts(state, target).every((part) =>
      model?.parts?.includes(part)
    );
  });
};

export const isProstheticSelectionCompatibleWithTargets = (
  targets: readonly ProstheticTarget[],
  selectionId: string,
  state: LimbOverrideState,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): boolean => {
  const normalizedTargets = normalizeProstheticTargets(targets);
  return (
    normalizedTargets.length > 0 &&
    resolveApplicableProstheticTargets(
      normalizedTargets,
      selectionId,
      state,
      context,
      catalog
    ).length === normalizedTargets.length
  );
};

const resolveProstheticModelTargetLabels = (
  model?: ProstheticCatalogModel | null
): string[] => {
  if (
    CANONICAL_TARGET_ORDER.every((target) => model?.parts?.includes(target))
  ) {
    return [PROSTHETIC_TARGET_LABELS.full_body];
  }
  return CANONICAL_TARGET_ORDER.filter((target) =>
    model?.parts?.includes(target)
  ).map((target) => PROSTHETIC_TARGET_LABELS[target]);
};

export const resolveProstheticGalleryDefinitionsForTargets = (
  targets: readonly ProstheticTarget[],
  state: LimbOverrideState,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): ProstheticGalleryDefinition[] => {
  const normalizedTargets = normalizeProstheticTargets(targets);
  return resolveProstheticGalleryDefinitions(context, catalog).map(
    (definition) => {
      const applicableTargets = resolveApplicableProstheticTargets(
        normalizedTargets,
        definition.id,
        state,
        context,
        catalog
      );
      const missingTargets = normalizedTargets.filter(
        (target) => !applicableTargets.includes(target)
      );
      const unsupportedParts = Array.from(
        new Set(
          normalizedTargets.flatMap((target) => {
            const selection = resolveProstheticSelectionsForTarget(
              target,
              context,
              catalog
            ).find((entry) => entry.id === definition.id);
            if (selection?.operationState !== 'prosthesis') {
              return [];
            }
            const model = catalog?.models?.[selection.model || definition.id];
            return resolveProstheticOperationParts(state, target).filter(
              (part) => !model?.parts?.includes(part)
            );
          })
        )
      );
      const disabled = !normalizedTargets.length || missingTargets.length > 0;
      const disabledReason = !disabled
        ? undefined
        : !normalizedTargets.length
          ? 'Select a body target to enable compatible chassis.'
          : unsupportedParts.length
            ? `This chassis does not support the required ${unsupportedParts
                .map((part) => PROSTHETIC_TARGET_LABELS[part])
                .join(', ')}.`
            : `Cannot be applied to ${missingTargets
                .map((target) => PROSTHETIC_TARGET_LABELS[target])
                .join(', ')}.`;
      const supportedTargetLabels = resolveProstheticModelTargetLabels(
        catalog?.models?.[definition.id]
      );
      return {
        ...definition,
        disabled,
        disabledReason,
        tooltip: [
          definition.description,
          supportedTargetLabels.length
            ? `Applies to: ${supportedTargetLabels.join(', ')}.`
            : 'Applies to: no selectable body targets.',
          disabledReason,
        ]
          .filter(Boolean)
          .join('\n'),
      };
    }
  );
};

export const applyProstheticSelectionToTargets = (
  source: LimbOverrideState,
  targets: readonly ProstheticTarget[],
  selectionId: string,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): LimbOverrideState => {
  let next = cloneLimbOverrideState(source);
  const applicableTargets = resolveApplicableProstheticTargets(
    targets,
    selectionId,
    source,
    context,
    catalog
  );
  for (const target of applicableTargets) {
    const definition = resolveProstheticSelectionsForTarget(
      target,
      context,
      catalog
    ).find((entry) => entry.id === selectionId);
    if (definition) {
      next = applyLimbOperation(
        next,
        operationForProstheticSelection(target, definition),
        context
      );
    }
  }
  return next;
};

export const resolveInternalOrganOptions = (
  organ: InternalOrganId,
  state: LimbOverrideState,
  context?: BasicProstheticContext | null
): InternalOrganChoice[] => {
  const definition = resolveInternalOrganDefinitions(context).find(
    (entry) => entry.id === organ
  );
  if (!definition?.allowed_states.length) {
    return [];
  }
  if (organ === 'brain') {
    if (state.external.head?.status !== 'cyborg') {
      return [];
    }
    const choices: InternalOrganChoice[] = [];
    if (definition.allowed_states.includes('assisted')) {
      choices.push({ id: 'assisted', label: 'Cybernetic' });
    }
    if (
      definition.allowed_states.includes('mechanical') &&
      context?.brain_positronic_allowed
    ) {
      choices.push({ id: 'mechanical', label: 'Positronic' });
    }
    if (
      definition.allowed_states.includes('digital') &&
      context?.brain_drone_allowed
    ) {
      choices.push({ id: 'digital', label: 'Drone' });
    }
    return choices;
  }
  const choices: InternalOrganChoice[] = [];
  if (
    definition.allowed_states.includes('normal') &&
    state.external.torso?.status !== 'cyborg'
  ) {
    choices.push({ id: 'normal', label: 'Organic' });
  }
  if (definition.allowed_states.includes('assisted')) {
    choices.push({ id: 'assisted', label: 'Assisted' });
  }
  if (definition.allowed_states.includes('mechanical')) {
    choices.push({ id: 'mechanical', label: 'Mechanical' });
  }
  return choices;
};

export const resetEditableProstheticSettings = (
  state: BasicAppearanceState,
  context?: BasicProstheticContext | null
): BasicAppearanceState => {
  let limbs = cloneLimbOverrideState(state.limbs);
  if (!context) {
    return { ...state, limbs };
  }
  if (isProstheticTargetEditable('full_body', limbs, context)) {
    limbs = applyLimbOperation(
      limbs,
      {
        target: 'full_body',
        state: 'normal',
      },
      context
    );
  } else {
    for (const target of PROSTHETIC_TARGETS) {
      if (
        target === 'full_body' ||
        target === 'head' ||
        !isProstheticTargetEditable(target, limbs, context)
      ) {
        continue;
      }
      limbs = applyLimbOperation(limbs, { target, state: 'normal' });
    }
  }
  for (const definition of resolveInternalOrganDefinitions(context)) {
    const target = definition.id as InternalOrganId;
    if (
      !resolveInternalOrganOptions(target, limbs, context).some(
        (entry) => entry.id === 'normal'
      )
    ) {
      continue;
    }
    limbs = applyInternalOrganOperation(limbs, {
      target,
      state: 'normal',
    });
  }
  return { ...state, limbs };
};

export const buildProstheticShowcaseState = (
  state: BasicAppearanceState,
  modelId: string,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): BasicAppearanceState => {
  const model = catalog?.models?.[modelId];
  const limbs = cloneLimbOverrideState(state.limbs);
  if (!model || !context) {
    return { ...state, limbs };
  }
  const locked = new Set(context.locked_parts || []);
  for (const part of EXTERNAL_PARTS) {
    if (!locked.has(part)) {
      setExternalEntry(limbs, part, 'normal');
    }
  }
  for (const part of model.parts || []) {
    if (!locked.has(part) && context.part_states?.[part]) {
      setExternalEntry(limbs, part, 'cyborg', model.id);
    }
  }
  return {
    ...state,
    limbs,
    tail_style: null,
    ear_style: null,
    horn_style: null,
    wing_style: null,
  };
};

const buildAddColorMatrix = (hex: string): number[] => {
  const normalized = hex.replace('#', '').padEnd(6, '0').slice(0, 6);
  const red = parseInt(normalized.slice(0, 2), 16) || 0;
  const green = parseInt(normalized.slice(2, 4), 16) || 0;
  const blue = parseInt(normalized.slice(4, 6), 16) || 0;
  return [
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    red / 255,
    green / 255,
    blue / 255,
    0,
  ];
};

const buildColorTransform = (
  color: string | null | undefined,
  multiply: boolean
): GearColorTransform[] | undefined => {
  if (!color) {
    return undefined;
  }
  return [multiply ? color : buildAddColorMatrix(color)];
};

export const resolveBiologicalGenderSuffix = (
  biologicalGender: string | null | undefined
): 'm' | 'f' => (biologicalGender === 'female' ? 'f' : 'm');

export const resolveProstheticContextForBiologicalGender = (
  context: BasicProstheticContext | null | undefined,
  biologicalGender: string | null | undefined
): BasicProstheticContext | null => {
  if (!context) {
    return null;
  }
  const genderSuffix = resolveBiologicalGenderSuffix(biologicalGender);
  if (context.gender_suffix === genderSuffix) {
    return context;
  }
  const partStates: BasicProstheticContext['part_states'] = {};
  for (const [part, state] of Object.entries(context.part_states || {})) {
    partStates[part] = state.gendered_state
      ? { ...state, gendered_state: `${state.state}_${genderSuffix}` }
      : state;
  }
  return {
    ...context,
    gender_suffix: genderSuffix,
    part_states: partStates,
  };
};

const resolveModelStateName = (
  model: ProstheticCatalogModel,
  context: BasicProstheticContext,
  part: string
) => {
  const partState = context.part_states?.[part];
  if (!partState) {
    return null;
  }
  if (partState.gendered_state && model.states?.[partState.gendered_state]) {
    return partState.gendered_state;
  }
  return model.states?.[partState.state] ? partState.state : null;
};

const resolveModelState = (
  model: ProstheticCatalogModel,
  context: BasicProstheticContext,
  part: string
) => {
  const stateName = resolveModelStateName(model, context, part);
  return stateName ? model.states[stateName] : null;
};

export const buildProstheticGalleryCompositeKey = (
  model: ProstheticCatalogModel,
  context: BasicProstheticContext
): string | null => {
  const stateEntries = [PROSTHETIC_GALLERY_COMPOSITE_REVISION];
  for (const part of PROSTHETIC_GALLERY_BODY_PARTS) {
    if (!model.parts?.includes(part)) {
      return null;
    }
    const stateName = resolveModelStateName(model, context, part);
    if (!stateName) {
      return null;
    }
    stateEntries.push(`${part}=${stateName}`);
  }
  return stateEntries.join('|');
};

export type ProstheticGalleryCompositeSelection = Readonly<{
  key: string;
  model: ProstheticCatalogModel;
  assets: Record<number, IconAssetReference>;
  colorable: boolean;
  bodyColor: string | null;
}>;

export type ProstheticGalleryCompositeOptions = Readonly<{
  requiresPartLevelMarkingComposition?: boolean;
  preservesSourcePartMarkings?: boolean;
  deferBodyColor?: boolean;
}>;

const customGridContentCache = new WeakMap<string[][], boolean>();

const customGridHasPixels = (grid: string[][] | null | undefined): boolean => {
  if (!grid) {
    return false;
  }
  const cached = customGridContentCache.get(grid);
  if (cached !== undefined) {
    return cached;
  }
  const hasPixels = gridHasPixels(grid);
  customGridContentCache.set(grid, hasPixels);
  return hasPixels;
};

export const canApplyProstheticGalleryCompositeToPreviewSources = (
  sources: PreviewDirectionSource[] | null | undefined,
  selection: ProstheticGalleryCompositeSelection | null,
  context?: BasicProstheticContext | null,
  options?: ProstheticGalleryCompositeOptions
): boolean => {
  if (
    !sources?.length ||
    !selection ||
    !context ||
    options?.requiresPartLevelMarkingComposition
  ) {
    return false;
  }
  return sources.every((source) => {
    if (!selection.assets[source.dir]) {
      return false;
    }
    const hiddenParts = new Set(source.hidden_body_parts || []);
    const markingExcluded = new Set(source.marking_excluded_parts || []);
    return PROSTHETIC_GALLERY_BODY_PARTS.every((part) => {
      if (hiddenParts.has(part) || source.reference_part_hair_assets?.[part]) {
        return false;
      }
      const preservesPartMarking =
        options?.preservesSourcePartMarkings || !markingExcluded.has(part);
      if (!preservesPartMarking) {
        return true;
      }
      return (
        !source.reference_part_marking_assets?.[part] &&
        !customGridHasPixels(source.custom_parts?.[part])
      );
    });
  });
};

export const resolveProstheticGalleryComposite = (
  modelId: string,
  state: BasicAppearanceState,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): ProstheticGalleryCompositeSelection | null => {
  const model = catalog?.models?.[modelId];
  if (
    !model ||
    !context ||
    (context.locked_parts || []).length ||
    (state.digitigrade && model.can_be_digitigrade)
  ) {
    return null;
  }
  for (const part of PROSTHETIC_GALLERY_BODY_PARTS) {
    const entry = state.limbs.external?.[part];
    if (entry?.status !== 'cyborg' || entry.model !== model.id) {
      return null;
    }
  }
  const key = buildProstheticGalleryCompositeKey(model, context);
  const composite = key ? model.gallery_composites?.[key] : null;
  if (!key || !composite?.assets) {
    return null;
  }
  return {
    key,
    model,
    assets: composite.assets,
    colorable: !followsBodyAppearance(model),
    bodyColor: state.body_color,
  };
};

const withSkinTone = (
  reference: IconAssetReference,
  context: BasicProstheticContext,
  model: ProstheticCatalogModel
): IconAssetReference => {
  if (
    !context.apply_skin_tone ||
    !context.skin_tone ||
    !followsBodyAppearance(model)
  ) {
    return reference;
  }
  const payload = resolveIconAssetReference(reference);
  if (!payload) {
    return reference;
  }
  return {
    ...payload,
    token: `${payload.token}-tone-${context.skin_tone}`,
    tone: context.skin_tone,
  };
};

const withColorTransform = (
  reference: IconAssetReference,
  color: string | null | undefined,
  multiply: boolean
): IconAssetReference => {
  const colors = buildColorTransform(color, multiply);
  if (!colors?.length) {
    return reference;
  }
  const payload = resolveIconAssetReference(reference);
  if (!payload) {
    return reference;
  }
  return {
    ...payload,
    colors: [...(payload.colors || []), ...colors],
  };
};

const withSkinColor = (
  reference: IconAssetReference,
  color: string | null | undefined,
  context: BasicProstheticContext,
  model: ProstheticCatalogModel
): IconAssetReference => {
  if (!context.apply_skin_color || !followsBodyAppearance(model)) {
    return reference;
  }
  return withColorTransform(reference, color, !!context.color_multiply);
};

const withProstheticColor = (
  reference: IconAssetReference,
  state: BasicAppearanceState,
  context: BasicProstheticContext,
  model: ProstheticCatalogModel,
  options?: ProstheticPreviewTransformOptions
): IconAssetReference => {
  let colored = withSkinTone(reference, context, model);
  if (options?.applyBodyColorToProsthetics && !options?.deferBodyColor) {
    colored = withSkinColor(colored, state.body_color, context, model);
  }
  if (
    options?.deferSynthColor ||
    followsBodyAppearance(model) ||
    !state.synth_color_enabled
  ) {
    return colored;
  }
  return withColorTransform(
    colored,
    state.synth_color,
    !!context.color_multiply
  );
};

export const applyProstheticGalleryCompositeToPreviewSources = (
  sources: PreviewDirectionSource[] | null,
  selection: ProstheticGalleryCompositeSelection | null,
  context?: BasicProstheticContext | null,
  options?: ProstheticGalleryCompositeOptions
): PreviewDirectionSource[] | null => {
  if (!sources?.length || !selection || !context) {
    return sources;
  }
  if (
    !canApplyProstheticGalleryCompositeToPreviewSources(
      sources,
      selection,
      context,
      options
    )
  ) {
    return sources;
  }
  return sources.map((source) => {
    const partAssets = { ...(source.reference_part_assets || {}) };
    const partHairAssets = { ...(source.reference_part_hair_assets || {}) };
    const partMarkingAssets = {
      ...(source.reference_part_marking_assets || {}),
    };
    const markingExcluded = new Set(source.marking_excluded_parts || []);
    const bodyColorExcluded = new Set(source.body_color_excluded_parts || []);
    for (const part of PROSTHETIC_GALLERY_BODY_PARTS) {
      delete partAssets[part];
      delete partHairAssets[part];
      delete partMarkingAssets[part];
      bodyColorExcluded.delete(part);
    }
    const tonedComposite = withSkinTone(
      selection.assets[source.dir],
      context,
      selection.model
    );
    partAssets[PROSTHETIC_GALLERY_COMPOSITE_PART] = options?.deferBodyColor
      ? tonedComposite
      : withSkinColor(
          tonedComposite,
          selection.bodyColor,
          context,
          selection.model
        );
    markingExcluded.add(PROSTHETIC_GALLERY_COMPOSITE_PART);
    bodyColorExcluded.add(PROSTHETIC_GALLERY_COMPOSITE_PART);
    const partOrder: string[] = [];
    let insertedComposite = false;
    for (const part of source.part_order || []) {
      if (
        PROSTHETIC_GALLERY_BODY_PARTS.includes(
          part as (typeof PROSTHETIC_GALLERY_BODY_PARTS)[number]
        )
      ) {
        if (!insertedComposite) {
          partOrder.push(PROSTHETIC_GALLERY_COMPOSITE_PART);
          insertedComposite = true;
        }
        continue;
      }
      partOrder.push(part);
    }
    if (!insertedComposite) {
      partOrder.unshift(PROSTHETIC_GALLERY_COMPOSITE_PART);
    }
    return {
      ...source,
      reference_part_assets: partAssets,
      reference_part_hair_assets: partHairAssets,
      reference_part_marking_assets: partMarkingAssets,
      part_order: partOrder,
      marking_excluded_parts: Array.from(markingExcluded),
      body_color_excluded_parts: Array.from(bodyColorExcluded),
    };
  });
};

const appendIntegratedOverlay = (
  overlays: Array<GearOverlayAssetReference | IconAssetReference>,
  model: ProstheticCatalogModel,
  stateName: 'tail' | 'ears' | 'wing',
  dir: number,
  slot: string,
  layer: number,
  color: string | null | undefined,
  multiply: boolean
) => {
  const state = model.states?.[stateName];
  const asset = state?.assets?.[dir];
  if (!asset) {
    return;
  }
  overlays.push({
    asset,
    colors: buildColorTransform(color, multiply),
    slot,
    layer,
  });
};

const resolveDeferredBodyColor = (
  bodyColor: string | null | undefined,
  options?: ProstheticPreviewTransformOptions
) => (options?.deferBodyColor ? null : bodyColor);

const transformedSourceCache = new WeakMap<
  PreviewDirectionSource[],
  Map<string, PreviewDirectionSource[]>
>();

export type ProstheticPreviewTransformOptions = Readonly<{
  deferSynthColor?: boolean;
  deferBodyColor?: boolean;
  applyBodyColorToProsthetics?: boolean;
}>;

const resolveProstheticBodyColorDependency = (
  state: BasicAppearanceState,
  context: BasicProstheticContext | null | undefined,
  catalog: ProstheticCatalog | null,
  options?: ProstheticPreviewTransformOptions
): { appliesBodyColor: boolean; usesBodyColor: boolean } => {
  let appliesBodyColor = false;
  let usesBodyColor = false;
  if (
    options?.applyBodyColorToProsthetics &&
    context?.apply_skin_color &&
    catalog?.models
  ) {
    const lockedParts = new Set(context.locked_parts || []);
    const digitigradeParts = new Set(context.digitigrade_parts || []);
    for (const [part, entry] of Object.entries(state.limbs.external || {})) {
      if (entry.status !== 'cyborg' || !entry.model || lockedParts.has(part)) {
        continue;
      }
      const model = catalog.models[entry.model];
      const keepsDigitigradeAnatomy =
        state.digitigrade &&
        !!model?.can_be_digitigrade &&
        digitigradeParts.has(part);
      if (followsBodyAppearance(model)) {
        appliesBodyColor = true;
        if (!keepsDigitigradeAnatomy && !options?.deferBodyColor) {
          usesBodyColor = true;
        }
      }
    }
  }
  const torso = state.limbs.external?.torso;
  if (torso?.status === 'cyborg' && torso.model) {
    const fullBodyModel = catalog?.models?.[torso.model];
    usesBodyColor =
      usesBodyColor ||
      !!(
        !options?.deferBodyColor &&
        ((fullBodyModel?.includes_tail && !state.tail_style) ||
          (fullBodyModel?.includes_wing && !state.wing_style))
      );
  }
  return { appliesBodyColor, usesBodyColor };
};

export const buildLimbPreviewSignature = (
  state: BasicAppearanceState,
  context?: BasicProstheticContext | null,
  options?: ProstheticPreviewTransformOptions,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
) => {
  const defersSynthColor = !!options?.deferSynthColor;
  const bodyColorDependency = resolveProstheticBodyColorDependency(
    state,
    context,
    catalog,
    options
  );
  return JSON.stringify({
    external: state.limbs?.external || {},
    biologicalGender: state.biological_gender,
    digitigrade: state.digitigrade,
    tail: state.tail_style,
    ears: state.ear_style,
    horns: state.horn_style,
    wings: state.wing_style,
    bodyColor: bodyColorDependency.usesBodyColor ? state.body_color : null,
    earColor: state.ear_colors?.[0],
    tone: context?.skin_tone,
    applySkinColor: context?.apply_skin_color,
    synthColorEnabled: defersSynthColor ? null : state.synth_color_enabled,
    synthColor:
      state.synth_color_enabled && !defersSynthColor ? state.synth_color : null,
    deferSynthColor: defersSynthColor,
    deferBodyColor: !!options?.deferBodyColor,
    applyBodyColorToProsthetics: bodyColorDependency.appliesBodyColor,
    synthColorMultiply: context?.color_multiply,
    synthColorParts: context?.synth_color_parts,
    synthMarkings: state.synth_markings,
  });
};

export const buildProstheticShowcaseAppearanceStructureSignature = (
  state: BasicAppearanceState
): string =>
  JSON.stringify({
    hair: state.hair_style,
    hairColor: state.hair_color,
    gradient: state.hair_gradient_style,
    gradientColor: state.hair_gradient_color,
    facialHair: state.facial_hair_style,
    facialHairColor: state.facial_hair_color,
  });

const applyExplicitSynthColorToParts = (
  partAssets: Record<string, IconAssetReference>,
  bodyColorExcluded: Set<string>,
  state: BasicAppearanceState,
  context: BasicProstheticContext,
  deferSynthColor: boolean
) => {
  if (!state.synth_color_enabled && !deferSynthColor) {
    return;
  }
  for (const part of context.synth_color_parts || []) {
    const reference = partAssets[part];
    if (!reference) {
      continue;
    }
    if (state.synth_color_enabled && !deferSynthColor) {
      partAssets[part] = withColorTransform(
        reference,
        state.synth_color,
        !!context.color_multiply
      );
    }
    bodyColorExcluded.add(part);
  }
};

export const applyProstheticsToPreviewSources = (
  sources: PreviewDirectionSource[] | null,
  state: BasicAppearanceState,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog(),
  options?: ProstheticPreviewTransformOptions
): PreviewDirectionSource[] | null => {
  if (!sources?.length || !context || !catalog?.models) {
    return sources;
  }
  const resolvedContext = resolveProstheticContextForBiologicalGender(
    context,
    state.biological_gender
  )!;
  const signature = buildLimbPreviewSignature(
    state,
    resolvedContext,
    options,
    catalog
  );
  let cache = transformedSourceCache.get(sources);
  const cached = cache?.get(signature);
  if (cached) {
    return cached;
  }
  const digitigradeParts = new Set(resolvedContext.digitigrade_parts || []);
  const lockedParts = new Set(resolvedContext.locked_parts || []);
  const transformed = sources.map((source) => {
    const partAssets: Record<string, IconAssetReference> = {
      ...(source.reference_part_assets || {}),
    };
    const partHairAssets: Record<string, IconAssetReference> = {
      ...(source.reference_part_hair_assets || {}),
    };
    const hiddenParts = new Set(source.hidden_body_parts || []);
    const markingExcluded = new Set(source.marking_excluded_parts || []);
    const bodyColorExcluded = new Set(source.body_color_excluded_parts || []);
    for (const [part, entry] of Object.entries(state.limbs.external || {})) {
      if (entry.status === 'amputated') {
        delete partAssets[part];
        delete partHairAssets[part];
        hiddenParts.add(part);
        markingExcluded.add(part);
        continue;
      }
      if (entry.status !== 'cyborg' || !entry.model) {
        continue;
      }
      if (lockedParts.has(part)) {
        continue;
      }
      const model = catalog.models[entry.model];
      if (!model) {
        continue;
      }
      const keepsDigitigradeAnatomy =
        state.digitigrade &&
        !!model.can_be_digitigrade &&
        digitigradeParts.has(part);
      if (!keepsDigitigradeAnatomy) {
        const modelState = resolveModelState(model, resolvedContext, part);
        const reference = modelState?.assets?.[source.dir];
        if (reference) {
          partAssets[part] = withProstheticColor(
            reference,
            state,
            resolvedContext,
            model,
            options
          );
        } else {
          delete partAssets[part];
        }
      } else if (
        state.synth_color_enabled &&
        !options?.deferSynthColor &&
        !followsBodyAppearance(model) &&
        partAssets[part]
      ) {
        partAssets[part] = withColorTransform(
          partAssets[part],
          state.synth_color,
          !!resolvedContext.color_multiply
        );
      }
      if (keepsDigitigradeAnatomy || state.synth_markings) {
        markingExcluded.delete(part);
      } else {
        markingExcluded.add(part);
      }
      const usesWholeBodyColorPass =
        followsBodyAppearance(model) &&
        resolvedContext.apply_skin_color &&
        (keepsDigitigradeAnatomy || !options?.applyBodyColorToProsthetics);
      if (usesWholeBodyColorPass) {
        bodyColorExcluded.delete(part);
      } else {
        bodyColorExcluded.add(part);
      }
    }
    applyExplicitSynthColorToParts(
      partAssets,
      bodyColorExcluded,
      state,
      resolvedContext,
      !!options?.deferSynthColor
    );
    let overlays = [...(source.overlay_assets || [])];
    const torso = state.limbs.external?.torso;
    const fullBodyModel =
      torso?.status === 'cyborg' && torso.model
        ? catalog.models[torso.model]
        : null;
    if (fullBodyModel?.includes_tail && !state.tail_style) {
      overlays = overlays.filter(
        (entry) =>
          typeof entry === 'string' ||
          !('slot' in entry) ||
          entry.slot !== 'species_tail'
      );
      appendIntegratedOverlay(
        overlays,
        fullBodyModel,
        'tail',
        source.dir,
        'prosthetic_tail',
        source.dir === 2 ? 7 : 16,
        resolveDeferredBodyColor(state.body_color, options),
        !!resolvedContext.color_multiply
      );
    }
    if (fullBodyModel?.includes_ears && !state.ear_style && !state.horn_style) {
      appendIntegratedOverlay(
        overlays,
        fullBodyModel,
        'ears',
        source.dir,
        'prosthetic_ears',
        23,
        state.ear_colors?.[0],
        !!resolvedContext.color_multiply
      );
    }
    if (fullBodyModel?.includes_wing && !state.wing_style) {
      appendIntegratedOverlay(
        overlays,
        fullBodyModel,
        'wing',
        source.dir,
        'prosthetic_wing',
        32,
        resolveDeferredBodyColor(state.body_color, options),
        !!resolvedContext.color_multiply
      );
    }
    return {
      ...source,
      reference_part_assets: partAssets,
      reference_part_hair_assets: partHairAssets,
      hidden_body_parts: Array.from(hiddenParts),
      marking_excluded_parts: Array.from(markingExcluded),
      body_color_excluded_parts: Array.from(bodyColorExcluded),
      overlay_assets: overlays,
    };
  });
  if (!cache) {
    cache = new Map();
    transformedSourceCache.set(sources, cache);
  }
  cache.set(signature, transformed);
  while (cache.size > 32) {
    const oldest = cache.keys().next().value as string | undefined;
    if (!oldest) {
      break;
    }
    cache.delete(oldest);
  }
  return transformed;
};

export const resolveProstheticSynthColorPasses = (
  state: BasicAppearanceState,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): Record<string, number> => {
  if (!state.synth_color_enabled || !context || !catalog?.models) {
    return {};
  }
  const passes: Record<string, number> = {};
  const addPass = (part: string) => {
    passes[part] = (passes[part] || 0) + 1;
  };
  const lockedParts = new Set(context.locked_parts || []);
  for (const [part, entry] of Object.entries(state.limbs.external || {})) {
    if (entry.status !== 'cyborg' || !entry.model || lockedParts.has(part)) {
      continue;
    }
    const model = catalog.models[entry.model];
    if (model && !followsBodyAppearance(model)) {
      addPass(part);
    }
  }
  for (const part of context.synth_color_parts || []) {
    addPass(part);
  }
  return passes;
};

export const resolveProstheticBodyColorPasses = (
  state: BasicAppearanceState,
  context?: BasicProstheticContext | null,
  catalog: ProstheticCatalog | null = getStaticProstheticCatalog()
): Record<string, number> => {
  if (!context?.apply_skin_color || !catalog?.models) {
    return {};
  }
  const passes: Record<string, number> = {};
  const lockedParts = new Set(context.locked_parts || []);
  const digitigradeParts = new Set(context.digitigrade_parts || []);
  for (const [part, entry] of Object.entries(state.limbs.external || {})) {
    if (entry.status !== 'cyborg' || !entry.model || lockedParts.has(part)) {
      continue;
    }
    const model = catalog.models[entry.model];
    const keepsDigitigradeAnatomy =
      state.digitigrade &&
      !!model?.can_be_digitigrade &&
      digitigradeParts.has(part);
    if (followsBodyAppearance(model) && !keepsDigitigradeAnatomy) {
      passes[part] = 1;
    }
  }
  return passes;
};

export const buildProstheticTileBaseCacheSignature = (options: {
  structureSignature: string;
  assetReadinessSignature?: string;
  complete: boolean;
}) => {
  const { structureSignature, assetReadinessSignature, complete } = options;
  if (complete) {
    return structureSignature;
  }
  return [
    structureSignature,
    `assets:${assetReadinessSignature || 'none'}`,
  ].join('::');
};

export type ProstheticTileLayerRecipe = Readonly<{
  layer: PreviewLayerEntry;
  rasterIdentity?: string;
  dependency: PreviewLayerRasterDependency;
  shareable: boolean;
}>;

export const buildProstheticTileLayerRecipes = (
  layers: PreviewLayerEntry[]
): ProstheticTileLayerRecipe[] =>
  layers.map((layer) => ({
    layer,
    rasterIdentity: layer.rasterIdentity,
    dependency: layer.rasterDependency || 'stable',
    shareable: !!layer.rasterIdentity && layer.rasterShareable === true,
  }));

export const buildProstheticPreviewLayerGroups = (options: {
  layers: PreviewLayerEntry[];
  colorPasses: Record<string, number>;
  color: string;
  multiply: boolean;
  cacheKey: string;
  cacheSignature: string;
  colorCacheSignature?: string;
  stableCacheSignature?: string;
  bodyColorPasses?: Record<string, number>;
  bodyColor?: string;
  bodyColorMultiply?: boolean;
  bodyColorCacheSignature?: string;
  eyeColorCacheSignature?: string;
  rasterScope?: string;
  direction?: number;
  unsharedLayerKeys?: ReadonlySet<string>;
}): PreviewLayerGroup[] => {
  const {
    layers,
    colorPasses,
    color,
    multiply,
    cacheKey,
    cacheSignature,
    colorCacheSignature = cacheSignature,
    stableCacheSignature = cacheSignature,
    bodyColorPasses = {},
    bodyColor = '#ffffff',
    bodyColorMultiply = false,
    bodyColorCacheSignature = stableCacheSignature,
    eyeColorCacheSignature = stableCacheSignature,
    rasterScope = 'designer-session',
    direction,
    unsharedLayerKeys,
  } = options;
  const buildPassMap = (passes: Record<string, number>) =>
    new Map(
      Object.entries(passes)
        .filter(([, count]) => count > 0)
        .map(([part, count]) => [`ref_${part}`, count])
    );
  const colorPassesByLayerKey = buildPassMap(colorPasses);
  const bodyPassesByLayerKey = buildPassMap(bodyColorPasses);
  const groups: PreviewLayerGroup[] = [];
  let currentLayers: PreviewLayerEntry[] = [];
  let currentTransformKey: string | null = null;
  let currentKind = 'base';
  let currentCacheSignature = cacheSignature;
  let currentColorTransform:
    | { color: string; multiply: boolean; passes: number }
    | undefined;
  let currentSharedRasterSignature: string | undefined;
  const flush = () => {
    if (!currentLayers.length || currentTransformKey === null) {
      return;
    }
    const index = groups.length;
    const isShared = !!currentSharedRasterSignature;
    groups.push({
      key: `${cacheKey}:${index}:${isShared ? 'shared' : currentKind}`,
      layers: currentLayers,
      cacheSignature: `${currentCacheSignature}:${index}`,
      sharedRasterSignature: currentSharedRasterSignature,
      colorTransform: currentColorTransform,
    });
    currentLayers = [];
    currentColorTransform = undefined;
    currentSharedRasterSignature = undefined;
  };

  const recipes = buildProstheticTileLayerRecipes(layers);
  for (let index = 0; index < recipes.length; index++) {
    const recipe = recipes[index];
    const layer = recipe.layer;
    const passes =
      layer.type === 'reference_part'
        ? colorPassesByLayerKey.get(layer.key) || 0
        : 0;
    const bodyPasses =
      layer.type === 'reference_part'
        ? bodyPassesByLayerKey.get(layer.key) || 0
        : 0;
    const isSynthColorable = passes > 0 && Array.isArray(layer.grid);
    const isBodyColorable =
      !isSynthColorable &&
      Array.isArray(layer.grid) &&
      (bodyPasses > 0 ||
        layer.source === 'prosthetic_tail' ||
        layer.source === 'prosthetic_wing');
    const dependency = isSynthColorable
      ? 'synth-direct'
      : isBodyColorable
        ? 'body-direct'
        : recipe.dependency;
    const isStableSharedRaster =
      !isSynthColorable &&
      !isBodyColorable &&
      recipe.shareable &&
      !unsharedLayerKeys?.has(layer.key) &&
      layer.source !== 'prosthetic_tail' &&
      layer.source !== 'prosthetic_wing';
    const sharedRasterSignature = isStableSharedRaster
      ? [
          'prosthetic-layer-v1',
          `scope:${rasterScope}`,
          `dir:${direction ?? 'unknown'}`,
          recipe.rasterIdentity,
        ].join('|')
      : undefined;
    const kind = isSynthColorable
      ? 'synth-color'
      : isBodyColorable
        ? 'body-color'
        : dependency === 'body-relative' || dependency === 'body-eye-fallback'
          ? 'body'
          : dependency === 'eye-direct'
            ? 'eye'
            : 'stable';
    const directPasses = isSynthColorable ? passes : Math.max(1, bodyPasses);
    const directMultiply = isSynthColorable ? multiply : bodyColorMultiply;
    const transformKey =
      isSynthColorable || isBodyColorable
        ? directMultiply
          ? `${kind}:${directPasses}`
          : `${kind}:${directPasses}:${index}`
        : sharedRasterSignature
          ? `shared:${index}`
          : `fallback:${kind}`;
    const nextCacheSignature = isSynthColorable
      ? colorCacheSignature
      : isBodyColorable
        ? bodyColorCacheSignature
        : kind === 'body'
          ? cacheSignature
          : kind === 'eye'
            ? eyeColorCacheSignature
            : stableCacheSignature;
    const nextColorTransform = isSynthColorable
      ? { color, multiply, passes }
      : isBodyColorable
        ? {
            color: bodyColor,
            multiply: bodyColorMultiply,
            passes: directPasses,
          }
        : undefined;
    if (currentTransformKey !== null && currentTransformKey !== transformKey) {
      flush();
    }
    currentTransformKey = transformKey;
    currentKind = kind;
    currentCacheSignature = nextCacheSignature;
    currentColorTransform = nextColorTransform;
    currentSharedRasterSignature = sharedRasterSignature;
    currentLayers.push(layer);
  }
  flush();
  return groups;
};
