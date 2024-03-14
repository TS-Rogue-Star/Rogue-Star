import { Fragment } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Input, LabeledList, Section, Tabs } from '../components';
import { ComplexModal, FoodListing } from '../interfaces/common/ComplexModal';
import { Window } from '../layouts';
import { flow } from 'common/fp';

export const SynthesizerMenu = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window width={700} height={620}>
      <Window.Content>
        <ComplexModal maxWidth="100%" />
        <Section title="SabreSnacks Menu">
          <SynthCartGuage />
          <FoodMenuTabs />
        </Section>
      </Window.Content>
    </Window>
  );
};
const menus = [
  {
    name: 'Appetizers',
    icon="list",
    template: <AppetizerMenu />,
  },
  {
    name: 'Breakfast',
    icon="list",
    template: <BreakfastMenu />,
  },
  {
    name: 'Lunch',
    icon="list",
    template: <LunchMenu />,
  },
  {
    name: 'Dinner',
    icon="list",
    template: <DinnerMenu />,
  },
  {
    name: 'Desserts',
    icon="list",
    template: <DessertMenu />,
  },
  {
    name: 'Exotic Menu',
    icon="list",
    template: <ExoticMenu />,
  },
  {
    name: 'Raw Offerings',
    icon="list",
    template: <RawMenu />,
  },
  {
    name: 'Crew Cookies',
    icon="list",
    template: <CrewMenu />,
  },
];

const FoodMenuTabs = (props, context) => {
  const { act, data } = useBackend(context);
  const [menu, setMenu] = useSharedState(context, 'foodmenu', 0);

  const [activeMenu] = useLocalState(
    context,
    menucatagory_list,
    null
  );
  const menuselection = flow([
    filter((val) => val.id === menucatagory_list),
    sortBy((val) => val.name),
  ])(menucatagories);

  return (
    <Window width={850} height={630}>
      <Window.Content scrollable>
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
      </Window.Content>
    </Window>
  );
};

const AppetizerMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, path, hidden, menucatagories } = data;
  const { name, desc, icon, menucatagories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

const BreakfastMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, categories, path, hidden } = data;
  const { name, desc, icon, categories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

const LunchMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, categories, path, hidden } = data;
  const { name, desc, icon, categories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

const DinnerMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, categories, path, hidden } = data;
  const { name, desc, icon, categories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

const DessertMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, categories, path, hidden } = data;
  const { name, desc, icon, categories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

const ExoticMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, catagory_list, path, hidden } = data;
  const { name, desc, icon, categories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

const RawMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, categories, path, hidden } = data;
  const { name, desc, icon, categories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

/*
const CrewMenu = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { recipe, recipes, name, desc, icon, categories, path, hidden } = data;
  const { name, desc, icon, categories, path, hidden } = modal.args;
  const {product} = props;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  return(
      <Stack>
        <Stack.Item basis="25%">
          <Section title="Food Selection" scrollable fill height="290px">
          <Box mt="0.5rem">
          {recipes.map((recipes) => (
              <Button
                key={recipes}
                fluid
                content={recipes.name}
                selected={category === activeCategory}
                onClick={() => setActiveCategory(category)}
                onClick={() => act('infofood', { infofood: recipes })}
              />
            ))}
           </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow={1} ml={2}>
          <Flex>
            <Flex.Item>
              <LabeledList>
                <LabeledList.Item label="Name">
                  {recipe.name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {recipe.desc}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item textAlign="right">
              {(product.isatom && (
                <span
                  className={classes(['synthesizer64x64', recipe.path])}
                  style={{
                    width: '100%',
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }}
                />
               ))}
                    <br />
                    Preview
              </Flex.Item>
            </Flex>
          </Stack.Item>
      </Stack>)};

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
*/
