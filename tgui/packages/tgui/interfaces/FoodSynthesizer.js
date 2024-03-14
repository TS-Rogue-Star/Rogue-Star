import { Fragment } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Input, LabeledList, Section, Tabs, Icon } from '../components';
import { ComplexModal, modalOpen, modalRegisterBodyOverride } from '../interfaces/common/ComplexModal';
import { Window } from '../layouts';


export const SynthesizerMenu = (props, context) => {
  const { act, data } = useBackend(context);
  modalRegisterBodyOverride('view_crate', FoodListing);
  return (
    <Window width={700} height={620}>
      <Window.Content>
        <ComplexModal maxWidth="100%" />
        <Section title="SabreSnacks Menu">
          <SynthCartGuage />
          <FoodMenuTabs />
          <SynthesizerMenuOrder />
        </Section>
      </Window.Content>
    </Window>
  );

  let body;
  if (screen === 2) {
      body = <AppetizerMenu />;
    } else if (screen === 3) {
      body = <BreakfastMenu />;
    } else if (screen === 4) {
      body = <LunchMenu />;
    } else if (screen === 5) {
      body = <DinnerMenu />;
    } else if (screen === 6) {
      body = <DessertMenu />;
    } else if (screen === 7) {
      body = <ExoticMenu />;
    } else if (screen === 8) {
      body = <CrewMenu />;
    } else if (screen === 9) {
      body = <SecurityRecordsView />;
    }

  return (
    <Window width={700} height={680} resizable>
      <ComplexModal maxHeight="100%" maxWidth="400px" />
      <Window.Content scrollable>
        <viewMenuListing />
        <Section flexGrow>{body}</Section>
      </Window.Content>
    </Window>
  );
};

const FoodMenuTabs = (props, context) => {
  const { act, data } = useBackend(context);

  const { screen } = data;

  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 0);

  return (
    <Section title="Menu Options">
      <Tabs>
        <Tabs.Tab
          icon="list"
          selected={tabIndex === 0}
          onClick={() => setTabIndex(0)}>
          Appetizers
        </Tabs.Tab>
        <Tabs.Tab
          icon="list"
          selected={tabIndex === 1}
          onClick={() => setTabIndex(1)}>
          Breakfast Menu
        </Tabs.Tab>
        <Tabs.Tab
          icon="list"
          selected={tabIndex === 2}
          onClick={() => setTabIndex(2)}>
          Lunch Menu
        </Tabs.Tab>
        <Tabs.Tab
          icon="list"
          selected={tabIndex === 3}
          onClick={() => setTabIndex(3)}>
          Dinner Menu
        </Tabs.Tab>
        <Tabs.Tab
          icon="list"
          selected={tabIndex === 4}
          onClick={() => setTabIndex(4)}>
          Desserts Menu
        </Tabs.Tab>
        <Tabs.Tab
          icon="list"
          selected={tabIndex === 5}
          onClick={() => setTabIndex(5)}>
          Exotic Menu
        </Tabs.Tab>
        <Tabs.Tab
          icon="list"
          selected={tabIndex === 6}
          onClick={() => setTabIndex(6)}>
          Raw Offerings
        </Tabs.Tab>
        <Tabs.Tab
          icon="fa-regular fa-address-card"
          selected={tabIndex === 7}
          onClick={() => setTabIndex(7)}>
          Crew Cookies
        </Tabs.Tab>
      </Tabs>
      {tabIndex === 0 ? <AppetizerMenu /> : null}
      {tabIndex === 1 ? <BreakfastMenu /> : null}
      {tabIndex === 2 ? <LunchMenu /> : null}
      {tabIndex === 3 ? <DinnerMenu /> : null}
      {tabIndex === 4 ? <DessertMenu /> : null}
      {tabIndex === 5 ? <ExoticMenu /> : null}
      {tabIndex === 6 ? <RawMenu /> : null}
      {tabIndex === 7 ? <CrewMenu /> : null}
    </Section>
  )}

const FoodDetailPanel = (_properties, context) => {
    const { act, data } = useBackend(context);
    const { general } = data;
    if (!general || !general.fields) {
      return <Box color="bad">General records missing!</Box>;
    }
    return (
      <Flex>
        <Flex.Item>
          <LabeledList>
            {general.fields.map((field, i) => (
              <LabeledList.Item key={i} label={field.field}>
                <Box height="20px" inline preserveWhitespace>
                  {field.value}
                </Box>
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Flex.Item>
        <Flex.Item textAlign="right">
          {!!general.has_photos &&
            general.photos.map((p, i) => (
              <Box
                key={i}
                width="64px"
                textAlign="center"
                display="inline-block"
                mr="0.5rem">
                <img
                  className={classes(['synthesizer32x32', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
                <br />
                Preview
              </Box>
            ))}
          </Flex.Item>
          </Flex>)}

const BodyDesignerBodyRecords = (props, context) => {
  const { act, data } = useBackend(context);
  const { bodyrecords } = data;
  return (
    <Section
      title="Body Records"
      buttons={
        <Button
          icon="arrow-left"
          content="Back"
          onClick={() => act('menu', { menu: 'Main' })}
        />
      }>
      {bodyrecords.map((record) => (
        <Button
          icon="eye"
          key={record.name}
          content={record.name}
          onClick={() => act('view_brec', { view_brec: record.recref })}
        />
      ))}
    </Section>
  );
};

const SupplyConsoleMenuOrder = (props, context) => {
  const { act, data } = useBackend(context);

  const { categories, supply_packs, contraband, supply_points } = data;

  const [activeCategory, setActiveCategory] = useLocalState(
    context,
    'activeCategory',
    null
  );

  const viewingPacks = flow([
    filter((val) => val.group === activeCategory),
    filter((val) => !val.contraband || contraband),
    sortBy((val) => val.name),
    sortBy((val) => val.cost > supply_points),
  ])(supply_packs);

  // const viewingPacks = sortBy(val => val.name)(supply_packs).filter(val => val.group === activeCategory);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
            <Button
              key={recipes}
              icon="user"
              mb="0.5rem"
              content={recipes.name}
              onClick={() => act('infofood', { infofood: recipes })}
            />
          ))}
           </Box>
          </Section>
        </Stack.Item>
      </Stack>
        <Stack.Item grow={1} ml={2}>
          <Section title="Contents" scrollable fill height="290px">
            {viewingPacks.map((pack) => (
              <Box key={pack.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <Button
                      fluid
                      icon="shopping-cart"
                      ellipsis
                      content={pack.name}
                      color={pack.cost > supply_points ? 'red' : null}
                      onClick={() => act('request_crate', { ref: recipe_list.ref })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      content="#"
                      color={pack.cost > supply_points ? 'red' : null}
                      onClick={() =>
                        act('request_crate_multi', { ref: pack.ref })
                      }
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      content="C"
                      color={pack.cost > supply_points ? 'red' : null}
                      onClick={() => act('view_crate', { crate: recipe_list.path })}
                    />
                  </Stack.Item>
                  <Stack.Item grow={1}>{pack.cost} points</Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
const AppetizerMenu = (props, context) => {
  const { act, data } = useBackend(context);

  const {categories, recipes} = data;
  const { mode } = props;

  const [activeCategory, setActiveCategory] = useLocalState(
    context,
    'activeCategory',
    null
  );

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
            <Button
              key={recipes}
              icon="user"
              mb="0.5rem"
              content={recipes.name}
              onClick={() => act('infofood', { infofood: recipes })}
            />
          ))}
           </Box>
          </Section>
        </Stack.Item>
      </Stack>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
            <Button
              key={recipes}
              icon="user"
              mb="0.5rem"
              content={recipes.name}
              onClick={() => act('infocrew', { infocrew: recipes })}
            />
          ))}
           </Box>
          </Section>
        </Stack.Item>
      </Stack>
        <Flex.Item>
        <LabeledList>
          {general.fields.map((field, i) => (
            <LabeledList.Item key={i} label={field.field}>
              <Box height="20px" inline preserveWhitespace>
                {field.value}
              </Box>
              {!!field.edit && (
                <Button
                  icon="pen"
                  ml="0.5rem"
                  onClick={() => doEdit(context, field)}
                />
              )}
            </LabeledList.Item>
          ))}
        </LabeledList>
      </Flex.Item>
      <Flex.Item textAlign="right">
        {!!general.has_photos &&
          general.photos.map((p, i) => (
            <Box
              key={i}
              display="inline-block"
              textAlign="center"
              color="label">
              <img
                src={p.substr(1, p.length - 1)}
                style={{
                  width: '96px',
                  'margin-bottom': '0.5rem',
                  '-ms-interpolation-mode': 'nearest-neighbor',
                }}
              />
              <br />
              Photo #{i + 1}
            </Box>
          ))}
      </Flex.Item>
    </section>


export const FoodSynthesizerMenuOrder = (props, context) => {
  const { act, data } = useBackend(context);

  const { categories, recipes, contraband, supply_points } = data;

  const [activeCategory, setActiveCategory] = useLocalState(
    context,
    'activeCategory',
    null
  );

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Categories" scrollable fill height="290px">
            {categories.map((category) => (
              <Button
                key={category}
                fluid
                content={category}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Contents" scrollable fill height="290px">
            {viewingPacks.map((pack) => (
              <Box key={pack.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <Button
                      fluid
                      icon="shopping-cart"
                      ellipsis
                      content={pack.name}
                      color={pack.cost > supply_points ? 'red' : null}
                      onClick={() => act('request_crate', { ref: pack.ref })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      content="#"
                      color={pack.cost > supply_points ? 'red' : null}
                      onClick={() =>
                        act('request_crate_multi', { ref: pack.ref })
                      }
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      content="C"
                      color={pack.cost > supply_points ? 'red' : null}
                      onClick={() => act('view_crate', { crate: pack.ref })}
                    />
                  </Stack.Item>
                  <Stack.Item grow={1}>{pack.cost} points</Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const AppetizerMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { records } = data;
  return (
    <Fragment>
      <Input
        fluid
        placeholder="Search by Name"
        onChange={(_event, value) => act('search', { t1: value })}
      />
      <Box mt="0.5rem">
        {records.map((record, i) => (
          <Button
          key={i}
          icon="fa-solid fa-burger"
          mb="0.5rem"
          color={record.color}
          content={
          }
          onClick={() => act('d_rec', { d_rec: record.ref })}
        />
          />
        ))}
      </Box>
    </Fragment>
  );
};
  const [category, setCategory] = useSharedState(context, "category", 0);

  const [
    searchText,
    setSearchText,
  ] = useSharedState(context, "search_text", "");

  const testSearch = createSearch(searchText, recipe => recipe.name);

  const recipesToShow = flow([
    filter(recipe => recipe.category === categories[category]),
    searchText && filter(testSearch),
    sortBy(recipe => recipe.name.toLowerCase()),
  ])(recipes);

  return (
    <Window width={550} height={700}>
      <Window.Content scrollable>
        <Section title="Recipes" buttons={
          <Dropdown
            width="190px"
            options={categories}
            selected={categories[category]}
            onSelected={val => setCategory(categories.indexOf(val))} />
        }>
          <Input
            fluid
            placeholder="Search for..."
            onInput={(e, v) => setSearchText(v)}
            mb={1} />
          {recipesToShow.map(recipe => (
            <Flex justify="space-between" align="center" key={recipe.ref}>
              <Flex.Item>
                <Button
                  color={recipe.hidden && "red" || null}
                  icon="hammer"
                  iconSpin={busy === recipe.name}
                  onClick={() => act("make", { make: recipe.ref })}>
                  {toTitleCase(recipe.name)}
                </Button>
              </Flex.Item>
            </Flex>
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};
