// /////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Prefetch helper for shared payloads on designer open //
// /////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

import type { BasicAppearancePayload, BodyMarkingsPayload } from '../types';

type PayloadPrefetchSchedulerProps = {
  readonly bodyPayload: BodyMarkingsPayload | null;
  readonly basicPayload: BasicAppearancePayload | null;
  readonly bodyLoadInProgress: boolean;
  readonly basicLoadInProgress: boolean;
  readonly bodyReloadPending: boolean;
  readonly basicReloadPending: boolean;
  readonly setBodyLoadInProgress: (value: boolean) => void;
  readonly setBasicLoadInProgress: (value: boolean) => void;
  readonly clearBodyReloadPending: () => void;
  readonly clearBasicReloadPending: () => void;
  readonly requestBody: () => void;
  readonly requestBasic: () => void;
};

export class PayloadPrefetchScheduler extends Component<PayloadPrefetchSchedulerProps> {
  private requestedBody = false;
  private requestedBasic = false;
  private pendingBody = false;

  componentDidMount() {
    this.sync();
  }

  componentDidUpdate(prevProps: PayloadPrefetchSchedulerProps) {
    if (
      prevProps.bodyPayload !== this.props.bodyPayload ||
      prevProps.basicPayload !== this.props.basicPayload ||
      prevProps.bodyLoadInProgress !== this.props.bodyLoadInProgress ||
      prevProps.basicLoadInProgress !== this.props.basicLoadInProgress
    ) {
      this.sync();
    }
  }

  private sync() {
    const {
      bodyPayload,
      basicPayload,
      bodyLoadInProgress,
      basicLoadInProgress,
      bodyReloadPending,
      basicReloadPending,
      setBodyLoadInProgress,
      setBasicLoadInProgress,
      clearBodyReloadPending,
      clearBasicReloadPending,
      requestBody,
      requestBasic,
    } = this.props;

    const bodyReady = !!bodyPayload && !bodyPayload.preview_only;
    const basicReady = !!basicPayload && !basicPayload.preview_only;
    const needsBody = !bodyReady;
    const needsBasic = !basicReady;

    if (bodyReady && bodyLoadInProgress) {
      setBodyLoadInProgress(false);
    }
    if (basicReady && basicLoadInProgress) {
      setBasicLoadInProgress(false);
    }

    if (this.pendingBody && basicReady) {
      this.pendingBody = false;
      if (needsBody && !this.requestedBody && !bodyLoadInProgress) {
        this.requestedBody = true;
        setBodyLoadInProgress(true);
        requestBody();
        if (bodyReloadPending) {
          clearBodyReloadPending();
        }
      }
      return;
    }

    if (needsBasic && !this.requestedBasic && !basicLoadInProgress) {
      this.requestedBasic = true;
      if (needsBody) {
        this.pendingBody = true;
      }
      setBasicLoadInProgress(true);
      requestBasic();
      if (basicReloadPending) {
        clearBasicReloadPending();
      }
      return;
    }

    if (needsBody && !this.requestedBody && !bodyLoadInProgress) {
      if (needsBasic && basicLoadInProgress) {
        this.pendingBody = true;
        return;
      }
      this.requestedBody = true;
      setBodyLoadInProgress(true);
      requestBody();
      if (bodyReloadPending) {
        clearBodyReloadPending();
      }
    }
  }

  render() {
    return null;
  }
}
