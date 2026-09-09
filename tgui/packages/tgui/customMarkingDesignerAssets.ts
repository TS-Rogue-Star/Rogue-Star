// ///////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star August 2026: Manage character designer assets //
// ///////////////////////////////////////////////////////////////////////////////

import type { Action, AnyAction, Dispatch, Middleware } from 'common/redux';

import {
  isStaticIconAssetRegistryLoaded,
  loadStaticIconAssetRegistry,
  registerStaticIconAssetRegistry,
  type IconAssetRegistryAsset,
} from './utils/character-preview';

const DESIGNER_INTERFACE = 'CustomMarkingDesigner';

const getManifestReference = (
  action: AnyAction
): IconAssetRegistryAsset | null => {
  const reference = action.payload?.static_data?.static_asset_manifest;
  if (
    !reference ||
    typeof reference.asset !== 'string' ||
    !reference.asset ||
    typeof reference.revision !== 'number'
  ) {
    return null;
  }
  return reference;
};

const getManifestKey = (reference: IconAssetRegistryAsset) =>
  `${reference.revision}:${reference.asset}`;

const withManifestError = (action: AnyAction, error: string | null) => ({
  ...action,
  payload: {
    ...action.payload,
    static_data: {
      ...action.payload?.static_data,
      static_asset_manifest_error: error,
    },
  },
});

const formatManifestError = (error: unknown) =>
  error instanceof Error ? error.message : 'The atlas registry request failed.';

export const customMarkingDesignerAssetMiddleware: Middleware =
  (_store) =>
  <ActionType extends Action = AnyAction>(next: Dispatch<ActionType>) => {
    let pendingKey: string | null = null;
    let pendingSequence = 0;
    let pendingActions: ActionType[] = [];

    const clearPending = () => {
      pendingKey = null;
      pendingActions = [];
    };

    return (rawAction: ActionType) => {
      const action = rawAction as AnyAction;
      if (action.type !== 'update') {
        if (action.type === 'suspend' && pendingKey) {
          pendingSequence++;
          clearPending();
        }
        return next(rawAction);
      }

      const interfaceName = action.payload?.config?.interface;
      if (interfaceName !== DESIGNER_INTERFACE) {
        if (pendingKey) {
          pendingSequence++;
          clearPending();
        }
        return next(rawAction);
      }

      const reference = getManifestReference(action);
      if (pendingKey) {
        if (!reference || getManifestKey(reference) === pendingKey) {
          pendingActions.push(rawAction);
          return;
        }
        pendingSequence++;
        clearPending();
      }

      if (!reference) {
        return next(rawAction);
      }

      if (isStaticIconAssetRegistryLoaded(reference)) {
        return next(withManifestError(action, null) as unknown as ActionType);
      }

      const key = getManifestKey(reference);
      const sequence = ++pendingSequence;
      pendingKey = key;
      pendingActions = [rawAction];
      loadStaticIconAssetRegistry(reference).then(
        (registry) => {
          if (sequence !== pendingSequence || pendingKey !== key) {
            return;
          }
          const actions = pendingActions;
          clearPending();
          registerStaticIconAssetRegistry(registry, reference.asset);
          actions.forEach((queuedAction, index) =>
            next(
              index === 0
                ? (withManifestError(
                    queuedAction as AnyAction,
                    null
                  ) as unknown as ActionType)
                : queuedAction
            )
          );
        },
        (error) => {
          if (sequence !== pendingSequence || pendingKey !== key) {
            return;
          }
          const actions = pendingActions;
          clearPending();
          actions.forEach((queuedAction, index) =>
            next(
              index === 0
                ? (withManifestError(
                    queuedAction as AnyAction,
                    formatManifestError(error)
                  ) as unknown as ActionType)
                : queuedAction
            )
          );
        }
      );
    };
  };
