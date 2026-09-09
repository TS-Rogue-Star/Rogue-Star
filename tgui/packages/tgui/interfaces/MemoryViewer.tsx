// /////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star May 2026: Admin tool for viewing character memories //
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
const STRIPED_TABLE_ROW_CLASS = 'RogueStar__memoryStripe';

const EVENT_LABELS: Record<string, string> = {
  absorbed_me: 'Absorbed Me',
  absorbed_say: 'Absorbed Say',
  attack: 'Attacks',
  me: 'Emotes',
  music: 'Music',
  picked_up: 'Pickups',
  pme: 'Absorbed Me',
  psay: 'Absorbed Say',
  say: 'Says',
  subtle: 'Subtles',
  vore_absorb: 'Vore absorptions',
  vore_digest: 'Vore digestions',
  vore_place: 'Vore placements',
  vore_release: 'Vore releases',
  vore_round_end_inside: 'Round-end inside',
  vore_transfer: 'Vore transfers',
  vore_unabsorb: 'Vore unabsorptions',
  whisper: 'Whispers',
};

const ROLE_LABELS: Record<string, string> = {
  as_attacker: 'As attacker',
  as_held: 'As held',
  as_holder: 'As holder',
  as_pred: 'As pred',
  as_prey: 'As prey',
  as_source_pred: 'As source pred',
  as_target: 'As target',
  as_target_pred: 'As target pred',
  by_them: 'By them',
  by_you: 'By you',
};

type KeyValueEntry = {
  key: string;
  value: string;
};

type MemoryFileEntry = {
  file: string;
  name: string;
  event?: boolean;
  path: string;
};

type CountRow = {
  date?: string;
  raw_event?: string;
  event: string;
  detail?: string;
  role: string;
  count: number;
};

type ContactRow = {
  contact_id: string;
  display_name: string;
  parsed_ckey?: string;
  parsed_name?: string;
  first_met?: string;
  last_seen?: string;
  day_count?: number;
  total_count?: number;
  notes_length?: number;
  duplicate_count?: number;
};

type ContactDetail = ContactRow & {
  notes?: string;
  totals?: CountRow[];
  daily?: CountRow[];
};

type DuplicateGroup = {
  key: string;
  ckey: string;
  name: string;
  count: number;
  contact_ids: string[];
};

type MemoryDetail = {
  name: string;
  file: string;
  path: string;
  event?: boolean;
  ckey?: string;
  owner?: string;
  schema_version?: string;
  metaRows?: KeyValueEntry[];
  contacts?: ContactRow[];
  duplicateGroups?: DuplicateGroup[];
  selected_contact?: string;
  contact_detail?: ContactDetail;
  character_error?: string;
};

type Data = {
  target_ckey?: string;
  status?: string;
  error?: string;
  characters?: MemoryFileEntry[];
  selected_file?: string;
  detail?: MemoryDetail;
  online_ckeys?: string[];
};

const formatEventDetail = (event: string, detail: string) => {
  if (event === 'vore_transfer') {
    return detail.replace(/\s+(?:->|\u2192|\u279c|-)\s+/, ' \u279c ');
  }
  return detail;
};

const formatEventLabel = (event: string, detail?: string) => {
  const label = EVENT_LABELS[event] || event;
  return detail ? `${label} (${formatEventDetail(event, detail)})` : label;
};

const formatRoleLabel = (role: string) => ROLE_LABELS[role] || role;

const formatDate = (date?: string) => date?.slice(0, 10) || 'Unknown';

export const MemoryViewer = (_props, context) => {
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
    'memoryViewerCkey',
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
      width={1260}
      height={760}
      resizable
      statusIcon={statusIcon}
      title={`Memory Viewer${target_ckey ? ` - ${target_ckey}` : ''}`}>
      <Window.Content scrollable>
        <Box className="RogueStar" position="relative" minHeight="100%">
          <Stack fill>
            <Stack.Item basis="28%" grow>
              <Stack vertical fill>
                <Stack.Item>
                  <Section
                    title="Target CKey"
                    buttons={
                      <Button
                        className={CHIP_BUTTON_CLASS}
                        icon="search"
                        content="Load"
                        disabled={!trimmedInput}
                        onClick={() =>
                          trimmedInput &&
                          act('load_ckey', { ckey: trimmedInput })
                        }
                      />
                    }>
                    <Input
                      value={ckeyInput}
                      placeholder="ckey"
                      fluid
                      onInput={(_, value) => setCkeyInput(value)}
                      onEnter={() =>
                        trimmedInput && act('load_ckey', { ckey: trimmedInput })
                      }
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
                <Stack.Item grow>
                  <Section title={`Memory Files (${characters.length})`} fill>
                    {characters.length ? (
                      <Stack vertical fill>
                        {characters.map((character) => (
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
                                  <Box color="label" fontSize={0.85} monospace>
                                    {character.file}
                                  </Box>
                                </Stack.Item>
                                {!!character.event && (
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
                        ))}
                      </Stack>
                    ) : (
                      <Box color="label">
                        Load a ckey to view available memory files.
                      </Box>
                    )}
                  </Section>
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item grow basis="72%">
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
                <MemoryFileDetail
                  detail={detail}
                  hasSelection={!!selected_file}
                  onConsolidate={(file) =>
                    act('consolidate_character', { file })
                  }
                  onRefresh={(file) => act('refresh_character', { file })}
                  onSelectContact={(contactId) =>
                    act('select_contact', { contact_id: contactId })
                  }
                />
              </Stack>
            </Stack.Item>
          </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};

type MemoryFileDetailProps = Readonly<{
  detail?: MemoryDetail;
  hasSelection: boolean;
  onConsolidate: (file?: string) => void;
  onRefresh: (file?: string) => void;
  onSelectContact: (contactId: string) => void;
}>;

const MemoryFileDetail = ({
  detail,
  hasSelection,
  onConsolidate,
  onRefresh,
  onSelectContact,
}: MemoryFileDetailProps) => {
  if (!detail) {
    return (
      <Stack.Item grow>
        <Section title="Memory Details" fill>
          <Box color="label">
            {hasSelection
              ? 'Unable to load the selected memory file.'
              : 'Select a memory file to inspect it.'}
          </Box>
        </Section>
      </Stack.Item>
    );
  }

  const contacts = detail.contacts || [];
  const duplicateGroups = detail.duplicateGroups || [];
  const selectedContact = detail.contact_detail;

  return (
    <Stack.Item grow>
      {detail.character_error && (
        <NoticeBox danger>{detail.character_error}</NoticeBox>
      )}
      <Section
        title="File Summary"
        buttons={
          <Stack>
            <Stack.Item>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="compress-arrows-alt"
                content="Consolidate @ entries"
                onClick={() => onConsolidate(detail.file)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                className={CHIP_BUTTON_CLASS}
                icon="redo"
                content="Refresh file"
                onClick={() => onRefresh(detail.file)}
              />
            </Stack.Item>
          </Stack>
        }>
        <LabeledList>
          <LabeledList.Item label="Character">
            {detail.name || 'Unknown'}
            {!!detail.event && (
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
          <LabeledList.Item label="Target CKey">
            {detail.ckey || 'Unknown'}
          </LabeledList.Item>
          <LabeledList.Item label="Metadata Owner">
            {detail.owner || 'Unknown'}
          </LabeledList.Item>
          <LabeledList.Item label="Schema Version">
            {detail.schema_version || 'Unknown'}
          </LabeledList.Item>
          <LabeledList.Item label="Contacts">
            {contacts.length}
          </LabeledList.Item>
          <LabeledList.Item label="Duplicate Candidates">
            {duplicateGroups.length}
          </LabeledList.Item>
          <LabeledList.Item label="File">{detail.file}</LabeledList.Item>
          <LabeledList.Item label="Path">
            <Box monospace>{detail.path}</Box>
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <DuplicateGroups groups={duplicateGroups} />
      <Stack fill>
        <Stack.Item basis="40%" grow>
          <Section title={`Contacts (${contacts.length})`} fill>
            <ContactList
              contacts={contacts}
              selectedContact={detail.selected_contact}
              onSelectContact={onSelectContact}
            />
          </Section>
        </Stack.Item>
        <Stack.Item basis="60%" grow>
          <ContactDiagnostics contact={selectedContact} />
        </Stack.Item>
      </Stack>
      <Section title="Metadata">
        <KeyValueTable
          rows={detail.metaRows || []}
          emptyText="No metadata rows found."
        />
      </Section>
    </Stack.Item>
  );
};

type DuplicateGroupsProps = Readonly<{
  groups: DuplicateGroup[];
}>;

const DuplicateGroups = ({ groups }: DuplicateGroupsProps) => {
  if (!groups.length) {
    return (
      <Section title="Duplicate Candidates">
        <Box color="label">
          No contacts share the same normalized ckey and character name.
        </Box>
      </Section>
    );
  }

  return (
    <Section title={`Duplicate Candidates (${groups.length})`}>
      <Table>
        <Table.Row header>
          <Table.Cell>CKey</Table.Cell>
          <Table.Cell>Character</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Entries
          </Table.Cell>
          <Table.Cell>Raw Contact IDs</Table.Cell>
        </Table.Row>
        {groups.map((group) => (
          <Table.Row key={group.key} className={STRIPED_TABLE_ROW_CLASS}>
            <Table.Cell>
              <Box monospace>{group.ckey}</Box>
            </Table.Cell>
            <Table.Cell>{group.name}</Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {group.count}
            </Table.Cell>
            <Table.Cell>
              <Box monospace style={{ whiteSpace: 'pre-wrap' }}>
                {group.contact_ids.join('\n')}
              </Box>
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

type ContactListProps = Readonly<{
  contacts: ContactRow[];
  selectedContact?: string;
  onSelectContact: (contactId: string) => void;
}>;

const ContactList = ({
  contacts,
  selectedContact,
  onSelectContact,
}: ContactListProps) => {
  if (!contacts.length) {
    return <Box color="label">No contacts recorded in this file.</Box>;
  }

  return (
    <Stack vertical fill>
      {contacts.map((contact) => {
        const duplicateCount = contact.duplicate_count || 0;
        return (
          <Stack.Item key={contact.contact_id} mb={0.25}>
            <Button
              className={PILL_BUTTON_CLASS}
              fluid
              selected={contact.contact_id === selectedContact}
              onClick={() => onSelectContact(contact.contact_id)}>
              <Stack align="center" justify="space-between">
                <Stack.Item grow>
                  <Box textAlign="left">{contact.display_name}</Box>
                  <Box color="label" fontSize={0.85} monospace>
                    {contact.parsed_ckey || 'unknown'} |{' '}
                    {contact.parsed_name || 'unknown'}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Stack>
                    {duplicateCount > 1 && (
                      <Stack.Item>
                        <Box
                          as="span"
                          className={CHIP_BUTTON_CLASS}
                          color="orange"
                          px="0.5rem"
                          py="0.2rem">
                          DUP {duplicateCount}
                        </Box>
                      </Stack.Item>
                    )}
                    <Stack.Item>
                      <Box
                        as="span"
                        className={CHIP_BUTTON_CLASS}
                        px="0.5rem"
                        py="0.2rem">
                        {contact.total_count || 0}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Button>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};

type ContactDiagnosticsProps = Readonly<{
  contact?: ContactDetail;
}>;

const ContactDiagnostics = ({ contact }: ContactDiagnosticsProps) => {
  if (!contact) {
    return (
      <Section title="Contact Details" fill>
        <Box color="label">Select a contact to view raw identity details.</Box>
      </Section>
    );
  }

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title={contact.display_name || 'Contact'}>
          <LabeledList>
            <LabeledList.Item label="Raw Contact ID">
              <Box monospace>{contact.contact_id}</Box>
            </LabeledList.Item>
            <LabeledList.Item label="Parsed CKey">
              <Box monospace>{contact.parsed_ckey || 'Unknown'}</Box>
            </LabeledList.Item>
            <LabeledList.Item label="Parsed Character">
              {contact.parsed_name || 'Unknown'}
            </LabeledList.Item>
            <LabeledList.Item label="Stored Display Name">
              {contact.display_name || 'Unknown'}
            </LabeledList.Item>
            <LabeledList.Item label="First Met">
              {formatDate(contact.first_met)}
            </LabeledList.Item>
            <LabeledList.Item label="Last Met">
              {formatDate(contact.last_seen)}
            </LabeledList.Item>
            <LabeledList.Item label="Duplicate Group Size">
              {contact.duplicate_count || 1}
            </LabeledList.Item>
            <LabeledList.Item label="Total Count">
              {contact.total_count || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Day Count">
              {contact.day_count || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Note Length">
              {contact.notes_length || 0}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Note">
          {contact.notes ? (
            <Box
              style={{
                maxHeight: '8rem',
                overflowY: 'auto',
                whiteSpace: 'pre-wrap',
              }}>
              {contact.notes}
            </Box>
          ) : (
            <Box color="label">No note saved.</Box>
          )}
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Totals">
          <CountTable rows={contact.totals || []} showDate={false} />
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section title="Daily Memory" fill>
          <CountTable rows={contact.daily || []} showDate />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

type CountTableProps = Readonly<{
  rows: CountRow[];
  showDate: boolean;
}>;

const CountTable = ({ rows, showDate }: CountTableProps) => {
  if (!rows.length) {
    return <Box color="label">No entries.</Box>;
  }

  return (
    <Table>
      <Table.Row header>
        {showDate && <Table.Cell>Date</Table.Cell>}
        <Table.Cell>Type</Table.Cell>
        <Table.Cell>Raw Event</Table.Cell>
        <Table.Cell>Role</Table.Cell>
        <Table.Cell collapsing textAlign="right">
          Count
        </Table.Cell>
      </Table.Row>
      {rows.map((row, index) => (
        <Table.Row
          key={`${row.date || 'total'}-${row.raw_event || row.event}-${
            row.role
          }-${index}`}
          className={STRIPED_TABLE_ROW_CLASS}>
          {showDate && <Table.Cell>{row.date}</Table.Cell>}
          <Table.Cell>{formatEventLabel(row.event, row.detail)}</Table.Cell>
          <Table.Cell>
            <Box monospace>{row.raw_event || row.event}</Box>
          </Table.Cell>
          <Table.Cell>{formatRoleLabel(row.role)}</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            {row.count}
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

type KeyValueTableProps = Readonly<{
  rows: KeyValueEntry[];
  emptyText: string;
}>;

const KeyValueTable = ({ rows, emptyText }: KeyValueTableProps) => {
  if (!rows.length) {
    return <Box color="label">{emptyText}</Box>;
  }

  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Key</Table.Cell>
        <Table.Cell>Value</Table.Cell>
      </Table.Row>
      {rows.map((row) => (
        <Table.Row key={row.key} className={STRIPED_TABLE_ROW_CLASS}>
          <Table.Cell>{row.key}</Table.Cell>
          <Table.Cell>{row.value}</Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};
