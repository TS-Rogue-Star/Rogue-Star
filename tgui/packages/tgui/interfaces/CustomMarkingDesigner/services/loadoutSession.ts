// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
// //////////////////////////////////////////////////////////////////////////////

import type { CustomMarkingDesignerData } from '../types';
import type {
  LoadoutCatalog,
  LoadoutDraft,
  LoadoutTweak,
  LoadoutValue,
  LoadoutVariant,
} from '../loadoutTypes';
import {
  buildLoadoutSave,
  cloneLoadout,
  loadoutsEqual,
  loadoutValidationError,
  tweakValue,
} from '../utils/loadout';

type SendAction = (action: string, params?: Record<string, unknown>) => void;
const TIMEOUT = 45000;

export class LoadoutSession {
  draft: LoadoutDraft | null = null;
  saved: LoadoutDraft | null = null;
  catalog: LoadoutCatalog | null = null;
  loading = false;
  previewsLoading = false;
  previewError: string | null = null;
  saving = false;
  closing = false;
  error: string | null = null;
  version = 0;
  onChange = () => {};
  onSaved = () => {};
  private counter = 0;
  private context = '';
  private loadedContext: string | null = null;
  private request: string | null = null;
  private replaceDraft = false;
  private timer: ReturnType<typeof setTimeout> | null = null;
  private previewTimer: ReturnType<typeof setTimeout> | null = null;
  private previewRequest: string | null = null;
  private previewSignature = '';
  private previewSequence = 0;
  private completion: ((accepted: boolean) => void) | null = null;
  private textListeners = new Set<() => void>();

  private readonly token: string;
  private readonly act: SendAction;

  constructor(token: string, act: SendAction) {
    this.token = token;
    this.act = act;
  }

  get dirty() {
    return !!this.draft && !loadoutsEqual(this.draft, this.saved);
  }
  get validationError() {
    if (!this.draft || !this.saved || !this.catalog) {
      return null;
    }
    return loadoutValidationError(
      { ...this.draft, slots: buildLoadoutSave(this.draft, this.saved).slots },
      this.catalog,
      this.saved
    );
  }
  notify() {
    this.version++;
    this.onChange();
  }
  private requestId() {
    return `${this.token}-loadout-${++this.counter}-${Date.now()}`;
  }
  private clearTimer() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }

  private stopPreviews() {
    if (this.previewTimer) {
      clearTimeout(this.previewTimer);
      this.previewTimer = null;
    }
    this.previewRequest = null;
    this.previewsLoading = false;
  }

  private waitForPreviews() {
    if (this.previewTimer) {
      clearTimeout(this.previewTimer);
    }
    this.previewTimer = setTimeout(() => {
      this.stopPreviews();
      this.previewError =
        'Some Loadout previews did not finish loading. Retry previews to continue.';
      this.notify();
    }, TIMEOUT);
  }

  load(discard = false) {
    if (this.loading || this.saving) {
      return;
    }
    this.loading = true;
    this.stopPreviews();
    this.previewError = null;
    this.loadedContext = this.context;
    this.replaceDraft = discard || !this.dirty;
    this.error = null;
    this.request = this.requestId();
    this.timer = setTimeout(() => {
      this.request = null;
      this.loading = false;
      this.error = 'Loadout did not finish loading. Please try again.';
      this.notify();
    }, TIMEOUT);
    try {
      this.act('load_loadout', { request_id: this.request });
    } catch {
      this.clearTimer();
      this.request = null;
      this.loading = false;
      this.error = 'Loadout could not be requested. Please try again.';
    }
    this.notify();
  }

  update(draft: LoadoutDraft) {
    if (this.loading || this.saving || !this.draft) {
      return;
    }
    this.draft = cloneLoadout(draft);
    this.notify();
  }

  subscribeTextChanges(listener: () => void) {
    this.textListeners.add(listener);
    return () => this.textListeners.delete(listener);
  }

  updateTweak(itemId: string, tweak: LoadoutTweak, value: LoadoutValue) {
    if (this.loading || this.saving || !this.draft || tweak.disabled) {
      return;
    }
    const draft = this.draft;
    const items = draft.slots[draft.active] || [];
    const item = items.find((entry) => entry.id === itemId);
    if (!item || tweakValue(item, tweak) === value) {
      return;
    }
    const updated = {
      ...item,
      tweaks: {
        ...item.tweaks,
        [tweak.id]: Array.isArray(value) ? [...value] : value,
      },
    };
    this.draft = {
      ...draft,
      slots: {
        ...draft.slots,
        [draft.active]: items.map((entry) =>
          entry === item ? updated : entry
        ),
      },
    };
    if (tweak.kind === 'text') {
      this.textListeners.forEach((listener) => listener());
    } else {
      this.notify();
    }
  }

  save(close = false): Promise<boolean> {
    if (
      this.loading ||
      this.saving ||
      !this.draft ||
      !this.saved ||
      !this.catalog
    ) {
      return Promise.resolve(false);
    }
    if (!this.dirty) {
      if (close) {
        this.act('close_loadout');
      }
      return Promise.resolve(true);
    }
    this.error = this.validationError;
    const request = this.requestId();
    const params = {
      request_id: request,
      loadout: JSON.stringify(buildLoadoutSave(this.draft, this.saved)),
    };
    if (
      encodeURIComponent(JSON.stringify({ action: 'save_loadout', ...params }))
        .length > 500000
    ) {
      this.error =
        'This loadout is too large to send. Shorten custom descriptions and try again.';
    }
    if (this.error) {
      this.notify();
      return Promise.resolve(false);
    }
    this.saving = true;
    this.closing = close;
    this.request = request;
    const result = new Promise<boolean>((resolve) => {
      this.completion = resolve;
    });
    this.timer = setTimeout(
      () =>
        this.finish(
          false,
          'The Loadout save was not confirmed. Your draft is still here; reload saved Loadout to check the result.'
        ),
      TIMEOUT
    );
    try {
      this.act('save_loadout', params);
    } catch {
      this.finish(false, 'Loadout could not be saved. Please try again.');
    }
    this.notify();
    return result;
  }

  private finish(accepted: boolean, error?: string) {
    this.clearTimer();
    const close = this.closing;
    const completion = this.completion;
    this.request = null;
    this.completion = null;
    this.saving = false;
    this.closing = false;
    this.error = accepted ? null : error || 'Loadout could not be saved.';
    this.notify();
    completion?.(accepted);
    if (accepted) {
      try {
        this.onSaved();
      } catch {
        this.error = 'Loadout saved, but the other previews could not refresh.';
        this.notify();
      }
      if (close) {
        this.act('close_loadout');
      }
    }
  }

  discard(close = false) {
    if (this.saving) {
      return;
    }
    if (this.saved) {
      this.draft = cloneLoadout(this.saved);
    }
    this.error = null;
    if (close) {
      this.act('close_loadout');
    }
    this.notify();
  }

  sync(data: CustomMarkingDesignerData, ready: boolean) {
    this.context = data.loadout_context_signature || '';
    if (this.loading && this.loadedContext !== this.context) {
      this.clearTimer();
      this.request = null;
      this.loading = false;
      this.loadedContext = null;
    }
    if (
      this.previewRequest &&
      data.loadout_recipe_signature &&
      data.loadout_recipe_signature !== this.previewSignature
    ) {
      this.stopPreviews();
      this.notify();
    }
    const payload = data.loadout_payload;
    if (this.loading && this.request && payload?.request_id === this.request) {
      this.clearTimer();
      this.loading = false;
      const loadRequest = this.request;
      this.request = null;
      if (
        payload.values &&
        payload.catalog &&
        !payload.error &&
        (!payload.context_signature ||
          payload.context_signature === this.context)
      ) {
        this.catalog = payload.catalog;
        this.saved = cloneLoadout(payload.values);
        if (this.replaceDraft) {
          this.draft = cloneLoadout(payload.values);
        }
        this.loadedContext = this.context;
        this.error = null;
        this.previewsLoading = payload.catalog.items.some((gear) =>
          gear.variants.some((variant) => !!variant.preview_pending)
        );
        if (this.previewsLoading) {
          this.previewRequest = loadRequest;
          this.previewSignature = payload.recipe_signature || '';
          this.previewSequence = 0;
          this.waitForPreviews();
        }
      } else {
        this.error = payload.error || 'Loadout could not be loaded.';
      }
      this.notify();
    }
    const batch = data.loadout_preview_batch;
    if (
      this.catalog &&
      this.previewRequest &&
      batch?.request_id === this.previewRequest &&
      batch.recipe_signature === this.previewSignature &&
      batch.sequence > this.previewSequence
    ) {
      if (batch.sequence !== this.previewSequence + 1) {
        this.stopPreviews();
        this.previewError =
          'Some Loadout previews were not received. Retry previews to continue.';
      } else {
        this.previewSequence = batch.sequence;
        const updates = new Map<string, Map<string, LoadoutVariant>>();
        for (const { gear_id, variant } of batch.previews) {
          let variants = updates.get(gear_id);
          if (!variants) {
            variants = new Map();
            updates.set(gear_id, variants);
          }
          variants.set(variant.id, variant);
        }
        this.catalog = {
          ...this.catalog,
          items: this.catalog.items.map((gear) => {
            const variants = updates.get(gear.id);
            return variants
              ? {
                  ...gear,
                  variants: gear.variants.map(
                    (variant) => variants.get(variant.id) || variant
                  ),
                }
              : gear;
          }),
        };
        if (batch.complete || batch.error) {
          this.stopPreviews();
          this.previewError = batch.error || null;
        } else {
          this.waitForPreviews();
        }
      }
      this.notify();
    }
    const result = data.loadout_save_result;
    if (this.saving && this.request && result?.request_id === this.request) {
      const accepted = !!result.accepted && !!result.values;
      if (accepted && result.values) {
        this.saved = cloneLoadout(result.values);
        this.draft = cloneLoadout(result.values);
        this.loadedContext = this.context;
        if (this.catalog && result.gear) {
          this.catalog = { ...this.catalog, gear: result.gear };
        }
      }
      this.finish(accepted, result.error);
    }
    if (
      ready &&
      !this.loading &&
      !this.saving &&
      !this.dirty &&
      this.loadedContext !== this.context
    ) {
      this.load();
    }
  }

  dispose() {
    this.clearTimer();
    this.stopPreviews();
    this.completion?.(false);
    this.completion = null;
    this.onChange = () => {};
    this.onSaved = () => {};
    this.textListeners.clear();
  }
}
