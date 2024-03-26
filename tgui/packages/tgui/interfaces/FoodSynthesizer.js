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
        <Section>
          <SynthCartGuage />
        </Section>
        <Section title="Menu Selection">
          <FoodMenuTabs />
        </Section>
        <Flex>
          <Flex.Item grow fill>
            <FoodSelectionMenu />
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

/** Displays the current Cartridge status. */

const SynthCartGuage = (props, context) => {
  const { data } = useBackend(context);
  const { isThereCart, cartFillStatus } = data;
  const adjustedCartChange = cartFillStatus / 100;
  return (
    <Section title="Cartridge Status">
      {isThereCart ? (
      <LabeledList.Item label="Product Remaining">
        {cartFillStatus ? ( <ProgressBar color="purple" value={adjustedCartChange} width={20} /> ) : (<ProgressBar color="red" value={adjustedCartChange} width={20} />)}
      </LabeledList.Item>
      ) : (
        <LabeledList.Item label="Cartridge Problem">
        <Box color="label">One or more cartridges are missing or damaged. <br /><br />
         Sabresnacks Co. recommends ordering a genuine Sabresnacks replacement cartidge through your local logistical cargo service.
        </Box>
        </LabeledList.Item>
      )}
    </Section>
  );
};

/** Dynamic menu tabs for every listing in catagory groups. */

const FoodMenuTabs = (props, context) => {
  const { act, data } = useBackend(context);
  const { active_menu, menucatagories } = data;
  const menusToShow = menucatagories.sort((a, b) => a.sortorder - b.sortorder);
  const [newMenu, setActiveMenu] = useSharedState(
    context,
    'ActiveMenu',
    data.active_menu
  );

  let handleActivemenu = (newMenu) => {
    setActiveMenu(newMenu);
    act('setactive_menu', { 'setactive_menu': newMenu });
  };

  return (
    <Flex flow-wrap>
      <Section>
        <Tabs>
          {menusToShow.map((menu) => (
            <Tabs.Tab>
              <Button
                key={menu.ref}
                fluid
                content={menu.name}
                icon="list"
                selected={menu.id === active_menu}
                onClick={() => handleActivemenu(menu.id)}
              />
            </Tabs.Tab>
          ))}
        </Tabs>
      </Section>
    </Flex>
  );
};

/** Chooses the menu item, displays information, and an image. Sorts via menu based catagory attribute listed in every catagory item. */

const FoodSelectionMenu = (props, context) => {
  const { act, data } = useBackend(context);
  const { active_menu, recipes, active_crew, crewdata, crew_cookies } = data;
  const { recipe } = props;
  const { hidden } = data.recipes;
  if (!recipes) {
    return <Box color="bad">Recipes records missing!</Box>;
  }
  const [ActiveFood, setActiveFood] = useSharedState(
    context,
    'ActiveFood',
    data.recipes
  );

  const recipesToShow = flow([
    filter((recipe) => recipe.catagory === active_menu),
    filter((recipe) => !recipe.hidden || hidden),
    sortBy((recipe) => recipe.name),
  ])(recipes);

  const [ActiveCookie, setActiveCookie] = useSharedState(
    context,
    'ActiveCookie',
    data.crew_cookies
  );

  const cookiesToShow = flow([
    filter((cookie) => cookie.catagory === active_menu),
    sortBy((cookie) => cookie.name),
  ])(crew_cookies);

  if (active_menu === 'crew') {
    return (
      <Section level={2}>
        <Stack>
          <Stack.Item basis="30%">
            <Section title="Food Selection" scrollable fill height="290px">
              <Tabs vertical>
                {cookiesToShow.map((cookie) => (
                  <Tabs.Tab>
                    <Button
                      key={cookie.name}
                      fluid
                      content={cookie.name}
                      selected={cookie === ActiveCookie}
                      onClick={() => setActiveCookie(cookie)}
                    />
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Section>
          </Stack.Item>
          <Flex>
            <Flex.Item>
              <LabeledList>
                {crewdata.fields.map((field, i) => (
                  <LabeledList.Item key={i} label={field.field}>
                    <Box height="20px" inline preserveWhitespace>
                      {field.value}
                    </Box>
                  </LabeledList.Item>
                ))}
              </LabeledList>
            </Flex.Item>
          </Flex>
        </Stack>
      </Section>
    );
  }

  return (
    <Section level={2}>
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
          <Section title="Product Details" fill height="290px">
            <Box key={ActiveFood.ref}>
              <Stack align="center" justify="flex-start">
                <Stack.Item>
                  <LabeledList>
                    <LabeledList.Item label="Name">
                      {ActiveFood.name}
                    </LabeledList.Item>
                    <br />
                    <LabeledList.Item label="Description">
                      {ActiveFood.desc}
                    </LabeledList.Item>
                    <br />
                    <LabeledList.Item label="Serving Temprature">
                      {ActiveFood.voice_temp}
                    </LabeledList.Item>
                  </LabeledList>
                  <br />
                  <br />
                  <br />
                  <Button
                    fluid
                    icon="print"
                    width="150px"
                    content="Begin Printing"
                    onClick={() => act('make', { make: ActiveFood.ref })}
                  />
                  <ProductImage recipe={ActiveFood} />
                </Stack.Item>
              </Stack>
            </Box>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

/** Displays the product image. Displays a default if there is none. */

const ProductImage = (props) => {
  const { recipe } = props;

  return recipe.img ? (
    <Box>
      <img
        src={`data:image/jpeg;base64,${recipe.img}`}
        style={{
          verticalAlign: 'middle',
        }}
      />
    </Box>
  ) : (
    <Box>
      <span
        className={classes(['synthesizer64x64', recipe.path])}
        style={{
          verticalAlign: 'middle',
        }}
      />
    </Box>
  );
};

/*  <Flex.Item textAlign="right">
              {!!crewdata.has_photos &&
                crewdata.photos.map((p, i) => (
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
                    {i}
                  </Box>
                ))}
              <Box>
                <Button onClick={() => act('crew_photo')}>
                  Update Crew Photo
                </Button>
              </Box>
            </Flex.Item> */  