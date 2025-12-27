// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Helpers for TGUI window scaling //
// ////////////////////////////////////////////////////////////////////////////////

export const DEFAULT_TGUI_UI_SCALE = 1;

export const getTguiUiScale = (): number => {
  if (typeof document === 'undefined') {
    return DEFAULT_TGUI_UI_SCALE;
  }

  const raw = document.documentElement?.dataset?.tguiScale;
  const parsed = raw ? Number(raw) : DEFAULT_TGUI_UI_SCALE;
  if (!isFinite(parsed) || parsed <= 0) {
    return DEFAULT_TGUI_UI_SCALE;
  }
  return parsed;
};

export const tguiScalePopperModifier: any = {
  name: 'tguiScale',
  enabled: true,
  phase: 'beforeWrite',
  requires: ['computeStyles'],
  fn({ state }: { state: any }) {
    const scale = getTguiUiScale();
    if (scale === DEFAULT_TGUI_UI_SCALE) {
      return;
    }
    if (!state.styles) {
      return;
    }
    if (!state.styles.popper) {
      state.styles.popper = {};
    }
    const baseTransform = state.styles.popper.transform;
    const scaleTransform = `scale(${scale})`;
    state.styles.popper.transform = baseTransform
      ? `${baseTransform} ${scaleTransform}`
      : scaleTransform;
    state.styles.popper.transformOrigin = 'top left';
  },
};
