import { Box, LabeledList, ProgressBar, Stack } from '../../../components';

export const ChargeStatus = (
  props: {
    name: string;
    color: string;
    charge: number | null;
    volume: number | null;
  },
  context
) => {
  const { name, color, charge, volume } = props;

  return (
    <LabeledList.Item label={name}>
      <Stack>
        <Stack.Item grow>
          {charge !== null ? (
            <ProgressBar color={color} value={charge} />
          ) : (
            <Box color="red">Missing Capacitor</Box>
          )}
        </Stack.Item>
        <Stack.Item>
          <Box color="label">Reserve:</Box>
        </Stack.Item>
        <Stack.Item basis="10%">
          {volume !== null ? (
            <Box color={color} bold>
              {volume}
            </Box>
          ) : (
            <Box color="red">Missing Bin</Box>
          )}
        </Stack.Item>
      </Stack>
    </LabeledList.Item>
  );
};
