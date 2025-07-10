import { Box, LabeledList, Stack } from '../../../components';
import { MedigunDescription } from '../MedigunHelpers/MedigunDescription';
import { ExamineData } from '../types';

export const MedigunParts = (props: { examineData: ExamineData }, context) => {
  const { examineData } = props;
  const { smodule, smanipulator, slaser, scapacitor, sbin } = examineData;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <LabeledList>
          <LabeledList.Item label="Scanning Module">
            {smodule ? (
              <MedigunDescription
                part_1={'It has a'}
                name={smodule.name}
                part_2={'installed, device will function within'}
                func={smodule.range + ' tiles'}
                part_3={smodule.rating >= 5 ? 'and' : undefined}
                extra={smodule.rating >= 5 ? 'through walls' : undefined}
              />
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Manipulator">
            {smanipulator ? (
              <MedigunDescription
                part_1={'It has a'}
                name={smanipulator.name}
                part_2={'installed, chem digitizing is now'}
                func={
                  smanipulator.rating >= 5
                    ? '125% Efficient'
                    : (smanipulator.rating / 4) * 100 + '% Efficient'
                }
              />
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Laser">
            {slaser ? (
              <MedigunDescription
                part_1={'It has a'}
                name={slaser.name}
                part_2={'installed, and can heal'}
                func={slaser.rating + ' damage per cycle'}
                part_3={slaser.rating >= 5 ? 'and will' : undefined}
                extra={
                  slaser.rating >= 5 ? 'stop bleeding and pain' : undefined
                }
                part_4={slaser.rating >= 5 ? 'while beam is focused' : ''}
              />
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Capacitor">
            {scapacitor ? (
              <MedigunDescription
                part_1={'It has a'}
                name={scapacitor.name}
                part_2={'installed, battery charge will now drain at'}
                func={scapacitor.chargecost + ' per second'}
                part_3={
                  scapacitor.rating >= 5
                    ? 'the cell will recharge from the local power grid, it also grants a heal charge capacity of'
                    : 'and grants a heal charge capacity of'
                }
                extra={scapacitor.tankmax + ' per type'}
              />
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Capacitor">
            {sbin ? (
              <MedigunDescription
                part_1={'It has a'}
                name={sbin.name}
                part_2={'installed, can hold '}
                func={sbin.chemcap + ' reserve chems'}
                part_3={
                  sbin.rating >= 5
                    ? 'and will slowly generate chems in exchange for power'
                    : undefined
                }
              />
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>
    </Stack>
  );
};
