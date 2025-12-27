// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Scheduler helper for deferred preview override application in TGUI //
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

import type {
  CustomPreviewOverrideMap,
  PendingPreviewOverrides,
} from '../types';

type PreviewOverrideSchedulerProps = {
  readonly pendingOverrides: PendingPreviewOverrides | null;
  readonly hasBodyPayload: boolean;
  readonly hasBasicPayload: boolean;
  readonly onApply: (options: {
    overrides: CustomPreviewOverrideMap;
    applyBody: boolean;
    applyBasic: boolean;
  }) => void;
};

export class PreviewOverrideScheduler extends Component<PreviewOverrideSchedulerProps> {
  componentDidMount() {
    this.tryApply();
  }

  componentDidUpdate(prevProps: PreviewOverrideSchedulerProps) {
    if (
      prevProps.pendingOverrides !== this.props.pendingOverrides ||
      prevProps.hasBodyPayload !== this.props.hasBodyPayload ||
      prevProps.hasBasicPayload !== this.props.hasBasicPayload
    ) {
      this.tryApply();
    }
  }

  private tryApply() {
    const { pendingOverrides, hasBodyPayload, hasBasicPayload, onApply } =
      this.props;
    if (!pendingOverrides) {
      return;
    }
    const applyBody = pendingOverrides.pendingBody && hasBodyPayload;
    const applyBasic = pendingOverrides.pendingBasic && hasBasicPayload;
    if (!applyBody && !applyBasic) {
      return;
    }
    onApply({
      overrides: pendingOverrides.overrides,
      applyBody,
      applyBasic,
    });
  }

  render() {
    return null;
  }
}
