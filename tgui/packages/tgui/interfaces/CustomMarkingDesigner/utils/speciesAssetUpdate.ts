// ///////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Character Designer species asset updates //
// ///////////////////////////////////////////////////////////////////////////////////////

import { backendSetSharedStates, selectBackend } from '../../../backend';

export const advanceSpeciesAssetRevision = (store: any) => {
  const sharedState = selectBackend(store.getState()).shared || {};
  const currentRevision = sharedState.speciesAssetRevision;
  store.dispatch(
    backendSetSharedStates({
      states: {
        speciesAssetRevision:
          ((typeof currentRevision === 'number' ? currentRevision : 0) + 1) %
          1000000,
      },
    })
  );
};
