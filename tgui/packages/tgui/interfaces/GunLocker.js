import { useBackend } from '../backend';
import { Box, Button, Icon, Section, Stack, ProgressBar, LabeledList } from '../components';
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
  } = data;

  return (
    <Window width={330} height={400}>
      <Window.Content>
        <Section>
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
        </Section>
        <Section title="Ammunition Status">
          <Stack.Item>
            <ArmoryInfo rackslot="rackslot1" />
          </Stack.Item>
          <Stack.Item>
            <ArmoryInfo rackslot="rackslot2" />
          </Stack.Item>
          <Stack.Item>
            <ArmoryInfo rackslot="rackslot3" />
          </Stack.Item>
          <Stack.Item>
            <ArmoryInfo rackslot="rackslot4" />
          </Stack.Item>
        </Section>
      </Window.Content>
    </Window>
  );
};

const ArmoryInfo = (props, context) => {
  const { data } = useBackend(context);

  const { rackslot } = props;

  const { guninfo } = data;

  if (rackslot in guninfo) {
    return (
      <LabeledList>
        <LabeledList.Item>
          <Box color="label">
            <ProgressBar
              key={rackslot}
              ranges={{
                bad: [-Infinity, 0],
                average: [0, 99],
                good: [99, 100],
              }}
              value={rackslot.charge / 100}
              minValue={0}
              maxValue={100}
            />
          </Box>
        </LabeledList.Item>
      </LabeledList>
    );
  }

  return (
    <LabeledList>
      <LabeledList.Item label="Firearm not present">
        <Box color="label">Please insert a compatible firearm.</Box>
      </LabeledList.Item>
    </LabeledList>
  );
};

const iconkeysToIcons = {
  'rackslot1': 'square-plus',
  'rackslot2': 'square-plus',
  'rackslot3': 'square-plus',
  'rackslot4': 'square-plus',
};

const ArmoryIcons = (props, context) => {
  const { data } = useBackend(context);

  const { iconkey, rackslot } = props;

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
