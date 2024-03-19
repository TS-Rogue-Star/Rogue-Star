import { classes } from 'common/react';
import { filter, sortBy } from 'common/collections';
import { useBackend, useSharedState } from '../backend';
import { Box, Button, LabeledList, Section, Flex, Tabs, ProgressBar, Stack } from '../components';
import { Window } from '../layouts';
import { flow } from 'common/fp';

export const FoodSynthesizer = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window width={900} height={500} resizable>
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
    <Section title="Cartridge Status" width="200">
      <LabeledList.Item>
        <ProgressBar color="purple" value={adjustedCartChange} />
      </LabeledList.Item>
    </Section>
  );
};

// dynamic selection for possible (but unlikely) additional or more specific menu making, they add tabs + the Crew menu
const FoodMenuTabs = (props, context) => {
  const { act, data } = useBackend(context);
  const { menucatagories, active_menu } = data;

  const menusToShow = flow([sortBy((menutab) => menutab.id)])(menucatagories);

  return (
    <Flex flow-wrap>
      <Section>
        <Tabs>
          {menusToShow.map((menutab) => (
            <Tabs.Tab>
              <Button
                key={menutab.id}
                fluid
                content={menutab.name}
                icon="list"
                selected={(menutab = active_menu)}
                onClick={() => {
                  act('setactive_menu', { setactive_menu: selected.id });
                }}
              />
            </Tabs.Tab>
          ))}
        </Tabs>
        <Flex.Item grow>
          <FoodSelectionMenu />
        </Flex.Item>
      </Section>
    </Flex>
  );
};

/*  <Tabs.Tab>
      <Button
        icon="user"
        selected={active_menu === MENU_CREW}
        content="Crew Menu"
        onClick={() => act(CrewMenu, { crewmenu: crew.name })}
      />
    </Tabs.Tab> */

const FoodSelectionMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { active_menu, recipes } = data;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useSharedState(context, 'ActiveFood', 0);

  const recipesToShow = flow([
    filter((recipe) => recipe.category === active_menu),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  return (
    <Section level={2} width="600px">
      <Stack>
        <Stack.Item basis="30%">
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
          <Section
            title="Product Details"
            scrollable
            fill
            height="290px"
            width="400px">
            <Box key={ActiveFood.name}>
              <Stack align="center" justify="flex-start">
                <Stack.Item>
                  <LabeledList>
                    <LabeledList.Item label="Name">
                      {ActiveFood.name}
                    </LabeledList.Item>
                    <LabeledList.Item label="Description">
                      {ActiveFood.desc}
                    </LabeledList.Item>
                    <LabeledList.Item label="Serving Temprature">
                      {ActiveFood.voice_temp}
                    </LabeledList.Item>
                  </LabeledList>
                  <Flex.Item>
                    <Button
                      fluid
                      icon="print"
                      width="150px"
                      content="Begin Printing"
                      onClick={() => act('make', { make: ActiveFood.ref })}
                    />
                  </Flex.Item>
                  <Box
                    className={classes([
                      'synthesizer64x64',
                      ActiveFood.icon_state,
                    ])}
                  />
                </Stack.Item>
              </Stack>
            </Box>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const CrewMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  return <Box>This will be filled out laters</Box>;
};
