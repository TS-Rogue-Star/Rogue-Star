// ////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Pet Register Interface //
// ////////////////////////////////////////////////////////////////////////

import { Box, Icon } from '../../components';

export const PetRegisterOpening = () => (
  <Box className="PetRegister__opening" aria-hidden="true">
    <Box className="PetRegister__openingScene">
      <Box className="PetRegister__openingTag">
        <Icon name="paw" />
      </Box>
      <Box className="PetRegister__openingTitle">PET System</Box>
      <Box className="PetRegister__openingSubtitle">Opening pet registry</Box>
      <Box className="PetRegister__openingTrail">
        {Array.from({ length: 6 }, (_, step) => (
          <Box
            key={step}
            className="PetRegister__openingStep"
            style={{ 'animation-delay': `${0.25 + step * 0.2}s` }}>
            <Icon name="paw" />
          </Box>
        ))}
      </Box>
    </Box>
  </Box>
);
