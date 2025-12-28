// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Scheduler helper for switching tabs after enabling custom markings in TGUI //
// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

type EnableCustomMarkingsSchedulerProps = {
  readonly allowCustomTab: boolean;
  readonly switchPending: boolean;
  readonly onReady: () => void;
};

export class EnableCustomMarkingsScheduler extends Component<EnableCustomMarkingsSchedulerProps> {
  componentDidMount() {
    this.tryTrigger();
  }

  componentDidUpdate(prevProps: EnableCustomMarkingsSchedulerProps) {
    if (
      prevProps.allowCustomTab !== this.props.allowCustomTab ||
      prevProps.switchPending !== this.props.switchPending
    ) {
      this.tryTrigger();
    }
  }

  private tryTrigger() {
    const { allowCustomTab, switchPending, onReady } = this.props;
    if (!allowCustomTab || !switchPending) {
      return;
    }
    onReady();
  }

  render() {
    return null;
  }
}
