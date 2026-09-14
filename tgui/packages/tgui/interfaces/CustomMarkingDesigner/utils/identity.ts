// ///////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Identity Tab //
// ///////////////////////////////////////////////////////////////////////////////////

import type {
  IdentityDraftState,
  IdentityLocationGroup,
  IdentityLocationOption,
  IdentityOrganizationOption,
  IdentityPayload,
  IdentitySavePayload,
  IdentitySaveResult,
} from '../types';

export const IDENTITY_MOBILE_LOCATION_GROUP = 'Mobile Flotillas';
export const IDENTITY_UNCONFIRMED_LOCATION_GROUP = 'Other / Unconfirmed';
export const IDENTITY_MOBILE_LOCATION_GROUP_DESCRIPTION =
  'Mobile settlements and fleets without a fixed parent star system.';
export const IDENTITY_UNCONFIRMED_LOCATION_GROUP_DESCRIPTION =
  'Locations whose parent star system is not confirmed by the current repository lore, plus the Unset option.';
export const IDENTITY_LOCATION_GROUP_DESCRIPTION_FALLBACK =
  'No broader system overview is currently available in the repository lore.';

export const getIdentityBirthdayMaxDay = (month: number): number => {
  if (month === 2) {
    return 29;
  }
  if ([4, 6, 9, 11].includes(month)) {
    return 30;
  }
  return month >= 1 && month <= 12 ? 31 : 0;
};

export const normalizeIdentityBirthday = (
  month: number,
  day: number
): { month: number; day: number } => {
  if (month === 0) {
    return { month, day: 0 };
  }
  const maximumDay = getIdentityBirthdayMaxDay(month);
  if (!maximumDay) {
    return { month, day };
  }
  return {
    month,
    day: Math.min(Math.max(day || 1, 1), maximumDay),
  };
};

const IDENTITY_VALUE_KEYS = [
  'real_name',
  'nickname',
  'name_color',
  'be_random_name',
  'identifying_gender',
  'age',
  'bday_month',
  'bday_day',
  'bday_announce',
  'metadata',
  'metadata_likes',
  'metadata_dislikes',
  'custom_link',
  'flavor_text_general',
  'flavor_text_head',
  'flavor_text_face',
  'flavor_text_eyes',
  'flavor_text_torso',
  'flavor_text_arms',
  'flavor_text_hands',
  'flavor_text_legs',
  'flavor_text_feet',
  'robot_flavor_texts',
  'economic_status',
  'home_system',
  'birthplace',
  'citizenship',
  'faction',
  'religion',
  'med_record',
  'gen_record',
  'sec_record',
] as const;

export const buildIdentityDraftState = (
  payload: IdentityPayload
): IdentityDraftState => {
  const draft = { revision: payload.revision } as IdentityDraftState;
  for (const key of IDENTITY_VALUE_KEYS) {
    (draft as Record<string, unknown>)[key] = payload[key];
  }
  draft.be_random_name = !!payload.be_random_name;
  draft.bday_announce = !!payload.bday_announce;
  const birthday = normalizeIdentityBirthday(
    payload.bday_month,
    payload.bday_day
  );
  draft.bday_month = birthday.month;
  draft.bday_day = birthday.day;
  draft.robot_flavor_texts = { ...payload.robot_flavor_texts };
  return draft;
};

export const cloneIdentityDraftState = (
  draft: IdentityDraftState
): IdentityDraftState => ({
  ...draft,
  robot_flavor_texts: { ...draft.robot_flavor_texts },
});

export const isIdentityRandomNameRequestCurrent = (
  draft: IdentityDraftState | null,
  requestedName: string
): boolean => !!draft && draft.real_name === requestedName;

export const getIdentityLocationDisplayName = (
  option: IdentityLocationOption
): string => option.display_name || option.name;

export const getIdentityLocationValueDisplayName = (
  value: string,
  options: readonly IdentityLocationOption[]
): string => {
  const option = options.find((candidate) => candidate.name === value);
  return option ? getIdentityLocationDisplayName(option) : value;
};

export const getIdentityOrganizationDisplayName = (
  option: IdentityOrganizationOption
): string => option.display_name || option.name;

export const getIdentityOrganizationValueDisplayName = (
  value: string,
  options: readonly IdentityOrganizationOption[]
): string => {
  const option = options.find((candidate) => candidate.name === value);
  return option ? getIdentityOrganizationDisplayName(option) : value;
};

export const sortIdentityOrganizationOptions = (
  options: readonly IdentityOrganizationOption[]
): IdentityOrganizationOption[] =>
  [...options].sort((left, right) =>
    getIdentityOrganizationDisplayName(left).localeCompare(
      getIdentityOrganizationDisplayName(right)
    )
  );

export const buildIdentityLocationGroups = (
  options: readonly IdentityLocationOption[]
): IdentityLocationGroup[] => {
  const systemGroups = new Map<string, IdentityLocationGroup>();
  const mobileLocations: IdentityLocationOption[] = [];
  const unconfirmedLocations: IdentityLocationOption[] = [];

  for (const option of options) {
    const system = option.system?.trim();
    if (system) {
      let group = systemGroups.get(system);
      if (!group) {
        group = {
          id: `system:${system}`,
          name: system,
          kind: 'system',
          description: option.system_description || null,
          locations: [],
        };
        systemGroups.set(system, group);
      } else if (!group.description && option.system_description) {
        group.description = option.system_description;
      }
      group.locations.push(option);
    } else if (option.kind === 'flotilla') {
      mobileLocations.push(option);
    } else {
      unconfirmedLocations.push(option);
    }
  }

  const groups = Array.from(systemGroups.values());
  if (mobileLocations.length) {
    groups.push({
      id: 'mobile-flotillas',
      name: IDENTITY_MOBILE_LOCATION_GROUP,
      kind: 'mobile',
      description: IDENTITY_MOBILE_LOCATION_GROUP_DESCRIPTION,
      locations: mobileLocations,
    });
  }
  if (unconfirmedLocations.length) {
    groups.push({
      id: 'other-unconfirmed',
      name: IDENTITY_UNCONFIRMED_LOCATION_GROUP,
      kind: 'unconfirmed',
      description: IDENTITY_UNCONFIRMED_LOCATION_GROUP_DESCRIPTION,
      locations: unconfirmedLocations,
    });
  }
  return groups;
};

export const identityDraftStatesEqual = (
  left: IdentityDraftState | null,
  right: IdentityDraftState | null
): boolean => {
  if (!left || !right) {
    return left === right;
  }
  return IDENTITY_VALUE_KEYS.every((key) => {
    if (key !== 'robot_flavor_texts') {
      return left[key] === right[key];
    }
    const leftModules = Object.keys(left.robot_flavor_texts);
    const rightModules = Object.keys(right.robot_flavor_texts);
    return (
      leftModules.length === rightModules.length &&
      leftModules.every(
        (module) =>
          left.robot_flavor_texts[module] === right.robot_flavor_texts[module]
      )
    );
  });
};

export const buildIdentitySavePayload = (
  draft: IdentityDraftState,
  payload: IdentityPayload
): IdentitySavePayload => {
  const outgoing = {
    ...draft,
    robot_flavor_texts: { ...draft.robot_flavor_texts },
  } as IdentitySavePayload;
  if (!payload.allow_ooc_notes) {
    delete outgoing.metadata;
    delete outgoing.metadata_likes;
    delete outgoing.metadata_dislikes;
  }
  if (payload.records_banned) {
    delete outgoing.med_record;
    delete outgoing.gen_record;
    delete outgoing.sec_record;
  }
  return outgoing;
};

export const resolveIdentitySaveAcknowledgement = (
  pendingRequestId: string | null,
  result: IdentitySaveResult | null,
  payload: IdentityPayload | null
): boolean | null => {
  if (!pendingRequestId || result?.request_id !== pendingRequestId) {
    return null;
  }
  if (!result.accepted) {
    return false;
  }
  if (!payload || payload.revision < result.identity_revision) {
    return null;
  }
  return true;
};

export type IdentityPayloadSyncState = {
  lastRevision: number;
  lastPayload?: IdentityPayload | null;
};

export const runIdentityPayloadSync = (
  state: IdentityPayloadSyncState,
  payload: IdentityPayload | null,
  onPayload: (payload: IdentityPayload) => boolean
): boolean => {
  // Basic Appearance can request a fresh Identity payload without changing its
  // content revision. Distinguish that delivery from a rerender of one object.
  if (
    !payload ||
    (payload.revision === state.lastRevision && payload === state.lastPayload)
  ) {
    return false;
  }
  const previousRevision = state.lastRevision;
  const previousPayload = state.lastPayload;
  // The callback writes local Redux state synchronously. Guard the payload
  // before invoking it so its nested render cannot re-enter this delivery.
  state.lastRevision = payload.revision;
  state.lastPayload = payload;
  if (!onPayload(payload)) {
    state.lastRevision = previousRevision;
    state.lastPayload = previousPayload;
  }
  return true;
};

const exceeds = (value: string, maximum: number) => value.length > maximum;

export const resolveIdentityDraftValidationError = (
  payload: IdentityPayload,
  draft: IdentityDraftState | null
): string | null => {
  if (!draft) {
    return 'Identity data is still loading.';
  }
  const realName = draft.real_name.trim();
  if (realName.length < 2 || exceeds(realName, payload.max_name_length)) {
    return `Name must be between 2 and ${payload.max_name_length} characters.`;
  }
  const nickname = draft.nickname.trim();
  if (
    nickname &&
    (nickname.length < 2 || exceeds(nickname, payload.max_name_length))
  ) {
    return `Nickname must be between 2 and ${payload.max_name_length} characters, or left blank.`;
  }
  if (!payload.pronoun_options.includes(draft.identifying_gender)) {
    return 'Choose a valid pronoun option.';
  }
  if (draft.age < payload.min_age || draft.age > payload.max_age) {
    return `Age must be between ${payload.min_age} and ${payload.max_age}.`;
  }
  if (draft.bday_month < 0 || draft.bday_month > 12) {
    return 'Birthday month must be between 1 and 12, or 0 when unset.';
  }
  const birthdayMax = getIdentityBirthdayMaxDay(draft.bday_month);
  if (
    (draft.bday_month === 0 && draft.bday_day !== 0) ||
    (draft.bday_month > 0 &&
      (draft.bday_day < 1 || draft.bday_day > birthdayMax))
  ) {
    return draft.bday_month
      ? `Birthday day must be between 1 and ${birthdayMax} for that month.`
      : 'Set a birthday month before choosing a day.';
  }
  if (!payload.economic_status_options.includes(draft.economic_status)) {
    return 'Choose a valid economic status.';
  }
  const backgroundValues = [
    ['Home', draft.home_system, payload.home_system_options],
    ['Birthplace', draft.birthplace, payload.home_system_options],
    ['Citizenship', draft.citizenship, payload.citizenship_options],
    ['Faction', draft.faction, payload.faction_options],
    ['Religion', draft.religion, payload.religion_options],
  ] as const;
  for (const [label, value, presets] of backgroundValues) {
    if (!value.trim()) {
      return `${label} cannot be blank.`;
    }
    if (
      exceeds(value, payload.max_name_length) &&
      !isIdentityPresetValue(value, presets)
    ) {
      return `${label} must be ${payload.max_name_length} characters or fewer.`;
    }
  }
  if (
    payload.allow_ooc_notes &&
    [draft.metadata, draft.metadata_likes, draft.metadata_dislikes].some(
      (value) => exceeds(value, payload.max_ooc_notes_length)
    )
  ) {
    return `OOC Notes fields must be ${payload.max_ooc_notes_length} characters or fewer.`;
  }
  if (exceeds(draft.custom_link, payload.max_custom_link_length)) {
    return `Custom Link must be ${payload.max_custom_link_length} characters or fewer.`;
  }
  if (
    [
      draft.flavor_text_general,
      draft.flavor_text_head,
      draft.flavor_text_face,
      draft.flavor_text_eyes,
      draft.flavor_text_torso,
      draft.flavor_text_arms,
      draft.flavor_text_hands,
      draft.flavor_text_legs,
      draft.flavor_text_feet,
    ].some((value) => exceeds(value, payload.max_flavor_text_length))
  ) {
    return `Flavor Text fields must be ${payload.max_flavor_text_length} characters or fewer.`;
  }
  if (
    payload.robot_flavor_text_modules.some((module) =>
      exceeds(
        draft.robot_flavor_texts[module] || '',
        payload.max_flavor_text_length
      )
    )
  ) {
    return `Robot Flavor Text fields must be ${payload.max_flavor_text_length} characters or fewer.`;
  }
  if (
    !payload.records_banned &&
    [draft.med_record, draft.gen_record, draft.sec_record].some((value) =>
      exceeds(value, payload.max_record_length)
    )
  ) {
    return `Records fields must be ${payload.max_record_length} characters or fewer.`;
  }
  return null;
};

export const isIdentityPresetValue = (
  value: string,
  options: readonly string[]
) => options.includes(value);
