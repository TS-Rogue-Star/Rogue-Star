import { useBackend } from '../backend';
import { Box, Button, Icon, Section, Stack, LabeledList } from '../components';
import { Window } from '../layouts';

export const GunLocker = (props, context) => {
  const { act, data } = useBackend(context);
  const { rackslot } = props;

  const {
    welded,
    emagged,
    locked,
    rackslot1,
    rackslot2,
    rackslot3,
    rackslot4,
    icons,
    guninfo,
  } = data;

  return (
    <Window width={330} height={400}>
      <Window.Content>
        <Section>
          <Stack>
            <Stack.Item>
              <Button
                width="64px"
                height="64px"
                position="relative"
                color={rackslot1 ? 'grey' : 'transparent'}
                style={{
                  border: rackslot1 ? null : '2px solid grey',
                }}
                onClick={() => act('rackslot1')}>
                <ArmoryIcons iconkey="rackslot1" />
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                width="64px"
                height="64px"
                position="relative"
                color={rackslot2 ? 'grey' : 'transparent'}
                style={{
                  border: rackslot2 ? null : '2px solid grey',
                }}
                onClick={() => act('rackslot2')}>
                <ArmoryIcons iconkey="rackslot2" />
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                width="64px"
                height="64px"
                position="relative"
                color={rackslot3 ? 'grey' : 'transparent'}
                style={{
                  border: rackslot3 ? null : '2px solid grey',
                }}
                onClick={() => act('rackslot3')}>
                <ArmoryIcons iconkey="rackslot3" />
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                width="64px"
                height="64px"
                position="relative"
                color={rackslot4 ? 'grey' : 'transparent'}
                style={{
                  border: rackslot4 ? null : '2px solid grey',
                }}
                onClick={() => act('rackslot4')}>
                <ArmoryIcons iconkey="rackslot4" />
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
        <Section title="Ammunition Status">
          <Stack vertical>
            <Stack.Item>
              <Armoryinfo rackslot="rackslot1" />
            </Stack.Item>
            <Stack.Item>
              <Armoryinfo rackslot="rackslot2" />
            </Stack.Item>
            <Stack.Item>
              <Armoryinfo rackslot="rackslot3" />
            </Stack.Item>
            <Stack.Item>
              <Armoryinfo rackslot="rackslot4" />
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

const Gunslotting = {
  'rackslot1': 'Slot One',
  'rackslot2': 'Slot Two',
  'rackslot3': 'Slot Three',
  'rackslot4': 'Slot Four',
};

const Armoryinfo = (props, context) => {
  const { data } = useBackend(context);
  const { rackslot } = props;
  const { guninfo } = data;

  return (
    <LabeledList>
      <LabeledList.Item key={guninfo[rackslot]} label={Gunslotting[rackslot]}>
        {guninfo[rackslot] ? (
          <Box color="label">
            {guninfo[rackslot][0]?.name}
            <br />
            Ammunition: {guninfo[rackslot][0]?.charge}
          </Box>
        ) : (
          <Box color="label">EMPTY</Box>
        )}
      </LabeledList.Item>
    </LabeledList>
  );
};

const iconkeysToIcons = {
  'rackslot1': 'box',
  'rackslot2': 'box',
  'rackslot3': 'box',
  'rackslot4': 'box',
};

const ArmoryIcons = (props, context) => {
  const { data } = useBackend(context);

  const { iconkey } = props;

  const { icons } = data;

  if (iconkey in icons) {
    return (
      <img
        src={icons[iconkey].substr(1, icons[iconkey].length - 1)}
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          width: '64px',
          height: '64px',
          '-ms-interpolation-mode': 'nearest-neighbor',
        }}
      />
    );
  }

  return (
    <Icon
      style={{
        position: 'absolute',
        left: '4px',
        right: 0,
        top: '20px',
        bottom: 0,
        width: '64px',
        height: '64px',
      }}
      fontSize={2}
      name={iconkeysToIcons[iconkey]}
    />
  );
};
