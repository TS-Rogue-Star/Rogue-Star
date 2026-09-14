// //////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Identity Tab Map //
// //////////////////////////////////////////////////////////////////

import { Box, Button, Flex, Icon, NoticeBox } from '../../components';
import type {
  IdentityDraftState,
  IdentityLocationGroup,
  IdentityLocationKind,
} from './types';
import { getIdentityLocationDisplayName } from './utils/identity';
import {
  getIdentityStarMapGroupForNode,
  getIdentityStarMapMatchingNodes,
  IDENTITY_STAR_MAP_AREA_LABELS,
  IDENTITY_STAR_MAP_BOUNDARIES,
  IDENTITY_STAR_MAP_NODES,
  IDENTITY_STAR_MAP_REGIONS,
  type IdentityStarMapNode,
} from './utils/identityStarMap';

type IdentityLocationTarget = 'home_system' | 'birthplace';

type IdentityStarMapProps = Readonly<{
  groups: IdentityLocationGroup[];
  draft: IdentityDraftState;
  selectedNodeId: string;
  search: string;
  disabled: boolean;
  onFocusNode: (nodeId: string) => void;
  onSelect: (target: IdentityLocationTarget, value: string) => void;
}>;

const IDENTITY_STAR_MAP_KIND_ICONS: Record<IdentityLocationKind, string> = {
  system: 'sun',
  planet: 'globe-americas',
  moon: 'moon',
  settlement: 'city',
  compact: 'sitemap',
  habitat: 'satellite',
  flotilla: 'ship',
  unknown: 'question-circle',
};

const nodeContainsValue = (
  node: IdentityStarMapNode,
  value: string,
  groups: readonly IdentityLocationGroup[]
): boolean =>
  !!getIdentityStarMapGroupForNode(node, groups)?.locations.some(
    (location) => location.name === value
  );

const IdentityStarMapChoice = ({
  option,
  draft,
  disabled,
  onSelect,
}: Readonly<{
  option: IdentityLocationGroup['locations'][number];
  draft: IdentityDraftState;
  disabled: boolean;
  onSelect: (target: IdentityLocationTarget) => void;
}>) => {
  const homeSelected = draft.home_system === option.name;
  const birthplaceSelected = draft.birthplace === option.name;
  const selected = homeSelected || birthplaceSelected;
  const displayName = getIdentityLocationDisplayName(option);
  return (
    <Button
      fluid
      selected={selected}
      className={`RogueStar__identityStarMapChoice${
        selected ? ' RogueStar__identityStarMapChoice--selected' : ''
      }`}
      tooltip={
        option.description ||
        'Left-click to set as home. Right-click to set as birthplace.'
      }
      tooltipPosition="left"
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
          <Box className="RogueStar__identityStarMapChoiceIcon">
            <Icon
              name={
                IDENTITY_STAR_MAP_KIND_ICONS[option.kind] || 'map-marker-alt'
              }
            />
          </Box>
        </Flex.Item>
        <Flex.Item grow minWidth={0}>
          <Box className="RogueStar__identityStarMapChoiceName">
            {displayName}
          </Box>
        </Flex.Item>
        {homeSelected || birthplaceSelected ? (
          <Flex.Item shrink={0}>
            <Box className="RogueStar__identityStarMapChoiceMarkers">
              {homeSelected ? <Icon name="home" /> : null}
              {birthplaceSelected ? <Icon name="baby" /> : null}
            </Box>
          </Flex.Item>
        ) : null}
      </Flex>
    </Button>
  );
};

const IdentityStarMapDetails = ({
  node,
  group,
  draft,
  disabled,
  onSelect,
}: Readonly<{
  node: IdentityStarMapNode;
  group: IdentityLocationGroup | null;
  draft: IdentityDraftState;
  disabled: boolean;
  onSelect: (target: IdentityLocationTarget, value: string) => void;
}>) => {
  const description =
    group?.description ||
    node.description ||
    'No broader system overview is currently available in the repository lore.';
  return (
    <Box className="RogueStar__identityStarMapDetails">
      <Box className="RogueStar__identityStarMapDetailsSummary">
        <Box className="RogueStar__identityStarMapDetailsHeader">
          <Box className="RogueStar__identityStarMapDetailsEyebrow">
            {node.region}
          </Box>
          <Box className="RogueStar__identityStarMapDetailsTitle">
            {node.label}
          </Box>
          {group ? (
            <Flex gap={0.35} wrap>
              <Flex.Item>
                <Box className="RogueStar__identityStarMapStatus">
                  {group.locations.length}{' '}
                  {group.locations.length === 1 ? 'choice' : 'choices'}
                </Box>
              </Flex.Item>
            </Flex>
          ) : null}
        </Box>
        <Box className="RogueStar__identityStarMapDescription">
          {description}
        </Box>
      </Box>
      <Box className="RogueStar__identityStarMapDetailsSelection">
        {group?.locations.length ? (
          <Box className="RogueStar__identityStarMapChoices">
            <Box className="RogueStar__identityStarMapChoicesLabel">
              Choose Location
            </Box>
            <Box className="RogueStar__identityStarMapChoiceGrid">
              {group.locations.map((option) => (
                <IdentityStarMapChoice
                  key={option.name}
                  option={option}
                  draft={draft}
                  disabled={disabled}
                  onSelect={(target) => onSelect(target, option.name)}
                />
              ))}
            </Box>
          </Box>
        ) : (
          <NoticeBox className="RogueStar__identityStarMapLandmarkNotice">
            This landmark provides map context and is not a selectable location.
          </NoticeBox>
        )}
      </Box>
    </Box>
  );
};

export const IdentityStarMap = ({
  groups,
  draft,
  selectedNodeId,
  search,
  disabled,
  onFocusNode,
  onSelect,
}: IdentityStarMapProps) => {
  const matchingNodes = getIdentityStarMapMatchingNodes(search, groups);
  const matchingNodeIds = new Set(matchingNodes.map((node) => node.id));
  const hasSearch = !!search.trim();
  const selectedNode =
    IDENTITY_STAR_MAP_NODES.find((node) => node.id === selectedNodeId) ||
    IDENTITY_STAR_MAP_NODES.find((node) => node.id === 'sol') ||
    IDENTITY_STAR_MAP_NODES[0];
  const selectedGroup = getIdentityStarMapGroupForNode(selectedNode, groups);

  return (
    <Box className="RogueStar__identityStarMapLayout">
      <Box
        className="RogueStar__identityStarMap"
        role="region"
        aria-label="Interactive origin star map">
        <Box className="RogueStar__identityStarMapCanvas">
          <svg
            className="RogueStar__identityStarMapOverlay"
            viewBox="0 0 100 100"
            preserveAspectRatio="none"
            aria-hidden="true">
            {IDENTITY_STAR_MAP_REGIONS.map((region) => (
              <path
                key={region.id}
                className={`RogueStar__identityStarMapRegion RogueStar__identityStarMapRegion--${region.tone}`}
                d={region.path}
              />
            ))}
            {IDENTITY_STAR_MAP_BOUNDARIES.map((boundary, boundaryIndex) => (
              <polyline
                key={boundaryIndex}
                className="RogueStar__identityStarMapBoundary"
                points={boundary
                  .map((point) => `${point.x},${point.y}`)
                  .join(' ')}
              />
            ))}
          </svg>
          {IDENTITY_STAR_MAP_REGIONS.map((region) => (
            <Box
              key={region.id}
              className={`RogueStar__identityStarMapRegionLabel RogueStar__identityStarMapRegionLabel--${region.tone}`}
              style={{ left: `${region.labelX}%`, top: `${region.labelY}%` }}>
              {region.label}
              {region.detail ? <small>{region.detail}</small> : null}
            </Box>
          ))}
          {IDENTITY_STAR_MAP_AREA_LABELS.map((areaLabel) => (
            <Box
              key={areaLabel.id}
              className="RogueStar__identityStarMapRegionLabel RogueStar__identityStarMapAreaLabel"
              style={{ left: `${areaLabel.x}%`, top: `${areaLabel.y}%` }}>
              {areaLabel.label}
            </Box>
          ))}
          {IDENTITY_STAR_MAP_NODES.map((node) => {
            const homeSelected = nodeContainsValue(
              node,
              draft.home_system,
              groups
            );
            const birthplaceSelected = nodeContainsValue(
              node,
              draft.birthplace,
              groups
            );
            const selected = selectedNode.id === node.id;
            const searchMatch = !hasSearch || matchingNodeIds.has(node.id);
            return (
              <button
                key={node.id}
                type="button"
                className={`RogueStar__identityStarMapNode RogueStar__identityStarMapNode--label-${node.labelPlacement}${
                  selected ? ' RogueStar__identityStarMapNode--selected' : ''
                }${
                  homeSelected || birthplaceSelected
                    ? ' RogueStar__identityStarMapNode--referenced'
                    : ''
                }${
                  !searchMatch
                    ? ' RogueStar__identityStarMapNode--searchDimmed'
                    : ''
                }${
                  hasSearch && searchMatch
                    ? ' RogueStar__identityStarMapNode--searchMatch'
                    : ''
                }`}
                style={{ left: `${node.x}%`, top: `${node.y}%` }}
                title={`${node.label} — ${node.region}. Open location details and choices.`}
                aria-label={`Open ${node.label} details`}
                aria-pressed={selected}
                onClick={() => onFocusNode(node.id)}>
                <span className="RogueStar__identityStarMapNodeHalo" />
                <span className="RogueStar__identityStarMapNodeCore" />
                <span className="RogueStar__identityStarMapNodeLabel">
                  {node.label}
                </span>
                {homeSelected || birthplaceSelected ? (
                  <span className="RogueStar__identityStarMapNodeMarkers">
                    {homeSelected ? <Icon name="home" /> : null}
                    {birthplaceSelected ? <Icon name="baby" /> : null}
                  </span>
                ) : null}
              </button>
            );
          })}
        </Box>
        {hasSearch && !matchingNodes.length ? (
          <Box className="RogueStar__identityStarMapNoMatch">
            No mapped system matches this search.
          </Box>
        ) : null}
      </Box>
      <IdentityStarMapDetails
        node={selectedNode}
        group={selectedGroup}
        draft={draft}
        disabled={disabled}
        onSelect={onSelect}
      />
    </Box>
  );
};
