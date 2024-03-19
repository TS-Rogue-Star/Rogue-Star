// import { Fragment } from 'inferno';
import { filter, sortBy } from 'common/collections';
import { useBackend, useSharedState } from '../backend';
import { Box, Button, LabeledList, Section, Flex, Tabs, ProgressBar, Stack } from '../components';
import { Window } from '../layouts';
import { flow } from 'common/fp';

export const FoodSynthesizer = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window width={800} height={700} resizable>
      <Window.Content>
        <SynthCartGuage />
        <FoodMenuTabs />
      </Window.Content>
    </Window>
  );
};

const SynthCartGuage = (props, context) => {
  const { data } = useBackend(context);
  const adjustedCartChange = data.cartFillStatus / 100;
  return (
    <Section title="Cartridge Status">
      <LabeledList.Item>
        <ProgressBar color="purple" value={adjustedCartChange} />
      </LabeledList.Item>
    </Section>
  );
};

// dynamic selection for possible (but unlikely) additional or more specific menu making, they add tabs + the Crew menu
const FoodMenuTabs = (props, context) => {
  const { act, data } = useBackend(context);
  const { recipes, menucatagories } = data;
  const [activemenu, setMenu] = useSharedState(context, 'synthmenu', 0);
  return (
    <Flex>
      <Section fill spacing={1}>
        <Tabs>
          {activemenu.map((foodmenu) => (
            <Tabs.Tab
              key={foodmenu.name}
              icon={foodmenu.icon}
              selected={foodmenu.selected}
              onClick={() => act('menupick', { menupick: foodmenu.id })}>
              {foodmenu.name}
            </Tabs.Tab>
          ))}
          <Tabs.Tab>
            <Button
              icon="face-grin-beam-o"
              content="Crew Menu"
              onClick={() => act(CrewMenu, { crewmenu: crew.name })}
            />
          </Tabs.Tab>
        </Tabs>
        <Flex.Item grow>
          {selected && (
            <Section title={selected.foodmenu.name}>
              <FoodSelectionMenu foodmenu={selected} />
            </Section>
          )}
        </Flex.Item>
      </Section>
    </Flex>
  );
};

const FoodSelectionMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipes, menucatagories } = data;
  const { active_menu } = props;
  const {
    category,
    name,
    desc,
    icon,
    icon_state,
    path,
    voice_order,
    voice_temp,
    hidden,
    ref,
  } = recipes;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useSharedState(context, 'ActiveFood', 0);

  const recipesToShow = flow([
    filter((recipe) => recipe.category === active_menu[category]),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Flex>
      <Section>
        <Stack>
          <Stack.Item basis="25%">
            <Section title="Food Selection" scrollable fill height="290px">
              <Tabs vertical>
                {recipesToShow.map((recipe) => (
                  <Tabs.Tab>
                    <Button
                      key={recipe.ref}
                      fluid
                      content={recipe.name}
                      selected={recipe === ActiveFood}
                      onClick={() => setActiveFood(recipe)}
                    />
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Section>
          </Stack.Item>
          <Stack.Item grow={1} ml={2}>
            <Section title="Product Details" scrollable fill height="290px">
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
                        onClick={() => act('make', { make: recipe.ref })}>
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
    </Flex>
  );
};

const CrewMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  return <Box>This will be filled out laters</Box>;
};
