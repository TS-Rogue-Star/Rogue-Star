// ///////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star May 2026 for persistent memory system //
// ///////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  NoticeBox,
  Section,
  Stack,
  Table,
  TextArea,
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

type CategoryFilter = 'all' | 'social' | 'physical' | 'vore' | 'other';
type VisibleCategoryFilter = Exclude<CategoryFilter, 'other'>;

const CATEGORY_FILTERS: Readonly<
  {
    id: VisibleCategoryFilter;
    label: string;
  }[]
> = [
  {
    id: 'all',
    label: 'All',
  },
  {
    id: 'social',
    label: 'Social',
  },
  {
    id: 'physical',
    label: 'Physical',
  },
  {
    id: 'vore',
    label: 'Vore',
  },
];

const EVENT_CATEGORIES: Record<string, CategoryFilter> = {
  absorbed_me: 'social',
  absorbed_say: 'social',
  attack: 'physical',
  me: 'social',
  music: 'social',
  picked_up: 'physical',
  pme: 'social',
  psay: 'social',
  say: 'social',
  subtle: 'social',
  whisper: 'social',
};

type RoleRow = {
  role: string;
  count: number;
};

type EventRow = {
  event: string;
  detail?: string;
  roles: RoleRow[];
};

type DayRow = {
  date: string;
  events: EventRow[];
};

type ContactRow = {
  id: string;
  name: string;
  last_seen?: string;
  day_count: number;
  categories?: string[];
};

type ContactDetail = {
  id: string;
  name: string;
  first_met?: string;
  last_seen?: string;
  notes?: string;
  categories?: string[];
  totals: EventRow[];
  days: DayRow[];
};

type Data = {
  status?: string;
  error?: string;
  note_limit: number;
  savable?: boolean;
  contacts: ContactRow[];
  selected_contact?: string;
  detail?: ContactDetail;
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

const formatMemoryDate = (date?: string) => {
  return date?.slice(0, 10) || 'Unknown';
};

const isKnownCategory = (
  category: string
): category is VisibleCategoryFilter => {
  return CATEGORY_FILTERS.some((filter) => filter.id === category);
};

const getEventCategory = (event: string): CategoryFilter => {
  if (event.startsWith('vore_')) {
    return 'vore';
  }
  return EVENT_CATEGORIES[event] || 'other';
};

const eventMatchesCategory = (event: string, category: CategoryFilter) => {
  return category === 'all' || getEventCategory(event) === category;
};

const contactMatchesCategory = (
  contact: ContactRow,
  category: CategoryFilter
) => {
  return category === 'all' || contact.categories?.includes(category);
};

const filterEventRows = (rows: EventRow[], category: CategoryFilter) => {
  if (category === 'all') {
    return rows;
  }
  return rows.filter((row) => eventMatchesCategory(row.event, category));
};

const filterDayRows = (days: DayRow[], category: CategoryFilter) => {
  if (category === 'all') {
    return days;
  }
  return days
    .map((day) => ({
      ...day,
      events: filterEventRows(day.events, category),
    }))
    .filter((day) => day.events.length > 0);
};

export const CharacterMemory = (_props, context) => {
  const { act, data } = useBackend<Data>(context);
  const {
    contacts = [],
    detail,
    error,
    note_limit = 4000,
    selected_contact,
    status,
  } = data;

  const [drafts, setDrafts] = useLocalState<Record<string, string>>(
    context,
    'characterMemoryDrafts',
    {}
  );

  const [savedCategoryFilter, setCategoryFilter] =
    useLocalState<CategoryFilter>(
      context,
      'characterMemoryCategoryFilter',
      'all'
    );
  const categoryFilter = isKnownCategory(savedCategoryFilter)
    ? savedCategoryFilter
    : 'all';
  const selectedContact = contacts.find(
    (contact) => contact.id === selected_contact
  );
  const visibleContacts = contacts.filter((contact) =>
    contactMatchesCategory(contact, categoryFilter)
  );
  const contactTitle =
    categoryFilter === 'all'
      ? `Characters (${contacts.length})`
      : `Characters (${visibleContacts.length}/${contacts.length})`;
  const filteredTotals = detail
    ? filterEventRows(detail.totals, categoryFilter)
    : [];
  const filteredDays = detail ? filterDayRows(detail.days, categoryFilter) : [];
  const selectCategoryFilter = (filter: VisibleCategoryFilter) => {
    setCategoryFilter(filter);
    if (selectedContact && contactMatchesCategory(selectedContact, filter)) {
      return;
    }
    const nextContact = contacts.find((contact) =>
      contactMatchesCategory(contact, filter)
    );
    if (nextContact) {
      act('select_contact', { id: nextContact.id });
    }
  };

  const activeId = detail?.id || '';
  const backendNote = detail?.notes || '';
  const draft = Object.prototype.hasOwnProperty.call(drafts, activeId)
    ? drafts[activeId]
    : backendNote;
  const clippedDraft = draft.slice(0, note_limit);
  const noteChanged = clippedDraft !== backendNote;

  const setDraft = (value: string) => {
    if (!activeId) {
      return;
    }
    setDrafts({
      ...drafts,
      [activeId]: value.slice(0, note_limit),
    });
  };

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
      width={1040}
      height={680}
      resizable
      statusIcon={statusIcon}
      title="Memory">
      <Window.Content scrollable>
        <Box className="RogueStar" position="relative" minHeight="100%">
          <Stack fill>
            <Stack.Item basis="30%" grow>
              <Section title={contactTitle} fill>
                {contacts.length ? (
                  <Stack vertical fill>
                    <Stack.Item>
                      <Stack wrap>
                        {CATEGORY_FILTERS.map((filter) => (
                          <Stack.Item key={filter.id}>
                            <Button
                              className={CHIP_BUTTON_CLASS}
                              selected={categoryFilter === filter.id}
                              onClick={() => selectCategoryFilter(filter.id)}>
                              {filter.label}
                            </Button>
                          </Stack.Item>
                        ))}
                      </Stack>
                    </Stack.Item>
                    {visibleContacts.length ? (
                      visibleContacts.map((contact) => (
                        <Stack.Item key={contact.id} mb={0.25}>
                          <Button
                            className={PILL_BUTTON_CLASS}
                            fluid
                            selected={contact.id === selected_contact}
                            onClick={() =>
                              act('select_contact', { id: contact.id })
                            }>
                            <Stack align="center" justify="space-between">
                              <Stack.Item grow>
                                <Box textAlign="left">{contact.name}</Box>
                              </Stack.Item>
                              <Stack.Item>
                                <Box
                                  as="span"
                                  className={CHIP_BUTTON_CLASS}
                                  px="0.5rem"
                                  py="0.2rem">
                                  {contact.day_count}
                                </Box>
                              </Stack.Item>
                            </Stack>
                          </Button>
                        </Stack.Item>
                      ))
                    ) : (
                      <Stack.Item>
                        <Box color="label">No memories in this category.</Box>
                      </Stack.Item>
                    )}
                  </Stack>
                ) : (
                  <Box color="label">No memories recorded.</Box>
                )}
              </Section>
            </Stack.Item>
            <Stack.Item grow basis="70%">
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
                {detail ? (
                  <>
                    <Stack.Item>
                      <Section
                        title={detail.name}
                        buttons={
                          <Button
                            className={CHIP_BUTTON_CLASS}
                            icon="sync-alt"
                            onClick={() => act('refresh')}
                          />
                        }>
                        <Table>
                          <Table.Row>
                            <Table.Cell color="label">First met</Table.Cell>
                            <Table.Cell>
                              {formatMemoryDate(detail.first_met)}
                            </Table.Cell>
                            <Table.Cell color="label">Last met</Table.Cell>
                            <Table.Cell>
                              {formatMemoryDate(detail.last_seen)}
                            </Table.Cell>
                          </Table.Row>
                        </Table>
                      </Section>
                    </Stack.Item>
                    <Stack.Item>
                      <Section
                        title="Memory Note"
                        buttons={
                          <Stack>
                            <Stack.Item>
                              <Box
                                color={
                                  clippedDraft.length >= note_limit
                                    ? 'bad'
                                    : 'label'
                                }>
                                {clippedDraft.length}/{note_limit}
                              </Box>
                            </Stack.Item>
                            <Stack.Item>
                              <Button
                                className={`${CHIP_BUTTON_CLASS} RogueStar__glowButton--positive`}
                                icon="save"
                                disabled={!noteChanged}
                                onClick={() =>
                                  act('save_note', {
                                    id: activeId,
                                    note: clippedDraft,
                                  })
                                }
                              />
                            </Stack.Item>
                          </Stack>
                        }>
                        <TextArea
                          height="8rem"
                          maxLength={note_limit}
                          onInput={(_, value) => setDraft(value)}
                          value={clippedDraft}
                        />
                      </Section>
                    </Stack.Item>
                    <Stack.Item>
                      <Section title="Totals">
                        <EventTable rows={filteredTotals} />
                      </Section>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Section title="Daily Memory" fill>
                        <DailyTable days={filteredDays} />
                      </Section>
                    </Stack.Item>
                  </>
                ) : (
                  <Stack.Item>
                    <Section title="Memory">
                      <Box color="label">No contact selected.</Box>
                    </Section>
                  </Stack.Item>
                )}
              </Stack>
            </Stack.Item>
          </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};

type DailyTableProps = Readonly<{
  days: DayRow[];
}>;

const DailyTable = ({ days }: DailyTableProps) => {
  const rows: {
    date: string;
    event: string;
    detail?: string;
    role: string;
    count: number;
    showDate: boolean;
    showEvent: boolean;
  }[] = [];

  days.forEach((day) => {
    day.events.forEach((eventRow) => {
      eventRow.roles.forEach((roleRow, roleIndex) => {
        rows.push({
          count: roleRow.count,
          date: day.date,
          detail: eventRow.detail,
          event: eventRow.event,
          role: roleRow.role,
          showDate: roleIndex === 0,
          showEvent: roleIndex === 0,
        });
      });
    });
  });

  if (!rows.length) {
    return <Box color="label">No daily entries.</Box>;
  }

  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Date</Table.Cell>
        <Table.Cell>Type</Table.Cell>
        <Table.Cell>Role</Table.Cell>
        <Table.Cell collapsing textAlign="right">
          Count
        </Table.Cell>
      </Table.Row>
      {rows.map((row, index) => (
        <Table.Row
          key={`${row.date}-${row.event}-${row.role}-${index}`}
          className={STRIPED_TABLE_ROW_CLASS}>
          <Table.Cell>{row.showDate ? row.date : ''}</Table.Cell>
          <Table.Cell>
            {row.showEvent ? formatEventLabel(row.event, row.detail) : ''}
          </Table.Cell>
          <Table.Cell>{ROLE_LABELS[row.role] || row.role}</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            {row.count}
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

type EventTableProps = Readonly<{
  rows: EventRow[];
}>;

const EventTable = ({ rows }: EventTableProps) => {
  const tableRows: {
    event: string;
    detail?: string;
    role: string;
    count: number;
    showEvent: boolean;
  }[] = [];

  rows.forEach((row) => {
    row.roles.forEach((roleRow, index) => {
      tableRows.push({
        count: roleRow.count,
        detail: row.detail,
        event: row.event,
        role: roleRow.role,
        showEvent: index === 0,
      });
    });
  });

  if (!tableRows.length) {
    return <Box color="label">No entries.</Box>;
  }

  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Type</Table.Cell>
        <Table.Cell>Role</Table.Cell>
        <Table.Cell collapsing textAlign="right">
          Count
        </Table.Cell>
      </Table.Row>
      {tableRows.map((row) => (
        <Table.Row
          key={`${row.event}-${row.detail || ''}-${row.role}`}
          className={STRIPED_TABLE_ROW_CLASS}>
          <Table.Cell>
            {row.showEvent ? formatEventLabel(row.event, row.detail) : ''}
          </Table.Cell>
          <Table.Cell>{ROLE_LABELS[row.role] || row.role}</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            {row.count}
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};
