// ///////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Ctrl+Z hotkey listener for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';

export type UndoHotkeyListenerProps = Readonly<{
  canUndo: boolean;
  onUndo: () => void;
}>;

export class DesignerUndoHotkeyListener extends Component<UndoHotkeyListenerProps> {
  handleKeyDown = (event: KeyboardEvent) => {
    const isModifier = event.ctrlKey || event.metaKey;
    if (!isModifier || event.shiftKey) {
      return;
    }
    const keyName = (event.key || '').toLowerCase();
    if (keyName !== 'z') {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    if (this.props.canUndo) {
      this.props.onUndo();
    }
  };

  componentDidMount() {
    window.addEventListener('keydown', this.handleKeyDown, true);
  }

  componentWillUnmount() {
    window.removeEventListener('keydown', this.handleKeyDown, true);
  }

  render() {
    return null;
  }
}
