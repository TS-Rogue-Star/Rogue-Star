// ////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Tool bootstrap scheduler helper for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

type ToolBootstrapSchedulerProps = {
  readonly isPlaceholderTool: boolean;
  readonly toolBootstrapScheduled: boolean;
  readonly setToolBootstrapScheduled: (value: boolean) => void;
  readonly setTool: (tool: string) => void;
};

export class ToolBootstrapScheduler extends Component<ToolBootstrapSchedulerProps> {
  componentDidMount() {
    this.trySchedule();
  }

  componentDidUpdate(prevProps: ToolBootstrapSchedulerProps) {
    if (
      prevProps.isPlaceholderTool !== this.props.isPlaceholderTool ||
      prevProps.toolBootstrapScheduled !== this.props.toolBootstrapScheduled
    ) {
      this.trySchedule();
    }
  }

  private trySchedule() {
    const {
      isPlaceholderTool,
      toolBootstrapScheduled,
      setToolBootstrapScheduled,
      setTool,
    } = this.props;
    if (!isPlaceholderTool || toolBootstrapScheduled) {
      return;
    }
    setToolBootstrapScheduled(true);
    const schedule =
      typeof window !== 'undefined' ? window.setTimeout : setTimeout;
    schedule(() => setTool('brush'), 100);
  }

  render() {
    return null;
  }
}
