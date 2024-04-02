import { useBackend } from '../backend';
import { Box, Button, Icon, Section, ProgressBar, LabeledList } from '../components';
import { Window } from '../layouts';

export const GunLocker = (props, context) => {
  const { act, data } = useBackend(context);

  const { broken, locked, rackslot1, rackslot2, rackslot3, rackslot4, icons } =
    data;
  const { name1, charge1 } = data.rackslot1;
  const { name2, charge2 } = data.rackslot2;
  const { name3, charge3 } = data.rackslot3;
  const { name4, charge4 } = data.rackslot4;

  return (
    <Window width={210} height={180}>
      <Window.Content>
        <Section></Section>
        <Section>
        <Button
          width="64px"
          height="64px"
          position="relative"
          tooltip={rackslot1 ? rackslot1 : 'Rack One'}
          tooltipPosition="bottom-end"
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
          tooltip={rackslot2 ? rackslot2 : 'Rack Two'}
          tooltipPosition="bottom"
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
          tooltip={rackslot3 ? rackslot3 : 'Rack Three'}
          tooltipPosition="bottom-end"
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
          tooltip={rackslot4 ? rackslot4 : 'Rack Four'}
          tooltipPosition="top-end"
          color={rackslot4 ? 'grey' : 'transparent'}
          style={{
            border: rackslot4 ? null : '2px solid grey',
          }}
          onClick={() => act('spray')}>
          <ArmoryIcons iconkey="rackslot4" />
        </Button>
        </Section>
        <Section title="Ammunition Status">
          <LabeledList>
            {rackslot1.charge ? (
              <LabeledList.Item>
                <Box color="label">
                  {rackslot1.name} ammunition status <br />
                  <ProgressBar
                    ranges={{
                      bad: [-Infinity, 0],
                      average: [0, 99],
                      good: [99, Infinity],
                    }}
                    value={rackslot1.charge / 100}
                    minValue={0}
                    maxValue={100}
                  />
                </Box>
              </LabeledList.Item>
            ) : (
              <LabeledList.Item label="Firearm not present">
                <Box color="label">Please insert a compatible firearm.</Box>
              </LabeledList.Item>
            )}
            <br />
            {rackslot2.charge2 ? (
              <LabeledList.Item>
                <Box color="label">
                  {rackslot2.name2} ammunition status <br />
                  <ProgressBar
                    ranges={{
                      bad: [-Infinity, 0],
                      average: [0, 99],
                      good: [99, Infinity],
                    }}
                    value={rackslot2.charge2 / 100}
                    minValue={0}
                    maxValue={100}
                  />
                </Box>
              </LabeledList.Item>
            ) : (
              <LabeledList.Item label="Firearm not present">
                <Box color="label">Please insert a compatible firearm.</Box>
              </LabeledList.Item>
            )}
            <br />
            {rackslot3.charge3 ? (
              <LabeledList.Item>
                <Box color="label">
                  {rackslot3.name3} ammunition status <br />
                  <ProgressBar
                    ranges={{
                      bad: [-Infinity, 0],
                      average: [0, 99],
                      good: [99, Infinity],
                    }}
                    value={rackslot3.charge3 / 100}
                    minValue={0}
                    maxValue={100}
                  />
                </Box>
              </LabeledList.Item>
            ) : (
              <LabeledList.Item label="Firearm not present">
                <Box color="label">Please insert a compatible firearm.</Box>
              </LabeledList.Item>
            )}
            <br />
            {rackslot4.charge4 ? (
              <LabeledList.Item>
                <Box color="label">
                  {rackslot4.name4} ammunition status <br />
                  <ProgressBar
                    ranges={{
                      bad: [-Infinity, 0],
                      average: [0, 99],
                      good: [99, Infinity],
                    }}
                    value={rackslot4.charge4 / 100}
                    minValue={0}
                    maxValue={100}
                  />
                </Box>
              </LabeledList.Item>
            ) : (
              <LabeledList.Item label="Firearm not present">
                <Box color="label">Please insert a compatible firearm.</Box>
              </LabeledList.Item>
            )}
            <br />
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
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
    />
  );
};
