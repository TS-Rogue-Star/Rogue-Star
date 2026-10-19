// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Occupation //
// /////////////////////////////////////////////////////////////////////////////////

import type { CustomMarkingDesignerData } from '../types';
import type {
  OccupationCatalog,
  OccupationDraft,
  OccupationPreview,
} from '../occupationTypes';
import {
  cloneOccupationDraft,
  occupationDraftsEqual,
} from '../utils/occupation';

type SendAction = (action: string, params?: Record<string, unknown>) => void;
const REQUEST_TIMEOUT = 15000;

export class OccupationSession {
  draft: OccupationDraft | null = null;
  saved: OccupationDraft | null = null;
  catalog: OccupationCatalog | null = null;
  previews = new Map<string, OccupationPreview>();
  previewSignature = '';
  previewComplete = false;
  previewError: string | null = null;
  loading = false;
  saving = false;
  closing = false;
  error: string | null = null;
  version = 0;
  onChange = () => {};
  onSaved = () => {};
  private counter = 0;
  private contextSignature = '';
  private requestedContext: string | null = null;
  private loadRequest: string | null = null;
  private saveRequest: string | null = null;
  private previewRequest: string | null = null;
  private previewSequence = 0;
  private replaceDraft = false;
  private loadTimer: ReturnType<typeof setTimeout> | null = null;
  private saveTimer: ReturnType<typeof setTimeout> | null = null;
  private finishSave: ((accepted: boolean) => void) | null = null;

  private readonly token: string;
  private readonly act: SendAction;

  constructor(token: string, act: SendAction) {
    this.token = token;
    this.act = act;
  }

  get dirty() {
    return !!this.draft && !occupationDraftsEqual(this.draft, this.saved);
  }

  notify() {
    this.version++;
    this.onChange();
  }

  private requestId() {
    return `${this.token}-occupation-${++this.counter}-${Date.now()}`;
  }

  load(discardDraft = false) {
    if (this.loading || this.saving) {
      return;
    }
    this.loading = true;
    this.requestedContext = this.contextSignature;
    this.replaceDraft = discardDraft || !this.dirty;
    this.error = null;
    this.loadRequest = this.requestId();
    this.previewRequest = null;
    this.loadTimer = setTimeout(() => {
      this.loadRequest = null;
      this.loading = false;
      this.error = 'Occupation did not finish loading. Please try again.';
      this.notify();
    }, REQUEST_TIMEOUT);
    try {
      this.act('load_occupation', { request_id: this.loadRequest });
    } catch {
      clearTimeout(this.loadTimer);
      this.loadRequest = null;
      this.loading = false;
      this.error = 'Occupation could not be requested. Please try again.';
    }
    this.notify();
  }

  update(draft: OccupationDraft) {
    if (this.saving || this.loading || !this.draft) {
      return;
    }
    this.draft = cloneOccupationDraft(draft);
    this.notify();
  }

  save(close = false): Promise<boolean> {
    if (this.loading || this.saving || !this.draft) {
      return Promise.resolve(false);
    }
    if (!this.dirty) {
      if (close) {
        this.act('close_occupation');
      }
      return Promise.resolve(true);
    }
    this.saving = true;
    this.closing = close;
    this.error = null;
    this.saveRequest = this.requestId();
    const result = new Promise<boolean>((resolve) => {
      this.finishSave = resolve;
    });
    this.saveTimer = setTimeout(() => {
      this.completeSave(
        false,
        'The Occupation save was not confirmed. Your draft is still here; reload saved Occupation to check the result.'
      );
    }, REQUEST_TIMEOUT);
    try {
      this.act('save_occupation', {
        request_id: this.saveRequest,
        occupation: JSON.stringify(this.draft),
      });
    } catch {
      this.completeSave(
        false,
        'Occupation could not be saved. Please try again.'
      );
    }
    this.notify();
    return result;
  }

  private completeSave(accepted: boolean, error?: string) {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer);
    }
    const close = this.closing;
    const resolve = this.finishSave;
    this.saveRequest = null;
    this.finishSave = null;
    this.saving = false;
    this.closing = false;
    this.error = accepted ? null : error || 'Occupation could not be saved.';
    this.notify();
    resolve?.(accepted);
    if (accepted) {
      try {
        this.onSaved();
        if (close) {
          this.act('close_occupation');
        }
      } catch {
        this.error =
          'Occupation was saved, but the preview could not refresh. Reopen the Designer to refresh it.';
        this.notify();
      }
    }
  }

  discard(close = false) {
    if (this.saving || this.loading) {
      return;
    }
    if (this.saved) {
      this.draft = cloneOccupationDraft(this.saved);
    }
    this.error = null;
    if (close) {
      this.act('close_occupation');
    }
    this.notify();
  }

  sync(data: CustomMarkingDesignerData, ready: boolean) {
    this.contextSignature = data.occupation_context_signature || '';
    const payload = data.occupation_payload;
    if (this.loadRequest && payload?.request_id === this.loadRequest) {
      if (this.loadTimer) {
        clearTimeout(this.loadTimer);
      }
      this.loading = false;
      this.loadRequest = null;
      if (payload.values && payload.catalog && payload.context_signature) {
        this.catalog = payload.catalog;
        this.saved = cloneOccupationDraft(payload.values);
        if (this.replaceDraft) {
          this.draft = cloneOccupationDraft(payload.values);
        }
        this.requestedContext = payload.context_signature;
        this.previewSignature = payload.context_signature;
        this.previews = new Map(
          (payload.previews || []).map((preview) => [preview.key, preview])
        );
        this.previewRequest = payload.error ? null : payload.request_id;
        this.previewSequence = 0;
        this.previewComplete = !!payload.preview_complete || !!payload.error;
        this.previewError = payload.error || null;
        this.error = null;
      } else {
        this.error = payload.error || 'Occupation could not be loaded.';
      }
      this.notify();
    }
    const batch = data.occupation_preview_batch;
    if (
      batch &&
      batch.request_id === this.previewRequest &&
      batch.recipe_signature === this.previewSignature &&
      batch.recipe_signature === this.contextSignature &&
      batch.sequence > this.previewSequence
    ) {
      this.previewSequence = batch.sequence;
      for (const preview of batch.previews) {
        this.previews.set(preview.key, preview);
      }
      this.previewComplete = !!batch.complete;
      this.previewError = batch.error || null;
      this.notify();
    }
    const result = data.occupation_save_result;
    if (this.saveRequest && result?.request_id === this.saveRequest) {
      const accepted = !!result.accepted && !!result.values;
      if (accepted && result.values) {
        this.saved = cloneOccupationDraft(result.values);
        this.draft = cloneOccupationDraft(result.values);
        this.catalog = result.catalog || this.catalog;
      }
      this.completeSave(accepted, result.error);
    }
    if (
      ready &&
      !this.loading &&
      !this.saving &&
      this.requestedContext !== this.contextSignature
    ) {
      this.load();
    }
  }

  dispose() {
    for (const timer of [this.loadTimer, this.saveTimer]) {
      if (timer) {
        clearTimeout(timer);
      }
    }
    this.finishSave?.(false);
    this.finishSave = null;
    this.onChange = () => {};
    this.onSaved = () => {};
  }
}
