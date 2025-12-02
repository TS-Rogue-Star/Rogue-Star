// /////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Admin tool for viewing etching data ///
// /////////////////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from '../components';
import { Window } from '../layouts';
import CustomEyeIconAsset from '../../../public/Icons/Rogue Star/eye 1.png';

const ROGUE_STAR_THEME = 'nanotrasen rogue-star-window';
const CHIP_BUTTON_CLASS = 'RogueStar__chip';
const PILL_BUTTON_CLASS = 'RogueStar__pillButton';

type ItemEntry = {
  label: string;
  type: string;
};

type KeyValueEntry = {
  key: string;
  value: string;
};

type CharacterEntry = {
  file: string;
  name: string;
  event?: boolean;
  path: string;
};

type CharacterDetail = {
  name: string;
  file: string;
  path: string;
  event?: boolean;
  ckey?: string;
  triangles?: number;
  xp?: { label: string; value: number }[];
  itemStorage?: ItemEntry[];
  unlockables?: ItemEntry[];
  extras?: KeyValueEntry[];
  nif?: {
    type?: string;
    durability?: number;
    savedata?: KeyValueEntry[];
    raw?: string;
  };
  meta?: {
    path?: string;
    size?: number;
  };
  rawJson?: string;
  character_error?: string;
};

type Data = {
  target_ckey?: string;
  status?: string;
  error?: string;
  characters?: CharacterEntry[];
  selected_file?: string;
  detail?: CharacterDetail;
  online_ckeys?: string[];
};

export const EtchingViewer = (_props, context) => {
  const { act, data } = useBackend<Data>(context);
  const {
    target_ckey,
    status,
    error,
    characters = [],
    selected_file,
    detail,
    online_ckeys = [],
  } = data;

  const [ckeyInput, setCkeyInput] = useLocalState(
    context,
    'etchingViewerCkey',
    target_ckey || ''
  );

  const trimmedInput = ckeyInput.trim();
  const onlinePreview = online_ckeys.slice(0, 25);
  const onlineOverflow = Math.max(
    0,
    online_ckeys.length - onlinePreview.length
  );
  const statusIcon = (
    <img
      className="TitleBar__statusIcon RogueStar__statusIcon"
      src={CustomEyeIconAsset}
      alt=""
    />
  );

  return (
    <Window
      theme={ROGUE_STAR_THEME}
      width={1120}
      height={720}
      resizable
      statusIcon={statusIcon}
      title={`Etching Viewer${target_ckey ? ` - ${target_ckey}` : ''}`}>
      <Window.Content scrollable>
        <Box className="RogueStar" position="relative" minHeight="100%">
          <Stack fill>
            <Stack.Item basis="32%" grow>
              <Stack vertical fill>
                <Stack.Item>
                  <Section title="Target CKey">
                    <Input
                      value={ckeyInput}
                      placeholder="ckey"
                      fluid
                      onInput={(_, value) => setCkeyInput(value)}
                      onEnter={() =>
                        trimmedInput && act('load_ckey', { ckey: trimmedInput })
                      }
                      mb={1}
                    />
                  </Section>
                </Stack.Item>
                <Stack.Item>
                  <Section title={`Online Players (${online_ckeys.length})`}>
                    {onlinePreview.length ? (
                      <Table>
                        <Table.Row header>
                          <Table.Cell>CKey</Table.Cell>
                          <Table.Cell collapsing>Action</Table.Cell>
                        </Table.Row>
                        {onlinePreview.map((ckey) => (
                          <Table.Row key={ckey}>
                            <Table.Cell>{ckey}</Table.Cell>
                            <Table.Cell collapsing>
                              <Button
                                className={PILL_BUTTON_CLASS}
                                icon="sign-in-alt"
                                content="Load"
                                onClick={() => {
                                  setCkeyInput(ckey);
                                  act('load_ckey', { ckey });
                                }}
                              />
                            </Table.Cell>
                          </Table.Row>
                        ))}
                      </Table>
                    ) : (
                      <Box color="label">No connected clients detected.</Box>
                    )}
                    {onlineOverflow > 0 && (
                      <Box mt={1} color="label">
                        +{onlineOverflow} more not shown.
                      </Box>
                    )}
                  </Section>
                </Stack.Item>
                <Stack.Item>
                  <Section title={`Characters (${characters.length})`}>
                    {characters.length ? (
                      <Stack vertical fill>
                        {characters.map((character) => {
                          const isEvent = !!character.event;
                          return (
                            <Stack.Item key={character.file} mb={0.25}>
                              <Button
                                className={PILL_BUTTON_CLASS}
                                fluid
                                selected={character.file === selected_file}
                                onClick={() =>
                                  act('select_character', {
                                    file: character.file,
                                  })
                                }>
                                <Stack align="center" justify="space-between">
                                  <Stack.Item grow>
                                    <Box textAlign="left">{character.name}</Box>
                                  </Stack.Item>
                                  {isEvent && (
                                    <Stack.Item>
                                      <Box
                                        as="span"
                                        className={CHIP_BUTTON_CLASS}
                                        px="0.5rem"
                                        py="0.2rem">
                                        EVENT
                                      </Box>
                                    </Stack.Item>
                                  )}
                                </Stack>
                              </Button>
                            </Stack.Item>
                          );
                        })}
                      </Stack>
                    ) : (
                      <Box color="label">
                        Load a ckey to view available etching files.
                      </Box>
                    )}
                  </Section>
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item grow basis="68%">
              <Stack vertical fill>
                {status && (
                  <Stack.Item>
                    <NoticeBox success>{status}</NoticeBox>
                  </Stack.Item>
                )}
                {error && (
                  <Stack.Item>
                    <NoticeBox danger>{error}</NoticeBox>
                  </Stack.Item>
                )}
                <EtchingDetail
                  detail={detail}
                  hasSelection={!!selected_file}
                  onRefresh={(file) => act('refresh_character', { file })}
                />
              </Stack>
            </Stack.Item>
          </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};

type EtchingDetailProps = Readonly<{
  detail?: CharacterDetail;
  hasSelection: boolean;
  onRefresh: (file?: string) => void;
}>;

const EtchingDetail = ({
  detail,
  hasSelection,
  onRefresh,
}: EtchingDetailProps) => {
  if (!detail) {
    return (
      <Stack.Item grow>
        <Section title="Etching Details" fill>
          <Box color="label">
            {hasSelection
              ? 'Unable to load the selected etching file.'
              : 'Select a character to view their etching data.'}
          </Box>
        </Section>
      </Stack.Item>
    );
  }

  const xpEntries = detail.xp || [];
  const itemStorage = detail.itemStorage || [];
  const unlockables = detail.unlockables || [];
  const nifSavedata = detail.nif?.savedata || [];
  const isEvent = !!detail.event;

  return (
    <Stack.Item grow>
      {detail.character_error && (
        <NoticeBox danger>{detail.character_error}</NoticeBox>
      )}
      <Section
        title="Summary"
        buttons={
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="redo"
            content="Refresh file"
            onClick={() => onRefresh(detail.file)}
          />
        }>
        <LabeledList>
          <LabeledList.Item label="Character">
            {detail.name || 'Unknown'}
            {isEvent && (
              <Box
                as="span"
                color="orange"
                ml={1}
                fontWeight="bold"
                fontSize={0.9}>
                EVENT
              </Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Event Character">
            {isEvent ? 'Yes' : 'No'}
          </LabeledList.Item>
          <LabeledList.Item label="CKey">{detail.ckey || '—'}</LabeledList.Item>
          <LabeledList.Item label="Triangles">
            {detail.triangles ?? 0}
          </LabeledList.Item>
          <LabeledList.Item label="File">{detail.file}</LabeledList.Item>
          <LabeledList.Item label="Path">
            <Box monospace>{detail.meta?.path || detail.path}</Box>
          </LabeledList.Item>
          <LabeledList.Item label="Size">
            {detail.meta?.size ? `${detail.meta.size} bytes` : 'Unknown'}
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title={`Experience (${xpEntries.length})`}>
        {xpEntries.length ? (
          <KeyValueTable
            headerKey="Type"
            headerValue="Amount"
            rows={xpEntries.map((entry) => ({
              key: entry.label,
              value: String(entry.value ?? 0),
            }))}
          />
        ) : (
          <Box color="label">No XP entries recorded.</Box>
        )}
      </Section>
      <Section title={`Item Storage (${itemStorage.length})`}>
        {itemStorage.length ? (
          <ItemTable entries={itemStorage} />
        ) : (
          <Box color="label">No stored items.</Box>
        )}
      </Section>
      <Section title={`Unlockables (${unlockables.length})`}>
        {unlockables.length ? (
          <ItemTable entries={unlockables} />
        ) : (
          <Box color="label">No unlockables catalogued.</Box>
        )}
      </Section>
      <Section title="NIF Status">
        <LabeledList>
          <LabeledList.Item label="Type">
            {detail.nif?.type || 'None'}
          </LabeledList.Item>
          <LabeledList.Item label="Durability">
            {detail.nif?.durability ?? '—'}
          </LabeledList.Item>
        </LabeledList>
        {nifSavedata.length ? (
          <KeyValueTable
            headerKey="Field"
            headerValue="Value"
            rows={nifSavedata}
          />
        ) : (
          <Box color="label">No stored NIF data.</Box>
        )}
      </Section>
      <Section title="Raw JSON">
        {detail.rawJson ? (
          <Box
            monospace
            mb={1}
            style={{
              whiteSpace: 'pre-wrap',
              maxHeight: '18rem',
              overflowY: 'auto',
            }}>
            {detail.rawJson}
          </Box>
        ) : (
          <Box color="label">Raw payload unavailable.</Box>
        )}
      </Section>
    </Stack.Item>
  );
};

type ItemTableProps = Readonly<{
  entries: ItemEntry[];
}>;

const ItemTable = ({ entries }: ItemTableProps) => {
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Name</Table.Cell>
        <Table.Cell>Type</Table.Cell>
      </Table.Row>
      {entries.map((entry) => (
        <Table.Row key={`${entry.label}-${entry.type}`}>
          <Table.Cell>{entry.label}</Table.Cell>
          <Table.Cell>{entry.type}</Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

type KeyValueTableProps = Readonly<{
  rows: KeyValueEntry[];
  headerKey: string;
  headerValue: string;
}>;

const KeyValueTable = ({
  rows,
  headerKey,
  headerValue,
}: KeyValueTableProps) => {
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>{headerKey}</Table.Cell>
        <Table.Cell>{headerValue}</Table.Cell>
      </Table.Row>
      {rows.map((row, index) => (
        <Table.Row key={`${row.key}-${index}`}>
          <Table.Cell>{row.key}</Table.Cell>
          <Table.Cell>{row.value}</Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};
