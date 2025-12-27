// //////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Helper to normalize basic appearence data //
// //////////////////////////////////////////////////////////////////////////////////////////

import { normalizeHex } from '../../../utils/color';
import type { BasicAppearancePayload, BasicAppearanceState } from '../types';

export const buildBasicStateFromPayload = (
  payload?: BasicAppearancePayload | null
): BasicAppearanceState => {
  const rawGradientStyle =
    typeof payload?.hair_gradient_style === 'string'
      ? payload.hair_gradient_style.trim()
      : '';
  const digitigradeAllowed = payload?.digitigrade_allowed !== false;
  return {
    digitigrade: digitigradeAllowed && !!payload?.digitigrade,
    body_color: payload?.body_color ? normalizeHex(payload.body_color) : null,
    eye_color: payload?.eye_color ? normalizeHex(payload.eye_color) : null,
    hair_style:
      typeof payload?.hair_style === 'string' && payload.hair_style.length
        ? payload.hair_style
        : null,
    hair_color: payload?.hair_color ? normalizeHex(payload.hair_color) : null,
    hair_gradient_style:
      rawGradientStyle.length && rawGradientStyle.toLowerCase() !== 'none'
        ? rawGradientStyle
        : null,
    hair_gradient_color: payload?.hair_gradient_color
      ? normalizeHex(payload.hair_gradient_color)
      : null,
    facial_hair_style:
      typeof payload?.facial_hair_style === 'string' &&
      payload.facial_hair_style.length
        ? payload.facial_hair_style
        : null,
    facial_hair_color: payload?.facial_hair_color
      ? normalizeHex(payload.facial_hair_color)
      : null,
    ear_style:
      typeof payload?.ear_style === 'string' && payload.ear_style.length
        ? payload.ear_style
        : null,
    ear_colors: Array.isArray(payload?.ear_colors)
      ? (payload?.ear_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [null, null, null],
    horn_style:
      typeof payload?.horn_style === 'string' && payload.horn_style.length
        ? payload.horn_style
        : null,
    horn_colors: Array.isArray(payload?.horn_colors)
      ? (payload?.horn_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [],
    tail_style:
      typeof payload?.tail_style === 'string' && payload.tail_style.length
        ? payload.tail_style
        : null,
    tail_colors: Array.isArray(payload?.tail_colors)
      ? (payload?.tail_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [null, null, null],
    wing_style:
      typeof payload?.wing_style === 'string' && payload.wing_style.length
        ? payload.wing_style
        : null,
    wing_colors: Array.isArray(payload?.wing_colors)
      ? (payload?.wing_colors || []).map((color) =>
          color ? normalizeHex(color) : null
        )
      : [null, null, null],
  };
};
