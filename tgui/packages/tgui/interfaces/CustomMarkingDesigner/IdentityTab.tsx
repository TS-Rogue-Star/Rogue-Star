// ///////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Identity Tab //
// ///////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../backend';
import {
  Box,
  Button,
  Collapsible,
  ColorBox,
  Dropdown,
  Flex,
  Icon,
  Input,
  Modal,
  NoticeBox,
  NumberInput,
  RogueStarColorPicker,
  Section,
  Tabs,
  TextArea,
} from '../../components';
import type { PreviewDirectionEntry } from '../../utils/character-preview';
import { LivePreviewCard, LoadingOverlay } from './components';
import { CHIP_BUTTON_CLASS } from './constants';
import { IdentityStarMap } from './IdentityStarMap';
import type {
  CanvasBackgroundOption,
  IdentityDraftState,
  IdentityLocationGroup,
  IdentityLocationKind,
  IdentityLocationOption,
  IdentityOrganizationOption,
  IdentityPayload,
} from './types';
import {
  buildIdentityLocationGroups,
  getIdentityBirthdayMaxDay,
  getIdentityLocationDisplayName,
  getIdentityLocationValueDisplayName,
  getIdentityOrganizationDisplayName,
  getIdentityOrganizationValueDisplayName,
  IDENTITY_LOCATION_GROUP_DESCRIPTION_FALLBACK,
  identityDraftStatesEqual,
  resolveIdentityDraftValidationError,
  sortIdentityOrganizationOptions,
} from './utils/identity';
import {
  buildIdentityLocationRegions,
  type IdentityLocationRegion,
} from './utils/identityLocationCatalog';
import {
  findIdentityStarMapNodeForLocation,
  findIdentityStarMapNodeForSearch,
  getIdentityStarMapMatchingNodes,
} from './utils/identityStarMap';

type IdentityTabProps = Readonly<{
  context: any;
  stateToken: string;
  payload: IdentityPayload | null;
  draft: IdentityDraftState | null;
  savedDraft: IdentityDraftState | null;
  setDraft: (draft: IdentityDraftState | null) => void;
  setDirty: (dirty: boolean) => void;
  dirty: boolean;
  pendingSave: boolean;
  pendingClose: boolean;
  randomNamePending: boolean;
  saveError: string | null;
  uiLocked: boolean;
  onRandomizeName: (identifyingGender: string) => void;
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
  iconScaleX?: number;
  iconScaleY?: number;
  previewFitToFrame: boolean;
  onTogglePreviewFit: () => void;
  showEquipment: boolean;
  onToggleEquipment: () => void;
  showJobGear: boolean;
  onToggleJobGear: () => void;
  showLoadoutGear: boolean;
  onToggleLoadout: () => void;
}>;

type IdentityValueKey = keyof IdentityDraftState;
type IdentityWorkspaceTab =
  | 'notes'
  | 'flavor'
  | 'robot-flavor'
  | 'records'
  | 'locations'
  | 'citizenship'
  | 'factions'
  | 'religion';
type IdentityLocationTarget = 'home_system' | 'birthplace';
type IdentityLocationView = 'map' | 'catalog';
type IdentityOrganizationKind = 'citizenship' | 'faction' | 'religion';

const IDENTITY_WORKSPACE_TABS: ReadonlyArray<{
  id: IdentityWorkspaceTab;
  label: string;
}> = [
  { id: 'flavor', label: 'Flavor Text' },
  { id: 'robot-flavor', label: 'Robot Flavor Text' },
  { id: 'notes', label: 'OOC Notes' },
  { id: 'records', label: 'Records' },
  { id: 'locations', label: 'Home/Birthplace' },
  { id: 'citizenship', label: 'Citizenship' },
  { id: 'factions', label: 'Factions' },
  { id: 'religion', label: 'Religion' },
];

const IDENTITY_FLAVOR_TEXT_FIELDS = [
  { key: 'flavor_text_general', label: 'General' },
  { key: 'flavor_text_head', label: 'Head' },
  { key: 'flavor_text_face', label: 'Face' },
  { key: 'flavor_text_eyes', label: 'Eyes' },
  { key: 'flavor_text_torso', label: 'Body' },
  { key: 'flavor_text_arms', label: 'Arms' },
  { key: 'flavor_text_hands', label: 'Hands' },
  { key: 'flavor_text_legs', label: 'Legs' },
  { key: 'flavor_text_feet', label: 'Feet' },
] as const;

const IDENTITY_ORGANIZATION_CONFIG: Record<
  IdentityOrganizationKind,
  Readonly<{ label: string; plural: string; icon: string }>
> = {
  citizenship: {
    label: 'Citizenship',
    plural: 'citizenships',
    icon: 'flag',
  },
  faction: { label: 'Faction', plural: 'factions', icon: 'building' },
  religion: {
    label: 'Religion',
    plural: 'religions',
    icon: 'place-of-worship',
  },
};

const IDENTITY_LOCATION_KIND_ICONS: Record<IdentityLocationKind, string> = {
  system: 'sun',
  planet: 'globe-americas',
  moon: 'moon',
  settlement: 'city',
  compact: 'sitemap',
  habitat: 'satellite',
  flotilla: 'ship',
  unknown: 'question-circle',
};

const IDENTITY_LOCATION_GROUP_ICONS: Record<
  IdentityLocationGroup['kind'],
  string
> = {
  system: 'sun',
  mobile: 'ship',
  unconfirmed: 'question-circle',
};

const formatPronounLabel = (value: string) =>
  value ? `${value.charAt(0).toUpperCase()}${value.slice(1)}` : 'Unset';

const formatNameColorTooltip = (value: string | null) =>
  value
    ? `Name color is ${value}. Click to change it.`
    : 'Name color uses the default. Click to choose a custom color.';

const IdentityField = ({
  label,
  children,
}: Readonly<{ label: string; children: any }>) => (
  <Box className="RogueStar__identityField">
    <Box className="RogueStar__identityFieldLabel">{label}</Box>
    <Box className="RogueStar__identityFieldControl">{children}</Box>
  </Box>
);

const IdentityDropdown = ({
  icon,
  value,
  options,
  disabled,
  displayText,
  onSelected,
}: Readonly<{
  icon: string;
  value: string;
  options: string[];
  disabled: boolean;
  displayText?: string;
  onSelected: (value: string) => void;
}>) => (
  <Dropdown
    key={`${value}-${options.length}`}
    className={`${CHIP_BUTTON_CLASS} RogueStar__identityDropdown`}
    controlContentClassName="Button__content RogueStar__identityDropdownContent"
    color="transparent"
    dropdownStyle="rogue-star"
    icon={icon}
    width="100%"
    options={options}
    selected={value}
    displayText={displayText || value}
    disabled={disabled || !options.length}
    onSelected={(selection) =>
      typeof selection === 'string' && onSelected(selection)
    }
  />
);

const IdentitySelectionReadout = ({ value }: Readonly<{ value: string }>) => {
  const displayValue = value || 'None';
  return (
    <Box className="RogueStar__identitySelectionReadout" title={displayValue}>
      {displayValue}
    </Box>
  );
};

const LongTextEditor = ({
  label,
  value,
  maxLength,
  disabled,
  resetLabel,
  onChange,
}: Readonly<{
  label: string;
  value: string;
  maxLength: number;
  disabled: boolean;
  resetLabel?: string;
  onChange: (value: string) => void;
}>) => (
  <Box className="RogueStar__identityLongTextEditor">
    <Flex align="center" mb={0.5}>
      <Flex.Item grow>
        <Box bold>{label}</Box>
      </Flex.Item>
      <Flex.Item>
        <Box color="label" mr={resetLabel ? 0.5 : 0}>
          {value.length}/{maxLength}
        </Box>
      </Flex.Item>
      {resetLabel ? (
        <Flex.Item>
          <Button.Confirm
            className={CHIP_BUTTON_CLASS}
            icon="rotate-left"
            confirmIcon="triangle-exclamation"
            tooltip={`Clear ${label}`}
            confirmContent={resetLabel}
            disabled={disabled || !value}
            onClick={() => onChange('')}
          />
        </Flex.Item>
      ) : null}
    </Flex>
    <TextArea
      className="RogueStar__identityTextArea"
      maxLength={maxLength}
      value={value}
      disabled={disabled}
      onInput={(_event, nextValue) => onChange(nextValue)}
    />
  </Box>
);

const IdentityCustomLinkEditor = ({
  value,
  maxLength,
  disabled,
  onChange,
}: Readonly<{
  value: string;
  maxLength: number;
  disabled: boolean;
  onChange: (value: string) => void;
}>) => (
  <Box className="RogueStar__identityCustomLinkEditor">
    <Flex align="center" gap={0.5} wrap={false}>
      <Flex.Item basis="112px" shrink={0}>
        <Box bold>Custom Link</Box>
      </Flex.Item>
      <Flex.Item grow minWidth={0}>
        <Input
          fluid
          value={value}
          maxLength={maxLength}
          placeholder="https://example.com/your-profile"
          disabled={disabled}
          onInput={(_event, nextValue) => onChange(nextValue)}
        />
      </Flex.Item>
      <Flex.Item shrink={0}>
        <Box color="label">
          {value.length}/{maxLength}
        </Box>
      </Flex.Item>
      <Flex.Item shrink={0}>
        <Button
          className={CHIP_BUTTON_CLASS}
          icon="times"
          tooltip="Clear custom link"
          disabled={disabled || !value}
          onClick={() => onChange('')}
        />
      </Flex.Item>
    </Flex>
    <Box color="label" mt={0.5}>
      Shown below your examine text. Use a related image, gallery, or profile
      link such as F-list; this is not the place for memes.
    </Box>
  </Box>
);

const IdentityRobotFlavorTextEditor = ({
  visible,
  modules,
  values,
  maxLength,
  disabled,
  onChange,
}: Readonly<{
  visible: boolean;
  modules: string[];
  values: Record<string, string>;
  maxLength: number;
  disabled: boolean;
  onChange: (module: string, value: string) => void;
}>) => {
  if (!visible) {
    return null;
  }
  return (
    <Box className="RogueStar__identityRobotFlavorTextWorkspace">
      <NoticeBox mb={1}>
        Default is used when a robot module has no individual text. Leave a
        module empty to use Default, or enter a single space to intentionally
        show no flavor text for that module.
      </NoticeBox>
      <Box className="RogueStar__identityRobotFlavorTextGrid">
        {modules.map((module) => (
          <LongTextEditor
            key={module}
            label={module}
            value={values[module] || ''}
            maxLength={maxLength}
            disabled={disabled}
            onChange={(value) => onChange(module, value)}
          />
        ))}
      </Box>
    </Box>
  );
};

const IdentityCustomLocationField = ({
  label,
  value,
  valueIsPreset,
  maxLength,
  disabled,
  onChange,
}: Readonly<{
  label: string;
  value: string;
  valueIsPreset: boolean;
  maxLength: number;
  disabled: boolean;
  onChange: (value: string) => void;
}>) => (
  <Box className="RogueStar__identityCustomLocationField">
    <Flex align="center" mb={0.5}>
      <Flex.Item grow>
        <Box bold>Custom {label}</Box>
      </Flex.Item>
      <Flex.Item>
        <Box color="label">
          {valueIsPreset ? 0 : value.length}/{maxLength}
        </Box>
      </Flex.Item>
    </Flex>
    <Input
      fluid
      value={valueIsPreset ? '' : value}
      maxLength={maxLength}
      placeholder={`Enter a custom ${label.toLowerCase()}…`}
      disabled={disabled}
      onInput={(_event, nextValue) => onChange(nextValue)}
    />
  </Box>
);

const IdentityLocationTooltip = ({
  option,
  homeSelected,
  birthplaceSelected,
}: Readonly<{
  option: IdentityLocationOption;
  homeSelected: boolean;
  birthplaceSelected: boolean;
}>) => (
  <Box className="RogueStar__traitDescriptionTooltip RogueStar__identityLocationTooltip">
    <Box className="RogueStar__identityLocationTooltipTitle">
      {getIdentityLocationDisplayName(option)}
    </Box>
    {option.description ? <Box>{option.description}</Box> : null}
    {homeSelected || birthplaceSelected ? (
      <Box className="RogueStar__traitTooltipReason RogueStar__identityLocationTooltipStatus">
        {homeSelected ? (
          <Box>
            <Icon name="home" /> Current home
          </Box>
        ) : null}
        {birthplaceSelected ? (
          <Box>
            <Icon name="baby" /> Current birthplace
          </Box>
        ) : null}
      </Box>
    ) : null}
    <Box className="RogueStar__traitTooltipHint">
      Left-click to set as home. Right-click to set as birthplace.
    </Box>
  </Box>
);

const IdentityLocationTile = ({
  option,
  homeSelected,
  birthplaceSelected,
  disabled,
  onSelect,
}: Readonly<{
  option: IdentityLocationOption;
  homeSelected: boolean;
  birthplaceSelected: boolean;
  disabled: boolean;
  onSelect: (target: IdentityLocationTarget) => void;
}>) => {
  const selected = homeSelected || birthplaceSelected;
  const displayName = getIdentityLocationDisplayName(option);
  return (
    <Button
      fluid
      selected={selected}
      className={`RogueStar__traitTile RogueStar__identityLocationTile${
        selected ? ' RogueStar__traitTile--selected' : ''
      }`}
      tooltip={
        <IdentityLocationTooltip
          option={option}
          homeSelected={homeSelected}
          birthplaceSelected={birthplaceSelected}
        />
      }
      tooltipPosition="right"
      aria-label={`${displayName}; left-click to set home, right-click to set birthplace`}
      aria-pressed={selected}
      disabled={disabled}
      onClick={() => onSelect('home_system')}
      onContextMenu={(event) => {
        event.preventDefault();
        event.stopPropagation();
        if (!disabled) {
          onSelect('birthplace');
        }
      }}>
      <Flex align="center" gap={0.45} wrap={false} width="100%">
        <Flex.Item shrink={0}>
          <Box className="RogueStar__identityLocationTileIcon">
            <Icon
              name={
                IDENTITY_LOCATION_KIND_ICONS[option.kind] || 'map-marker-alt'
              }
            />
          </Box>
        </Flex.Item>
        <Flex.Item grow minWidth={0}>
          <Box className="RogueStar__traitTileName RogueStar__identityLocationTileName">
            {displayName}
          </Box>
        </Flex.Item>
        {selected ? (
          <Flex.Item shrink={0}>
            <Box className="RogueStar__identityLocationTileMarkers">
              {homeSelected ? <Icon name="home" /> : null}
              {birthplaceSelected ? <Icon name="baby" /> : null}
            </Box>
          </Flex.Item>
        ) : null}
      </Flex>
    </Button>
  );
};

const IdentityLocationGroupTitle = ({
  group,
  draft,
}: Readonly<{
  group: IdentityLocationGroup;
  draft: IdentityDraftState;
}>) => {
  const containsHome = group.locations.some(
    (option) => option.name === draft.home_system
  );
  const containsBirthplace = group.locations.some(
    (option) => option.name === draft.birthplace
  );
  return (
    <Flex
      className="RogueStar__traitGroupHeader RogueStar__identityLocationGroupHeader"
      align="center"
      gap={0.65}
      wrap={false}>
      <Flex.Item shrink={0}>
        <Box
          className={`RogueStar__traitGroupIcon RogueStar__identityLocationGroupIcon RogueStar__identityLocationGroupIcon--${group.kind}`}>
          <Icon name={IDENTITY_LOCATION_GROUP_ICONS[group.kind]} />
        </Box>
      </Flex.Item>
      <Flex.Item grow minWidth={0}>
        <Box className="RogueStar__traitGroupName">{group.name}</Box>
      </Flex.Item>
      {containsHome || containsBirthplace ? (
        <Flex.Item shrink={0}>
          <Box className="RogueStar__traitGroupSelected RogueStar__identityLocationGroupSelected">
            {containsHome ? (
              <span>
                <Icon name="home" /> Home
              </span>
            ) : null}
            {containsBirthplace ? (
              <span>
                <Icon name="baby" /> Birthplace
              </span>
            ) : null}
          </Box>
        </Flex.Item>
      ) : null}
      <Flex.Item shrink={0}>
        <Box className="RogueStar__traitGroupCount">
          {group.locations.length}{' '}
          {group.locations.length === 1 ? 'location' : 'locations'}
        </Box>
      </Flex.Item>
    </Flex>
  );
};

const IdentityLocationGroupTooltip = ({
  group,
  draft,
}: Readonly<{
  group: IdentityLocationGroup;
  draft: IdentityDraftState;
}>) => {
  const containsHome = group.locations.some(
    (option) => option.name === draft.home_system
  );
  const containsBirthplace = group.locations.some(
    (option) => option.name === draft.birthplace
  );
  return (
    <Box className="RogueStar__traitDescriptionTooltip RogueStar__identityLocationTooltip RogueStar__identityLocationGroupTooltip">
      <Box className="RogueStar__identityLocationTooltipTitle">
        {group.name}
      </Box>
      <Box>
        {group.description || IDENTITY_LOCATION_GROUP_DESCRIPTION_FALLBACK}
      </Box>
      {containsHome || containsBirthplace ? (
        <Box className="RogueStar__traitTooltipReason RogueStar__identityLocationTooltipStatus">
          {containsHome ? (
            <Box>
              <Icon name="home" /> Contains current home
            </Box>
          ) : null}
          {containsBirthplace ? (
            <Box>
              <Icon name="baby" /> Contains current birthplace
            </Box>
          ) : null}
        </Box>
      ) : null}
      <Box className="RogueStar__traitTooltipHint">
        Click to expand or collapse this group.
      </Box>
    </Box>
  );
};

const IdentityLocationGroupSection = ({
  group,
  draft,
  forceOpen,
  disabled,
  onSelect,
}: Readonly<{
  group: IdentityLocationGroup;
  draft: IdentityDraftState;
  forceOpen: boolean;
  disabled: boolean;
  onSelect: (target: IdentityLocationTarget, value: string) => void;
}>) => (
  <Box
    className={`RogueStar__traitGroup RogueStar__identityLocationGroup RogueStar__identityLocationGroup--${group.kind}`}>
    <Collapsible
      open={forceOpen}
      className={`RogueStar__traitGroupToggle RogueStar__identityLocationGroupToggle RogueStar__identityLocationGroupToggle--${group.kind}`}
      tooltip={<IdentityLocationGroupTooltip group={group} draft={draft} />}
      tooltipPosition="right"
      title={<IdentityLocationGroupTitle group={group} draft={draft} />}>
      <Box className="RogueStar__identityLocationGrid">
        {group.locations.map((option) => {
          const homeSelected = draft.home_system === option.name;
          const birthplaceSelected = draft.birthplace === option.name;
          return (
            <IdentityLocationTile
              key={option.name}
              option={option}
              homeSelected={homeSelected}
              birthplaceSelected={birthplaceSelected}
              disabled={disabled}
              onSelect={(target) => onSelect(target, option.name)}
            />
          );
        })}
      </Box>
    </Collapsible>
  </Box>
);

const IdentityLocationRegionSection = ({
  region,
  draft,
  forceOpen,
  disabled,
  onSelect,
}: Readonly<{
  region: IdentityLocationRegion;
  draft: IdentityDraftState;
  forceOpen: boolean;
  disabled: boolean;
  onSelect: (target: IdentityLocationTarget, value: string) => void;
}>) => (
  <Box
    className="RogueStar__identityLocationRegion"
    role="group"
    aria-label={region.name}>
    <Flex
      align="center"
      gap={0.5}
      className="RogueStar__identityLocationRegionHeader">
      <Flex.Item grow>
        <Box
          className="RogueStar__identityLocationRegionTitle"
          role="heading"
          aria-level={3}>
          {region.name}
        </Box>
      </Flex.Item>
      <Flex.Item shrink={0}>
        <Box className="RogueStar__identityLocationRegionCount">
          {region.locationCount}{' '}
          {region.locationCount === 1 ? 'location' : 'locations'}
        </Box>
      </Flex.Item>
    </Flex>
    <Box className="RogueStar__traitGroups RogueStar__identityLocationGroups">
      {region.groups.map((group) => (
        <IdentityLocationGroupSection
          key={`${group.id}:${forceOpen ? 'filtered' : 'browse'}`}
          group={group}
          draft={draft}
          forceOpen={forceOpen}
          disabled={disabled}
          onSelect={onSelect}
        />
      ))}
    </Box>
  </Box>
);

const IdentityLocationEditor = ({
  options,
  draft,
  view,
  setView,
  search,
  setSearch,
  selectedMapNodeId,
  setSelectedMapNodeId,
  maxLength,
  disabled,
  onChange,
}: Readonly<{
  options: IdentityLocationOption[];
  draft: IdentityDraftState;
  view: IdentityLocationView;
  setView: (view: IdentityLocationView) => void;
  search: string;
  setSearch: (search: string) => void;
  selectedMapNodeId: string;
  setSelectedMapNodeId: (nodeId: string) => void;
  maxLength: number;
  disabled: boolean;
  onChange: (target: IdentityLocationTarget, value: string) => void;
}>) => {
  const allLocationGroups = buildIdentityLocationGroups(options);
  const locationRegions = buildIdentityLocationRegions(options, search);
  const filteredLocationCount = locationRegions.reduce(
    (count, region) => count + region.locationCount,
    0
  );
  const forceGroupsOpen = !!search.trim();
  const mappedSearchMatches = getIdentityStarMapMatchingNodes(
    search,
    allLocationGroups
  );
  const focusMapNode = (nodeId: string) => setSelectedMapNodeId(nodeId);
  const changeSearch = (value: string) => {
    setSearch(value);
    const mapNode = findIdentityStarMapNodeForSearch(value, allLocationGroups);
    if (mapNode) {
      focusMapNode(mapNode.id);
    }
  };

  return (
    <Box className="RogueStar__identityLocationEditor">
      <Flex align="center" wrap={false}>
        <Flex.Item grow minWidth={0} mr={1}>
          <Box color="label">
            Left-click a location to set Home; right-click it to set Birthplace.
            Home is your current primary residence; Birthplace is where the
            character was born or created.
          </Box>
        </Flex.Item>
        <Flex.Item shrink={0} mr={0.5}>
          <Button.Checkbox
            className={CHIP_BUTTON_CLASS}
            checked={draft.home_system === 'Unset'}
            tooltip="Set this character's home to none."
            disabled={disabled}
            onClick={() => onChange('home_system', 'Unset')}>
            No Home
          </Button.Checkbox>
        </Flex.Item>
        <Flex.Item shrink={0}>
          <Button.Checkbox
            className={CHIP_BUTTON_CLASS}
            checked={draft.birthplace === 'Unset'}
            tooltip="Set this character's birthplace to none."
            disabled={disabled}
            onClick={() => onChange('birthplace', 'Unset')}>
            No Birthplace
          </Button.Checkbox>
        </Flex.Item>
      </Flex>
      <Input
        fluid
        mt={1}
        mb={1}
        value={search}
        placeholder="Search regions, locations or lore…"
        onInput={(_event, value) => changeSearch(value)}
      />
      <Tabs fluid className="RogueStar__identityLocationViewTabs">
        <Tabs.Tab
          icon="map"
          selected={view === 'map'}
          onClick={() => setView('map')}>
          Map View
        </Tabs.Tab>
        <Tabs.Tab
          icon="list"
          selected={view === 'catalog'}
          onClick={() => setView('catalog')}>
          Catalog View
        </Tabs.Tab>
      </Tabs>
      {view === 'map' ? (
        <IdentityStarMap
          groups={allLocationGroups}
          draft={draft}
          selectedNodeId={selectedMapNodeId}
          search={search}
          disabled={disabled}
          onFocusNode={focusMapNode}
          onSelect={onChange}
        />
      ) : filteredLocationCount ? (
        <Box className="RogueStar__identityLocationCatalog">
          <Flex
            align="center"
            className="RogueStar__identityLocationCatalogHeader">
            <Flex.Item grow>
              <Box className="RogueStar__identityLocationCatalogTitle">
                Location Catalog
              </Box>
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Box className="RogueStar__identityLocationCatalogCount">
                {filteredLocationCount}{' '}
                {filteredLocationCount === 1 ? 'result' : 'results'}
              </Box>
            </Flex.Item>
          </Flex>
          <Box className="RogueStar__identityLocationRegions">
            {locationRegions.map((region) => (
              <IdentityLocationRegionSection
                key={region.name}
                region={region}
                draft={draft}
                forceOpen={forceGroupsOpen}
                disabled={disabled}
                onSelect={onChange}
              />
            ))}
          </Box>
        </Box>
      ) : mappedSearchMatches.length ? (
        <NoticeBox>
          This search only matches a context landmark. Switch to Map View to
          inspect it; it is not a selectable location.
        </NoticeBox>
      ) : view === 'catalog' ? (
        <NoticeBox>No locations match that search.</NoticeBox>
      ) : null}
      <Box className="RogueStar__identityCustomLocation">
        <Box className="RogueStar__identityCustomLocationGrid">
          <IdentityCustomLocationField
            label="Home"
            value={draft.home_system}
            valueIsPreset={options.some(
              (option) => option.name === draft.home_system
            )}
            maxLength={maxLength}
            disabled={disabled}
            onChange={(value) => onChange('home_system', value)}
          />
          <IdentityCustomLocationField
            label="Birthplace"
            value={draft.birthplace}
            valueIsPreset={options.some(
              (option) => option.name === draft.birthplace
            )}
            maxLength={maxLength}
            disabled={disabled}
            onChange={(value) => onChange('birthplace', value)}
          />
        </Box>
      </Box>
    </Box>
  );
};

const IdentityOrganizationTooltip = ({
  option,
  selected,
  kind,
}: Readonly<{
  option: IdentityOrganizationOption;
  selected: boolean;
  kind: IdentityOrganizationKind;
}>) => {
  return (
    <Box className="RogueStar__traitDescriptionTooltip RogueStar__identityLocationTooltip RogueStar__identityOrganizationTooltip">
      <Box className="RogueStar__identityLocationTooltipTitle">
        {getIdentityOrganizationDisplayName(option)}
      </Box>
      <Box className="RogueStar__identityOrganizationTooltipDescription">
        {option.description || `No ${kind} description is available.`}
      </Box>
      {selected ? (
        <Box className="RogueStar__traitTooltipReason RogueStar__identityLocationTooltipStatus">
          <Icon name="check" /> Current {kind}
        </Box>
      ) : null}
      <Box className="RogueStar__traitTooltipHint">
        Click to set as this character&apos;s {kind}.
      </Box>
    </Box>
  );
};

const IdentityOrganizationTile = ({
  option,
  selected,
  kind,
  disabled,
  onSelect,
}: Readonly<{
  option: IdentityOrganizationOption;
  selected: boolean;
  kind: IdentityOrganizationKind;
  disabled: boolean;
  onSelect: () => void;
}>) => {
  const config = IDENTITY_ORGANIZATION_CONFIG[kind];
  return (
    <Button
      fluid
      selected={selected}
      className={`RogueStar__traitTile RogueStar__identityLocationTile RogueStar__identityOrganizationTile${
        selected ? ' RogueStar__traitTile--selected' : ''
      }`}
      tooltip={
        <IdentityOrganizationTooltip
          option={option}
          selected={selected}
          kind={kind}
        />
      }
      tooltipPosition="right"
      aria-label={`Set ${kind} to ${getIdentityOrganizationDisplayName(option)}`}
      aria-pressed={selected}
      disabled={disabled}
      onClick={onSelect}>
      <Flex align="center" gap={0.45} wrap={false} width="100%">
        <Flex.Item shrink={0}>
          <Box className="RogueStar__identityLocationTileIcon RogueStar__identityOrganizationTileIcon">
            <Icon name={config.icon} />
          </Box>
        </Flex.Item>
        <Flex.Item grow minWidth={0}>
          <Box className="RogueStar__traitTileName RogueStar__identityLocationTileName">
            {getIdentityOrganizationDisplayName(option)}
          </Box>
        </Flex.Item>
        {selected ? (
          <Flex.Item shrink={0}>
            <Box className="RogueStar__identityLocationTileMarkers">
              <Icon name="check" />
            </Box>
          </Flex.Item>
        ) : null}
      </Flex>
    </Button>
  );
};

const IdentityOrganizationEditor = ({
  options,
  value,
  search,
  setSearch,
  kind,
  maxLength,
  disabled,
  onChange,
}: Readonly<{
  options: IdentityOrganizationOption[];
  value: string;
  search: string;
  setSearch: (search: string) => void;
  kind: IdentityOrganizationKind;
  maxLength: number;
  disabled: boolean;
  onChange: (value: string) => void;
}>) => {
  const config = IDENTITY_ORGANIZATION_CONFIG[kind];
  const sortedOptions = sortIdentityOrganizationOptions(options);
  const normalizedSearch = search.trim().toLowerCase();
  const filteredOptions = normalizedSearch
    ? sortedOptions.filter(
        (option) =>
          option.name.toLowerCase().includes(normalizedSearch) ||
          getIdentityOrganizationDisplayName(option)
            .toLowerCase()
            .includes(normalizedSearch) ||
          option.description.toLowerCase().includes(normalizedSearch)
      )
    : sortedOptions;
  const valueIsPreset = options.some((option) => option.name === value);
  const customValue = value === 'None' || valueIsPreset ? '' : value;

  return (
    <Box className="RogueStar__identityOrganizationEditor">
      <Box color="label" mb={1}>
        Select an established {kind} from the catalog. Hover over any entry for
        its lore description, or enter a custom {kind} below.
      </Box>
      <Flex align="center" gap={0.75} mb={1} wrap={false}>
        <Flex.Item grow minWidth={0}>
          <Box>
            Current {kind}:{' '}
            <b>
              {getIdentityOrganizationValueDisplayName(value, options) ||
                'None'}
            </b>
          </Box>
        </Flex.Item>
        <Flex.Item shrink={0}>
          <Button.Checkbox
            className={CHIP_BUTTON_CLASS}
            checked={value === 'None'}
            tooltip={`Set this character's ${kind} to None.`}
            disabled={disabled}
            onClick={() => onChange('None')}>
            No {config.label}
          </Button.Checkbox>
        </Flex.Item>
      </Flex>
      <Input
        fluid
        mb={1}
        value={search}
        placeholder={`Search ${config.plural} or lore…`}
        onInput={(_event, nextValue) => setSearch(nextValue)}
      />
      {filteredOptions.length ? (
        <Box className="RogueStar__identityLocationCatalog RogueStar__identityOrganizationCatalog">
          <Flex
            align="center"
            className="RogueStar__identityLocationCatalogHeader">
            <Flex.Item grow>
              <Box className="RogueStar__identityLocationCatalogTitle">
                {config.label} Catalog
              </Box>
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Box className="RogueStar__identityLocationCatalogCount">
                {filteredOptions.length}{' '}
                {filteredOptions.length === 1 ? 'result' : 'results'}
              </Box>
            </Flex.Item>
          </Flex>
          <Box className="RogueStar__identityLocationGrid RogueStar__identityOrganizationGrid">
            {filteredOptions.map((option) => (
              <IdentityOrganizationTile
                key={option.name}
                option={option}
                selected={value === option.name}
                kind={kind}
                disabled={disabled}
                onSelect={() => onChange(option.name)}
              />
            ))}
          </Box>
        </Box>
      ) : (
        <NoticeBox>No {config.plural} match that search.</NoticeBox>
      )}
      <Box className="RogueStar__identityCustomLocation">
        <Flex align="center" mb={0.5}>
          <Flex.Item grow>
            <Box bold>Custom {config.label}</Box>
          </Flex.Item>
          <Flex.Item>
            <Box color="label">
              {customValue.length}/{maxLength}
            </Box>
          </Flex.Item>
        </Flex>
        <Input
          fluid
          value={customValue}
          maxLength={maxLength}
          placeholder={`Enter a custom ${kind}…`}
          disabled={disabled}
          onInput={(_event, nextValue) => onChange(nextValue)}
        />
      </Box>
    </Box>
  );
};

const IdentitySaveSection = ({
  dirty,
  pendingSave,
  pendingClose,
  uiLocked,
  saveError,
  validationError,
  onSave,
  onSaveAndClose,
  onDiscardAndClose,
}: Readonly<{
  dirty: boolean;
  pendingSave: boolean;
  pendingClose: boolean;
  uiLocked: boolean;
  saveError: string | null;
  validationError: string | null;
  onSave: () => void;
  onSaveAndClose: () => void;
  onDiscardAndClose: () => void;
}>) => (
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

export const IdentityTab = ({
  context,
  stateToken,
  payload,
  draft,
  savedDraft,
  setDraft,
  setDirty,
  dirty,
  pendingSave,
  pendingClose,
  randomNamePending,
  saveError,
  uiLocked,
  onRandomizeName,
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
  iconScaleX,
  iconScaleY,
  previewFitToFrame,
  onTogglePreviewFit,
  showEquipment,
  onToggleEquipment,
  showJobGear,
  onToggleJobGear,
  showLoadoutGear,
  onToggleLoadout,
}: IdentityTabProps) => {
  const [colorPickerOpen, setColorPickerOpen] = useLocalState<boolean>(
    context,
    `identityColorPickerOpen-${stateToken}`,
    false
  );
  const [colorDraft, setColorDraft] = useLocalState<string>(
    context,
    `identityColorDraft-${stateToken}`,
    draft?.name_color || '#7f7f7f'
  );
  const [workspaceTab, setWorkspaceTab] = useLocalState<IdentityWorkspaceTab>(
    context,
    `identityWorkspaceTab-${stateToken}`,
    'flavor'
  );
  const [locationView, setLocationView] = useLocalState<IdentityLocationView>(
    context,
    `identityLocationView-${stateToken}`,
    'map'
  );
  const [locationSearch, setLocationSearch] = useLocalState<string>(
    context,
    `identityLocationSearch-${stateToken}`,
    ''
  );
  const [citizenshipSearch, setCitizenshipSearch] = useLocalState<string>(
    context,
    `identityCitizenshipSearch-${stateToken}`,
    ''
  );
  const [factionSearch, setFactionSearch] = useLocalState<string>(
    context,
    `identityFactionSearch-${stateToken}`,
    ''
  );
  const [religionSearch, setReligionSearch] = useLocalState<string>(
    context,
    `identityReligionSearch-${stateToken}`,
    ''
  );
  const [locationMapNodeId, setLocationMapNodeId] = useLocalState<string>(
    context,
    `identityLocationMapNode-${stateToken}`,
    findIdentityStarMapNodeForLocation(
      draft?.home_system || '',
      payload?.location_options || []
    )?.id || 'sol'
  );

  if (!payload || !draft || !savedDraft) {
    return (
      <Box className="RogueStar" position="relative" minHeight="100%">
        <LoadingOverlay
          title="Loading identity..."
          subtitle="Fetching this character's identity and records."
        />
      </Box>
    );
  }

  const controlsLocked = uiLocked || pendingSave || pendingClose;
  const validationError = resolveIdentityDraftValidationError(payload, draft);
  const updateDraft = <K extends IdentityValueKey>(
    key: K,
    value: IdentityDraftState[K]
  ) => {
    if (controlsLocked) {
      return;
    }
    const next = { ...draft, [key]: value };
    setDraft(next);
    setDirty(!identityDraftStatesEqual(next, savedDraft));
  };
  const birthdayMax = getIdentityBirthdayMaxDay(draft.bday_month);
  const previewBackgroundImage = resolvedCanvasBackground?.asset?.png
    ? `data:image/png;base64,${resolvedCanvasBackground.asset.png}`
    : null;
  const previewBackgroundTileWidth = resolvedCanvasBackground?.asset?.width
    ? resolvedCanvasBackground.asset.width * canvasBackgroundScale
    : undefined;
  const previewBackgroundTileHeight = resolvedCanvasBackground?.asset?.height
    ? resolvedCanvasBackground.asset.height * canvasBackgroundScale
    : undefined;

  return (
    <Box
      className={`RogueStar RogueStar__identityTab${
        pendingSave || pendingClose
          ? ' RogueStar__identityTab--transientLocked'
          : ''
      }`}
      minHeight="100%">
      <Flex direction="row" gap={1} wrap={false} height="100%">
        {/* Match the 840px catalog + 418px settings footprint of other tabs. */}
        <Flex.Item basis="1258px" shrink={0} minWidth={0}>
          <Flex direction="column" gap={1} height="100%">
            <Section
              className="RogueStar__identityWorkspace"
              title="Character Information"
              fill
              scrollable
              buttons={
                <Tabs>
                  {IDENTITY_WORKSPACE_TABS.map((tab) => (
                    <Tabs.Tab
                      key={tab.id}
                      selected={workspaceTab === tab.id}
                      onClick={() => setWorkspaceTab(tab.id)}>
                      {tab.label}
                    </Tabs.Tab>
                  ))}
                </Tabs>
              }>
              {workspaceTab === 'notes' && payload.allow_ooc_notes ? (
                <Box className="RogueStar__identityLongTextGrid">
                  <LongTextEditor
                    label="General"
                    value={draft.metadata}
                    maxLength={payload.max_ooc_notes_length}
                    disabled={controlsLocked}
                    onChange={(value) => updateDraft('metadata', value)}
                  />
                  <LongTextEditor
                    label="Likes"
                    value={draft.metadata_likes}
                    maxLength={payload.max_ooc_notes_length}
                    disabled={controlsLocked}
                    onChange={(value) => updateDraft('metadata_likes', value)}
                  />
                  <LongTextEditor
                    label="Dislikes"
                    value={draft.metadata_dislikes}
                    maxLength={payload.max_ooc_notes_length}
                    disabled={controlsLocked}
                    onChange={(value) =>
                      updateDraft('metadata_dislikes', value)
                    }
                  />
                </Box>
              ) : workspaceTab === 'notes' ? (
                <NoticeBox warning>
                  OOC Notes are disabled by the current server configuration.
                </NoticeBox>
              ) : null}
              {workspaceTab === 'flavor' ? (
                <Box className="RogueStar__identityFlavorTextWorkspace">
                  <IdentityCustomLinkEditor
                    value={draft.custom_link}
                    maxLength={payload.max_custom_link_length}
                    disabled={controlsLocked}
                    onChange={(value) => updateDraft('custom_link', value)}
                  />
                  <Box className="RogueStar__identityFlavorTextGrid">
                    {IDENTITY_FLAVOR_TEXT_FIELDS.map((field) => (
                      <LongTextEditor
                        key={field.key}
                        label={field.label}
                        value={draft[field.key]}
                        maxLength={payload.max_flavor_text_length}
                        disabled={controlsLocked}
                        onChange={(value) => updateDraft(field.key, value)}
                      />
                    ))}
                  </Box>
                </Box>
              ) : null}
              <IdentityRobotFlavorTextEditor
                visible={workspaceTab === 'robot-flavor'}
                modules={payload.robot_flavor_text_modules}
                values={draft.robot_flavor_texts}
                maxLength={payload.max_flavor_text_length}
                disabled={controlsLocked}
                onChange={(module, value) =>
                  updateDraft('robot_flavor_texts', {
                    ...draft.robot_flavor_texts,
                    [module]: value,
                  })
                }
              />
              {workspaceTab === 'records' && payload.records_banned ? (
                <NoticeBox danger>
                  You are banned from using character records.
                </NoticeBox>
              ) : workspaceTab === 'records' ? (
                <Box className="RogueStar__identityLongTextGrid">
                  <LongTextEditor
                    label="Medical Records"
                    value={draft.med_record}
                    maxLength={payload.max_record_length}
                    disabled={controlsLocked}
                    resetLabel="Clear Medical Records"
                    onChange={(value) => updateDraft('med_record', value)}
                  />
                  <LongTextEditor
                    label="Employment Records"
                    value={draft.gen_record}
                    maxLength={payload.max_record_length}
                    disabled={controlsLocked}
                    resetLabel="Clear Employment Records"
                    onChange={(value) => updateDraft('gen_record', value)}
                  />
                  <LongTextEditor
                    label="Security Records"
                    value={draft.sec_record}
                    maxLength={payload.max_record_length}
                    disabled={controlsLocked}
                    resetLabel="Clear Security Records"
                    onChange={(value) => updateDraft('sec_record', value)}
                  />
                </Box>
              ) : null}
              {workspaceTab === 'locations' ? (
                <IdentityLocationEditor
                  options={payload.location_options}
                  draft={draft}
                  view={locationView}
                  setView={setLocationView}
                  search={locationSearch}
                  setSearch={setLocationSearch}
                  selectedMapNodeId={locationMapNodeId}
                  setSelectedMapNodeId={setLocationMapNodeId}
                  maxLength={payload.max_name_length}
                  disabled={controlsLocked}
                  onChange={(target, value) => updateDraft(target, value)}
                />
              ) : null}
              {workspaceTab === 'citizenship' ? (
                <IdentityOrganizationEditor
                  options={payload.citizenship_catalog_options}
                  value={draft.citizenship}
                  search={citizenshipSearch}
                  setSearch={setCitizenshipSearch}
                  kind="citizenship"
                  maxLength={payload.max_name_length}
                  disabled={controlsLocked}
                  onChange={(value) => updateDraft('citizenship', value)}
                />
              ) : null}
              {workspaceTab === 'factions' ? (
                <IdentityOrganizationEditor
                  options={payload.faction_catalog_options}
                  value={draft.faction}
                  search={factionSearch}
                  setSearch={setFactionSearch}
                  kind="faction"
                  maxLength={payload.max_name_length}
                  disabled={controlsLocked}
                  onChange={(value) => updateDraft('faction', value)}
                />
              ) : null}
              {workspaceTab === 'religion' ? (
                <IdentityOrganizationEditor
                  options={payload.religion_catalog_options}
                  value={draft.religion}
                  search={religionSearch}
                  setSearch={setReligionSearch}
                  kind="religion"
                  maxLength={payload.max_name_length}
                  disabled={controlsLocked}
                  onChange={(value) => updateDraft('religion', value)}
                />
              ) : null}
            </Section>
          </Flex>
        </Flex.Item>
        <Flex.Item grow>
          <Flex direction="column" gap={1} height="100%" minHeight={0}>
            <Flex.Item basis="448px" shrink={0} minHeight={0}>
              <LivePreviewCard
                preview={livePreview}
                canvasWidth={canvasWidth}
                canvasHeight={canvasHeight}
                iconScaleX={iconScaleX}
                iconScaleY={iconScaleY}
                previewFitToFrame={previewFitToFrame}
                onTogglePreviewFit={onTogglePreviewFit}
                previewBackgroundImage={previewBackgroundImage}
                backgroundFallbackColor={backgroundFallbackColor}
                canvasBackgroundScale={canvasBackgroundScale}
                previewBackgroundTileWidth={previewBackgroundTileWidth}
                previewBackgroundTileHeight={previewBackgroundTileHeight}
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
            <Flex.Item shrink={0}>
              <IdentitySaveSection
                dirty={dirty}
                pendingSave={pendingSave}
                pendingClose={pendingClose}
                uiLocked={uiLocked}
                saveError={saveError}
                validationError={validationError}
                onSave={onSave}
                onSaveAndClose={onSaveAndClose}
                onDiscardAndClose={onDiscardAndClose}
              />
            </Flex.Item>
            <Flex.Item grow minHeight={0}>
              <Section title="Identity and Background" fill scrollable>
                <IdentityField label="Name">
                  <Flex>
                    <Flex.Item grow minWidth={0}>
                      <Input
                        fluid
                        value={draft.real_name}
                        color={draft.name_color || undefined}
                        maxLength={payload.max_name_length}
                        disabled={controlsLocked}
                        onInput={(_event, value) =>
                          updateDraft('real_name', value)
                        }
                      />
                    </Flex.Item>
                    <Flex.Item ml={0.5} shrink={0}>
                      <Button
                        className={`${CHIP_BUTTON_CLASS} RogueStar__identityNameColorButton`}
                        icon="palette"
                        tooltip={formatNameColorTooltip(draft.name_color)}
                        disabled={controlsLocked}
                        onClick={() => {
                          setColorDraft(draft.name_color || '#7f7f7f');
                          setColorPickerOpen(true);
                        }}>
                        <ColorBox
                          className="RogueStar__identityNameColorSwatch"
                          color={draft.name_color || '#7f7f7f'}
                        />
                      </Button>
                    </Flex.Item>
                    <Flex.Item ml={0.5} shrink={0}>
                      <Button
                        className={CHIP_BUTTON_CLASS}
                        icon={randomNamePending ? 'spinner-third' : 'dice'}
                        iconSpin={randomNamePending}
                        tooltip="Generate a random name using the selected pronouns."
                        disabled={controlsLocked || randomNamePending}
                        onClick={() =>
                          onRandomizeName(draft.identifying_gender)
                        }
                      />
                    </Flex.Item>
                    <Flex.Item ml={0.5} shrink={0}>
                      <Button.Checkbox
                        className={CHIP_BUTTON_CLASS}
                        icon="random"
                        checked={draft.be_random_name}
                        tooltip={`Always use a newly generated name each round. Currently ${
                          draft.be_random_name ? 'enabled' : 'disabled'
                        }.`}
                        disabled={controlsLocked}
                        onClick={() =>
                          updateDraft('be_random_name', !draft.be_random_name)
                        }
                      />
                    </Flex.Item>
                  </Flex>
                </IdentityField>
                <IdentityField label="Nickname">
                  <Flex>
                    <Flex.Item grow minWidth={0}>
                      <Input
                        fluid
                        value={draft.nickname}
                        maxLength={payload.max_name_length}
                        disabled={controlsLocked}
                        placeholder="No nickname"
                        onInput={(_event, value) =>
                          updateDraft('nickname', value)
                        }
                      />
                    </Flex.Item>
                    <Flex.Item ml={0.5}>
                      <Button
                        className={CHIP_BUTTON_CLASS}
                        icon="times"
                        tooltip="Clear nickname"
                        disabled={controlsLocked || !draft.nickname}
                        onClick={() => updateDraft('nickname', '')}
                      />
                    </Flex.Item>
                  </Flex>
                </IdentityField>
                <IdentityField label="Pronouns">
                  <IdentityDropdown
                    icon="venus-mars"
                    value={draft.identifying_gender}
                    options={payload.pronoun_options}
                    displayText={formatPronounLabel(draft.identifying_gender)}
                    disabled={controlsLocked}
                    onSelected={(value) =>
                      updateDraft('identifying_gender', value)
                    }
                  />
                </IdentityField>
                <IdentityField label="Age / Birthday">
                  <Flex align="center">
                    <Flex.Item basis="64px" shrink={0} minWidth={0}>
                      <NumberInput
                        className="RogueStar__numberInput RogueStar__identityNumber"
                        width="100%"
                        minValue={payload.min_age}
                        maxValue={payload.max_age}
                        step={1}
                        value={draft.age}
                        disabled={controlsLocked}
                        onChange={(_event, value) =>
                          updateDraft('age', value ?? payload.min_age)
                        }
                      />
                    </Flex.Item>
                    <Box mx={0.5} color="label">
                      |
                    </Box>
                    <Flex.Item grow>
                      <NumberInput
                        className="RogueStar__numberInput RogueStar__identityNumber"
                        width="100%"
                        minValue={0}
                        maxValue={12}
                        step={1}
                        value={draft.bday_month}
                        disabled={controlsLocked}
                        onChange={(_event, value) => {
                          const month = value ?? 0;
                          const maxDay = getIdentityBirthdayMaxDay(month);
                          const day = month
                            ? Math.min(Math.max(draft.bday_day || 1, 1), maxDay)
                            : 0;
                          const next = {
                            ...draft,
                            bday_month: month,
                            bday_day: day,
                          };
                          setDraft(next);
                          setDirty(!identityDraftStatesEqual(next, savedDraft));
                        }}
                      />
                    </Flex.Item>
                    <Box mx={0.5}>/</Box>
                    <Flex.Item grow>
                      <NumberInput
                        className="RogueStar__numberInput RogueStar__identityNumber"
                        width="100%"
                        minValue={draft.bday_month ? 1 : 0}
                        maxValue={birthdayMax}
                        step={1}
                        value={draft.bday_day}
                        disabled={controlsLocked || !draft.bday_month}
                        onChange={(_event, value) =>
                          updateDraft('bday_day', value ?? 0)
                        }
                      />
                    </Flex.Item>
                    <Flex.Item ml={0.5} shrink={0}>
                      <Button.Checkbox
                        className={CHIP_BUTTON_CLASS}
                        icon="bell"
                        checked={draft.bday_announce}
                        tooltip={
                          draft.bday_month
                            ? `Announce this character's birthday. Currently ${
                                draft.bday_announce ? 'enabled' : 'disabled'
                              }.`
                            : 'Set a birthday to enable birthday announcements.'
                        }
                        disabled={controlsLocked || !draft.bday_month}
                        onClick={() =>
                          updateDraft('bday_announce', !draft.bday_announce)
                        }
                      />
                    </Flex.Item>
                  </Flex>
                </IdentityField>
                <IdentityField label="Economic Status">
                  <IdentityDropdown
                    icon="coins"
                    value={draft.economic_status}
                    options={payload.economic_status_options}
                    disabled={controlsLocked}
                    onSelected={(value) =>
                      updateDraft('economic_status', value)
                    }
                  />
                </IdentityField>
                <IdentityField label="Home">
                  <IdentitySelectionReadout
                    value={getIdentityLocationValueDisplayName(
                      draft.home_system,
                      payload.location_options
                    )}
                  />
                </IdentityField>
                <IdentityField label="Birthplace">
                  <IdentitySelectionReadout
                    value={getIdentityLocationValueDisplayName(
                      draft.birthplace,
                      payload.location_options
                    )}
                  />
                </IdentityField>
                <IdentityField label="Citizenship">
                  <IdentitySelectionReadout
                    value={getIdentityOrganizationValueDisplayName(
                      draft.citizenship,
                      payload.citizenship_catalog_options
                    )}
                  />
                </IdentityField>
                <IdentityField label="Faction">
                  <IdentitySelectionReadout
                    value={getIdentityOrganizationValueDisplayName(
                      draft.faction,
                      payload.faction_catalog_options
                    )}
                  />
                </IdentityField>
                <IdentityField label="Religion">
                  <IdentitySelectionReadout value={draft.religion} />
                </IdentityField>
              </Section>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      {colorPickerOpen ? (
        <Modal width="680px" maxWidth="90%" maxHeight="90%" mx="auto">
          <Section
            title="Name Color"
            buttons={
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="times"
                onClick={() => setColorPickerOpen(false)}
              />
            }>
            <Box className="RogueStar__inlineColorPicker">
              <RogueStarColorPicker
                color={colorDraft}
                currentColor={draft.name_color || '#7f7f7f'}
                onChange={setColorDraft}
                onCommit={setColorDraft}
                showCustomColors={false}
              />
            </Box>
            <Flex mt={1} align="center" justify="space-between">
              <Flex.Item>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  icon="rotate-left"
                  disabled={controlsLocked || !draft.name_color}
                  tooltip="Remove the custom name color."
                  onClick={() => {
                    updateDraft('name_color', null);
                    setColorPickerOpen(false);
                  }}>
                  Use Default
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button
                  className={CHIP_BUTTON_CLASS}
                  icon="times"
                  mr={0.5}
                  onClick={() => setColorPickerOpen(false)}>
                  Cancel
                </Button>
                <Button
                  className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
                  icon="check"
                  onClick={() => {
                    updateDraft('name_color', colorDraft);
                    setColorPickerOpen(false);
                  }}>
                  Apply
                </Button>
              </Flex.Item>
            </Flex>
          </Section>
        </Modal>
      ) : null}
    </Box>
  );
};
