import { decodeHtmlEntities } from 'common/string';
import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section, Tabs } from '../components';
import { Window } from '../layouts';

const FoodListing = (modal, context) => {
  const { act, data, cart } = useBackend(context);
  const { cartfilling } = cart;
  const { name, id, categories, path, recipes } = modal.args;
  return (
    <Section
      width="400px"
      screen={9}
      m="-1rem"
      pb="1rem"
      title={name}
      buttons={
        <Button
          icon="shopping-cart"
          content={name}
          disabled={cartfilling <= 0}
          onClick={() => act('d_rec', { d_rec: record.ref })}
          onClick={() => act('make', { make: path })}
        />
      }>
      
      <Section
        title={'' + (random ? ' any ' + random + ' of:' : '')}
        scrollable
        height="200px">
        {manifest.map((m) => (
          <Box key={m}>{m}</Box>
        ))}
      </Section>
    </Section>
  );
};

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
        <MenuNavigation />
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
    <Tabs>
      <Tabs.Tab
        selected={screen === 2}
        icon="list"
        onClick={() => act('screen', { screen: 2 })}>
        Appetizers
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 3}
        icon="list"
        onClick={() => act('screen', { screen: 3 })}>
        Breakfast
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 4}
        icon="list"
        onClick={() => act('screen', { screen: 4 })}>
        Lunch
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 5}
        icon="list"
        onClick={() => act('screen', { screen: 5 })}>
        Dinner
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 6}
        icon="list"
        onClick={() => act('screen', { screen: 6 })}>
        Desserts
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 7}
        icon="list"
        onClick={() => act('screen', { screen: 7 })}>
        Exotic & Raw
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 8}
        icon="fa-regular fa-address-card"
        onClick={() => act('screen', { screen: 8 })}>
        Crew Cookies
      </Tabs.Tab>
    </Tabs>
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
                Preview {i}
              </Box>
            ))}
  
  const AppetizerMenu = (_properties, context) => {
    const { act, data } = useBackend(context);
    const { records } = data;
    return (
      <Fragment>
        <Box mt="0.5rem">
          {records.map((record, i) => (
            <Button
              key={i}
              icon="fa-solid fa-burger"
              mb="0.5rem"
              content={records.name
              }
              onClick={() => act('info', { d_rec: records.ref })}
            />
          ))}
        </Box>
      </Fragment>
    );
  };
const SynthesizerMenuOrder = (props, context) => {
  const { act, data } = useBackend(context);

  const { categories, supply_packs, contraband, supply_points } = data;

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
          <Section title="Selected Food Information" scrollable fill height="290px">
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
                      onClick={() => act('info', { ref: pack.ref })}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
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
