import { useBackend, useLocalState } from '../backend';
import { Box, Button, LabeledList, Section, Tabs, ProgressBar, Stack } from '../components';
import { Window } from '../layouts';
import { flow } from 'common/fp';

export const FoodSynthesizer = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window width={700} height={700}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <SynthCartGuage />
          </Stack.Item>
          <Stack.Item>
            <FoodMenuTabs />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SynthCartGuage = (props, context) => {
  const { data } = useBackend(context);
  return (
    <Section title="Cartridge Status">
      <Box>
        <LabeledList.Item label={data.cart.name}>
          <ProgressBar color="purple" value={data.cartFillStatus} />
        </LabeledList.Item>
      </Box>
    </Section>
  );
};

const menus = [
  {
    name: 'Appetizers',
    icon: 'list',
    template: <AppetizerMenu />,
  },
  {
    name: 'Breakfast',
    icon: 'list',
    template: <BreakfastMenu />,
  },
  {
    name: 'Lunch',
    icon: 'list',
    template: <LunchMenu />,
  },
  {
    name: 'Dinner',
    icon: 'list',
    template: <DinnerMenu />,
  },
  {
    name: 'Desserts',
    icon: 'list',
    template: <DessertMenu />,
  },
  {
    name: 'Exotic Menu',
    icon: 'list',
    template: <ExoticMenu />,
  },
  {
    name: 'Raw Offerings',
    icon: 'list',
    template: <RawMenu />,
  },
];

/*  {
    name: 'Crew Cookies',
    icon: 'list',
    template: <CrewMenu />,
  },  */

const FoodMenuTabs = (props, context) => {
  const [menu, setMenu] = useSharedState(context, 'menutabs', 0);

  const menus = [
    {
      name: 'Appetizers',
      icon: 'list',
      template: <AppetizerMenu />,
    },
    {
      name: 'Breakfast',
      icon: 'list',
      template: <BreakfastMenu />,
    },
    {
      name: 'Lunch',
      icon: 'list',
      template: <LunchMenu />,
    },
    {
      name: 'Dinner',
      icon: 'list',
      template: <DinnerMenu />,
    },
    {
      name: 'Desserts',
      icon: 'list',
      template: <DessertMenu />,
    },
    {
      name: 'Exotic Menu',
      icon: 'list',
      template: <ExoticMenu />,
    },
    {
      name: 'Raw Offerings',
      icon: 'list',
      template: <RawMenu />,
    },
  ];
  
  return (
    <Window>
      <Box>
        <Tabs>
          {menus.map((obj, i) => (
            <Tabs.Tab
              key={i}
              icon={obj.icon}
              selected={menu === i}
              onClick={() => setMenu(i)}>
              {obj.name}
            </Tabs.Tab>
          ))}
        </Tabs>
        {menus[menu].template}
      </Box>
    </Window>
  );
};

const AppetizerMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useLocalState(
    context,
    'ActiveFood',
    null
  );

  const FoodList = flow([
    filter((recipe) => recipe.name === ActiveFood),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
            {menuselection.map((recipe) => (
              <Button
                key={recipe}
                fluid
                content={recipe.name}
                selected={recipe === ActiveFood}
                onClick={() => setActiveFood(recipes)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Details" scrollable fill height="290px">
            {FoodList.map((recipe) => (
              <Box key={recipe.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <LabeledList>
                      <LabeledList.Item label="Name">
                        {recipe.name}
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        {recipe.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Serving Temprature">
                        {recipe.voice_temp}
                      </LabeledList.Item>
                    </LabeledList>
                    <Button
                      fluid
                      icon="print"
                      content="Begin Printing"
                      onClick={() => act('make', { make: recipe.path })}>
                      {toTitleCase(recipe.name)}
                    </Button>
                    <Box
                      className={classes([
                        'synthesizer64x64',
                        recipe.icon_state,
                      ])}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const BreakfastMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useLocalState(
    context,
    'ActiveFood',
    null
  );

  const FoodList = flow([
    filter((recipe) => recipe.name === ActiveFood),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
            {menuselection.map((recipe) => (
              <Button
                key={recipe}
                fluid
                content={recipe.name}
                selected={recipe === ActiveFood}
                onClick={() => setActiveFood(recipes)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Details" scrollable fill height="290px">
            {FoodList.map((recipe) => (
              <Box key={recipe.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <LabeledList>
                      <LabeledList.Item label="Name">
                        {recipe.name}
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        {recipe.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Serving Temprature">
                        {recipe.voice_temp}
                      </LabeledList.Item>
                    </LabeledList>
                    <Button
                      fluid
                      icon="print"
                      content="Begin Printing"
                      onClick={() => act('make', { make: recipe.path })}>
                      {toTitleCase(recipe.name)}
                    </Button>
                    <Box
                      className={classes([
                        'synthesizer64x64',
                        recipe.icon_state,
                      ])}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const LunchMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useLocalState(
    context,
    'ActiveFood',
    null
  );

  const FoodList = flow([
    filter((recipe) => recipe.name === ActiveFood),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
            {menuselection.map((recipe) => (
              <Button
                key={recipe}
                fluid
                content={recipe.name}
                selected={recipe === ActiveFood}
                onClick={() => setActiveFood(recipes)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Details" scrollable fill height="290px">
            {FoodList.map((recipe) => (
              <Box key={recipe.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <LabeledList>
                      <LabeledList.Item label="Name">
                        {recipe.name}
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        {recipe.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Serving Temprature">
                        {recipe.voice_temp}
                      </LabeledList.Item>
                    </LabeledList>
                    <Button
                      fluid
                      icon="print"
                      content="Begin Printing"
                      onClick={() => act('make', { make: recipe.path })}>
                      {toTitleCase(recipe.name)}
                    </Button>
                    <Box
                      className={classes([
                        'synthesizer64x64',
                        recipe.icon_state,
                      ])}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const DinnerMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useLocalState(
    context,
    'ActiveFood',
    null
  );

  const FoodList = flow([
    filter((recipe) => recipe.name === ActiveFood),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
            {menuselection.map((recipe) => (
              <Button
                key={recipe}
                fluid
                content={recipe.name}
                selected={recipe === ActiveFood}
                onClick={() => setActiveFood(recipes)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Details" scrollable fill height="290px">
            {FoodList.map((recipe) => (
              <Box key={recipe.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <LabeledList>
                      <LabeledList.Item label="Name">
                        {recipe.name}
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        {recipe.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Serving Temprature">
                        {recipe.voice_temp}
                      </LabeledList.Item>
                    </LabeledList>
                    <Button
                      fluid
                      icon="print"
                      content="Begin Printing"
                      onClick={() => act('make', { make: recipe.path })}>
                      {toTitleCase(recipe.name)}
                    </Button>
                    <Box
                      className={classes([
                        'synthesizer64x64',
                        recipe.icon_state,
                      ])}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const DessertMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useLocalState(
    context,
    'ActiveFood',
    null
  );

  const FoodList = flow([
    filter((recipe) => recipe.name === ActiveFood),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
            {menuselection.map((recipe) => (
              <Button
                key={recipe}
                fluid
                content={recipe.name}
                selected={recipe === ActiveFood}
                onClick={() => setActiveFood(recipes)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Details" scrollable fill height="290px">
            {FoodList.map((recipe) => (
              <Box key={recipe.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <LabeledList>
                      <LabeledList.Item label="Name">
                        {recipe.name}
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        {recipe.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Serving Temprature">
                        {recipe.voice_temp}
                      </LabeledList.Item>
                    </LabeledList>
                    <Button
                      fluid
                      icon="print"
                      content="Begin Printing"
                      onClick={() => act('make', { make: recipe.path })}>
                      {toTitleCase(recipe.name)}
                    </Button>
                    <Box
                      className={classes([
                        'synthesizer64x64',
                        recipe.icon_state,
                      ])}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ExoticMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useLocalState(
    context,
    'ActiveFood',
    null
  );

  const FoodList = flow([
    filter((recipe) => recipe.name === ActiveFood),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
            {menuselection.map((recipe) => (
              <Button
                key={recipe}
                fluid
                content={recipe.name}
                selected={recipe === ActiveFood}
                onClick={() => setActiveFood(recipes)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Details" scrollable fill height="290px">
            {FoodList.map((recipe) => (
              <Box key={recipe.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <LabeledList>
                      <LabeledList.Item label="Name">
                        {recipe.name}
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        {recipe.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Serving Temprature">
                        {recipe.voice_temp}
                      </LabeledList.Item>
                    </LabeledList>
                    <Button
                      fluid
                      icon="print"
                      content="Begin Printing"
                      onClick={() => act('make', { make: recipe.path })}>
                      {toTitleCase(recipe.name)}
                    </Button>
                    <Box
                      className={classes([
                        'synthesizer64x64',
                        recipe.icon_state,
                      ])}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const RawMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useLocalState(
    context,
    'ActiveFood',
    null
  );

  const FoodList = flow([
    filter((recipe) => recipe.name === ActiveFood),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2}>
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
            {menuselection.map((recipe) => (
              <Button
                key={recipe}
                fluid
                content={recipe.name}
                selected={recipe === ActiveFood}
                onClick={() => setActiveFood(recipes)}
              />
            ))}
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Section title="Details" scrollable fill height="290px">
            {FoodList.map((recipe) => (
              <Box key={recipe.name}>
                <Stack align="center" justify="flex-start">
                  <Stack.Item basis="70%">
                    <LabeledList>
                      <LabeledList.Item label="Name">
                        {recipe.name}
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        {recipe.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Serving Temprature">
                        {recipe.voice_temp}
                      </LabeledList.Item>
                    </LabeledList>
                    <Button
                      fluid
                      icon="print"
                      content="Begin Printing"
                      onClick={() => act('make', { make: recipe.path })}>
                      {toTitleCase(recipe.name)}
                    </Button>
                    <Box
                      className={classes([
                        'synthesizer64x64',
                        recipe.icon_state,
                      ])}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

/*
const CrewMenu = (_properties, context) => {
  const { act, data } = useBackend(context); */
