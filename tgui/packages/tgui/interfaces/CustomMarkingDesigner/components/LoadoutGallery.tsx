// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
// //////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import {
  scheduleCharacterPreviewWork,
  type CharacterPreviewWorkHandle,
  type CharacterPreviewWorkPriority,
} from '../../../utils/character-preview';
import {
  BasicTile,
  BasicTileSection,
  compareByName,
  type BasicTileDefinition,
  type BasicTileSectionProps,
  type BasicTilePreviewEntry,
} from '../BasicAppearanceTab';

export type LoadoutTilePreview = {
  signature: string;
  preview: BasicTilePreviewEntry[];
  complete: boolean;
};

type Props = Omit<BasicTileSectionProps, 'getTilePreviewEntries'> & {
  readonly getSignature: (definition: BasicTileDefinition) => string;
  readonly getCachedPreview: (
    definition: BasicTileDefinition
  ) => LoadoutTilePreview | null;
  readonly buildPreview: (
    definition: BasicTileDefinition,
    priority: CharacterPreviewWorkPriority,
    onUpdated: () => void
  ) => LoadoutTilePreview;
};

type TileProps = Props & {
  readonly definition: BasicTileDefinition;
  readonly signature: string;
  readonly selected: boolean;
  readonly onReady: (id: string, signature: string) => void;
};

const EMPTY_PREVIEW: BasicTilePreviewEntry[] = [];
const getEmptyPreview = () => EMPTY_PREVIEW;

class LoadoutTile extends Component<
  TileProps,
  { result: LoadoutTilePreview | null }
> {
  state = { result: null as LoadoutTilePreview | null };
  private mounted = false;
  private work: CharacterPreviewWorkHandle | null = null;
  private displayedPreview: LoadoutTilePreview | null = null;

  componentDidMount() {
    this.mounted = true;
    this.schedulePreview();
  }
  componentDidUpdate(previous: TileProps) {
    if (
      previous.signature !== this.props.signature ||
      previous.definition.previewPending !==
        this.props.definition.previewPending
    ) {
      this.work?.cancel();
      this.work = null;
      this.schedulePreview();
    }
  }
  componentWillUnmount() {
    this.mounted = false;
    this.work?.cancel();
    this.work = null;
  }
  private result() {
    const { definition, getCachedPreview, getSignature } = this.props;
    const cached = getCachedPreview(definition);
    return (
      cached ||
      (this.state.result?.signature === getSignature(definition)
        ? this.state.result
        : null)
    );
  }
  private schedulePreview = () => {
    if (!this.mounted || this.work || this.props.definition.previewPending) {
      return;
    }
    const ready = this.result();
    if (ready?.complete) {
      if (ready !== this.state.result) {
        this.setState({ result: ready });
      }
      this.props.onReady(this.props.definition.id, ready.signature);
      return;
    }
    this.work = scheduleCharacterPreviewWork(() => {
      this.work = null;
      if (!this.mounted) {
        return;
      }
      const result = this.props.buildPreview(
        this.props.definition,
        'visible',
        this.schedulePreview
      );
      this.setState({ result });
      if (result.complete) {
        this.props.onReady(this.props.definition.id, result.signature);
      }
    }, 'visible');
  };
  private handleSelect = () => this.props.onSelect(this.props.definition.id);

  shouldComponentUpdate(
    next: TileProps,
    state: { result: LoadoutTilePreview | null }
  ) {
    const previous = this.props;
    return (
      state.result !== this.state.result ||
      next.signature !== previous.signature ||
      next.selected !== previous.selected ||
      next.definition.name !== previous.definition.name ||
      next.definition.tooltip !== previous.definition.tooltip ||
      next.definition.disabled !== previous.definition.disabled ||
      next.definition.previewPending !== previous.definition.previewPending ||
      next.definition.singlePreview !== previous.definition.singlePreview ||
      next.canvasWidth !== previous.canvasWidth ||
      next.canvasHeight !== previous.canvasHeight ||
      next.backgroundImage !== previous.backgroundImage ||
      next.backgroundColor !== previous.backgroundColor ||
      next.backgroundScale !== previous.backgroundScale ||
      next.backgroundTileWidth !== previous.backgroundTileWidth ||
      next.backgroundTileHeight !== previous.backgroundTileHeight
    );
  }
  render() {
    let result = this.result();
    if (
      !result &&
      this.displayedPreview &&
      !this.props.definition.previewPending
    ) {
      result = this.props.buildPreview(
        this.props.definition,
        'visible',
        this.schedulePreview
      );
    }
    if (result?.complete) {
      this.displayedPreview = result;
    }
    const displayed = this.displayedPreview || result;
    return (
      <BasicTile
        {...this.props}
        def={{ ...this.props.definition, previewPending: !displayed?.complete }}
        previews={displayed?.preview || EMPTY_PREVIEW}
        onToggle={this.handleSelect}
      />
    );
  }
}

export class LoadoutGallery extends Component<Props> {
  private mounted = false;
  private generation = 0;
  private warmSignature = '';
  private waiting = new Set<string>();
  private warmTimer: ReturnType<typeof setTimeout> | null = null;
  private warmWork = new Map<string, CharacterPreviewWorkHandle>();
  private visible: BasicTileDefinition[] = [];
  private adjacent: BasicTileDefinition[] = [];

  componentDidMount() {
    this.mounted = true;
    this.syncWarmup();
  }
  componentDidUpdate() {
    this.syncWarmup();
  }
  componentWillUnmount() {
    this.mounted = false;
    this.cancelWarmup();
  }
  private cancelWarmup() {
    this.generation++;
    if (this.warmTimer) {
      clearTimeout(this.warmTimer);
      this.warmTimer = null;
    }
    this.warmWork.forEach((handle) => handle.cancel());
    this.warmWork.clear();
  }
  private syncWarmup() {
    const signature = [...this.visible, ...this.adjacent]
      .map((def) => `${this.props.getSignature(def)}:${!!def.previewPending}`)
      .join('|');
    if (signature !== this.warmSignature) {
      this.cancelWarmup();
      this.warmSignature = signature;
      this.waiting = new Set(
        this.visible
          .filter((def) => !this.props.getCachedPreview(def)?.complete)
          .map((def) => def.id)
      );
    }
    if (!this.waiting.size && !this.warmTimer && !this.warmWork.size) {
      this.warmTimer = setTimeout(() => {
        this.warmTimer = null;
        const generation = this.generation;
        this.adjacent.forEach((def) => this.warmPreview(def, generation));
      }, 150);
    }
  }
  private warmPreview(def: BasicTileDefinition, generation: number) {
    if (
      !this.mounted ||
      generation !== this.generation ||
      def.previewPending ||
      this.warmWork.has(def.id) ||
      this.props.getCachedPreview(def)?.complete
    ) {
      return;
    }
    const work = scheduleCharacterPreviewWork(() => {
      this.warmWork.delete(def.id);
      if (!this.mounted || generation !== this.generation) {
        return;
      }
      this.props.buildPreview(def, 'background', () =>
        this.warmPreview(def, generation)
      );
    }, 'background');
    this.warmWork.set(def.id, work);
  }
  private handleReady = (id: string, signature: string) => {
    const def = this.visible.find((entry) => entry.id === id);
    if (def && this.props.getSignature(def) === signature) {
      this.waiting.delete(id);
      if (this.mounted && !this.waiting.size) {
        this.syncWarmup();
      }
    }
  };
  private renderTile = (definition: BasicTileDefinition, selected: boolean) => (
    <LoadoutTile
      key={definition.id}
      {...this.props}
      definition={definition}
      signature={this.props.getSignature(definition)}
      selected={selected}
      onReady={this.handleReady}
    />
  );
  render() {
    const needle = this.props.search.trim().toLowerCase();
    const filtered = this.props.definitions
      .filter((def) =>
        [def.id, def.name, def.description || ''].some((value) =>
          value.toLowerCase().includes(needle)
        )
      )
      .sort(compareByName);
    const page = Math.max(
      0,
      Math.min(this.props.page, Math.ceil(filtered.length / 20) - 1)
    );
    this.visible = filtered.slice(page * 20, (page + 1) * 20);
    const neighbor =
      page + 1 < Math.ceil(filtered.length / 20) ? page + 1 : page - 1;
    this.adjacent =
      neighbor >= 0 ? filtered.slice(neighbor * 20, (neighbor + 1) * 20) : [];
    return (
      <BasicTileSection
        {...this.props}
        renderTile={this.renderTile}
        getTilePreviewEntries={getEmptyPreview}
      />
    );
  }
}
