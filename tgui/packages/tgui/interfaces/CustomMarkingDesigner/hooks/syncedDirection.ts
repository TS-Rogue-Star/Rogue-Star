// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Direction sync helpers for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../../backend';

const resolveCurrentDirectionKey = (
  serverDirection: number,
  uiDirection: number | undefined,
  snapshot: number,
  setSnapshot: (dir: number) => void,
  setUiDirection: (dir: number) => void
): number => {
  if (snapshot !== serverDirection) {
    setSnapshot(serverDirection);
    if (typeof uiDirection !== 'number' || uiDirection === snapshot) {
      setUiDirection(serverDirection);
      return serverDirection;
    }
  }
  return typeof uiDirection === 'number' ? uiDirection : serverDirection;
};

export const useSyncedDirectionState = (
  context: any,
  sessionToken: string | null,
  serverDirection: number
) => {
  const directionStateKey = `uiDirection-${sessionToken || 'session'}`;
  const [uiDirectionKey, setUiDirectionKey] = useLocalState(
    context,
    directionStateKey,
    serverDirection
  );
  const directionSnapshotKey = `serverDirectionSnapshot-${
    sessionToken || 'session'
  }`;
  const [serverDirectionSnapshot, setServerDirectionSnapshot] = useLocalState(
    context,
    directionSnapshotKey,
    serverDirection
  );
  const currentDirectionKey = resolveCurrentDirectionKey(
    serverDirection,
    uiDirectionKey,
    serverDirectionSnapshot,
    setServerDirectionSnapshot,
    setUiDirectionKey
  );
  return {
    currentDirectionKey,
    setUiDirectionKey,
  };
};
