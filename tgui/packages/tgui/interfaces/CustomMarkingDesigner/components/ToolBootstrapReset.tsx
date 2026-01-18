// ////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Tool bootstrap reset helper for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

export type ToolBootstrapResetProps = {
  readonly stateToken: string;
  readonly onReset: () => void;
};

export class ToolBootstrapReset extends Component<ToolBootstrapResetProps> {
  componentDidMount() {
    this.triggerReset();
  }

  componentDidUpdate(prevProps: ToolBootstrapResetProps) {
    if (prevProps.stateToken !== this.props.stateToken) {
      this.triggerReset();
    }
  }

  private triggerReset() {
    const { onReset } = this.props;
    if (typeof onReset === 'function') {
      onReset();
    }
  }

  render() {
    return null;
  }
}
