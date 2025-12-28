// ///////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Tool state helpers for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////

import { useLocalState } from '../../../backend';
import { PLACEHOLDER_TOOL } from '../constants';

type ToolStateParams = Readonly<{
  context: any;
  stateToken: string;
}>;

type ToolState = {
  primaryTool: string;
  setPrimaryTool: (tool: string) => void;
  secondaryTool: string | null;
  setSecondaryTool: (tool: string) => void;
  isPlaceholderTool: boolean;
  activePrimaryTool: string | null;
  activeSecondaryTool: string | null;
  toolBootstrapScheduled: boolean;
  setToolBootstrapScheduled: (scheduled: boolean) => void;
  phantomClickScheduled: boolean;
  setPhantomClickScheduled: (scheduled: boolean) => void;
  handleToolBootstrapReset: () => void;
  assignPrimaryTool: (nextTool: string) => void;
  assignSecondaryTool: (nextTool: string) => void;
  resolveToolForButton: (button?: number | null) => string;
  resolveCanvasTool: (
    toolFromCanvas?: string | null,
    button?: number | null
  ) => string;
  resolveDefaultTool: () => string;
};

export const useToolState = ({
  context,
  stateToken,
}: ToolStateParams): ToolState => {
  const [primaryTool, setPrimaryTool] = useLocalState(
    context,
    `primaryTool-${stateToken}`,
    PLACEHOLDER_TOOL
  );
  const [secondaryTool, setSecondaryTool] = useLocalState(
    context,
    `secondaryTool-${stateToken}`,
    'eraser'
  );
  const [toolBootstrapScheduled, setToolBootstrapScheduled] = useLocalState(
    context,
    `toolBootstrapScheduled-${stateToken}`,
    false
  );
  const [phantomClickScheduled, setPhantomClickScheduled] = useLocalState(
    context,
    `phantomClickScheduled-${stateToken}`,
    false
  );

  const isPlaceholderTool = primaryTool === PLACEHOLDER_TOOL;
  const activePrimaryTool = isPlaceholderTool ? null : primaryTool;
  const activeSecondaryTool =
    secondaryTool && secondaryTool !== PLACEHOLDER_TOOL ? secondaryTool : null;

  const handleToolBootstrapReset = () => {
    const shouldResetTool =
      !primaryTool ||
      primaryTool === 'brush' ||
      primaryTool === PLACEHOLDER_TOOL;
    if (!shouldResetTool) {
      if (phantomClickScheduled) {
        setPhantomClickScheduled(false);
      }
      if (!activeSecondaryTool) {
        setSecondaryTool('eraser');
      }
      return;
    }
    if (primaryTool !== PLACEHOLDER_TOOL) {
      setPrimaryTool(PLACEHOLDER_TOOL);
    }
    if (!secondaryTool || secondaryTool === PLACEHOLDER_TOOL) {
      setSecondaryTool('eraser');
    }
    if (toolBootstrapScheduled) {
      setToolBootstrapScheduled(false);
    }
    if (phantomClickScheduled) {
      setPhantomClickScheduled(false);
    }
  };

  const resolveDefaultTool = () => activePrimaryTool || 'brush';

  const resolveToolForButton = (button?: number | null) => {
    const isRightClick = button === 2;
    const fallbackTool = resolveDefaultTool();
    if (isRightClick) {
      return activeSecondaryTool || fallbackTool;
    }
    return activePrimaryTool || fallbackTool;
  };

  const resolveCanvasTool = (
    toolFromCanvas?: string | null,
    button?: number | null
  ) => {
    if (toolFromCanvas && toolFromCanvas !== PLACEHOLDER_TOOL) {
      return toolFromCanvas;
    }
    return resolveToolForButton(button);
  };

  const assignPrimaryTool = (nextTool: string) => {
    const normalized = nextTool || resolveDefaultTool();
    if (normalized === activePrimaryTool) {
      return;
    }
    if (normalized === activeSecondaryTool && activePrimaryTool) {
      setSecondaryTool(activePrimaryTool);
    }
    setPrimaryTool(normalized);
  };

  const assignSecondaryTool = (nextTool: string) => {
    const normalized = nextTool || resolveDefaultTool();
    if (normalized === activeSecondaryTool) {
      return;
    }
    if (normalized === activePrimaryTool && activeSecondaryTool) {
      setPrimaryTool(activeSecondaryTool);
    }
    setSecondaryTool(normalized);
  };

  return {
    primaryTool,
    setPrimaryTool,
    secondaryTool,
    setSecondaryTool,
    isPlaceholderTool,
    activePrimaryTool,
    activeSecondaryTool,
    toolBootstrapScheduled,
    setToolBootstrapScheduled,
    phantomClickScheduled,
    setPhantomClickScheduled,
    handleToolBootstrapReset,
    assignPrimaryTool,
    assignSecondaryTool,
    resolveToolForButton,
    resolveCanvasTool,
    resolveDefaultTool,
  };
};
