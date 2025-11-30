// //////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Canvas background helpers for custom marking designer //
// //////////////////////////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../../backend';
import type { CanvasBackgroundOption } from '../types';

type CanvasBackgroundParams = Readonly<{
  context: any;
  stateToken: string;
  options: CanvasBackgroundOption[];
  defaultKey: string;
}>;

export const useCanvasBackground = ({
  context,
  stateToken,
  options,
  defaultKey,
}: CanvasBackgroundParams) => {
  const [canvasBackgroundKey, setCanvasBackgroundKey] = useLocalState(
    context,
    `canvasBackground-${stateToken}`,
    defaultKey
  );

  const resolvedCanvasBackground =
    options.find((entry) => entry.id === canvasBackgroundKey) ||
    options.find((entry) => entry.id === defaultKey) ||
    options[0] ||
    null;

  const backgroundFallbackColor = (() => {
    const key = resolvedCanvasBackground?.id || defaultKey;
    if (key === 'spring') return '#6bdc6b33';
    if (key === 'summer') return '#f7d96b33';
    if (key === 'fall') return '#d98b5233';
    if (key === 'winter') return '#9bd0ff33';
    return 'rgba(18, 10, 32, 0.6)';
  })();

  const canvasBackgroundStyle = resolvedCanvasBackground?.asset?.png
    ? {
        backgroundImage: `url(data:image/png;base64,${resolvedCanvasBackground.asset.png})`,
        backgroundRepeat: 'repeat',
        backgroundPosition: 'center center',
        backgroundSize: `${resolvedCanvasBackground.asset.width || 32}px ${resolvedCanvasBackground.asset.height || 32}px`,
        backgroundColor: backgroundFallbackColor,
      }
    : {
        backgroundColor: backgroundFallbackColor,
      };

  const cycleCanvasBackground = () => {
    if (!options.length) {
      return;
    }
    const currentIndex = options.findIndex(
      (entry) =>
        entry.id === (resolvedCanvasBackground?.id || canvasBackgroundKey)
    );
    const nextIndex =
      currentIndex >= 0 && currentIndex < options.length - 1
        ? currentIndex + 1
        : 0;
    const nextEntry = options[nextIndex];
    if (!nextEntry) {
      return;
    }
    setCanvasBackgroundKey(nextEntry.id || defaultKey);
  };

  return {
    canvasBackgroundKey,
    setCanvasBackgroundKey,
    resolvedCanvasBackground,
    backgroundFallbackColor,
    canvasBackgroundStyle,
    cycleCanvasBackground,
  };
};
