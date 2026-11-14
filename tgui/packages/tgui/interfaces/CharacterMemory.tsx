// ///////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star May 2026 for persistent memory system //
// ///////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2026: Drink Memories //////////
// ///////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2026: Chemistry Memories //////
// ///////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
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
  Tabs,
  TextArea,
} from '../components';
import { Layout, Window } from '../layouts';
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

type DrinkIngredient = {
  id: string;
  name: string;
  amount: number;
};

type DrinkRecipe = {
  product: string;
  ingredients: DrinkIngredient[];
  catalysts: (DrinkIngredient & { consumed: number; total: number })[];
  inhibitors: DrinkIngredient[];
  yield: number;
  minimum_yield: number;
  input_volume: number;
  mixture_volume: number;
  leftovers: DrinkIngredient[];
  pour_order: DrinkIngredient[];
  notes: string[];
  batches: number;
  batch_yield: number;
  batch_limit: number;
  method: string;
  equipment: string;
  slime_extract?: string;
  temperature?: string;
  ingredient_recipes: Record<string, number[]>;
};

type DrinkRow = {
  id: string;
  name: string;
  times_made: number;
  ingredient_names?: string[];
  search_text?: string;
};

type ChemicalProperties = {
  effects: string;
  application?: string;
  limitations?: string;
  overdose: number;
  overdose_effects: string;
  overdose_touch: boolean;
  interactions: string[];
};

type DrinkDetail = DrinkRow & {
  medical?: ChemicalProperties;
  description: string;
  image: string;
  traits?: {
    taste?: string;
    alcohol: string;
    allergens: string[];
    effects: string[];
  };
  first_made?: string;
  last_made?: string;
  recipes: DrinkRecipe[];
  recipe_steps: DrinkRecipe[];
};

type Data = {
  status?: string;
  error?: string;
  note_limit: number;
  savable?: boolean;
  contacts: ContactRow[];
  selected_contact?: string;
  detail?: ContactDetail;
  chemicals: DrinkRow[];
  selected_chemical?: string;
  chemical_detail?: DrinkDetail;
  chemistry_xp: number;
  chemicals_made: number;
  drinks: DrinkRow[];
  selected_drink?: string;
  drink_detail?: DrinkDetail;
  bartending_xp: number;
  drinks_made: number;
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

  const [tab, setTab] = useLocalState(
    context,
    'characterMemoryTab',
    'characters'
  );

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
      <Window.Content>
        <Stack className="RogueStar" position="relative" vertical fill>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={tab === 'characters'}
                onClick={() => setTab('characters')}
                icon="users">
                Characters
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'drinks'}
                onClick={() => setTab('drinks')}
                icon="cocktail">
                Drinks
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'chemistry'}
                onClick={() => setTab('chemistry')}
                icon="flask">
                Chemistry
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow minHeight={0}>
            {tab === 'chemistry' ? (
              <ReagentMemory key="chemistry" chemistry />
            ) : tab === 'drinks' ? (
              <ReagentMemory key="drinks" />
            ) : (
              <Stack fill>
                <Stack.Item basis="30%" grow>
                  <Section title={contactTitle} fill scrollable>
                    {contacts.length ? (
                      <Stack vertical>
                        <Stack.Item>
                          <Stack wrap>
                            {CATEGORY_FILTERS.map((filter) => (
                              <Stack.Item key={filter.id}>
                                <Button
                                  className={CHIP_BUTTON_CLASS}
                                  selected={categoryFilter === filter.id}
                                  onClick={() =>
                                    selectCategoryFilter(filter.id)
                                  }>
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
                            <Box color="label">
                              No memories in this category.
                            </Box>
                          </Stack.Item>
                        )}
                      </Stack>
                    ) : (
                      <Box color="label">No memories recorded.</Box>
                    )}
                  </Section>
                </Stack.Item>
                <Stack.Item grow basis="70%" position="relative">
                  <Layout.Content scrollable>
                    <Stack vertical>
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
                                  <Table.Cell color="label">
                                    First met
                                  </Table.Cell>
                                  <Table.Cell>
                                    {formatMemoryDate(detail.first_met)}
                                  </Table.Cell>
                                  <Table.Cell color="label">
                                    Last met
                                  </Table.Cell>
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
                  </Layout.Content>
                </Stack.Item>
              </Stack>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const ReagentMemory = ({ chemistry = false }, context) => {
  const { act, data } = useBackend<Data>(context);
  const drinks = (chemistry ? data.chemicals : data.drinks) || [];
  const detail = chemistry ? data.chemical_detail : data.drink_detail;
  const selected = chemistry ? data.selected_chemical : data.selected_drink;
  const noun = chemistry ? 'chemical' : 'drink';
  const title = chemistry ? 'Chemistry' : 'Drinks';
  const [search, setSearch] = useLocalState(
    context,
    chemistry ? 'characterMemoryChemicalSearch' : 'characterMemoryDrinkSearch',
    ''
  );
  const query = search.trim().toLowerCase();
  const visibleDrinks = drinks.filter(
    (drink) =>
      drink.name.toLowerCase().includes(query) ||
      drink.ingredient_names?.some((name) =>
        name.toLowerCase().includes(query)
      ) ||
      (chemistry && drink.search_text?.includes(query))
  );

  return (
    <Stack vertical fill>
      {!drinks.length ? (
        <Stack.Item>
          <NoticeBox>
            No {noun}s remembered yet. Mix your first {noun} to save its recipe
            here.
          </NoticeBox>
        </Stack.Item>
      ) : (
        <Stack.Item grow minHeight={0}>
          <Stack fill>
            <Stack.Item basis="30%" grow>
              <Section
                title={`${title} (${drinks.length})`}
                fill
                scrollable
                buttons={
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    icon="sync-alt"
                    tooltip={`Refresh ${noun} memories`}
                    onClick={() => act('refresh')}
                  />
                }>
                <Input
                  fluid
                  mb={1}
                  placeholder={
                    chemistry
                      ? 'Search chemicals, uses, or ingredients...'
                      : 'Search drinks or ingredients...'
                  }
                  value={search}
                  onInput={(_, value) => setSearch(value)}
                />
                {visibleDrinks.map((drink) => (
                  <Button
                    key={drink.id}
                    className={PILL_BUTTON_CLASS}
                    fluid
                    mb={0.5}
                    selected={drink.id === selected}
                    onClick={() =>
                      act(chemistry ? 'select_chemical' : 'select_drink', {
                        id: drink.id,
                      })
                    }>
                    <Stack justify="space-between" align="center">
                      <Stack.Item grow>
                        <Box textAlign="left">{drink.name}</Box>
                      </Stack.Item>
                      <Stack.Item>{drink.times_made}</Stack.Item>
                    </Stack>
                  </Button>
                ))}
                {!visibleDrinks.length && (
                  <Box color="label">No learned {noun}s match your search.</Box>
                )}
              </Section>
            </Stack.Item>
            <Stack.Item basis="70%" grow>
              {detail ? (
                <Section title={detail.name} fill scrollable>
                  <Stack align="center" mb={2}>
                    <Stack.Item>
                      <Box
                        as="img"
                        src={`data:image/png;base64,${detail.image}`}
                        alt={detail.name}
                        width="96px"
                        height="96px"
                        style={{
                          'image-rendering': 'pixelated',
                          '-ms-interpolation-mode': 'nearest-neighbor',
                        }}
                      />
                    </Stack.Item>
                    <Stack.Item grow>
                      {!detail.medical && (
                        <Box mb={1}>{detail.description}</Box>
                      )}
                      <Box bold>
                        Made {detail.times_made}{' '}
                        {detail.times_made === 1 ? 'time' : 'times'}
                      </Box>
                      <Box color="label" mt={0.5}>
                        First made: {formatMemoryDate(detail.first_made)}
                      </Box>
                      <Box color="label">
                        Last made: {formatMemoryDate(detail.last_made)}
                      </Box>
                    </Stack.Item>
                  </Stack>
                  {detail.medical && (
                    <ChemicalCharacteristics properties={detail.medical} />
                  )}
                  {detail.traits && (
                    <Section title="Drink characteristics">
                      <LabeledList>
                        {detail.traits.taste && (
                          <LabeledList.Item label="Taste">
                            {detail.traits.taste}
                          </LabeledList.Item>
                        )}
                        <LabeledList.Item label="Alcohol">
                          {detail.traits.alcohol}
                        </LabeledList.Item>
                        <LabeledList.Item label="Allergens">
                          {detail.traits.allergens.join(', ') || 'None listed'}
                        </LabeledList.Item>
                        {!!detail.traits.effects.length && (
                          <LabeledList.Item label="Notable effects">
                            {detail.traits.effects.join(', ')}
                          </LabeledList.Item>
                        )}
                      </LabeledList>
                    </Section>
                  )}
                  {detail.recipes.map((recipe, index) => (
                    <Section
                      key={`${detail.id}-${index}`}
                      title={formatDrinkRecipeTitle(
                        recipe,
                        detail.recipes.length > 1 ? index + 1 : undefined
                      )}>
                      <IngredientTable
                        ingredients={recipe.ingredients}
                        catalysts={recipe.catalysts}
                        pourOrder={recipe.pour_order}
                        ingredientRecipes={recipe.ingredient_recipes}
                        recipeSteps={detail.recipe_steps}
                      />
                      <DrinkRecipeDetails recipe={recipe} />
                      <DrinkRecipePreparation recipe={recipe} />
                    </Section>
                  ))}
                  {!detail.recipes.length && (
                    <Box color="label">
                      This recipe is no longer available. Your discovery and
                      made count are preserved.
                    </Box>
                  )}
                </Section>
              ) : (
                <NoticeBox>Select a {noun} to see its recipe.</NoticeBox>
              )}
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}
    </Stack>
  );
};

const ChemicalCharacteristics = ({
  properties,
}: {
  readonly properties: ChemicalProperties;
}) => (
  <Section title="Use and effects">
    <LabeledList>
      <LabeledList.Item label="Purpose">{properties.effects}</LabeledList.Item>
      {!!properties.application && (
        <LabeledList.Item label="How to use">
          {properties.application}
        </LabeledList.Item>
      )}
      {!!properties.limitations && (
        <LabeledList.Item label="Limits and hazards">
          <Box color="average">{properties.limitations}</Box>
        </LabeledList.Item>
      )}
      <LabeledList.Item label="Overdose">
        {properties.overdose > 0 ? (
          <>
            <Box bold color="bad">
              Above {formatDrinkAmount(properties.overdose)} units
            </Box>
            <Box>{properties.overdose_effects}</Box>
            <Box color="label">
              Typical threshold; varies by species.{' '}
              {properties.overdose_touch
                ? 'Also applies to skin contact.'
                : 'Does not apply to skin contact.'}
            </Box>
          </>
        ) : (
          'No known overdose threshold'
        )}
      </LabeledList.Item>
      {!!properties.interactions.length && (
        <LabeledList.Item label="Interactions">
          {properties.interactions.map((interaction) => (
            <Box key={interaction} mb={0.5}>
              {interaction}
            </Box>
          ))}
        </LabeledList.Item>
      )}
    </LabeledList>
  </Section>
);

const formatDrinkAmount = (amount: number) =>
  amount > 0 && amount < 0.001 ? '<0.001' : Math.round(amount * 1000) / 1000;

const formatDrinkRecipeTitle = (recipe: DrinkRecipe, recipeNumber?: number) =>
  `${recipe.method} recipe${recipeNumber ? ` ${recipeNumber}` : ''}${
    recipe.slime_extract ? ` (${recipe.slime_extract})` : ''
  }`;

const DrinkRecipeDetails = ({ recipe }: { readonly recipe: DrinkRecipe }) => (
  <Box mt={1}>
    <LabeledList>
      <LabeledList.Item label="Produces">
        {formatDrinkAmount(recipe.yield)}{' '}
        {recipe.yield === 1 ? 'unit' : 'units'} of {recipe.product}
        {recipe.leftovers.length
          ? `; ${formatDrinkAmount(recipe.mixture_volume)} units in the container including leftovers`
          : ''}
      </LabeledList.Item>
      {recipe.temperature && (
        <LabeledList.Item label="Temperature">
          {recipe.temperature}
        </LabeledList.Item>
      )}
    </LabeledList>
  </Box>
);

const DrinkRecipePreparation = ({
  recipe,
}: {
  readonly recipe: DrinkRecipe;
}) => (
  <>
    {!!recipe.batch_limit && (
      <NoticeBox mt={1}>
        Mix {formatDrinkAmount(recipe.batch_yield)} units at a time.
        {recipe.batches > 1 && ` Repeat for ${recipe.batches} batches.`} Finish
        each batch before starting the next.
      </NoticeBox>
    )}
    {!!recipe.pour_order.length && (
      <Box mt={1}>
        <Box bold>Pouring order{recipe.batch_limit ? ' (per batch)' : ''}</Box>
        <Box as="ol" mt={0.5} mb={0.5} pl={2}>
          {recipe.pour_order.map((ingredient) => (
            <Box as="li" key={ingredient.id}>
              {formatDrinkAmount(ingredient.amount)} units {ingredient.name}
            </Box>
          ))}
        </Box>
      </Box>
    )}
    {recipe.notes.map((note) => (
      <Box mt={1} key={note}>
        {note}
      </Box>
    ))}
    {!!recipe.inhibitors.length && (
      <Box mt={1}>
        Prevented by:{' '}
        {recipe.inhibitors
          .map(
            (item) =>
              `${formatDrinkAmount(item.amount)} or more units ${item.name}`
          )
          .join(', ')}
      </Box>
    )}
  </>
);

const IngredientTable = ({
  ingredients,
  catalysts = [],
  pourOrder = [],
  ingredientRecipes,
  recipeSteps,
}: {
  readonly ingredients: DrinkIngredient[];
  readonly catalysts?: DrinkRecipe['catalysts'];
  readonly pourOrder?: DrinkIngredient[];
  readonly ingredientRecipes: DrinkRecipe['ingredient_recipes'];
  readonly recipeSteps: DrinkRecipe[];
}) => {
  const rows: (DrinkIngredient & { consumed?: number })[] = ingredients.map(
    (ingredient) => ({ ...ingredient })
  );
  for (const catalyst of catalysts) {
    const ingredient = rows.find((row) => row.id === catalyst.id);
    if (ingredient) {
      ingredient.consumed = ingredient.amount;
      ingredient.amount += catalyst.total - catalyst.consumed;
    } else {
      rows.push({ ...catalyst, amount: catalyst.total });
    }
  }
  if (pourOrder.length) {
    const order = [...pourOrder, ...rows].map((ingredient) => ingredient.id);
    rows.sort(
      (left, right) => order.indexOf(left.id) - order.indexOf(right.id)
    );
  }

  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Ingredient</Table.Cell>
        <Table.Cell textAlign="right">Units</Table.Cell>
      </Table.Row>
      {rows.map((ingredient) => (
        <DrinkIngredientRow
          key={ingredient.id}
          ingredient={ingredient}
          recipes={(ingredientRecipes[ingredient.id] || []).map(
            (stepId) => recipeSteps[stepId - 1]
          )}
          recipeSteps={recipeSteps}
        />
      ))}
    </Table>
  );
};

class DrinkIngredientRow extends Component<
  {
    readonly ingredient: DrinkIngredient & { consumed?: number };
    readonly recipes: DrinkRecipe[];
    readonly recipeSteps: DrinkRecipe[];
  },
  { expanded: boolean }
> {
  state = { expanded: false };

  render() {
    const { ingredient, recipes, recipeSteps } = this.props;
    const expanded = this.state.expanded && recipes.length > 0;
    return (
      <>
        <Table.Row className={STRIPED_TABLE_ROW_CLASS}>
          <Table.Cell>
            {recipes.length ? (
              <button
                type="button"
                className="RogueStar__memoryIngredientLink"
                aria-expanded={expanded}
                onClick={() => this.setState({ expanded: !expanded })}>
                {ingredient.name}
              </button>
            ) : (
              ingredient.name
            )}
            {ingredient.consumed !== undefined && (
              <Box inline color="label" ml={1}>
                (Catalyst; {formatDrinkAmount(ingredient.consumed)}{' '}
                {ingredient.consumed === 1 ? 'unit' : 'units'} consumed)
              </Box>
            )}
          </Table.Cell>
          <Table.Cell textAlign="right">
            {formatDrinkAmount(ingredient.amount)}
          </Table.Cell>
        </Table.Row>
        {expanded && (
          <Table.Row>
            <Table.Cell colSpan={2}>
              <Box ml={2} my={1}>
                {recipes.map((recipe, index) => (
                  <Section
                    key={index}
                    title={formatDrinkRecipeTitle(
                      recipe,
                      recipes.length > 1 ? index + 1 : undefined
                    )}>
                    <IngredientTable
                      ingredients={recipe.ingredients}
                      catalysts={recipe.catalysts}
                      pourOrder={recipe.pour_order}
                      ingredientRecipes={recipe.ingredient_recipes}
                      recipeSteps={recipeSteps}
                    />
                    <DrinkRecipeDetails recipe={recipe} />
                    {(ingredient.amount < recipe.yield ||
                      recipe.leftovers.length > 0) && (
                      <Box mt={1} color="label">
                        Use {formatDrinkAmount(ingredient.amount)} units of{' '}
                        {ingredient.name}
                        {recipe.leftovers.length
                          ? ' after separating the leftovers.'
                          : ' from this batch.'}
                      </Box>
                    )}
                    <DrinkRecipePreparation recipe={recipe} />
                  </Section>
                ))}
              </Box>
            </Table.Cell>
          </Table.Row>
        )}
      </>
    );
  }
}

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
