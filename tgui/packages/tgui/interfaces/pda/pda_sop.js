// ////////////////////////////////////////////////////////
// Created by Lira for Rogue Star February 2026: SOP App //
// ////////////////////////////////////////////////////////

import { useBackend } from '../../backend';
import { Box, NoticeBox } from '../../components';

export const pda_sop = (props, context) => {
  const { data } = useBackend(context);
  const { sop_url } = data;

  if (!sop_url) {
    return (
      <NoticeBox danger>
        SOP wiki URL is not configured. Contact an admin.
      </NoticeBox>
    );
  }

  return (
    <Box backgroundColor="white">
      <Box fontSize="12px" italic mb={1} textAlign="center" color="gray">
        Penned by Huuuk Furok.
      </Box>
      <iframe
        title="Standard Operating Procedure"
        src={sop_url}
        style={{
          width: '100%',
          height: '465px',
          border: '0',
          backgroundColor: 'white',
        }}
      />
    </Box>
  );
};
