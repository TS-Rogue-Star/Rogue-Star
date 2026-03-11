// /////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star March 2026: Interface for the Item Bank //
// /////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import { UI_DISABLED, UI_INTERACTIVE, UI_UPDATE } from '../constants';
import {
  Box,
  Button,
  Input,
  NumberInput,
  Section,
  Stack,
  Tooltip,
} from '../components';
import { Window } from '../layouts';
import Eye1IconAsset from '../../../public/Icons/Rogue Star/eye 1.png';
import Eye2IconAsset from '../../../public/Icons/Rogue Star/eye 2.png';
import Eye3IconAsset from '../../../public/Icons/Rogue Star/eye 3.png';

type ItemEntry = {
  id: string;
  label: string;
  type: string;
  preview?: string | null;
  claimed?: boolean;
};

type GroupedItemEntry = {
  id: string;
  label: string;
  type: string;
  preview?: string | null;
  claimed?: boolean;
  count: number;
};

type PendingGeneralWithdraw = {
  id: string;
  label: string;
};

type Data = {
  busy?: boolean;
  characterName?: string;
  infoText?: string;
  generalTaken?: boolean;
  handsFull?: boolean;
  triangles?: number;
  generalItems?: ItemEntry[];
  personalItems?: ItemEntry[];
  generalCapacity?: number;
  personalCapacity?: number;
};

const ROGUE_STAR_THEME = 'nanotrasen rogue-star-window';
const CHIP_BUTTON_CLASS = 'RogueStar__chip';
const STORAGE_TIMESTAMP_SUFFIX_RE = /\s-\s\d{14}$/;

const getDisplayLabel = (label: string) =>
  label.replace(STORAGE_TIMESTAMP_SUFFIX_RE, '');

const groupTileEntries = (entries: ItemEntry[]): GroupedItemEntry[] => {
  const grouped = new Map<string, GroupedItemEntry>();

  for (const entry of entries) {
    const displayLabel = getDisplayLabel(entry.label);
    const groupKey = [
      displayLabel,
      entry.type,
      entry.preview || '',
      entry.claimed ? '1' : '0',
    ].join('|');

    const existing = grouped.get(groupKey);
    if (existing) {
      existing.count += 1;
      continue;
    }

    grouped.set(groupKey, {
      id: entry.id,
      label: displayLabel,
      type: entry.type,
      preview: entry.preview,
      claimed: entry.claimed,
      count: 1,
    });
  }

  return Array.from(grouped.values());
};

type EntryTileProps = Readonly<{
  disabled: boolean;
  entry: GroupedItemEntry;
  onClick: () => void;
}>;

const EntryTile = ({ disabled, entry, onClick }: EntryTileProps) => {
  const isClaimed = !!entry.claimed;
  const actionDisabled = disabled || isClaimed;
  const countText = entry.count > 1 ? ` x${entry.count}` : '';
  const tooltipText = isClaimed
    ? `${entry.label}${countText} (claimed this shift)`
    : `${entry.label}${countText}`;

  return (
    <Button
      className={`RogueStar__itemBankTile${isClaimed ? ' RogueStar__itemBankTile--claimed' : ''}`}
      disabled={actionDisabled}
      tooltip={tooltipText}
      title={tooltipText}
      onClick={onClick}>
      <Box className="RogueStar__itemBankPreview RogueStar__itemBankPreview--tile">
        {entry.preview ? (
          <img
            className="RogueStar__itemBankPreviewImage"
            src={`data:image/png;base64,${entry.preview}`}
            alt=""
          />
        ) : (
          <Box className="RogueStar__itemBankPreviewFallback">NO PREVIEW</Box>
        )}
      </Box>
      {entry.count > 1 && (
        <Box className="RogueStar__itemBankTileCount">x{entry.count}</Box>
      )}
      {isClaimed && <Box className="RogueStar__itemBankTileBadge">Claimed</Box>}
    </Button>
  );
};

export const ItemBank = (_props, context) => {
  const { act, config, data } = useBackend<Data>(context);
  const {
    busy = false,
    characterName = '',
    generalItems = [],
    generalTaken = false,
    handsFull = false,
    infoText = '',
    personalItems = [],
    generalCapacity = 50,
    personalCapacity = 0,
    triangles = 0,
  } = data;

  const [generalSearch, setGeneralSearch] = useLocalState(
    context,
    'itemBankGeneralSearch',
    ''
  );
  const [personalSearch, setPersonalSearch] = useLocalState(
    context,
    'itemBankPersonalSearch',
    ''
  );
  const [coinAmount, setCoinAmount] = useLocalState(
    context,
    'itemBankCoinAmount',
    0
  );
  const [pendingWithdraw, setPendingWithdraw] = useLocalState(
    context,
    'itemBankPendingWithdraw',
    false
  );
  const [pendingGeneralWithdraw, setPendingGeneralWithdraw] =
    useLocalState<PendingGeneralWithdraw | null>(
      context,
      'itemBankPendingGeneralWithdraw',
      null
    );

  const normalizedGeneralSearch = generalSearch.trim().toLowerCase();
  const normalizedPersonalSearch = personalSearch.trim().toLowerCase();
  const normalizedCoinAmount = Math.max(0, Math.round(Number(coinAmount) || 0));

  const filteredGeneralItems = generalItems.filter((entry) => {
    if (!normalizedGeneralSearch) {
      return true;
    }
    const displayLabel = getDisplayLabel(entry.label);
    return (
      displayLabel.toLowerCase().includes(normalizedGeneralSearch) ||
      entry.type.toLowerCase().includes(normalizedGeneralSearch)
    );
  });

  const filteredPersonalItems = personalItems.filter((entry) => {
    if (!normalizedPersonalSearch) {
      return true;
    }
    const displayLabel = getDisplayLabel(entry.label);
    return (
      displayLabel.toLowerCase().includes(normalizedPersonalSearch) ||
      entry.type.toLowerCase().includes(normalizedPersonalSearch)
    );
  });
  const groupedGeneralItems = groupTileEntries(filteredGeneralItems);
  const groupedPersonalItems = groupTileEntries(filteredPersonalItems);
  const resolvedGeneralCapacity = Math.max(
    generalCapacity,
    generalItems.length
  );
  const resolvedPersonalCapacity = Math.max(
    personalCapacity,
    personalItems.length
  );
  const windowTitle = infoText ? (
    <Tooltip content={infoText} position="bottom">
      <Box className="RogueStar__itemBankTitleInfo">Electronic Lockbox</Box>
    </Tooltip>
  ) : (
    'Electronic Lockbox'
  );
  const eyeIconAssetByStatus = {
    [UI_INTERACTIVE]: Eye1IconAsset,
    [UI_UPDATE]: Eye2IconAsset,
    [UI_DISABLED]: Eye3IconAsset,
  };
  const statusIconAsset =
    eyeIconAssetByStatus[config.status] || eyeIconAssetByStatus[UI_DISABLED];
  const statusIcon = (
    <img
      className="TitleBar__statusIcon RogueStar__statusIcon"
      src={statusIconAsset}
      alt=""
    />
  );

  return (
    <Window
      title={windowTitle}
      width={1200}
      height={760}
      resizable
      statusIcon={statusIcon}
      theme={ROGUE_STAR_THEME}>
      <Window.Content scrollable>
        <Box
          className="RogueStar RogueStar--itemBank"
          position="relative"
          minHeight="100%">
          <Box className="RogueStar__itemBankBootOverlay">
            <Box className="RogueStar__itemBankBootText">
              <Box className="RogueStar__itemBankBootLine">
                Biometrics identified: {characterName || 'Unknown User'}
              </Box>
              <Box className="RogueStar__itemBankBootLine">Logging in...</Box>
            </Box>
          </Box>
          <Box className="RogueStar__itemBankContent">
            <Box className="RogueStar__itemBankTopStatus">
              {handsFull ? (
                <Box className="RogueStar__noticeBar RogueStar__noticeBar--yellow">
                  <Box className="RogueStar__noticeText">
                    Your hands are full. Retrieval actions are blocked.
                  </Box>
                </Box>
              ) : (
                <Box
                  className={`RogueStar__noticeBar ${
                    busy
                      ? 'RogueStar__noticeBar--blue'
                      : 'RogueStar__noticeBar--green'
                  }`}>
                  <Box className="RogueStar__noticeText">
                    {busy
                      ? 'The lockbox is processing an action.'
                      : 'The lockbox is ready.'}
                  </Box>
                </Box>
              )}
            </Box>
            <Section className="RogueStar__itemBankWithdrawSection">
              <Box className="RogueStar__itemBankWithdrawRow">
                <Box className="RogueStar__itemBankWithdrawLabel">
                  Withdraw Triangles
                </Box>
                <Box className="RogueStar__itemBankStatusRow RogueStar__itemBankStatusRow--inline">
                  <Box as="span">Available Triangles:</Box>
                  <Box as="span" bold>
                    {triangles}
                  </Box>
                </Box>
                <NumberInput
                  className="RogueStar__numberInput RogueStar__itemBankWithdrawInput"
                  minValue={0}
                  maxValue={Math.max(0, triangles)}
                  step={1}
                  value={normalizedCoinAmount}
                  onChange={(_event, value) =>
                    setCoinAmount(Math.max(0, Math.round(value)))
                  }
                />
                <Box className="RogueStar__itemBankActions RogueStar__itemBankActions--inline">
                  {pendingWithdraw ? (
                    <>
                      <Button
                        className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
                        disabled={
                          busy ||
                          normalizedCoinAmount <= 0 ||
                          normalizedCoinAmount > triangles
                        }
                        icon="check"
                        onClick={() => {
                          act('withdraw_triangles', {
                            amount: normalizedCoinAmount,
                            confirm: 1,
                          });
                          setPendingWithdraw(false);
                        }}>
                        Confirm Withdraw
                      </Button>
                      <Button
                        className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--negative`}
                        icon="times"
                        onClick={() => setPendingWithdraw(false)}>
                        Cancel
                      </Button>
                    </>
                  ) : (
                    <Button
                      className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
                      disabled={
                        busy ||
                        normalizedCoinAmount <= 0 ||
                        normalizedCoinAmount > triangles
                      }
                      icon="coins"
                      onClick={() => setPendingWithdraw(true)}>
                      Withdraw {normalizedCoinAmount}
                    </Button>
                  )}
                </Box>
              </Box>
            </Section>
            <Stack vertical fill>
              <Stack.Item grow>
                <Section
                  title={`General Compartment (${generalItems.length} / ${resolvedGeneralCapacity})`}
                  buttons={
                    <Box color={generalTaken ? 'average' : 'good'}>
                      {generalTaken
                        ? 'Already withdrawn this shift'
                        : 'Available'}
                    </Box>
                  }>
                  <Input
                    className="RogueStar__itemBankSearch"
                    fluid
                    mb={1}
                    placeholder="Search general storage"
                    value={generalSearch}
                    onInput={(_, value) => setGeneralSearch(value)}
                  />
                  {pendingGeneralWithdraw && (
                    <Box
                      className="RogueStar__noticeBar RogueStar__noticeBar--yellow"
                      mb={1}>
                      <Stack align="center">
                        <Stack.Item grow>
                          <Box className="RogueStar__noticeText">
                            Withdraw {pendingGeneralWithdraw.label}? This
                            general-compartment retrieval is irreversible for
                            the rest of the shift.
                          </Box>
                        </Stack.Item>
                        <Stack.Item>
                          <Box className="RogueStar__itemBankActions RogueStar__itemBankActions--inline">
                            <Button
                              className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
                              disabled={busy || generalTaken || handsFull}
                              icon="check"
                              onClick={() => {
                                act('retrieve_general', {
                                  id: pendingGeneralWithdraw.id,
                                  confirm: 1,
                                });
                                setPendingGeneralWithdraw(null);
                              }}>
                              Confirm Withdraw
                            </Button>
                            <Button
                              className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--negative`}
                              icon="times"
                              onClick={() => setPendingGeneralWithdraw(null)}>
                              Cancel
                            </Button>
                          </Box>
                        </Stack.Item>
                      </Stack>
                    </Box>
                  )}
                  <Box className="RogueStar__itemBankList">
                    {groupedGeneralItems.length ? (
                      groupedGeneralItems.map((entry) => (
                        <EntryTile
                          key={entry.id}
                          disabled={busy || generalTaken || handsFull}
                          entry={entry}
                          onClick={() =>
                            setPendingGeneralWithdraw({
                              id: entry.id,
                              label: entry.label,
                            })
                          }
                        />
                      ))
                    ) : (
                      <Box color="label" className="RogueStar__itemBankEmpty">
                        {generalItems.length
                          ? 'No general items match your search.'
                          : 'No stored items available.'}
                      </Box>
                    )}
                  </Box>
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section
                  title={`Personal Compartment (${personalItems.length} / ${resolvedPersonalCapacity})`}>
                  <Input
                    className="RogueStar__itemBankSearch"
                    fluid
                    mb={1}
                    placeholder="Search personal storage"
                    value={personalSearch}
                    onInput={(_, value) => setPersonalSearch(value)}
                  />
                  <Box className="RogueStar__itemBankList">
                    {groupedPersonalItems.length ? (
                      groupedPersonalItems.map((entry) => (
                        <EntryTile
                          key={entry.id}
                          disabled={busy || handsFull}
                          entry={entry}
                          onClick={() =>
                            act('retrieve_personal', {
                              id: entry.id,
                              confirm: 1,
                            })
                          }
                        />
                      ))
                    ) : (
                      <Box color="label" className="RogueStar__itemBankEmpty">
                        {personalItems.length
                          ? 'No personal items match your search.'
                          : 'No personal unlockables catalogued.'}
                      </Box>
                    )}
                  </Box>
                </Section>
              </Stack.Item>
            </Stack>
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};
