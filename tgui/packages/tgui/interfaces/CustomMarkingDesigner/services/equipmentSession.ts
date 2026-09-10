// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Equipment //
// ////////////////////////////////////////////////////////////////////////////////

import type {
  CustomMarkingDesignerData,
  EquipmentCatalog,
  EquipmentDraftState,
  EquipmentGearOptions,
} from '../types';
import { cloneEquipmentDraft, equipmentDraftsEqual } from '../utils/equipment';

const REQUEST_TIMEOUT = 15000;
type SendAction = (action: string, params?: Record<string, unknown>) => void;

export class EquipmentSession {
  draft: EquipmentDraftState | null = null;
  saved: EquipmentDraftState | null = null;
  catalog: EquipmentCatalog | null = null;
  catalogSignature = '';
  gearOptions: EquipmentGearOptions | null = null;
  loading = false;
  saving = false;
  closing = false;
  error: string | null = null;
  version = 0;
  onChange = () => {};
  onSaved = () => {};
  private counter = 0;
  private loadRequest: string | null = null;
  private saveRequest: string | null = null;
  private replaceDraft = false;
  private contextSignature = '';
  private requestedContext: string | null = null;
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
    return !!this.draft && !equipmentDraftsEqual(this.draft, this.saved);
  }

  notify() {
    this.version++;
    this.onChange();
  }

  private requestId() {
    return `${this.token}-equipment-${++this.counter}-${Date.now()}`;
  }

  load(discardDraft = false) {
    if (this.loading || this.saving) {
      return;
    }
    this.loading = true;
    this.requestedContext = this.contextSignature;
    this.error = null;
    this.replaceDraft = discardDraft || !this.dirty;
    this.loadRequest = this.requestId();
    this.loadTimer = setTimeout(() => {
      this.loadRequest = null;
      this.loading = false;
      this.error = 'Equipment did not finish loading. Please try again.';
      this.notify();
    }, REQUEST_TIMEOUT);
    try {
      this.act('load_equipment', {
        request_id: this.loadRequest,
        known_catalog: this.catalogSignature,
      });
    } catch {
      clearTimeout(this.loadTimer);
      this.loadRequest = null;
      this.loading = false;
      this.error = 'Equipment could not be requested. Please try again.';
    }
    this.notify();
  }

  update(draft: EquipmentDraftState) {
    if (this.saving || this.loading || !this.draft) {
      return;
    }
    this.draft = cloneEquipmentDraft(draft);
    this.notify();
  }

  save(close = false): Promise<boolean> {
    if (this.saving || this.loading || !this.draft) {
      return Promise.resolve(false);
    }
    if (!this.dirty) {
      if (close) {
        this.act('close_equipment');
      }
      return Promise.resolve(true);
    }
    this.saving = true;
    this.closing = close;
    this.error = null;
    this.saveRequest = this.requestId();
    const completion = new Promise<boolean>((resolve) => {
      this.finishSave = resolve;
    });
    this.saveTimer = setTimeout(() => {
      this.completeSave(
        false,
        'The Equipment save was not confirmed. Your draft is still here; reload saved Equipment to check the result.'
      );
    }, REQUEST_TIMEOUT);
    try {
      this.act('save_equipment', {
        request_id: this.saveRequest,
        equipment: JSON.stringify(this.draft),
      });
    } catch {
      this.completeSave(
        false,
        'Equipment could not be saved. Please try again.'
      );
    }
    this.notify();
    return completion;
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
    this.error = accepted ? null : error || 'Equipment could not be saved.';
    this.notify();
    resolve?.(accepted);
    if (accepted) {
      try {
        this.onSaved();
        if (close) {
          this.act('close_equipment');
        }
      } catch {
        this.error =
          'Equipment was saved, but the window could not refresh. Reopen the Designer to refresh its preview.';
        this.notify();
      }
    }
  }

  discard(close = false) {
    if (this.saving) {
      return;
    }
    if (this.saved) {
      this.draft = cloneEquipmentDraft(this.saved);
    }
    this.error = null;
    if (close) {
      this.act('close_equipment');
    }
    this.notify();
  }

  sync(data: CustomMarkingDesignerData, preloadReady: boolean) {
    this.contextSignature = data.equipment_context_signature || '';
    const payload = data.equipment_payload;
    if (this.loadRequest && payload?.request_id === this.loadRequest) {
      if (this.loadTimer) {
        clearTimeout(this.loadTimer);
      }
      this.loading = false;
      this.loadRequest = null;
      if (payload.values && (payload.catalog || this.catalog)) {
        this.catalog = payload.catalog || this.catalog;
        this.catalogSignature = payload.catalog_signature || '';
        this.saved = cloneEquipmentDraft(payload.values);
        if (this.replaceDraft) {
          this.draft = cloneEquipmentDraft(payload.values);
        }
        this.gearOptions = payload.gear_options || null;
        this.error = null;
      } else {
        this.error = payload.error || 'Equipment could not be loaded.';
      }
      this.notify();
    }
    const result = data.equipment_save_result;
    if (this.saveRequest && result?.request_id === this.saveRequest) {
      const accepted = !!result.accepted && !!result.values;
      if (accepted && result.values) {
        this.requestedContext = this.contextSignature;
        this.saved = cloneEquipmentDraft(result.values);
        this.draft = cloneEquipmentDraft(result.values);
        if (result.gear_options) {
          this.gearOptions = result.gear_options;
        }
      }
      this.completeSave(accepted, result.error);
    }
    if (
      preloadReady &&
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
