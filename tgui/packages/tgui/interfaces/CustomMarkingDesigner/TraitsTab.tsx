// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer - Traits Tab //
// //////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

import { useBackend, useLocalState } from '../../backend';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Flex,
  Icon,
  Input,
  Modal,
  NoticeBox,
  NumberInput,
  Popper,
  RogueStarColorPicker,
  Section,
} from '../../components';
import { sanitizeText } from '../../sanitize';
import { normalizeHex } from '../../utils/color';
import type { PreviewDirectionEntry } from '../../utils/character-preview';
import { LivePreviewCard, LoadingOverlay } from './components';
import { CHIP_BUTTON_CLASS } from './constants';
import type {
  CanvasBackgroundOption,
  CharacterLanguageEntry,
  CharacterLanguagesPayload,
  CharacterPersistenceDetailEntry,
  CharacterPersistencePayload,
  CharacterTraitCategory,
  CharacterTraitEntry,
  CustomMarkingDesignerData,
  TraitCategoryId,
  TraitPreferenceValue,
  TraitPreferenceEntry,
  TraitsDraftState,
  TraitsPayload,
} from './types';
import {
  applyTraitsDraftToPayload,
  buildTraitsDraftState,
  resolveLanguagesDraftValidationError,
  resolveTraitsPreviewScale,
  sortLanguagesAlphabetically,
  sortTraitsByConfiguredOrder,
  traitsDraftStatesEqual,
  updateLanguageDraftCustomKey,
  updateLanguageDraftPrefixes,
  updateLanguageDraftPreferred,
  updateLanguageDraftSelection,
  updateTraitsDraftPreference,
  updateTraitsDraftSelection,
} from './utils/traits';

type TraitsCatalogCategoryId = TraitCategoryId | 'languages';

type TraitsTabProps = Readonly<{
  data: CustomMarkingDesignerData;
  draftState: TraitsDraftState | null;
  setDraftState: (state: TraitsDraftState | null) => void;
  dirty: boolean;
  setDirty: (dirty: boolean) => void;
  pendingSave: boolean;
  pendingClose: boolean;
  saveError: string | null;
  onSave: () => void;
  onSaveAndClose: () => void;
  onDiscardAndClose: () => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  backgroundFallbackColor: string;
  cycleCanvasBackground: () => void;
  canvasBackgroundScale: number;
  livePreview: PreviewDirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  previewFitToFrame: boolean;
  onTogglePreviewFit: () => void;
  showEquipment: boolean;
  onToggleEquipment: () => void;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
}>;

type TraitsPayloadInitializerProps = Readonly<{
  payload: TraitsPayload | null;
  expectedRevision?: number;
  expectedSpecies?: string | null;
  requestPayload: () => void;
}>;

class TraitsPayloadInitializer extends Component<TraitsPayloadInitializerProps> {
  private requestedKey: string | null = null;

  componentDidMount() {
    this.requestIfNeeded();
  }

  componentDidUpdate() {
    this.requestIfNeeded();
  }

  requestIfNeeded() {
    const { payload, expectedRevision, expectedSpecies, requestPayload } =
      this.props;
    const revisionMatches =
      !expectedRevision || payload?.revision === expectedRevision;
    const speciesMatches =
      !expectedSpecies || payload?.species_id === expectedSpecies;
    if (payload && revisionMatches && speciesMatches) {
      this.requestedKey = null;
      return;
    }
    const requestKey = `${expectedRevision || 0}:${expectedSpecies || ''}`;
    if (this.requestedKey === requestKey) {
      return;
    }
    this.requestedKey = requestKey;
    requestPayload();
  }

  render() {
    return null;
  }
}

const CATEGORY_PRESENTATION: Record<TraitsCatalogCategoryId, { icon: string }> =
  {
    positive: { icon: 'plus-circle' },
    neutral: { icon: 'compass' },
    negative: { icon: 'triangle-exclamation' },
    languages: { icon: 'language' },
  };

const getCategoryPresentation = (category: TraitsCatalogCategoryId) =>
  CATEGORY_PRESENTATION[category] || CATEGORY_PRESENTATION.neutral;

type TraitGroupDefinition = Readonly<{
  id: string;
  name: string;
  icon: string;
  roots?: readonly string[];
  prefixes?: readonly string[];
  traitOrder?: readonly string[];
}>;

type VisibleTraitGroup = TraitGroupDefinition & {
  traits: CharacterTraitEntry[];
  selectedCount: number;
};

const POSITIVE_TRAIT_PATH = '/datum/trait/positive';
const NEUTRAL_TRAIT_PATH = '/datum/trait/neutral';
const NEGATIVE_TRAIT_PATH = '/datum/trait/negative';

const SHARED_TRAIT_GROUP_PRESENTATION = {
  movement: {
    id: 'movement',
    name: 'Movement',
    icon: 'running',
  },
  carryingEncumbrance: {
    id: 'carrying_encumbrance',
    name: 'Carrying & Encumbrance',
    icon: 'weight-hanging',
  },
  enduranceDurability: {
    id: 'endurance_durability',
    name: 'Endurance & Durability',
    icon: 'heartbeat',
  },
  damageResistances: {
    id: 'damage_response',
    name: 'Damage Resistances & Vulnerabilities',
    icon: 'shield-alt',
  },
  vision: {
    id: 'vision',
    name: 'Vision',
    icon: 'eye',
  },
  marksmanship: {
    id: 'marksmanship',
    name: 'Marksmanship',
    icon: 'bullseye',
  },
  languages: {
    id: 'languages',
    name: 'Languages',
    icon: 'book',
  },
  specialAbilities: {
    id: 'special_abilities',
    name: 'Special Abilities',
    icon: 'magic',
  },
} as const;

const TRAIT_GROUP_DEFINITIONS: Record<
  TraitCategoryId,
  readonly TraitGroupDefinition[]
> = {
  positive: [
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.movement,
      prefixes: [
        `${POSITIVE_TRAIT_PATH}/winged_flight`,
        `${POSITIVE_TRAIT_PATH}/soft_landing`,
        `${POSITIVE_TRAIT_PATH}/traceur`,
        `${POSITIVE_TRAIT_PATH}/snowwalker`,
        `${POSITIVE_TRAIT_PATH}/aquatic`,
        `${POSITIVE_TRAIT_PATH}/wall_climber`,
      ],
      traitOrder: [
        `${POSITIVE_TRAIT_PATH}/winged_flight`,
        `${POSITIVE_TRAIT_PATH}/soft_landing`,
        `${POSITIVE_TRAIT_PATH}/traceur`,
        `${POSITIVE_TRAIT_PATH}/snowwalker`,
        `${POSITIVE_TRAIT_PATH}/aquatic`,
        `${POSITIVE_TRAIT_PATH}/wall_climber`,
        `${POSITIVE_TRAIT_PATH}/wall_climber_natural`,
        `${POSITIVE_TRAIT_PATH}/wall_climber_pro`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.carryingEncumbrance,
      prefixes: [`${POSITIVE_TRAIT_PATH}/hardy`],
      traitOrder: [
        `${POSITIVE_TRAIT_PATH}/hardy`,
        `${POSITIVE_TRAIT_PATH}/hardy_plus`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.enduranceDurability,
      prefixes: [
        `${POSITIVE_TRAIT_PATH}/endurance_high`,
        `${POSITIVE_TRAIT_PATH}/pain_tolerance`,
        `${POSITIVE_TRAIT_PATH}/throw_resistance`,
      ],
      traitOrder: [
        `${POSITIVE_TRAIT_PATH}/endurance_high`,
        `${POSITIVE_TRAIT_PATH}/pain_tolerance`,
        `${POSITIVE_TRAIT_PATH}/throw_resistance`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.damageResistances,
      prefixes: [
        `${POSITIVE_TRAIT_PATH}/nonconductive`,
        `${POSITIVE_TRAIT_PATH}/minor_brute_resist`,
        `${POSITIVE_TRAIT_PATH}/brute_resist`,
        `${POSITIVE_TRAIT_PATH}/minor_burn_resist`,
        `${POSITIVE_TRAIT_PATH}/burn_resist`,
        `${POSITIVE_TRAIT_PATH}/photoresistant`,
      ],
      traitOrder: [
        `${POSITIVE_TRAIT_PATH}/minor_brute_resist`,
        `${POSITIVE_TRAIT_PATH}/brute_resist`,
        `${POSITIVE_TRAIT_PATH}/minor_burn_resist`,
        `${POSITIVE_TRAIT_PATH}/burn_resist`,
        `${POSITIVE_TRAIT_PATH}/nonconductive`,
        `${POSITIVE_TRAIT_PATH}/nonconductive_plus`,
        `${POSITIVE_TRAIT_PATH}/photoresistant`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.vision,
      prefixes: [`${POSITIVE_TRAIT_PATH}/darksight`],
      traitOrder: [
        `${POSITIVE_TRAIT_PATH}/darksight`,
        `${POSITIVE_TRAIT_PATH}/darksight_plus`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.marksmanship,
      roots: [`${POSITIVE_TRAIT_PATH}/good_shooter`],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.languages,
      roots: [`${POSITIVE_TRAIT_PATH}/linguist`],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.specialAbilities,
      roots: [
        `${POSITIVE_TRAIT_PATH}/melee_attack`,
        `${POSITIVE_TRAIT_PATH}/antiseptic_saliva`,
        `${POSITIVE_TRAIT_PATH}/weaver`,
        `${POSITIVE_TRAIT_PATH}/cocoon_tf`,
        `${POSITIVE_TRAIT_PATH}/blend_in`,
        `${POSITIVE_TRAIT_PATH}/tracker`,
      ],
      traitOrder: [
        `${POSITIVE_TRAIT_PATH}/melee_attack`,
        `${POSITIVE_TRAIT_PATH}/antiseptic_saliva`,
        `${POSITIVE_TRAIT_PATH}/weaver`,
        `${POSITIVE_TRAIT_PATH}/cocoon_tf`,
        `${POSITIVE_TRAIT_PATH}/blend_in`,
        `${POSITIVE_TRAIT_PATH}/tracker`,
      ],
    },
  ],
  neutral: [
    {
      id: 'visual_scale',
      name: 'Visual Body Scale',
      icon: 'expand-arrows-alt',
      prefixes: [
        `${NEUTRAL_TRAIT_PATH}/tall`,
        `${NEUTRAL_TRAIT_PATH}/short`,
        `${NEUTRAL_TRAIT_PATH}/obese`,
        `${NEUTRAL_TRAIT_PATH}/fat`,
        `${NEUTRAL_TRAIT_PATH}/thin`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/tall`,
        `${NEUTRAL_TRAIT_PATH}/taller`,
        `${NEUTRAL_TRAIT_PATH}/tallest`,
        `${NEUTRAL_TRAIT_PATH}/short`,
        `${NEUTRAL_TRAIT_PATH}/shorter`,
        `${NEUTRAL_TRAIT_PATH}/shortest`,
        `${NEUTRAL_TRAIT_PATH}/fat`,
        `${NEUTRAL_TRAIT_PATH}/obese`,
        `${NEUTRAL_TRAIT_PATH}/thin`,
        `${NEUTRAL_TRAIT_PATH}/thinner`,
      ],
    },
    {
      id: 'interaction_size',
      name: 'Micro Interaction Size',
      icon: 'ruler-combined',
      prefixes: [`${NEUTRAL_TRAIT_PATH}/micro_size_`],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/micro_size_down`,
        `${NEUTRAL_TRAIT_PATH}/micro_size_up`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.movement,
      roots: [`${NEUTRAL_TRAIT_PATH}/waddle`],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.enduranceDurability,
      roots: [`${NEUTRAL_TRAIT_PATH}/hardfeet`],
    },
    {
      id: 'metabolism',
      name: 'Metabolism & Hunger',
      icon: 'heartbeat',
      prefixes: [
        `${NEUTRAL_TRAIT_PATH}/metabolism_`,
        `${NEUTRAL_TRAIT_PATH}/food_value_`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/metabolism_down`,
        `${NEUTRAL_TRAIT_PATH}/metabolism_up`,
        `${NEUTRAL_TRAIT_PATH}/metabolism_apex`,
        `${NEUTRAL_TRAIT_PATH}/food_value_down`,
        `${NEUTRAL_TRAIT_PATH}/food_value_down_plus`,
      ],
    },
    {
      id: 'food_preferences',
      name: 'Food Preferences',
      icon: 'utensils',
      roots: [`${NEUTRAL_TRAIT_PATH}/food_pref`],
    },
    {
      id: 'dietary_adaptations',
      name: 'Dietary Adaptations',
      icon: 'cookie-bite',
      roots: [
        `${NEUTRAL_TRAIT_PATH}/trashcan`,
        `${NEUTRAL_TRAIT_PATH}/gem_eater`,
        `${NEUTRAL_TRAIT_PATH}/bloodsucker`,
        `${NEUTRAL_TRAIT_PATH}/bloodsucker_freeform`,
        `${NEUTRAL_TRAIT_PATH}/electrovore`,
        `${NEUTRAL_TRAIT_PATH}/electrovore_obligate`,
        `${NEUTRAL_TRAIT_PATH}/synth_chemfurnace`,
        `${NEUTRAL_TRAIT_PATH}/biofuel_value_down`,
        `${NEUTRAL_TRAIT_PATH}/synth_ethanolburner`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/trashcan`,
        `${NEUTRAL_TRAIT_PATH}/gem_eater`,
        `${NEUTRAL_TRAIT_PATH}/bloodsucker_freeform`,
        `${NEUTRAL_TRAIT_PATH}/bloodsucker`,
        `${NEUTRAL_TRAIT_PATH}/electrovore`,
        `${NEUTRAL_TRAIT_PATH}/electrovore_obligate`,
        `${NEUTRAL_TRAIT_PATH}/synth_chemfurnace`,
        `${NEUTRAL_TRAIT_PATH}/biofuel_value_down`,
        `${NEUTRAL_TRAIT_PATH}/synth_ethanolburner`,
      ],
    },
    {
      id: 'food_allergies',
      name: 'Food Allergies',
      icon: 'exclamation-triangle',
      roots: [`${NEUTRAL_TRAIT_PATH}/allergy`],
    },
    {
      id: 'allergy_reactions',
      name: 'Allergy Reactions',
      icon: 'medkit',
      roots: [`${NEUTRAL_TRAIT_PATH}/allergy_reaction`],
      prefixes: [`${NEUTRAL_TRAIT_PATH}/allergen_`],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/oxy`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/brute`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/burn`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/pain`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/weaken`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/blurry`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/sleepy`,
        `${NEUTRAL_TRAIT_PATH}/allergy_reaction/confusion`,
        `${NEUTRAL_TRAIT_PATH}/allergen_reduced_effect`,
        `${NEUTRAL_TRAIT_PATH}/allergen_increased_effect`,
      ],
    },
    {
      id: 'spice_tolerance',
      name: 'Spice Tolerance',
      icon: 'pepper-hot',
      prefixes: [`${NEUTRAL_TRAIT_PATH}/spice_`],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/spice_intolerance_extreme`,
        `${NEUTRAL_TRAIT_PATH}/spice_intolerance_basic`,
        `${NEUTRAL_TRAIT_PATH}/spice_intolerance_slight`,
        `${NEUTRAL_TRAIT_PATH}/spice_tolerance_basic`,
        `${NEUTRAL_TRAIT_PATH}/spice_tolerance_advanced`,
        `${NEUTRAL_TRAIT_PATH}/spice_immunity`,
      ],
    },
    {
      id: 'alcohol_tolerance',
      name: 'Alcohol Tolerance',
      icon: 'wine-bottle',
      prefixes: [`${NEUTRAL_TRAIT_PATH}/alcohol_`],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/alcohol_intolerance_advanced`,
        `${NEUTRAL_TRAIT_PATH}/alcohol_intolerance_basic`,
        `${NEUTRAL_TRAIT_PATH}/alcohol_intolerance_slight`,
        `${NEUTRAL_TRAIT_PATH}/alcohol_tolerance_reset`,
        `${NEUTRAL_TRAIT_PATH}/alcohol_tolerance_basic`,
        `${NEUTRAL_TRAIT_PATH}/alcohol_tolerance_advanced`,
        `${NEUTRAL_TRAIT_PATH}/alcohol_immunity`,
      ],
    },
    {
      id: 'temperature',
      name: 'Temperature Adaptation',
      icon: 'thermometer-half',
      roots: [
        `${NEUTRAL_TRAIT_PATH}/coldadapt`,
        `${NEUTRAL_TRAIT_PATH}/hotadapt`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/coldadapt`,
        `${NEUTRAL_TRAIT_PATH}/hotadapt`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.vision,
      roots: [`${NEUTRAL_TRAIT_PATH}/colorblind`],
    },
    {
      id: 'luminescence',
      name: 'Luminescence',
      icon: 'lightbulb',
      roots: [
        `${NEUTRAL_TRAIT_PATH}/glowing_eyes`,
        `${NEUTRAL_TRAIT_PATH}/glowing_body`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/glowing_eyes`,
        `${NEUTRAL_TRAIT_PATH}/glowing_body`,
      ],
    },
    {
      id: 'vocal_traits',
      name: 'Vocal Traits',
      icon: 'comments',
      roots: [
        `${NEUTRAL_TRAIT_PATH}/autohiss_unathi`,
        `${NEUTRAL_TRAIT_PATH}/autohiss_tajaran`,
        `${NEUTRAL_TRAIT_PATH}/autohiss_zaddat`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/autohiss_unathi`,
        `${NEUTRAL_TRAIT_PATH}/autohiss_tajaran`,
        `${NEUTRAL_TRAIT_PATH}/autohiss_zaddat`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.specialAbilities,
      roots: [
        `${NEUTRAL_TRAIT_PATH}/natural_artist`,
        `${NEUTRAL_TRAIT_PATH}/venom_bite`,
        `${NEUTRAL_TRAIT_PATH}/long_vore`,
        `${NEUTRAL_TRAIT_PATH}/stuffing_feeder`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/natural_artist`,
        `${NEUTRAL_TRAIT_PATH}/venom_bite`,
        `${NEUTRAL_TRAIT_PATH}/long_vore`,
        `${NEUTRAL_TRAIT_PATH}/stuffing_feeder`,
      ],
    },
    {
      id: 'prey_traits',
      name: 'Prey Traits',
      icon: 'paw',
      roots: [
        `${NEUTRAL_TRAIT_PATH}/nodigestpain`,
        `${NEUTRAL_TRAIT_PATH}/food_body`,
      ],
      prefixes: [`${NEUTRAL_TRAIT_PATH}/digestion_value_`],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/digestion_value_down_plus`,
        `${NEUTRAL_TRAIT_PATH}/digestion_value_down`,
        `${NEUTRAL_TRAIT_PATH}/digestion_value_up`,
        `${NEUTRAL_TRAIT_PATH}/digestion_value_up_plus`,
        `${NEUTRAL_TRAIT_PATH}/nodigestpain`,
        `${NEUTRAL_TRAIT_PATH}/food_body`,
      ],
    },
    {
      id: 'synthetic_abilities',
      name: 'Synthetic Abilities',
      icon: 'robot',
      roots: [
        `${NEUTRAL_TRAIT_PATH}/synth_ethanol_sim`,
        `${NEUTRAL_TRAIT_PATH}/synth_cosmetic_pain`,
      ],
      traitOrder: [
        `${NEUTRAL_TRAIT_PATH}/synth_ethanol_sim`,
        `${NEUTRAL_TRAIT_PATH}/synth_cosmetic_pain`,
      ],
    },
  ],
  negative: [
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.movement,
      prefixes: [
        `${NEGATIVE_TRAIT_PATH}/speed_slow`,
        `${NEGATIVE_TRAIT_PATH}/clumsy`,
      ],
      traitOrder: [
        `${NEGATIVE_TRAIT_PATH}/speed_slow`,
        `${NEGATIVE_TRAIT_PATH}/speed_slow_plus`,
        `${NEGATIVE_TRAIT_PATH}/clumsy`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.carryingEncumbrance,
      prefixes: [`${NEGATIVE_TRAIT_PATH}/weakling`],
      traitOrder: [
        `${NEGATIVE_TRAIT_PATH}/weakling`,
        `${NEGATIVE_TRAIT_PATH}/weakling_plus`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.enduranceDurability,
      prefixes: [
        `${NEGATIVE_TRAIT_PATH}/endurance_`,
        `${NEGATIVE_TRAIT_PATH}/haemophilia`,
        `${NEGATIVE_TRAIT_PATH}/neural_hypersensitivity`,
        `${NEGATIVE_TRAIT_PATH}/hollow`,
        `${NEGATIVE_TRAIT_PATH}/lightweight`,
      ],
      traitOrder: [
        `${NEGATIVE_TRAIT_PATH}/endurance_low`,
        `${NEGATIVE_TRAIT_PATH}/endurance_very_low`,
        `${NEGATIVE_TRAIT_PATH}/haemophilia`,
        `${NEGATIVE_TRAIT_PATH}/neural_hypersensitivity`,
        `${NEGATIVE_TRAIT_PATH}/hollow`,
        `${NEGATIVE_TRAIT_PATH}/lightweight`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.damageResistances,
      prefixes: [
        `${NEGATIVE_TRAIT_PATH}/minor_brute_weak`,
        `${NEGATIVE_TRAIT_PATH}/brute_weak`,
        `${NEGATIVE_TRAIT_PATH}/minor_burn_weak`,
        `${NEGATIVE_TRAIT_PATH}/burn_weak`,
        `${NEGATIVE_TRAIT_PATH}/conductive`,
      ],
      traitOrder: [
        `${NEGATIVE_TRAIT_PATH}/minor_brute_weak`,
        `${NEGATIVE_TRAIT_PATH}/brute_weak`,
        `${NEGATIVE_TRAIT_PATH}/brute_weak_plus`,
        `${NEGATIVE_TRAIT_PATH}/minor_burn_weak`,
        `${NEGATIVE_TRAIT_PATH}/burn_weak`,
        `${NEGATIVE_TRAIT_PATH}/burn_weak_plus`,
        `${NEGATIVE_TRAIT_PATH}/conductive`,
        `${NEGATIVE_TRAIT_PATH}/conductive_plus`,
      ],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.vision,
      roots: [`${NEGATIVE_TRAIT_PATH}/dark_blind`],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.marksmanship,
      roots: [`${NEGATIVE_TRAIT_PATH}/bad_shooter`],
    },
    {
      ...SHARED_TRAIT_GROUP_PRESENTATION.languages,
      roots: [`${NEGATIVE_TRAIT_PATH}/monolingual`],
    },
    {
      id: 'breathing',
      name: 'Breathing Requirements',
      icon: 'lungs',
      roots: [`${NEGATIVE_TRAIT_PATH}/breathes`],
      traitOrder: [
        `${NEGATIVE_TRAIT_PATH}/breathes/phoron`,
        `${NEGATIVE_TRAIT_PATH}/breathes/nitrogen`,
      ],
    },
  ],
};

const FALLBACK_TRAIT_GROUPS: Record<TraitCategoryId, TraitGroupDefinition> = {
  positive: {
    id: 'other_positive',
    name: 'Other Advantages',
    icon: 'plus-circle',
  },
  neutral: {
    id: 'other_neutral',
    name: 'Other Neutral Traits',
    icon: 'compass',
  },
  negative: {
    id: 'other_negative',
    name: 'Other Tradeoffs',
    icon: 'exclamation-triangle',
  },
};

const traitMatchesGroup = (
  trait: CharacterTraitEntry,
  group: TraitGroupDefinition
) =>
  !!group.roots?.some(
    (root) => trait.id === root || trait.id.startsWith(`${root}/`)
  ) || !!group.prefixes?.some((prefix) => trait.id.startsWith(prefix));

const resolveTraitGroupDefinition = (
  trait: CharacterTraitEntry,
  category: TraitCategoryId
) =>
  TRAIT_GROUP_DEFINITIONS[category].find((candidate) =>
    traitMatchesGroup(trait, candidate)
  ) || FALLBACK_TRAIT_GROUPS[category];

const buildVisibleTraitGroups = (
  traits: CharacterTraitEntry[],
  category: TraitCategoryId
): VisibleTraitGroup[] => {
  const definitions = TRAIT_GROUP_DEFINITIONS[category];
  const fallback = FALLBACK_TRAIT_GROUPS[category];
  const groupedTraits: Record<string, CharacterTraitEntry[]> = {};
  for (const trait of traits) {
    const definition = resolveTraitGroupDefinition(trait, category);
    if (!groupedTraits[definition.id]) {
      groupedTraits[definition.id] = [];
    }
    groupedTraits[definition.id].push(trait);
  }
  return [...definitions, fallback]
    .map((definition) => {
      const groupTraits = sortTraitsByConfiguredOrder(
        groupedTraits[definition.id] || [],
        definition.traitOrder
      );
      return {
        ...definition,
        traits: groupTraits,
        selectedCount: groupTraits.filter((trait) => trait.selected).length,
      };
    })
    .filter((group) => group.traits.length > 0);
};

const formatPreferenceValue = (preference: TraitPreferenceEntry) => {
  if (preference.kind === 'boolean') {
    return preference.value ? 'Enabled' : 'Disabled';
  }
  if (
    preference.value === null ||
    preference.value === undefined ||
    preference.value === ''
  ) {
    return 'Not set';
  }
  return String(preference.value);
};

type TraitPreferenceEditorState = Readonly<{
  traitId: string;
  preferenceId: string;
  value: TraitPreferenceValue;
}>;

type SelectedTraitPopoverMode = 'settings' | 'details';

type SelectedTraitPopoverState = Readonly<{
  traitId: string;
  mode: SelectedTraitPopoverMode;
}>;

const isTraitPreferenceValueValid = (
  preference: TraitPreferenceEntry,
  value: TraitPreferenceValue
) => {
  if (preference.kind === 'color') {
    return typeof value === 'string' && !!normalizeHex(value);
  }
  if (preference.kind === 'string') {
    return typeof value === 'string' && value.length >= 3 && value.length <= 40;
  }
  if (preference.kind === 'number') {
    return typeof value === 'number' && Number.isFinite(value);
  }
  if (preference.kind === 'list') {
    return (
      typeof value === 'string' &&
      (!preference.options?.length || preference.options.includes(value))
    );
  }
  return true;
};

const TraitPreferenceEditor = ({
  trait,
  preference,
  editor,
  onChange,
  onConfirm,
  onCancel,
}: Readonly<{
  trait: CharacterTraitEntry;
  preference: TraitPreferenceEntry;
  editor: TraitPreferenceEditorState;
  onChange: (value: TraitPreferenceValue) => void;
  onConfirm: () => void;
  onCancel: () => void;
}>) => {
  const valueIsValid = isTraitPreferenceValueValid(preference, editor.value);
  const colorValue =
    typeof editor.value === 'string'
      ? normalizeHex(editor.value) || '#ffffff'
      : '#ffffff';
  return (
    <Modal width="680px" maxWidth="90%" maxHeight="90%" mx="auto">
      <Section
        title={`${trait.name}: ${preference.label}`}
        buttons={<Button icon="times" onClick={onCancel} />}>
        <Box className="RogueStar__inlineColorPicker">
          <RogueStarColorPicker
            color={colorValue}
            currentColor={
              typeof preference.value === 'string'
                ? preference.value
                : colorValue
            }
            onChange={onChange}
            onCommit={onChange}
            showCustomColors={false}
          />
        </Box>
        <Flex mt={1} justify="flex-end" gap={0.5}>
          <Button className={CHIP_BUTTON_CLASS} icon="times" onClick={onCancel}>
            Cancel
          </Button>
          <Button
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
            icon="check"
            disabled={!valueIsValid}
            onClick={onConfirm}>
            Apply
          </Button>
        </Flex>
      </Section>
    </Modal>
  );
};

type TraitStringPreferenceInputProps = Readonly<{
  preference: TraitPreferenceEntry;
  disabled: boolean;
  onChange: (value: string) => void;
}>;

type TraitStringPreferenceInputState = Readonly<{
  value: string;
}>;

class TraitStringPreferenceInput extends Component<
  TraitStringPreferenceInputProps,
  TraitStringPreferenceInputState
> {
  state: TraitStringPreferenceInputState = {
    value: this.resolveExternalValue(this.props),
  };

  componentDidUpdate(prevProps: TraitStringPreferenceInputProps) {
    if (prevProps.preference.value === this.props.preference.value) {
      return;
    }
    const value = this.resolveExternalValue(this.props);
    if (value !== this.state.value) {
      this.setState({ value });
    }
  }

  resolveExternalValue(props: TraitStringPreferenceInputProps) {
    return typeof props.preference.value === 'string'
      ? props.preference.value
      : '';
  }

  handleInput = (_event, value: string) => {
    if (this.props.disabled) {
      return;
    }
    this.setState({ value });
    if (isTraitPreferenceValueValid(this.props.preference, value)) {
      this.props.onChange(value);
    }
  };

  handleCommit = (event, value: string) => {
    const externalValue = this.resolveExternalValue(this.props);
    if (
      this.props.disabled ||
      !isTraitPreferenceValueValid(this.props.preference, value)
    ) {
      event.target.value = externalValue;
      this.setState({ value: externalValue });
      return;
    }
    if (value !== externalValue) {
      this.props.onChange(value);
    }
  };

  handleEscape = (event) => {
    const value = this.resolveExternalValue(this.props);
    event.target.value = value;
    event.target.blur();
    this.setState({ value });
  };

  render() {
    const { preference } = this.props;
    const { value } = this.state;
    const valid = isTraitPreferenceValueValid(preference, value);
    return (
      <>
        <Input
          fluid
          className={`RogueStar__traitPreferenceInput${
            valid ? '' : ' RogueStar__traitPreferenceInput--invalid'
          }`}
          maxLength={40}
          value={value}
          onInput={this.handleInput}
          onChange={this.handleCommit}
          onEscape={this.handleEscape}
        />
        {!valid ? (
          <Box className="RogueStar__traitPreferenceValidation">
            Use 3–40 characters.
          </Box>
        ) : null}
      </>
    );
  }
}

const TraitPreferenceControl = ({
  trait,
  preference,
  disabled,
  onChange,
  onEditColor,
}: Readonly<{
  trait: CharacterTraitEntry;
  preference: TraitPreferenceEntry;
  disabled: boolean;
  onChange: (
    traitId: string,
    preferenceId: string,
    value: TraitPreferenceValue
  ) => void;
  onEditColor: (traitId: string, preferenceId: string) => void;
}>) => {
  const booleanEnabled = preference.kind === 'boolean' && !!preference.value;
  const stringValue =
    typeof preference.value === 'string' ? preference.value : '';
  const colorValue =
    preference.kind === 'color'
      ? normalizeHex(stringValue) || '#ffffff'
      : '#ffffff';
  const control =
    preference.kind === 'boolean' ? (
      <Button
        className="RogueStar__traitPreferenceValue"
        verticalAlignContent="middle"
        selected={booleanEnabled}
        icon={booleanEnabled ? 'toggle-on' : 'toggle-off'}
        disabled={disabled}
        onClick={() => onChange(trait.id, preference.id, !booleanEnabled)}>
        {formatPreferenceValue(preference)}
      </Button>
    ) : preference.kind === 'color' ? (
      <Button
        className="RogueStar__traitPreferenceValue"
        verticalAlignContent="middle"
        icon="palette"
        disabled={disabled}
        onClick={() => onEditColor(trait.id, preference.id)}>
        <Box
          as="span"
          className="RogueStar__traitPreferenceSwatch"
          backgroundColor={colorValue}
        />
        {formatPreferenceValue(preference)}
      </Button>
    ) : preference.kind === 'string' ? (
      <TraitStringPreferenceInput
        preference={preference}
        disabled={disabled}
        onChange={(value) => onChange(trait.id, preference.id, value)}
      />
    ) : preference.kind === 'number' ? (
      <NumberInput
        className="RogueStar__numberInput RogueStar__traitPreferenceNumber"
        width="100%"
        minValue={0}
        maxValue={5}
        step={1}
        value={
          typeof preference.value === 'number' ? preference.value : Number(0)
        }
        onChange={(_event, value) => {
          if (!disabled) {
            onChange(trait.id, preference.id, value ?? 0);
          }
        }}
      />
    ) : (
      <Dropdown
        key={stringValue}
        className="RogueStar__traitPreferenceDropdown"
        controlContentClassName="Button__content RogueStar__traitPreferenceDropdownContent"
        color="transparent"
        width="100%"
        menuZIndex={21}
        dropdownStyle="rogue-star"
        options={preference.options || []}
        selected={stringValue}
        displayText={stringValue || 'Choose an option'}
        disabled={disabled}
        onSelected={(value) =>
          typeof value === 'string' && onChange(trait.id, preference.id, value)
        }
      />
    );
  return (
    <Box className="RogueStar__traitPreference">
      <Box className="RogueStar__traitPreferenceLabel">{preference.label}</Box>
      {control}
    </Box>
  );
};

const TraitDescriptionTooltip = ({
  trait,
  showSettingsHint = false,
  showDetailHint = true,
}: Readonly<{
  trait: CharacterTraitEntry;
  showSettingsHint?: boolean;
  showDetailHint?: boolean;
}>) => {
  const showAvailableDetailHint = showDetailHint && !!trait.tutorial;
  return (
    <Box className="RogueStar__traitDescriptionTooltip">
      <Box>{trait.description}</Box>
      {trait.warning_reason ? (
        <Box className="RogueStar__traitTooltipReason RogueStar__traitTooltipReason--warning">
          <Icon name="triangle-exclamation" /> {trait.warning_reason}
        </Box>
      ) : trait.disabled_reason ? (
        <Box className="RogueStar__traitTooltipReason">
          <Icon name="lock" /> {trait.disabled_reason}
        </Box>
      ) : null}
      {showSettingsHint || showAvailableDetailHint ? (
        <Box className="RogueStar__traitTooltipHint">
          {showSettingsHint ? <Box>Left-click for trait settings.</Box> : null}
          {showAvailableDetailHint ? (
            <Box>Right-click for the detailed guide.</Box>
          ) : null}
        </Box>
      ) : null}
    </Box>
  );
};

const TraitDetailPopover = ({
  trait,
}: Readonly<{
  trait: CharacterTraitEntry;
}>) => (
  <Box className="RogueStar__traitDetailPopover">
    <Box className="RogueStar__traitDetailEyebrow">Detailed guide</Box>
    <Box className="RogueStar__traitDetailTitle">{trait.name}</Box>
    {trait.tutorial ? (
      <Box
        className="RogueStar__traitDetailGuide"
        dangerouslySetInnerHTML={{
          __html: sanitizeText(trait.tutorial, false, ['br', 'b', 'i']),
        }}
      />
    ) : null}
  </Box>
);

const TraitSettingsPopover = ({
  trait,
  controlsLocked,
  onChangePreference,
  onEditColorPreference,
}: Readonly<{
  trait: CharacterTraitEntry;
  controlsLocked: boolean;
  onChangePreference: (
    traitId: string,
    preferenceId: string,
    value: TraitPreferenceValue
  ) => void;
  onEditColorPreference: (traitId: string, preferenceId: string) => void;
}>) => (
  <Box
    className={`RogueStar__traitSettingsPopover${
      controlsLocked ? ' RogueStar__traitSettingsPopover--locked' : ''
    }`}>
    <Box className="RogueStar__traitDetailEyebrow">Trait settings</Box>
    <Box className="RogueStar__traitDetailTitle">{trait.name}</Box>
    <Box className="RogueStar__traitSettingsGrid">
      {trait.preferences?.map((preference) => (
        <TraitPreferenceControl
          key={preference.id}
          trait={trait}
          preference={preference}
          disabled={controlsLocked}
          onChange={onChangePreference}
          onEditColor={onEditColorPreference}
        />
      ))}
    </Box>
  </Box>
);

const TraitCard = ({
  trait,
  category,
  controlsLocked,
  detailOpen,
  onToggle,
  onToggleDetail,
}: Readonly<{
  trait: CharacterTraitEntry;
  category: TraitCategoryId;
  controlsLocked: boolean;
  detailOpen: boolean;
  onToggle: (traitId: string) => void;
  onToggleDetail: (traitId: string) => void;
}>) => {
  const selected = !!trait.selected;
  const disabled = !selected && !!trait.disabled_reason;
  const hasDetails = !!trait.tutorial;
  const tile = (
    <Button
      fluid
      selected={selected}
      className={`RogueStar__traitTile RogueStar__traitTile--${category}${
        selected ? ' RogueStar__traitTile--selected' : ''
      }${disabled ? ' RogueStar__traitTile--disabled' : ''}${
        trait.warning_reason ? ' RogueStar__traitTile--warning' : ''
      }`}
      tooltip={
        detailOpen && hasDetails ? undefined : (
          <TraitDescriptionTooltip trait={trait} />
        )
      }
      tooltipPosition="right"
      aria-label={`${selected ? 'Remove' : 'Add'} ${trait.name}`}
      aria-pressed={selected}
      aria-haspopup={hasDetails ? 'dialog' : undefined}
      aria-expanded={hasDetails ? detailOpen : undefined}
      disabled={controlsLocked || disabled}
      onClick={() => onToggle(trait.id)}
      onContextMenu={
        hasDetails
          ? (event) => {
              event.preventDefault();
              event.stopPropagation();
              onToggleDetail(trait.id);
            }
          : undefined
      }>
      <Box className="RogueStar__traitTileName">{trait.name}</Box>
    </Button>
  );
  return detailOpen && hasDetails ? (
    <Popper
      additionalStyles={{ 'z-index': '20' }}
      options={{
        placement: 'right-start',
        modifiers: [
          { name: 'offset', options: { offset: [0, 8] } },
          {
            name: 'flip',
            options: { fallbackPlacements: ['left-start', 'bottom-start'] },
          },
          { name: 'preventOverflow', options: { padding: 12 } },
        ],
      }}
      popperContent={<TraitDetailPopover trait={trait} />}>
      {tile}
    </Popper>
  ) : (
    tile
  );
};

const TraitGroupTitle = ({
  group,
  category,
}: Readonly<{
  group: VisibleTraitGroup;
  category: TraitCategoryId;
}>) => (
  <Flex
    className={`RogueStar__traitGroupHeader RogueStar__traitGroupHeader--${category}`}
    align="center"
    gap={0.65}
    wrap={false}>
    <Flex.Item shrink={0}>
      <Box className="RogueStar__traitGroupIcon">
        <Icon name={group.icon} />
      </Box>
    </Flex.Item>
    <Flex.Item grow minWidth={0}>
      <Box className="RogueStar__traitGroupName">{group.name}</Box>
    </Flex.Item>
    {group.selectedCount > 0 ? (
      <Flex.Item shrink={0}>
        <Box className="RogueStar__traitGroupSelected">
          <Icon name="star" /> {group.selectedCount} selected
        </Box>
      </Flex.Item>
    ) : null}
    <Flex.Item shrink={0}>
      <Box className="RogueStar__traitGroupCount">
        {group.traits.length} {group.traits.length === 1 ? 'trait' : 'traits'}
      </Box>
    </Flex.Item>
  </Flex>
);

const TraitGroupSection = ({
  group,
  category,
  open,
  controlsLocked,
  openDetailTraitId,
  onToggle,
  onToggleDetail,
}: Readonly<{
  group: VisibleTraitGroup;
  category: TraitCategoryId;
  open: boolean;
  controlsLocked: boolean;
  openDetailTraitId: string | null;
  onToggle: (traitId: string) => void;
  onToggleDetail: (traitId: string) => void;
}>) => (
  <Box className={`RogueStar__traitGroup RogueStar__traitGroup--${category}`}>
    <Collapsible
      open={open}
      className={`RogueStar__traitGroupToggle RogueStar__traitGroupToggle--${category}`}
      title={<TraitGroupTitle group={group} category={category} />}>
      <Box className="RogueStar__traitGrid">
        {group.traits.map((trait) => (
          <TraitCard
            key={trait.id}
            trait={trait}
            category={category}
            controlsLocked={controlsLocked}
            detailOpen={openDetailTraitId === trait.id}
            onToggle={onToggle}
            onToggleDetail={onToggleDetail}
          />
        ))}
      </Box>
    </Collapsible>
  </Box>
);

const TraitCategoryButton = ({
  category,
  positiveLimit,
  selected,
  onSelect,
}: Readonly<{
  category: CharacterTraitCategory;
  positiveLimit: number;
  selected: boolean;
  onSelect: (category: TraitCategoryId) => void;
}>) => {
  const presentation = getCategoryPresentation(category.id);
  return (
    <Button
      fluid
      selected={selected}
      className={`RogueStar__traitCategoryButton RogueStar__traitCategoryButton--${category.id}`}
      onClick={() => onSelect(category.id)}>
      <Box className="RogueStar__traitCategoryIcon">
        <Icon name={presentation.icon} />
      </Box>
      <Box className="RogueStar__traitCategoryCopy">
        <Flex align="center" justify="space-between" wrap={false}>
          <Box className="RogueStar__traitCategoryName">{category.name}</Box>
          <Box className="RogueStar__traitCategoryCount">
            {category.id === 'positive'
              ? `${category.selected_count}/${positiveLimit}`
              : category.selected_count}
          </Box>
        </Flex>
      </Box>
    </Button>
  );
};

const LanguageCategoryButton = ({
  languages,
  selected,
  onSelect,
}: Readonly<{
  languages: CharacterLanguagesPayload;
  selected: boolean;
  onSelect: () => void;
}>) => (
  <Button
    fluid
    selected={selected}
    className="RogueStar__traitCategoryButton RogueStar__traitCategoryButton--languages"
    onClick={onSelect}>
    <Box className="RogueStar__traitCategoryIcon">
      <Icon name={getCategoryPresentation('languages').icon} />
    </Box>
    <Box className="RogueStar__traitCategoryCopy">
      <Flex align="center" justify="space-between" wrap={false}>
        <Box className="RogueStar__traitCategoryName">Languages</Box>
        <Box className="RogueStar__traitCategoryCount">
          {languages.selected_optional_count}/{languages.optional_limit}
        </Box>
      </Flex>
    </Box>
  </Button>
);

const LanguageDescriptionTooltip = ({
  language,
  selectedRow = false,
}: Readonly<{
  language: CharacterLanguageEntry;
  selectedRow?: boolean;
}>) => (
  <Box className="RogueStar__traitDescriptionTooltip">
    <Box>{language.description}</Box>
    <Box className="RogueStar__languageTooltipStatus">
      {language.automatic
        ? 'Known automatically.'
        : language.selected
          ? 'Uses one optional language slot.'
          : language.selectable
            ? 'Available as an optional language.'
            : language.preferred_eligible
              ? 'Available only as a preferred-language fallback.'
              : 'Unavailable to this character.'}
    </Box>
    {language.disabled_reason ? (
      <Box className="RogueStar__traitTooltipReason">
        <Icon name="lock" /> {language.disabled_reason}
      </Box>
    ) : null}
    <Box className="RogueStar__traitTooltipHint">
      {selectedRow ? <Box>Left-click for language settings.</Box> : null}
      {language.preferred_eligible ? (
        <Box>Right-click to make this the preferred language.</Box>
      ) : null}
    </Box>
  </Box>
);

const LanguageCatalogTile = ({
  language,
  controlsLocked,
  onToggle,
  onSetPreferred,
}: Readonly<{
  language: CharacterLanguageEntry;
  controlsLocked: boolean;
  onToggle: (languageId: string) => void;
  onSetPreferred: (languageId: string) => void;
}>) => {
  const selected = !!language.selected;
  const canToggle = !!language.selectable || (selected && !language.automatic);
  const optionalUnavailable =
    !selected && !!language.selectable && !!language.disabled_reason;
  const cannotSelect = !selected && !language.selectable;
  const unavailable = cannotSelect && !language.preferred_eligible;
  return (
    <Button
      fluid
      selected={selected}
      className={`RogueStar__traitTile RogueStar__languageTile${
        selected ? ' RogueStar__traitTile--selected' : ''
      }${language.automatic ? ' RogueStar__languageTile--automatic' : ''}${
        language.preferred ? ' RogueStar__languageTile--preferred' : ''
      }${
        optionalUnavailable || cannotSelect
          ? ' RogueStar__traitTile--disabled'
          : ''
      }`}
      tooltip={<LanguageDescriptionTooltip language={language} />}
      tooltipPosition="right"
      aria-label={`${selected ? 'Remove' : 'Add'} ${language.name}${
        language.preferred_eligible ? '; right-click to make preferred' : ''
      }`}
      aria-pressed={selected}
      disabled={controlsLocked || optionalUnavailable || unavailable}
      onClick={canToggle ? () => onToggle(language.id) : undefined}
      onContextMenu={
        language.preferred_eligible
          ? (event) => {
              event.preventDefault();
              event.stopPropagation();
              if (!controlsLocked) {
                onSetPreferred(language.id);
              }
            }
          : undefined
      }>
      <Flex align="center" justify="center" gap={0.35} wrap={false}>
        {language.preferred ? <Icon name="star" /> : null}
        <Box className="RogueStar__traitTileName">{language.name}</Box>
        {language.automatic ? (
          <Flex.Item
            shrink={0}
            className="RogueStar__languageAutomaticIconControl">
            <Icon className="RogueStar__languageAutomaticIcon" name="lock" />
          </Flex.Item>
        ) : null}
      </Flex>
    </Button>
  );
};

const LanguageSettingsPopover = ({
  language,
  controlsLocked,
  error,
  onChangeCustomKey,
  onClearCustomKey,
  onSetPreferred,
}: Readonly<{
  language: CharacterLanguageEntry;
  controlsLocked: boolean;
  error: string | null;
  onChangeCustomKey: (value: string) => void;
  onClearCustomKey: () => void;
  onSetPreferred: () => void;
}>) => {
  const canCustomize = !!language.selected;
  return (
    <Box className="RogueStar__traitSettingsPopover RogueStar__languageSettingsPopover">
      <Box className="RogueStar__traitDetailEyebrow">Language settings</Box>
      <Box className="RogueStar__traitDetailTitle">{language.name}</Box>
      <Box className="RogueStar__languageSettingsDescription">
        {language.description}
      </Box>
      <Box className="RogueStar__traitSettingsGrid">
        <Box className="RogueStar__traitPreference">
          <Box className="RogueStar__traitPreferenceLabel">Custom key</Box>
          <Flex className="RogueStar__languageCustomKeyControl" wrap={false}>
            <Flex.Item grow minWidth={0}>
              <Input
                fluid
                className="RogueStar__traitPreferenceInput RogueStar__languageCustomKeyInput"
                value={language.custom_key || ''}
                maxLength={1}
                placeholder="None"
                disabled={controlsLocked || !canCustomize}
                onInput={(_event, value) => onChangeCustomKey(value)}
              />
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Button
                className="RogueStar__selectedTraitRemoveButton RogueStar__languageCustomKeyResetButton"
                icon="times"
                tooltip="Reset custom key"
                aria-label="Reset custom key"
                disabled={
                  controlsLocked || !canCustomize || !language.custom_key
                }
                onClick={onClearCustomKey}
              />
            </Flex.Item>
          </Flex>
          <Box className="RogueStar__languageSettingsHint">
            One case-sensitive letter or number.
          </Box>
          {error ? (
            <Box className="RogueStar__traitPreferenceValidation">{error}</Box>
          ) : null}
        </Box>
        <Box className="RogueStar__traitPreference">
          <Box className="RogueStar__traitPreferenceLabel">
            Preferred language
          </Box>
          <Button
            fluid
            selected={!!language.preferred}
            className="RogueStar__traitPreferenceValue RogueStar__languagePreferredControl"
            icon="star"
            verticalAlignContent="middle"
            disabled={controlsLocked || !language.preferred_eligible}
            onClick={onSetPreferred}>
            {language.preferred ? 'Currently Preferred' : 'Set Preferred'}
          </Button>
        </Box>
      </Box>
    </Box>
  );
};

const SelectedLanguageCard = ({
  language,
  controlsLocked,
  settingsOpen,
  settingsError,
  onToggleSettings,
  onRemove,
  onChangeCustomKey,
  onClearCustomKey,
  onSetPreferred,
}: Readonly<{
  language: CharacterLanguageEntry;
  controlsLocked: boolean;
  settingsOpen: boolean;
  settingsError: string | null;
  onToggleSettings: (languageId: string) => void;
  onRemove: (languageId: string) => void;
  onChangeCustomKey: (languageId: string, value: string) => void;
  onClearCustomKey: (languageId: string) => void;
  onSetPreferred: (languageId: string) => void;
}>) => {
  const actionButton = (
    <Button
      fluid
      verticalAlignContent="middle"
      className="RogueStar__selectedTraitButton"
      tooltip={
        settingsOpen ? undefined : (
          <LanguageDescriptionTooltip language={language} selectedRow />
        )
      }
      tooltipPosition="left"
      aria-label={`${language.name}; left-click for settings${
        language.preferred_eligible ? '; right-click to make preferred' : ''
      }`}
      aria-haspopup="dialog"
      aria-expanded={settingsOpen}
      disabled={controlsLocked}
      onClick={() => onToggleSettings(language.id)}
      onContextMenu={
        language.preferred_eligible
          ? (event) => {
              event.preventDefault();
              event.stopPropagation();
              if (!controlsLocked) {
                onSetPreferred(language.id);
              }
            }
          : undefined
      }>
      <Flex align="center" gap={0.35} wrap={false}>
        {language.preferred ? (
          <Flex.Item shrink={0}>
            <Icon className="RogueStar__languagePreferredIcon" name="star" />
          </Flex.Item>
        ) : null}
        <Flex.Item grow minWidth={0}>
          <Box className="RogueStar__selectedTraitName">{language.name}</Box>
        </Flex.Item>
        {language.custom_key ? (
          <Flex.Item shrink={0}>
            <Box className="RogueStar__languageCustomKey">
              {language.custom_key}
            </Box>
          </Flex.Item>
        ) : null}
        <Flex.Item
          shrink={0}
          className="RogueStar__selectedLanguageSettingsControl">
          <Icon className="RogueStar__selectedTraitSettings" name="sliders-h" />
        </Flex.Item>
      </Flex>
    </Button>
  );
  const anchoredAction = settingsOpen ? (
    <Popper
      additionalStyles={{ 'z-index': '20' }}
      options={{
        placement: 'left-start',
        modifiers: [
          { name: 'offset', options: { offset: [0, 8] } },
          {
            name: 'flip',
            options: { fallbackPlacements: ['right-start', 'bottom-start'] },
          },
          { name: 'preventOverflow', options: { padding: 12 } },
        ],
      }}
      popperContent={
        <LanguageSettingsPopover
          language={language}
          controlsLocked={controlsLocked}
          error={settingsError}
          onChangeCustomKey={(value) => onChangeCustomKey(language.id, value)}
          onClearCustomKey={() => onClearCustomKey(language.id)}
          onSetPreferred={() => onSetPreferred(language.id)}
        />
      }>
      {actionButton}
    </Popper>
  ) : (
    actionButton
  );
  const canRemove = !!language.selected && !language.automatic;
  return (
    <Box
      className={`RogueStar__selectedTraitCard RogueStar__selectedLanguageCard${
        settingsOpen ? ' RogueStar__selectedTraitCard--open' : ''
      }${
        language.preferred ? ' RogueStar__selectedLanguageCard--preferred' : ''
      }`}>
      <Flex align="center" wrap={false}>
        <Flex.Item grow minWidth={0}>
          {anchoredAction}
        </Flex.Item>
        <Flex.Item shrink={0}>
          {canRemove ? (
            <Button
              className="RogueStar__selectedTraitRemoveButton"
              icon="times"
              verticalAlignContent="middle"
              tooltip={`Remove ${language.name}`}
              tooltipPosition="left"
              aria-label={`Remove ${language.name}`}
              disabled={controlsLocked}
              onClick={() => onRemove(language.id)}
            />
          ) : (
            <Box
              className="RogueStar__languageLockedBadge"
              title={language.automatic ? 'Known automatically' : 'Preferred'}>
              <Icon name={language.automatic ? 'lock' : 'star'} />
            </Box>
          )}
        </Flex.Item>
      </Flex>
    </Box>
  );
};

const SelectedLanguagesSection = ({
  languages,
  controlsLocked,
  openLanguageId,
  settingsError,
  validationError,
  onToggleSettings,
  onRemove,
  onChangeCustomKey,
  onClearCustomKey,
  onSetPreferred,
}: Readonly<{
  languages: CharacterLanguagesPayload;
  controlsLocked: boolean;
  openLanguageId: string | null;
  settingsError: string | null;
  validationError: string | null;
  onToggleSettings: (languageId: string) => void;
  onRemove: (languageId: string) => void;
  onChangeCustomKey: (languageId: string, value: string) => void;
  onClearCustomKey: (languageId: string) => void;
  onSetPreferred: (languageId: string) => void;
}>) => {
  const selectedLanguages = sortLanguagesAlphabetically(
    languages.entries.filter(
      (language) => !!language.selected || !!language.preferred
    )
  );
  return (
    <Section
      className="RogueStar__selectedTraits RogueStar__selectedLanguages"
      title="Selected Languages"
      fill
      scrollable
      buttons={
        <Box className="RogueStar__selectedTraitsCount">
          {languages.selected_optional_count}/{languages.optional_limit}{' '}
          optional
        </Box>
      }>
      {validationError ? (
        <NoticeBox danger mb={1}>
          {validationError}
        </NoticeBox>
      ) : null}
      {selectedLanguages.length ? (
        <Box className="RogueStar__selectedTraitList RogueStar__selectedLanguageList">
          {selectedLanguages.map((language) => (
            <SelectedLanguageCard
              key={language.id}
              language={language}
              controlsLocked={controlsLocked}
              settingsOpen={openLanguageId === language.id}
              settingsError={
                openLanguageId === language.id ? settingsError : null
              }
              onToggleSettings={onToggleSettings}
              onRemove={onRemove}
              onChangeCustomKey={onChangeCustomKey}
              onClearCustomKey={onClearCustomKey}
              onSetPreferred={onSetPreferred}
            />
          ))}
        </Box>
      ) : (
        <Box className="RogueStar__selectedTraitsEmpty">
          <Icon name="language" />
          <Box className="RogueStar__selectedTraitsEmptyTitle">
            No languages available
          </Box>
          <Box className="RogueStar__selectedTraitsEmptyCopy">
            This species has no language choices in the current catalog.
          </Box>
        </Box>
      )}
    </Section>
  );
};

const LanguageKeysSection = ({
  languages,
  controlsLocked,
  onChange,
  onReset,
}: Readonly<{
  languages: CharacterLanguagesPayload;
  controlsLocked: boolean;
  onChange: () => void;
  onReset: () => void;
}>) => (
  <Section
    className="RogueStar__languageKeysSection"
    title="Language Keys"
    buttons={
      <Flex gap={0.35}>
        <Button
          className={CHIP_BUTTON_CLASS}
          icon="pen"
          disabled={controlsLocked}
          onClick={onChange}>
          Change
        </Button>
        <Button
          className={CHIP_BUTTON_CLASS}
          icon="undo"
          disabled={controlsLocked}
          onClick={onReset}>
          Reset
        </Button>
      </Flex>
    }>
    <Flex align="center" gap={0.35} wrap>
      <Box className="RogueStar__languageKeysCopy">
        Prefix spoken language with one of these keys:
      </Box>
      {languages.language_prefixes.map((prefix, index) => (
        <Box
          key={`${prefix}-${index}`}
          className="RogueStar__languagePrefixKey">
          {prefix === ' ' ? 'Space' : prefix}
        </Box>
      ))}
    </Flex>
  </Section>
);

const isLanguagePrefixValid = (prefix: string) =>
  prefix.length === 1 &&
  !/[A-Za-z0-9]/.test(prefix) &&
  ![';', ':', '.', '!', '*', '^', '-'].includes(prefix);

const LanguagePrefixEditor = ({
  prefixes,
  onChange,
  onConfirm,
  onCancel,
}: Readonly<{
  prefixes: string[];
  onChange: (prefixes: string[]) => void;
  onConfirm: () => void;
  onCancel: () => void;
}>) => {
  const selectedPrefixes = prefixes.filter((prefix) => prefix.length > 0);
  const valid =
    selectedPrefixes.length > 0 &&
    selectedPrefixes.length <= 3 &&
    selectedPrefixes.every(isLanguagePrefixValid);
  return (
    <Modal width="480px" maxWidth="90%" maxHeight="90%" mx="auto">
      <Section
        title="Change Language Keys"
        buttons={<Button icon="times" onClick={onCancel} />}>
        <Box mb={1}>
          Choose one to three single special characters. Letters, numbers, radio
          prefixes (; : .), and say prefixes (! * ^ -) are unavailable. Repeated
          characters are allowed.
        </Box>
        <Flex gap={0.5} justify="center" wrap={false}>
          {prefixes.map((prefix, index) => (
            <Flex.Item key={index} basis="92px">
              <Box className="RogueStar__traitPreferenceLabel">
                Key {index + 1}
              </Box>
              <Input
                fluid
                className={`RogueStar__traitPreferenceInput${
                  !prefix || isLanguagePrefixValid(prefix)
                    ? ''
                    : ' RogueStar__traitPreferenceInput--invalid'
                }`}
                value={prefix}
                maxLength={1}
                aria-label={`Language key ${index + 1}`}
                onInput={(_event, value) => {
                  const nextPrefixes = [...prefixes];
                  nextPrefixes[index] = value;
                  onChange(nextPrefixes);
                }}
              />
            </Flex.Item>
          ))}
        </Flex>
        {!valid ? (
          <NoticeBox danger mt={1}>
            Enter one to three allowed special characters.
          </NoticeBox>
        ) : null}
        <Flex mt={1} justify="flex-end" gap={0.5}>
          <Button className={CHIP_BUTTON_CLASS} icon="times" onClick={onCancel}>
            Cancel
          </Button>
          <Button
            className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
            icon="check"
            disabled={!valid}
            onClick={onConfirm}>
            Apply
          </Button>
        </Flex>
      </Section>
    </Modal>
  );
};

const SelectedTraitCard = ({
  trait,
  category,
  controlsLocked,
  openMode,
  onTogglePopover,
  onRemove,
  onChangePreference,
  onEditColorPreference,
}: Readonly<{
  trait: CharacterTraitEntry;
  category: TraitCategoryId;
  controlsLocked: boolean;
  openMode: SelectedTraitPopoverMode | null;
  onTogglePopover: (traitId: string, mode: SelectedTraitPopoverMode) => void;
  onRemove: (traitId: string) => void;
  onChangePreference: (
    traitId: string,
    preferenceId: string,
    value: TraitPreferenceValue
  ) => void;
  onEditColorPreference: (traitId: string, preferenceId: string) => void;
}>) => {
  const hasSettings = !!trait.preferences?.length;
  const hasDetails = !!trait.tutorial;
  const settingsOpen = hasSettings && openMode === 'settings';
  const detailsOpen = hasDetails && openMode === 'details';
  const popoverOpen = settingsOpen || detailsOpen;
  const actionButton = (
    <Button
      fluid
      verticalAlignContent="middle"
      className="RogueStar__selectedTraitButton"
      tooltip={
        popoverOpen ? undefined : (
          <TraitDescriptionTooltip
            trait={trait}
            showSettingsHint={hasSettings}
          />
        )
      }
      tooltipPosition="left"
      aria-label={`${trait.name}${
        hasSettings ? '; left-click for trait settings' : ''
      }${hasDetails ? '; right-click for detailed guide' : ''}`}
      aria-haspopup={hasSettings || hasDetails ? 'dialog' : undefined}
      aria-expanded={hasSettings || hasDetails ? popoverOpen : undefined}
      disabled={controlsLocked}
      onClick={
        hasSettings ? () => onTogglePopover(trait.id, 'settings') : undefined
      }
      onContextMenu={
        hasDetails
          ? (event) => {
              event.preventDefault();
              event.stopPropagation();
              onTogglePopover(trait.id, 'details');
            }
          : undefined
      }>
      <Flex align="center" gap={0.4} wrap={false}>
        <Flex.Item grow minWidth={0}>
          <Box className="RogueStar__selectedTraitName">{trait.name}</Box>
        </Flex.Item>
        {trait.warning_reason ? (
          <Flex.Item shrink={0}>
            <Icon
              className="RogueStar__selectedTraitWarning"
              name="triangle-exclamation"
            />
          </Flex.Item>
        ) : null}
        {hasSettings ? (
          <Flex.Item shrink={0}>
            <Icon
              className="RogueStar__selectedTraitSettings"
              name="sliders-h"
            />
          </Flex.Item>
        ) : null}
        {hasDetails ? (
          <Flex.Item shrink={0}>
            <Icon
              className="RogueStar__selectedTraitDetails"
              name="book-open"
            />
          </Flex.Item>
        ) : null}
      </Flex>
    </Button>
  );
  const anchoredAction = popoverOpen ? (
    <Popper
      additionalStyles={{ 'z-index': '20' }}
      options={{
        placement: 'left-start',
        modifiers: [
          { name: 'offset', options: { offset: [0, 8] } },
          {
            name: 'flip',
            options: { fallbackPlacements: ['right-start', 'bottom-start'] },
          },
          { name: 'preventOverflow', options: { padding: 12 } },
        ],
      }}
      popperContent={
        settingsOpen ? (
          <TraitSettingsPopover
            trait={trait}
            controlsLocked={controlsLocked}
            onChangePreference={onChangePreference}
            onEditColorPreference={onEditColorPreference}
          />
        ) : (
          <TraitDetailPopover trait={trait} />
        )
      }>
      {actionButton}
    </Popper>
  ) : (
    actionButton
  );

  return (
    <Box
      className={`RogueStar__selectedTraitCard RogueStar__selectedTraitCard--${category}${
        popoverOpen ? ' RogueStar__selectedTraitCard--open' : ''
      }`}>
      <Flex align="center" wrap={false}>
        <Flex.Item grow minWidth={0}>
          {anchoredAction}
        </Flex.Item>
        <Flex.Item shrink={0}>
          <Button
            className="RogueStar__selectedTraitRemoveButton"
            icon="times"
            verticalAlignContent="middle"
            tooltip={`Remove ${trait.name}`}
            tooltipPosition="left"
            aria-label={`Remove ${trait.name}`}
            disabled={controlsLocked}
            onClick={() => onRemove(trait.id)}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
};

const SelectedTraitsSection = ({
  categories,
  controlsLocked,
  openPopover,
  onTogglePopover,
  onRemove,
  onChangePreference,
  onEditColorPreference,
}: Readonly<{
  categories: CharacterTraitCategory[];
  controlsLocked: boolean;
  openPopover: SelectedTraitPopoverState | null;
  onTogglePopover: (traitId: string, mode: SelectedTraitPopoverMode) => void;
  onRemove: (traitId: string) => void;
  onChangePreference: (
    traitId: string,
    preferenceId: string,
    value: TraitPreferenceValue
  ) => void;
  onEditColorPreference: (traitId: string, preferenceId: string) => void;
}>) => {
  const selectedCategories = categories
    .map((category) => ({
      category,
      traits: category.traits.filter((trait) => !!trait.selected),
    }))
    .filter(({ traits }) => traits.length > 0);
  const selectedCount = selectedCategories.reduce(
    (total, { traits }) => total + traits.length,
    0
  );

  return (
    <Section
      className="RogueStar__selectedTraits"
      title="Selected Traits"
      fill
      scrollable
      buttons={
        <Box className="RogueStar__selectedTraitsCount">
          {selectedCount} selected
        </Box>
      }>
      {selectedCount ? (
        <Box className="RogueStar__selectedTraitGroups">
          {selectedCategories.map(({ category, traits }) => {
            const presentation = getCategoryPresentation(category.id);
            return (
              <Box
                key={category.id}
                className={`RogueStar__selectedTraitGroup RogueStar__selectedTraitGroup--${category.id}`}>
                <Flex
                  className="RogueStar__selectedTraitGroupHeader"
                  align="center"
                  gap={0.4}
                  wrap={false}>
                  <Icon name={presentation.icon} />
                  <Box className="RogueStar__selectedTraitGroupName">
                    {category.name}
                  </Box>
                  <Box className="RogueStar__selectedTraitGroupCount">
                    {traits.length}
                  </Box>
                </Flex>
                <Box className="RogueStar__selectedTraitList">
                  {traits.map((trait) => (
                    <SelectedTraitCard
                      key={trait.id}
                      trait={trait}
                      category={category.id}
                      controlsLocked={controlsLocked}
                      openMode={
                        openPopover?.traitId === trait.id
                          ? openPopover.mode
                          : null
                      }
                      onTogglePopover={onTogglePopover}
                      onRemove={onRemove}
                      onChangePreference={onChangePreference}
                      onEditColorPreference={onEditColorPreference}
                    />
                  ))}
                </Box>
              </Box>
            );
          })}
        </Box>
      ) : (
        <Box className="RogueStar__selectedTraitsEmpty">
          <Icon name="star" />
          <Box className="RogueStar__selectedTraitsEmptyTitle">
            No traits selected
          </Box>
          <Box className="RogueStar__selectedTraitsEmptyCopy">
            Choose traits from the categories above to build your character.
          </Box>
        </Box>
      )}
    </Section>
  );
};

type TraitsSaveSectionProps = Readonly<{
  pendingSave: boolean;
  pendingClose: boolean;
  uiLocked: boolean;
  dirty: boolean;
  saveError: string | null;
  validationError: string | null;
  onSave: () => void;
  onSaveAndClose: () => void;
  onDiscardAndClose: () => void;
}>;

const TraitsSaveSection = ({
  pendingSave,
  pendingClose,
  uiLocked,
  dirty,
  saveError,
  validationError,
  onSave,
  onSaveAndClose,
  onDiscardAndClose,
}: TraitsSaveSectionProps) => (
  <Section title="Save">
    {saveError ? (
      <NoticeBox danger mb={1}>
        {saveError}
      </NoticeBox>
    ) : null}
    {validationError ? (
      <NoticeBox danger mb={1}>
        {validationError}
      </NoticeBox>
    ) : null}
    <Flex justify="space-between" wrap className="RogueStar__sessionButtons">
      <Flex.Item>
        <Button
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
          icon={pendingSave ? 'spinner-third' : 'save'}
          iconSpin={pendingSave}
          disabled={
            pendingClose ||
            pendingSave ||
            uiLocked ||
            !dirty ||
            !!validationError
          }
          onClick={onSave}>
          Save
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
          icon={pendingClose ? 'spinner-third' : 'floppy-disk'}
          iconSpin={pendingClose}
          disabled={
            pendingClose || pendingSave || uiLocked || !!validationError
          }
          onClick={onSaveAndClose}>
          Save &amp; Close
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button.Confirm
          className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--negative`}
          icon="door-open"
          confirmIcon="triangle-exclamation"
          content="Close Without Saving"
          confirmContent="Confirm Close"
          color="transparent"
          confirmColor="bad"
          disabled={pendingClose || pendingSave || uiLocked}
          onClick={onDiscardAndClose}
        />
      </Flex.Item>
    </Flex>
  </Section>
);

const PERSISTENCE_COLOR_PATTERN =
  /^#(?:[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i;

const PersistenceDetails = ({
  details,
}: Readonly<{ details: CharacterPersistenceDetailEntry[] }>) => (
  <Box className="RogueStar__traitPersistenceDetails">
    {details.map((detail, index) => {
      const isColor = PERSISTENCE_COLOR_PATTERN.test(detail.value);
      return (
        <Box
          key={`${detail.label}-${index}`}
          className="RogueStar__traitPersistenceDetail">
          <Box className="RogueStar__traitPersistenceDetailLabel">
            {detail.label}
          </Box>
          <Flex align="center" gap={0.35} minWidth={0}>
            {isColor ? (
              <Box
                className="RogueStar__traitPersistenceSwatch"
                style={{ backgroundColor: detail.value }}
              />
            ) : null}
            <Flex.Item grow minWidth={0}>
              <Box
                className="RogueStar__traitPersistenceDetailValue"
                title={detail.value}>
                {detail.value}
              </Box>
            </Flex.Item>
          </Flex>
        </Box>
      );
    })}
  </Box>
);

const PersistenceEmpty = ({
  icon,
  children,
}: Readonly<{ icon: string; children: string }>) => (
  <Box className="RogueStar__traitPersistenceEmpty">
    <Icon name={icon} />
    <Box>{children}</Box>
  </Box>
);

const TraitsPersistenceSection = ({
  persistence,
}: Readonly<{ persistence?: CharacterPersistencePayload }>) => {
  const experience = persistence?.experience || [];
  const nif = persistence?.nif;
  const pet = persistence?.pet;
  const nifPresent = !!nif?.present;
  const petPresent = !!pet?.present;
  const nifDetails = nif?.details || [];
  const petDetails = pet?.details || [];
  const durabilityPercent = Math.max(
    0,
    Math.min(100, nif?.durability_percent || 0)
  );
  const durabilityTone =
    durabilityPercent <= 25
      ? 'critical'
      : durabilityPercent <= 50
        ? 'warning'
        : 'stable';

  return (
    <Section
      className="RogueStar__traitPersistence"
      title="Persistence"
      fill
      scrollable>
      <Box className="RogueStar__traitPersistenceGrid">
        <Box className="RogueStar__traitPersistenceCard RogueStar__traitPersistenceCard--experience">
          <Flex
            className="RogueStar__traitPersistenceCardHeader"
            align="center"
            justify="space-between"
            gap={0.5}>
            <Flex align="center" gap={0.4} minWidth={0}>
              <Box className="RogueStar__traitPersistenceCardIcon">
                <Icon name="star" />
              </Box>
              <Box className="RogueStar__traitPersistenceCardTitle">
                Experience
              </Box>
            </Flex>
            <Box className="RogueStar__traitPersistenceStatus">
              {experience.length
                ? `${experience.length} recorded`
                : 'No entries'}
            </Box>
          </Flex>
          {experience.length ? (
            <Box className="RogueStar__traitExperienceGrid">
              {experience.map((entry, index) => (
                <Box
                  key={`${entry.label}-${index}`}
                  className="RogueStar__traitExperienceEntry">
                  <Box className="RogueStar__traitExperienceValue">
                    {entry.value}
                  </Box>
                  <Box className="RogueStar__traitExperienceLabel">
                    {entry.label}
                  </Box>
                </Box>
              ))}
            </Box>
          ) : (
            <PersistenceEmpty icon="star">
              No experience points have been recorded for this character.
            </PersistenceEmpty>
          )}
        </Box>

        <Box className="RogueStar__traitPersistenceCard RogueStar__traitPersistenceCard--nif">
          <Flex
            className="RogueStar__traitPersistenceCardHeader"
            align="center"
            justify="space-between"
            gap={0.5}>
            <Flex align="center" gap={0.4} minWidth={0}>
              <Box className="RogueStar__traitPersistenceCardIcon">
                <Icon name="microchip" />
              </Box>
              <Box className="RogueStar__traitPersistenceCardTitle">NIF</Box>
            </Flex>
            <Box
              className={`RogueStar__traitPersistenceStatus${
                nifPresent ? ' RogueStar__traitPersistenceStatus--present' : ''
              }`}>
              {nifPresent ? 'Present' : 'None'}
            </Box>
          </Flex>
          {nifPresent ? (
            <>
              <Box className="RogueStar__traitPersistencePrimary">
                {nif?.name || 'Stored NIF'}
              </Box>
              <Flex
                className="RogueStar__traitPersistenceMeterLabel"
                justify="space-between"
                gap={0.5}>
                <Box>Durability</Box>
                <Box>
                  {nif?.durability ?? 0} / {nif?.max_durability ?? '—'}
                </Box>
              </Flex>
              <Box
                className="RogueStar__traitPersistenceMeter"
                role="meter"
                aria-label={`NIF durability ${durabilityPercent}%`}>
                <Box
                  className={`RogueStar__traitPersistenceMeterFill RogueStar__traitPersistenceMeterFill--${durabilityTone}`}
                  style={{ width: `${durabilityPercent}%` }}
                />
              </Box>
              {nifDetails.length ? (
                <PersistenceDetails details={nifDetails} />
              ) : (
                <Box className="RogueStar__traitPersistenceMinor">
                  No additional NIF settings are stored.
                </Box>
              )}
            </>
          ) : (
            <PersistenceEmpty icon="microchip">
              No NIF is stored for this character.
            </PersistenceEmpty>
          )}
        </Box>

        <Box className="RogueStar__traitPersistenceCard RogueStar__traitPersistenceCard--pet">
          <Flex
            className="RogueStar__traitPersistenceCardHeader"
            align="center"
            justify="space-between"
            gap={0.5}>
            <Flex align="center" gap={0.4} minWidth={0}>
              <Box className="RogueStar__traitPersistenceCardIcon">
                <Icon name="paw" />
              </Box>
              <Box className="RogueStar__traitPersistenceCardTitle">Pet</Box>
            </Flex>
            <Box
              className={`RogueStar__traitPersistenceStatus${
                petPresent ? ' RogueStar__traitPersistenceStatus--present' : ''
              }`}>
              {petPresent ? 'Registered' : 'None'}
            </Box>
          </Flex>
          {pet?.error ? (
            <NoticeBox danger>{pet.error}</NoticeBox>
          ) : petPresent ? (
            <>
              <Box className="RogueStar__traitPersistencePrimary">
                {pet?.name || 'Unnamed pet'}
              </Box>
              <Box className="RogueStar__traitPersistenceSecondary">
                {pet?.species || 'Unknown pet type'}
              </Box>
              {petDetails.length ? (
                <PersistenceDetails details={petDetails} />
              ) : (
                <Box className="RogueStar__traitPersistenceMinor">
                  No additional pet traits are stored.
                </Box>
              )}
            </>
          ) : (
            <PersistenceEmpty icon="paw">
              No pet is registered to this character slot.
            </PersistenceEmpty>
          )}
        </Box>
      </Box>
    </Section>
  );
};

const TraitsPreviewColumn = ({
  preview,
  canvasWidth,
  canvasHeight,
  previewFitToFrame,
  onTogglePreviewFit,
  previewBackgroundImage,
  backgroundFallbackColor,
  canvasBackgroundScale,
  previewBackgroundTileWidth,
  previewBackgroundTileHeight,
  iconScaleX,
  iconScaleY,
  showEquipment,
  onToggleEquipment,
  showJobGear,
  onToggleJobGear,
  showLoadoutGear,
  onToggleLoadout,
  canvasBackgroundOptions,
  resolvedCanvasBackground,
  cycleCanvasBackground,
  persistence,
}: Readonly<{
  preview: PreviewDirectionEntry[];
  canvasWidth: number;
  canvasHeight: number;
  previewFitToFrame: boolean;
  onTogglePreviewFit: () => void;
  previewBackgroundImage: string | null;
  backgroundFallbackColor: string;
  canvasBackgroundScale: number;
  previewBackgroundTileWidth?: number;
  previewBackgroundTileHeight?: number;
  iconScaleX: number;
  iconScaleY: number;
  showEquipment: boolean;
  onToggleEquipment: () => void;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
  canvasBackgroundOptions: CanvasBackgroundOption[];
  resolvedCanvasBackground: CanvasBackgroundOption | null;
  cycleCanvasBackground: () => void;
  persistence?: CharacterPersistencePayload;
}>) => (
  <Flex
    className="RogueStar__traitPreviewColumn"
    direction="column"
    gap={1}
    height="100%">
    <Flex.Item basis="448px" shrink={0} minHeight={0}>
      <LivePreviewCard
        preview={preview}
        canvasWidth={canvasWidth}
        canvasHeight={canvasHeight}
        previewFitToFrame={previewFitToFrame}
        onTogglePreviewFit={onTogglePreviewFit}
        previewBackgroundImage={previewBackgroundImage}
        backgroundFallbackColor={backgroundFallbackColor}
        canvasBackgroundScale={canvasBackgroundScale}
        previewBackgroundTileWidth={previewBackgroundTileWidth}
        previewBackgroundTileHeight={previewBackgroundTileHeight}
        iconScaleX={iconScaleX}
        iconScaleY={iconScaleY}
        showEquipment={showEquipment}
        onToggleEquipment={onToggleEquipment}
        showJobGear={showJobGear}
        onToggleJobGear={onToggleJobGear}
        showLoadoutGear={showLoadoutGear}
        onToggleLoadout={onToggleLoadout}
        canvasBackgroundOptions={canvasBackgroundOptions}
        resolvedCanvasBackground={resolvedCanvasBackground}
        cycleCanvasBackground={cycleCanvasBackground}
      />
    </Flex.Item>
    <Flex.Item grow minHeight={0}>
      <TraitsPersistenceSection persistence={persistence} />
    </Flex.Item>
  </Flex>
);

const TraitsCatalogSection = ({
  languageMode,
  activeCategory,
  languages,
  visibleLanguages,
  visibleTraits,
  visibleTraitGroups,
  resolvedCategoryId,
  forceGroupsOpen,
  controlsLocked,
  openDetailTraitId,
  search,
  onSearch,
  onToggleTrait,
  onToggleTraitDetail,
  onToggleLanguage,
  onSetPreferredLanguage,
}: Readonly<{
  languageMode: boolean;
  activeCategory: CharacterTraitCategory | null;
  languages?: CharacterLanguagesPayload;
  visibleLanguages: CharacterLanguageEntry[];
  visibleTraits: CharacterTraitEntry[];
  visibleTraitGroups: VisibleTraitGroup[];
  resolvedCategoryId: TraitCategoryId;
  forceGroupsOpen: boolean;
  controlsLocked: boolean;
  openDetailTraitId: string | null;
  search: string;
  onSearch: (value: string) => void;
  onToggleTrait: (traitId: string) => void;
  onToggleTraitDetail: (traitId: string) => void;
  onToggleLanguage: (languageId: string) => void;
  onSetPreferredLanguage: (languageId: string) => void;
}>) => (
  <Section
    className="RogueStar__traitCatalog"
    title={languageMode ? 'Languages' : activeCategory?.name || 'Traits'}
    fill
    scrollable
    buttons={
      <Box className="RogueStar__traitCatalogCount">
        {languageMode ? (
          <>
            {visibleLanguages.length} languages ·{' '}
            {languages?.selected_optional_count || 0}/
            {languages?.optional_limit || 0} optional
          </>
        ) : (
          <>
            {visibleTraits.length} traits · {visibleTraitGroups.length} groups
          </>
        )}
      </Box>
    }>
    <Box mb={1}>
      <Input
        fluid
        value={search}
        placeholder={languageMode ? 'Search languages…' : 'Search traits…'}
        onInput={(_event, value) => onSearch(value)}
      />
    </Box>
    {languageMode && visibleLanguages.length ? (
      <Box className="RogueStar__traitGrid RogueStar__languageGrid">
        {visibleLanguages.map((language) => (
          <LanguageCatalogTile
            key={language.id}
            language={language}
            controlsLocked={controlsLocked}
            onToggle={onToggleLanguage}
            onSetPreferred={onSetPreferredLanguage}
          />
        ))}
      </Box>
    ) : !languageMode && visibleTraits.length ? (
      <Box className="RogueStar__traitGroups">
        {visibleTraitGroups.map((group) => (
          <TraitGroupSection
            key={
              resolvedCategoryId +
              ':' +
              group.id +
              ':' +
              (forceGroupsOpen ? 'filtered' : 'browse')
            }
            group={group}
            category={resolvedCategoryId}
            open={forceGroupsOpen}
            controlsLocked={controlsLocked}
            openDetailTraitId={openDetailTraitId}
            onToggle={onToggleTrait}
            onToggleDetail={onToggleTraitDetail}
          />
        ))}
      </Box>
    ) : (
      <NoticeBox className="RogueStar__traitEmptyState">
        <Icon name="search" /> No {languageMode ? 'languages' : 'traits'} match
        this search.
      </NoticeBox>
    )}
  </Section>
);

const TraitsCategoryAndSelectionSections = ({
  draftedPayload,
  activeCategoryId,
  languageMode,
  controlsLocked,
  preferenceEditorOpen,
  selectedTraitPopover,
  openLanguageId,
  languageSettingsError,
  validationError,
  onSelectCategory,
  onToggleTraitPopover,
  onToggleTrait,
  onChangePreference,
  onEditColorPreference,
  onOpenPrefixEditor,
  onResetPrefixes,
  onToggleLanguageSettings,
  onToggleLanguage,
  onChangeLanguageCustomKey,
  onSetPreferredLanguage,
}: Readonly<{
  draftedPayload: TraitsPayload;
  activeCategoryId: TraitsCatalogCategoryId;
  languageMode: boolean;
  controlsLocked: boolean;
  preferenceEditorOpen: boolean;
  selectedTraitPopover: SelectedTraitPopoverState | null;
  openLanguageId: string | null;
  languageSettingsError: string | null;
  validationError: string | null;
  onSelectCategory: (categoryId: TraitsCatalogCategoryId) => void;
  onToggleTraitPopover: (
    traitId: string,
    mode: SelectedTraitPopoverMode
  ) => void;
  onToggleTrait: (traitId: string) => void;
  onChangePreference: (
    traitId: string,
    preferenceId: string,
    value: TraitPreferenceValue
  ) => void;
  onEditColorPreference: (traitId: string, preferenceId: string) => void;
  onOpenPrefixEditor: () => void;
  onResetPrefixes: () => void;
  onToggleLanguageSettings: (languageId: string) => void;
  onToggleLanguage: (languageId: string) => void;
  onChangeLanguageCustomKey: (languageId: string, value: string) => void;
  onSetPreferredLanguage: (languageId: string) => void;
}>) => (
  <>
    <Section title="Categories">
      <Box className="RogueStar__traitCategoryList">
        {draftedPayload.categories.map((category) => (
          <TraitCategoryButton
            key={category.id}
            category={category}
            positiveLimit={draftedPayload.max_traits}
            selected={category.id === activeCategoryId}
            onSelect={onSelectCategory}
          />
        ))}
        {draftedPayload.languages ? (
          <LanguageCategoryButton
            languages={draftedPayload.languages}
            selected={languageMode}
            onSelect={() => onSelectCategory('languages')}
          />
        ) : null}
      </Box>
    </Section>
    {languageMode && draftedPayload.languages ? (
      <LanguageKeysSection
        languages={draftedPayload.languages}
        controlsLocked={controlsLocked}
        onChange={onOpenPrefixEditor}
        onReset={onResetPrefixes}
      />
    ) : null}
    <Flex.Item grow minHeight={0}>
      {languageMode && draftedPayload.languages ? (
        <SelectedLanguagesSection
          languages={draftedPayload.languages}
          controlsLocked={controlsLocked}
          openLanguageId={openLanguageId}
          settingsError={languageSettingsError}
          validationError={validationError}
          onToggleSettings={onToggleLanguageSettings}
          onRemove={onToggleLanguage}
          onChangeCustomKey={onChangeLanguageCustomKey}
          onClearCustomKey={(languageId) =>
            onChangeLanguageCustomKey(languageId, '')
          }
          onSetPreferred={onSetPreferredLanguage}
        />
      ) : (
        <SelectedTraitsSection
          categories={draftedPayload.categories}
          controlsLocked={controlsLocked}
          openPopover={preferenceEditorOpen ? null : selectedTraitPopover}
          onTogglePopover={onToggleTraitPopover}
          onRemove={onToggleTrait}
          onChangePreference={onChangePreference}
          onEditColorPreference={onEditColorPreference}
        />
      )}
    </Flex.Item>
  </>
);

const LanguagePrefixEditorOverlay = ({
  prefixes,
  onChange,
  onConfirm,
  onCancel,
}: Readonly<{
  prefixes: string[] | null;
  onChange: (prefixes: string[] | null) => void;
  onConfirm: () => void;
  onCancel: () => void;
}>) =>
  prefixes ? (
    <LanguagePrefixEditor
      prefixes={prefixes}
      onChange={onChange}
      onConfirm={onConfirm}
      onCancel={onCancel}
    />
  ) : null;

export const TraitsTab = (props: TraitsTabProps, context) => {
  const {
    data,
    draftState,
    setDraftState,
    dirty,
    setDirty,
    pendingSave,
    pendingClose,
    saveError,
    onSave,
    onSaveAndClose,
    onDiscardAndClose,
    canvasBackgroundOptions,
    resolvedCanvasBackground,
    backgroundFallbackColor,
    cycleCanvasBackground,
    canvasBackgroundScale,
    livePreview,
    canvasWidth,
    canvasHeight,
    previewFitToFrame,
    onTogglePreviewFit,
    showEquipment,
    onToggleEquipment,
    showJobGear,
    onToggleJobGear,
    showLoadoutGear,
    onToggleLoadout,
  } = props;
  const { act } = useBackend<CustomMarkingDesignerData>(context);
  const stateToken = data.state_token || 'session';
  const [activeCategoryId, setActiveCategoryId] =
    useLocalState<TraitsCatalogCategoryId>(
      context,
      `customMarkingTraitsCategory-${stateToken}`,
      'positive'
    );
  const [search, setSearch] = useLocalState<string>(
    context,
    `customMarkingTraitsSearch-${stateToken}`,
    ''
  );
  const [openDetailTraitId, setOpenDetailTraitId] = useLocalState<
    string | null
  >(context, `customMarkingTraitsDetail-${stateToken}`, null);
  const [selectedTraitPopover, setSelectedTraitPopover] =
    useLocalState<SelectedTraitPopoverState | null>(
      context,
      `customMarkingSelectedTraitPopover-${stateToken}`,
      null
    );
  const [preferenceEditor, setPreferenceEditor] =
    useLocalState<TraitPreferenceEditorState | null>(
      context,
      `customMarkingTraitsColorPreferenceEditor-${stateToken}`,
      null
    );
  const [openLanguageId, setOpenLanguageId] = useLocalState<string | null>(
    context,
    `customMarkingSelectedLanguage-${stateToken}`,
    null
  );
  const [languageSettingsError, setLanguageSettingsError] = useLocalState<
    string | null
  >(context, `customMarkingLanguageSettingsError-${stateToken}`, null);
  const [prefixEditor, setPrefixEditor] = useLocalState<string[] | null>(
    context,
    `customMarkingLanguagePrefixEditor-${stateToken}`,
    null
  );

  const payload = data.traits_payload || null;
  const revisionMatches =
    !data.traits_revision || payload?.revision === data.traits_revision;
  const speciesMatches =
    !data.traits_species || payload?.species_id === data.traits_species;
  const resolvedPayload =
    payload && revisionMatches && speciesMatches ? payload : null;
  const requestPayload = () => act('load_traits');

  if (!resolvedPayload) {
    return (
      <Box className="RogueStar" position="relative" minHeight="100%">
        <TraitsPayloadInitializer
          payload={payload}
          expectedRevision={data.traits_revision}
          expectedSpecies={data.traits_species}
          requestPayload={requestPayload}
        />
        <LoadingOverlay
          title="Charting traits..."
          subtitle="Building your species-aware trait catalog."
        />
      </Box>
    );
  }

  const canonicalDraft = buildTraitsDraftState(resolvedPayload);
  const activeDraft =
    draftState?.revision === resolvedPayload.revision
      ? draftState
      : canonicalDraft;
  const draftedPayload = applyTraitsDraftToPayload(
    resolvedPayload,
    activeDraft
  );
  const previewScale = resolveTraitsPreviewScale(resolvedPayload, activeDraft);
  const validationError = resolveLanguagesDraftValidationError(
    resolvedPayload,
    activeDraft
  );
  const transientLock = !!data.ui_locked || pendingSave || pendingClose;
  const controlsLocked = transientLock || !!preferenceEditor || !!prefixEditor;

  const languageMode =
    activeCategoryId === 'languages' && !!draftedPayload.languages;
  const activeCategory = languageMode
    ? null
    : draftedPayload.categories.find(
        (category) => category.id === activeCategoryId
      ) || draftedPayload.categories[0];
  const resolvedCategoryId = activeCategory?.id || 'neutral';
  const searchNeedle = search.trim().toLowerCase();
  const visibleTraits = (activeCategory?.traits || []).filter((trait) => {
    if (!searchNeedle) {
      return true;
    }
    const group = resolveTraitGroupDefinition(trait, resolvedCategoryId);
    return [
      trait.name,
      trait.description,
      trait.tutorial || '',
      group.name,
    ].some((value) => value.toLowerCase().includes(searchNeedle));
  });
  const visibleTraitGroups = buildVisibleTraitGroups(
    visibleTraits,
    resolvedCategoryId
  );
  const visibleLanguages = sortLanguagesAlphabetically(
    (draftedPayload.languages?.entries || []).filter((language) => {
      if (!searchNeedle) {
        return true;
      }
      return [language.name, language.description].some((value) =>
        value.toLowerCase().includes(searchNeedle)
      );
    })
  );
  const forceGroupsOpen = !!searchNeedle;

  const commitDraft = (nextDraft: TraitsDraftState) => {
    setDraftState(nextDraft);
    setDirty(!traitsDraftStatesEqual(nextDraft, canonicalDraft));
  };

  const findDraftedTrait = (traitId: string) => {
    for (const category of draftedPayload.categories) {
      const trait = category.traits.find((entry) => entry.id === traitId);
      if (trait) {
        return trait;
      }
    }
    return null;
  };

  const handleToggle = (traitId: string) => {
    if (controlsLocked) {
      return;
    }
    const trait = findDraftedTrait(traitId);
    if (!trait || (!trait.selected && trait.disabled_reason)) {
      return;
    }
    setOpenDetailTraitId(null);
    setSelectedTraitPopover(null);
    setOpenLanguageId(null);
    setLanguageSettingsError(null);
    commitDraft(
      updateTraitsDraftSelection(activeDraft, traitId, !trait.selected)
    );
  };

  const handleToggleDetail = (traitId: string) => {
    setSelectedTraitPopover(null);
    setOpenLanguageId(null);
    setLanguageSettingsError(null);
    setOpenDetailTraitId(openDetailTraitId === traitId ? null : traitId);
  };

  const handleToggleSelectedTraitPopover = (
    traitId: string,
    mode: SelectedTraitPopoverMode
  ) => {
    if (controlsLocked) {
      return;
    }
    setOpenDetailTraitId(null);
    setOpenLanguageId(null);
    setLanguageSettingsError(null);
    setSelectedTraitPopover(
      selectedTraitPopover?.traitId === traitId &&
        selectedTraitPopover.mode === mode
        ? null
        : { traitId, mode }
    );
  };

  const commitPreferenceValue = (
    traitId: string,
    preferenceId: string,
    value: TraitPreferenceValue
  ) => {
    const trait = findDraftedTrait(traitId);
    const preference = trait?.preferences?.find(
      (entry) => entry.id === preferenceId
    );
    if (
      !trait?.selected ||
      !preference ||
      !isTraitPreferenceValueValid(preference, value)
    ) {
      return false;
    }
    const normalizedValue =
      preference.kind === 'color' && typeof value === 'string'
        ? normalizeHex(value) || '#ffffff'
        : value;
    commitDraft(
      updateTraitsDraftPreference(
        activeDraft,
        traitId,
        preferenceId,
        normalizedValue
      )
    );
    return true;
  };

  const handleChangePreference = (
    traitId: string,
    preferenceId: string,
    value: TraitPreferenceValue
  ) => {
    if (controlsLocked) {
      return;
    }
    commitPreferenceValue(traitId, preferenceId, value);
  };

  const handleEditColorPreference = (traitId: string, preferenceId: string) => {
    if (controlsLocked) {
      return;
    }
    const trait = findDraftedTrait(traitId);
    const preference = trait?.preferences?.find(
      (entry) => entry.id === preferenceId
    );
    if (!trait?.selected || preference?.kind !== 'color') {
      return;
    }
    setPreferenceEditor({
      traitId,
      preferenceId,
      value:
        typeof preference.value === 'string' ? preference.value : '#ffffff',
    });
  };

  const findDraftedLanguage = (languageId: string) =>
    draftedPayload.languages?.entries.find(
      (language) => language.id === languageId
    ) || null;

  const handleToggleLanguage = (languageId: string) => {
    if (controlsLocked || !draftedPayload.languages) {
      return;
    }
    const language = findDraftedLanguage(languageId);
    if (
      !language ||
      (!language.selectable && !language.selected) ||
      (!language.selected && language.disabled_reason)
    ) {
      return;
    }
    setOpenDetailTraitId(null);
    setSelectedTraitPopover(null);
    setOpenLanguageId(null);
    setLanguageSettingsError(null);
    commitDraft(
      updateLanguageDraftSelection(
        activeDraft,
        languageId,
        !language.selected,
        draftedPayload.languages.preferred_fallback
      )
    );
  };

  const handleSetPreferredLanguage = (languageId: string) => {
    if (controlsLocked) {
      return;
    }
    const language = findDraftedLanguage(languageId);
    if (!language?.preferred_eligible) {
      return;
    }
    setLanguageSettingsError(null);
    commitDraft(updateLanguageDraftPreferred(activeDraft, languageId));
  };

  const handleToggleLanguageSettings = (languageId: string) => {
    if (controlsLocked) {
      return;
    }
    setOpenDetailTraitId(null);
    setSelectedTraitPopover(null);
    setLanguageSettingsError(null);
    setOpenLanguageId(openLanguageId === languageId ? null : languageId);
  };

  const handleChangeLanguageCustomKey = (languageId: string, value: string) => {
    if (controlsLocked) {
      return;
    }
    const language = findDraftedLanguage(languageId);
    if (!language?.selected) {
      return;
    }
    if (value && !/^[A-Za-z0-9]$/.test(value)) {
      setLanguageSettingsError('Use one letter or number.');
      return;
    }
    const collision = Object.entries(
      activeDraft.languages?.custom_keys || {}
    ).find(
      ([otherLanguageId, customKey]) =>
        otherLanguageId !== languageId && customKey === value
    );
    if (value && collision) {
      const otherLanguage = findDraftedLanguage(collision[0]);
      setLanguageSettingsError(
        `“${value}” is already assigned to ${
          otherLanguage?.name || 'another language'
        }.`
      );
      return;
    }
    setLanguageSettingsError(null);
    commitDraft(updateLanguageDraftCustomKey(activeDraft, languageId, value));
  };

  const handleOpenPrefixEditor = () => {
    if (controlsLocked || !draftedPayload.languages) {
      return;
    }
    const prefixes = draftedPayload.languages.language_prefixes.slice(0, 3);
    while (prefixes.length < 3) {
      prefixes.push('');
    }
    setOpenLanguageId(null);
    setLanguageSettingsError(null);
    setPrefixEditor(prefixes);
  };

  const handleConfirmPrefixes = () => {
    const prefixes = prefixEditor?.filter((prefix) => prefix.length > 0) || [];
    if (
      !prefixes.length ||
      prefixes.length > 3 ||
      !prefixes.every(isLanguagePrefixValid)
    ) {
      return;
    }
    commitDraft(updateLanguageDraftPrefixes(activeDraft, prefixes));
    setPrefixEditor(null);
  };

  const handleResetPrefixes = () => {
    if (controlsLocked || !draftedPayload.languages) {
      return;
    }
    commitDraft(
      updateLanguageDraftPrefixes(
        activeDraft,
        draftedPayload.languages.default_language_prefixes
      )
    );
  };

  const preferenceEditorTrait = preferenceEditor
    ? findDraftedTrait(preferenceEditor.traitId)
    : null;
  const preferenceEditorDefinition = preferenceEditorTrait?.preferences?.find(
    (entry) => entry.id === preferenceEditor?.preferenceId
  );
  const handleConfirmPreference = () => {
    if (
      !preferenceEditor ||
      !preferenceEditorDefinition ||
      preferenceEditorDefinition.kind !== 'color' ||
      !isTraitPreferenceValueValid(
        preferenceEditorDefinition,
        preferenceEditor.value
      )
    ) {
      return;
    }
    if (
      commitPreferenceValue(
        preferenceEditor.traitId,
        preferenceEditor.preferenceId,
        preferenceEditor.value
      )
    ) {
      setPreferenceEditor(null);
    }
  };

  const previewBackgroundImage = resolvedCanvasBackground?.asset?.png
    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
    : null;
  const previewBackgroundTileWidth = resolvedCanvasBackground?.asset?.width
    ? resolvedCanvasBackground.asset.width * canvasBackgroundScale
    : undefined;
  const previewBackgroundTileHeight = resolvedCanvasBackground?.asset?.height
    ? resolvedCanvasBackground.asset.height * canvasBackgroundScale
    : undefined;
  const handleSearch = (value: string) => {
    setOpenDetailTraitId(null);
    setSelectedTraitPopover(null);
    setOpenLanguageId(null);
    setLanguageSettingsError(null);
    setSearch(value);
  };
  const handleSelectCategory = (categoryId: TraitsCatalogCategoryId) => {
    setOpenDetailTraitId(null);
    setSelectedTraitPopover(null);
    setOpenLanguageId(null);
    setLanguageSettingsError(null);
    setActiveCategoryId(categoryId);
  };

  return (
    <Box
      className={`RogueStar RogueStar__traitsTab${
        transientLock ? ' RogueStar__traitsTab--transientLocked' : ''
      }`}
      minHeight="100%">
      <Flex direction="row" gap={1} wrap={false} height="100%">
        <Flex.Item basis="840px" shrink={0} minWidth={0}>
          <TraitsCatalogSection
            languageMode={languageMode}
            activeCategory={activeCategory}
            languages={draftedPayload.languages}
            visibleLanguages={visibleLanguages}
            visibleTraits={visibleTraits}
            visibleTraitGroups={visibleTraitGroups}
            resolvedCategoryId={resolvedCategoryId}
            forceGroupsOpen={forceGroupsOpen}
            controlsLocked={controlsLocked}
            openDetailTraitId={openDetailTraitId}
            search={search}
            onSearch={handleSearch}
            onToggleTrait={handleToggle}
            onToggleTraitDetail={handleToggleDetail}
            onToggleLanguage={handleToggleLanguage}
            onSetPreferredLanguage={handleSetPreferredLanguage}
          />
        </Flex.Item>
        <Flex.Item basis="418px" shrink={0}>
          <Flex direction="column" gap={1} height="100%">
            <TraitsSaveSection
              pendingSave={pendingSave}
              pendingClose={pendingClose}
              uiLocked={!!data.ui_locked}
              dirty={dirty}
              saveError={saveError}
              validationError={validationError}
              onSave={onSave}
              onSaveAndClose={onSaveAndClose}
              onDiscardAndClose={onDiscardAndClose}
            />
            <TraitsCategoryAndSelectionSections
              draftedPayload={draftedPayload}
              activeCategoryId={activeCategoryId}
              languageMode={languageMode}
              controlsLocked={controlsLocked}
              preferenceEditorOpen={!!preferenceEditor}
              selectedTraitPopover={selectedTraitPopover}
              openLanguageId={openLanguageId}
              languageSettingsError={languageSettingsError}
              validationError={validationError}
              onSelectCategory={handleSelectCategory}
              onToggleTraitPopover={handleToggleSelectedTraitPopover}
              onToggleTrait={handleToggle}
              onChangePreference={handleChangePreference}
              onEditColorPreference={handleEditColorPreference}
              onOpenPrefixEditor={handleOpenPrefixEditor}
              onResetPrefixes={handleResetPrefixes}
              onToggleLanguageSettings={handleToggleLanguageSettings}
              onToggleLanguage={handleToggleLanguage}
              onChangeLanguageCustomKey={handleChangeLanguageCustomKey}
              onSetPreferredLanguage={handleSetPreferredLanguage}
            />
          </Flex>
        </Flex.Item>
        <Flex.Item grow>
          <TraitsPreviewColumn
            preview={livePreview}
            canvasWidth={canvasWidth}
            canvasHeight={canvasHeight}
            previewFitToFrame={previewFitToFrame}
            onTogglePreviewFit={onTogglePreviewFit}
            previewBackgroundImage={previewBackgroundImage}
            backgroundFallbackColor={backgroundFallbackColor}
            canvasBackgroundScale={canvasBackgroundScale}
            previewBackgroundTileWidth={previewBackgroundTileWidth}
            previewBackgroundTileHeight={previewBackgroundTileHeight}
            iconScaleX={previewScale.iconScaleX}
            iconScaleY={previewScale.iconScaleY}
            showEquipment={showEquipment}
            onToggleEquipment={onToggleEquipment}
            showJobGear={showJobGear}
            onToggleJobGear={onToggleJobGear}
            showLoadoutGear={showLoadoutGear}
            onToggleLoadout={onToggleLoadout}
            canvasBackgroundOptions={canvasBackgroundOptions}
            resolvedCanvasBackground={resolvedCanvasBackground}
            cycleCanvasBackground={cycleCanvasBackground}
            persistence={draftedPayload.persistence}
          />
        </Flex.Item>
      </Flex>
      {preferenceEditor &&
      preferenceEditorTrait &&
      preferenceEditorDefinition?.kind === 'color' ? (
        <TraitPreferenceEditor
          trait={preferenceEditorTrait}
          preference={preferenceEditorDefinition}
          editor={preferenceEditor}
          onChange={(value) =>
            setPreferenceEditor({ ...preferenceEditor, value })
          }
          onConfirm={handleConfirmPreference}
          onCancel={() => setPreferenceEditor(null)}
        />
      ) : null}
      <LanguagePrefixEditorOverlay
        prefixes={prefixEditor}
        onChange={setPrefixEditor}
        onConfirm={handleConfirmPrefixes}
        onCancel={() => setPrefixEditor(null)}
      />
    </Box>
  );
};
