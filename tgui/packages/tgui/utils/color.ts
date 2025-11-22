// /////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Color utilities for TGUI //
// /////////////////////////////////////////////////////////////////////////

import { clamp01 } from 'common/math';

export type RgbTuple = [number, number, number];

export type HsvColor = {
  h: number;
  s: number;
  v: number;
};

export type HslColor = {
  h: number;
  s: number;
  l: number;
};

export const TRANSPARENT_HEX = '#00000000';

type NormalizeHexOptions = {
  preserveTransparent?: boolean;
};

const HEX_PATTERN = /^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/;

const clampChannel = (value: number): number =>
  Math.round(Math.min(255, Math.max(0, Number.isFinite(value) ? value : 0)));

const normalizeShortHex = (value: string): string =>
  `#${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}`;

export const normalizeHex = (
  value?: string | null,
  options?: NormalizeHexOptions
): string | null => {
  if (!value || typeof value !== 'string') {
    return null;
  }
  let hex = value.trim().toLowerCase();
  if (!hex.length) {
    return null;
  }
  if (!hex.startsWith('#')) {
    hex = `#${hex}`;
  }
  if (!HEX_PATTERN.test(hex)) {
    return null;
  }
  if (hex.length === 4) {
    return normalizeShortHex(hex);
  }
  if (hex.length === 9) {
    if (hex === TRANSPARENT_HEX && !options?.preserveTransparent) {
      return null;
    }
    return hex.slice(0, 7);
  }
  return hex;
};

export const formatHex = (hex: string | null | undefined): string =>
  (hex || '#000000').toUpperCase();

export const hexToRgb = (hex: string): RgbTuple | null => {
  const normalized = normalizeHex(hex, { preserveTransparent: true });
  if (!normalized || normalized.length < 7) {
    return null;
  }
  const r = parseInt(normalized.slice(1, 3), 16);
  const g = parseInt(normalized.slice(3, 5), 16);
  const b = parseInt(normalized.slice(5, 7), 16);
  if ([r, g, b].some((component) => Number.isNaN(component))) {
    return null;
  }
  return [r, g, b];
};

export const rgbToHex = (r: number, g: number, b: number): string =>
  `#${clampChannel(r)
    .toString(16)
    .padStart(2, '0')}${clampChannel(g)
    .toString(16)
    .padStart(2, '0')}${clampChannel(b)
    .toString(16)
    .padStart(2, '0')}`;

const normalizeHue = (h: number): number => {
  if (!Number.isFinite(h)) {
    return 0;
  }
  return ((h % 360) + 360) % 360;
};

export const rgbToHsv = (r: number, g: number, b: number): HsvColor => {
  const rn = clampChannel(r) / 255;
  const gn = clampChannel(g) / 255;
  const bn = clampChannel(b) / 255;
  const max = Math.max(rn, gn, bn);
  const min = Math.min(rn, gn, bn);
  const delta = max - min;
  let h = 0;
  if (delta !== 0) {
    switch (max) {
      case rn:
        h = ((gn - bn) / delta) % 6;
        break;
      case gn:
        h = (bn - rn) / delta + 2;
        break;
      default:
        h = (rn - gn) / delta + 4;
        break;
    }
    h *= 60;
  }
  const s = max === 0 ? 0 : delta / max;
  const v = max;
  return {
    h: normalizeHue(h),
    s: clamp01(s),
    v: clamp01(v),
  };
};

export const hsvToRgb = (h: number, s: number, v: number): RgbTuple => {
  const hue = normalizeHue(h);
  const sat = clamp01(s);
  const val = clamp01(v);
  const c = val * sat;
  const hp = hue / 60;
  const x = c * (1 - Math.abs((hp % 2) - 1));
  let r1 = 0;
  let g1 = 0;
  let b1 = 0;
  if (hp >= 0 && hp < 1) {
    r1 = c;
    g1 = x;
  } else if (hp >= 1 && hp < 2) {
    r1 = x;
    g1 = c;
  } else if (hp >= 2 && hp < 3) {
    g1 = c;
    b1 = x;
  } else if (hp >= 3 && hp < 4) {
    g1 = x;
    b1 = c;
  } else if (hp >= 4 && hp < 5) {
    r1 = x;
    b1 = c;
  } else {
    r1 = c;
    b1 = x;
  }
  const m = val - c;
  return [
    clampChannel((r1 + m) * 255),
    clampChannel((g1 + m) * 255),
    clampChannel((b1 + m) * 255),
  ];
};

export const rgbToHsl = (r: number, g: number, b: number): HslColor => {
  const rn = clampChannel(r) / 255;
  const gn = clampChannel(g) / 255;
  const bn = clampChannel(b) / 255;
  const max = Math.max(rn, gn, bn);
  const min = Math.min(rn, gn, bn);
  const delta = max - min;
  let h = 0;
  if (delta !== 0) {
    switch (max) {
      case rn:
        h = ((gn - bn) / delta) % 6;
        break;
      case gn:
        h = (bn - rn) / delta + 2;
        break;
      default:
        h = (rn - gn) / delta + 4;
        break;
    }
    h *= 60;
  }
  const l = (max + min) / 2;
  const s = delta === 0 ? 0 : delta / (1 - Math.abs(2 * l - 1));
  return {
    h: normalizeHue(h),
    s: clamp01(s),
    l: clamp01(l),
  };
};

export const hslToRgb = (h: number, s: number, l: number): RgbTuple => {
  const hue = normalizeHue(h);
  const sat = clamp01(s);
  const lum = clamp01(l);
  const c = (1 - Math.abs(2 * lum - 1)) * sat;
  const hp = hue / 60;
  const x = c * (1 - Math.abs((hp % 2) - 1));
  let r1 = 0;
  let g1 = 0;
  let b1 = 0;
  if (hp >= 0 && hp < 1) {
    r1 = c;
    g1 = x;
  } else if (hp >= 1 && hp < 2) {
    r1 = x;
    g1 = c;
  } else if (hp >= 2 && hp < 3) {
    g1 = c;
    b1 = x;
  } else if (hp >= 3 && hp < 4) {
    g1 = x;
    b1 = c;
  } else if (hp >= 4 && hp < 5) {
    r1 = x;
    b1 = c;
  } else {
    r1 = c;
    b1 = x;
  }
  const m = lum - c / 2;
  return [
    clampChannel((r1 + m) * 255),
    clampChannel((g1 + m) * 255),
    clampChannel((b1 + m) * 255),
  ];
};

export const srgbToLinear = (value: number, eps = 0): number => {
  const clamped = Math.max(eps, clamp01(value));
  if (clamped <= 0.04045) {
    return clamped / 12.92;
  }
  return ((clamped + 0.055) / 1.055) ** 2.4;
};

export const linearToSrgb = (value: number): number => {
  if (value <= 0) {
    return 0;
  }
  if (value < 0.0031308) {
    return 12.92 * value;
  }
  return 1.055 * value ** (1 / 2.4) - 0.055;
};

export const blendAdd = (baseHex: string, addHex: string): string | null => {
  const base = hexToRgb(baseHex);
  const add = hexToRgb(addHex);
  if (!base || !add) {
    return null;
  }
  return rgbToHex(
    Math.min(255, base[0] + add[0]),
    Math.min(255, base[1] + add[1]),
    Math.min(255, base[2] + add[2])
  );
};

export const blendMultiply = (
  baseHex: string,
  mulHex: string
): string | null => {
  const base = hexToRgb(baseHex);
  const mul = hexToRgb(mulHex);
  if (!base || !mul) {
    return null;
  }
  return rgbToHex(
    Math.round((base[0] * mul[0]) / 255),
    Math.round((base[1] * mul[1]) / 255),
    Math.round((base[2] * mul[2]) / 255)
  );
};

export const mixColors = (
  baseHex: string,
  topHex: string,
  weight: number
): string | null => {
  const base = hexToRgb(baseHex);
  const top = hexToRgb(topHex);
  if (!base || !top) {
    return null;
  }
  const clamped = clamp01(weight);
  const mixChannel = (baseChannel: number, topChannel: number) => {
    const baseLinear = srgbToLinear(baseChannel / 255);
    const topLinear = srgbToLinear(topChannel / 255);
    const mixedLinear = baseLinear + (topLinear - baseLinear) * clamped;
    return Math.round(linearToSrgb(mixedLinear) * 255);
  };
  return rgbToHex(
    mixChannel(base[0], top[0]),
    mixChannel(base[1], top[1]),
    mixChannel(base[2], top[2])
  );
};

export const blendAnalog = (
  baseHex: string,
  mixHex: string,
  weight: number
): string | null => {
  const base = hexToRgb(baseHex);
  const mix = hexToRgb(mixHex);
  if (!base || !mix) {
    return mixHex;
  }
  const clamped = clamp01(weight);
  const iw = 1 - clamped;
  const eps = 0.001;
  const rm =
    Math.pow(srgbToLinear(base[0] / 255, eps), iw) *
    Math.pow(srgbToLinear(mix[0] / 255, eps), clamped);
  const gm =
    Math.pow(srgbToLinear(base[1] / 255, eps), iw) *
    Math.pow(srgbToLinear(mix[1] / 255, eps), clamped);
  const bm =
    Math.pow(srgbToLinear(base[2] / 255, eps), iw) *
    Math.pow(srgbToLinear(mix[2] / 255, eps), clamped);
  return rgbToHex(
    Math.round(linearToSrgb(rm) * 255),
    Math.round(linearToSrgb(gm) * 255),
    Math.round(linearToSrgb(bm) * 255)
  );
};

export const resolvePixelColorFromHex = (
  oldColor: string | null,
  newHex: string | null,
  mode: string,
  strength: number,
  fallbackColor: string | null
): string | null => {
  if (mode === 'erase' || !newHex) {
    return null;
  }
  let baseHex = normalizeHex(oldColor);
  if (!baseHex && fallbackColor) {
    baseHex = normalizeHex(fallbackColor);
  }
  if (!baseHex) {
    baseHex = newHex;
  }
  const weight = clamp01(strength);
  switch (mode) {
    case 'add': {
      const added = blendAdd(baseHex, newHex) || newHex;
      const mixed = mixColors(baseHex, added, weight);
      return mixed || added;
    }
    case 'multiply': {
      const mult = blendMultiply(baseHex, newHex) || newHex;
      const mixed2 = mixColors(baseHex, mult, weight);
      return mixed2 || mult;
    }
    case 'analog':
      return blendAnalog(baseHex, newHex, weight);
    default:
      return newHex;
  }
};
