import { useBackend } from '../../../backend';
import { Box, Button, LabeledList, Stack } from '../../../components';
import { ExamineData } from '../types';

export const MedigunComponents = (
  props: { examineData: ExamineData },
  context
) => {
  const { act } = useBackend(context);
  const { examineData } = props;
  const { smodule, smanipulator, slaser, scapacitor, sbin } = examineData;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <LabeledList>
          <LabeledList.Item label="Scanning Module">
            {smodule ? (
              <Button.Confirm onClick={() => act('rem_smodule')}>
                Remove Module
              </Button.Confirm>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Manipulator">
            {smanipulator ? (
              <Button.Confirm onClick={() => act('rem_mani')}>
                Remove Manipulator
              </Button.Confirm>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Laser">
            {slaser ? (
              <Button.Confirm onClick={() => act('rem_laser')}>
                Remove Laser
              </Button.Confirm>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Capacitor">
            {scapacitor ? (
              <Button.Confirm onClick={() => act('rem_cap')}>
                Remove Capacitor
              </Button.Confirm>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Matter Bin">
            {sbin ? (
              <Button.Confirm onClick={() => act('rem_bin')}>
                Remove Bin
              </Button.Confirm>
            ) : (
              <Box color="red">Missing</Box>
            )}
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>
    </Stack>
  );
};
