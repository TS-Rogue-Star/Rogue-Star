// ////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2025: Phantom click scheduler for custom marking designer //
// ////////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

type PhantomClickSchedulerProps = {
  phantomClickScheduled: boolean;
  isPlaceholderTool: boolean;
  activeTool: string | null;
  setPhantomClickScheduled: (value: boolean) => void;
  setTool: (tool: string) => void;
};

export class PhantomClickScheduler extends Component<PhantomClickSchedulerProps> {
  componentDidMount() {
    this.trySchedule();
  }

  componentDidUpdate(prevProps: PhantomClickSchedulerProps) {
    if (
      prevProps.phantomClickScheduled !== this.props.phantomClickScheduled ||
      prevProps.isPlaceholderTool !== this.props.isPlaceholderTool ||
      prevProps.activeTool !== this.props.activeTool
    ) {
      this.trySchedule();
    }
  }

  private trySchedule() {
    const {
      phantomClickScheduled,
      isPlaceholderTool,
      activeTool,
      setPhantomClickScheduled,
      setTool,
    } = this.props;
    if (phantomClickScheduled || isPlaceholderTool) {
      return;
    }
    setPhantomClickScheduled(true);
    const initialTool = activeTool || 'brush';
    if (typeof window !== 'undefined') {
      window.setTimeout(() => setTool(initialTool), 30);
    }
  }

  render() {
    return null;
  }
}
