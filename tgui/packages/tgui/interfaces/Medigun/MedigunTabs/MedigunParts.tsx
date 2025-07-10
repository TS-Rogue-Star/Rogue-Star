import { Box, LabeledList, Stack } from '../../../components';
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
              <Box>
                {'It has a ' +
                  smodule.name +
                  ' installed, device will function within ' +
                  smodule.range +
                  ' tiles'}
                {smodule.rating >= 5 ? ' and' : undefined}
                {smodule.rating >= 5 ? ' through walls' : undefined}
                {'.'}
              </Box>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Manipulator">
            {smanipulator ? (
              <Box>
                {'It has a ' +
                  smanipulator.name +
                  ' installed, chem digitizing is now '}
                {smanipulator.rating >= 5
                  ? '125% Efficient'
                  : (smanipulator.rating / 4) * 100 + '% Efficient'}
                {'.'}
              </Box>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Laser">
            {slaser ? (
              <Box>
                {'It has a ' +
                  slaser.name +
                  ' installed, and can heal ' +
                  slaser.rating +
                  ' damage per cycle '}
                {slaser.rating >= 5 ? ' and will' : undefined}
                {slaser.rating >= 5 ? ' stop bleeding and pain' : undefined}
                {slaser.rating >= 5 ? ' while beam is focused' : ''}
                {'.'}
              </Box>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Capacitor">
            {scapacitor ? (
              <Box>
                {'It has a ' +
                  scapacitor.name +
                  ' installed, battery charge will now drain at ' +
                  scapacitor.chargecost +
                  ' per second '}
                {scapacitor.rating >= 5
                  ? ' the cell will recharge from the local power grid, it also grants a heal charge capacity of '
                  : ' and grants a heal charge capacity of '}
                {scapacitor.tankmax + ' per type'}
                {'.'}
              </Box>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Capacitor">
            {sbin ? (
              <Box>
                {'It has a ' +
                  sbin.name +
                  ' installed, can hold ' +
                  sbin.chemcap +
                  ' reserve chems '}
                {sbin.rating >= 5
                  ? 'and will slowly generate chems in exchange for power'
                  : undefined}
                {'.'}
              </Box>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>
    </Stack>
  );
};
