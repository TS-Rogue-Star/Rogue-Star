// ////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Draft store helpers for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////

import { backendSetSharedState, selectBackend } from '../../../backend';
import type { StrokeDraftState } from '../types';

export const getStoredStrokeDraftsFromStore = (
  store: any
): StrokeDraftState => {
  const backendState = selectBackend(store.getState());
  const sharedStates = backendState.shared || {};
  const drafts = sharedStates.strokeDrafts;
  if (drafts && typeof drafts === 'object') {
    return drafts as StrokeDraftState;
  }
  return {};
};

export const updateStrokeDraftsInStore = (
  store: any,
  updater: (prev: StrokeDraftState) => StrokeDraftState
) => {
  const snapshot = getStoredStrokeDraftsFromStore(store);
  const next = updater(snapshot);
  if (next === snapshot) {
    return;
  }
  store.dispatch(
    backendSetSharedState({
      key: 'strokeDrafts',
      nextState: next,
    })
  );
};

export const clearAllLocalDraftsInStore = (store: any) => {
  updateStrokeDraftsInStore(store, (prev) => {
    if (!prev || !Object.keys(prev).length) {
      return prev;
    }
    return {};
  });
};
