import { Fragment } from 'inferno';
import { Box } from '../../../components';

export const MedigunDescription = (
  props: {
    part_1: string;
    name: string;
    part_2: string;
    func: string | number;
    part_3?: string;
    extra?: string;
    part_4?: string;
  },
  context
) => {
  const { part_1, name, part_2, func, part_3, extra, part_4 } = props;

  return (
    <Box inline>
      <Box inline>{part_1}</Box>{' '}
      <Box inline color="green">
        {name}
      </Box>{' '}
      <Box inline>{part_2}</Box>{' '}
      <Box inline color="green">
        {func}
      </Box>
      {!!part_3 && (
        <Fragment>
          {' '}
          <Box inline>{part_3}</Box>
        </Fragment>
      )}
      {!!extra && (
        <Fragment>
          {' '}
          <Box inline color="green">
            {extra}
          </Box>
        </Fragment>
      )}
      {!!part_4 && (
        <Fragment>
          {' '}
          <Box inline>{part_4}</Box>
        </Fragment>
      )}
      {'.'}
    </Box>
  );
};
