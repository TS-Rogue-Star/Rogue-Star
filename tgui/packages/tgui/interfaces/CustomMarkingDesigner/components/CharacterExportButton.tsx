// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2026: Character Designer - JSON Export //
// ////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import { Button } from '../../../components';
import { CHIP_BUTTON_CLASS } from '../constants';
import {
  buildCharacterExport,
  downloadCharacterJson,
  pickCharacterExportFile,
  type CharacterExportDrafts,
  type CharacterExportResult,
} from '../utils/characterExport';

type Props = Readonly<{
  disabled: boolean;
  stateToken: string;
  characterName?: string;
  result?: CharacterExportResult | null;
  collectDrafts: () => CharacterExportDrafts;
  act: (action: string, params: Record<string, unknown>) => void;
}>;

type PendingExport = {
  id: string;
  drafts: CharacterExportDrafts;
  fileHandle: FileSystemFileHandle | null;
  downloading?: boolean;
};

export class CharacterExportButton extends Component<
  Props,
  { pending: boolean; error: string | null }
> {
  state = { pending: false, error: null as string | null };
  private pending: PendingExport | null = null;
  private timeout: ReturnType<typeof setTimeout> | null = null;
  private sequence = 0;

  componentDidUpdate(previous: Props) {
    if (previous.stateToken !== this.props.stateToken) {
      this.finish();
      return;
    }
    const result = this.props.result;
    if (
      !this.pending ||
      this.pending.downloading ||
      !result ||
      result.request_id !== this.pending.id ||
      result.state_token !== this.props.stateToken
    ) {
      return;
    }
    if (!result.baseline || result.error) {
      this.finish(result.error || 'The character could not be exported.');
      return;
    }
    const request = this.pending;
    request.downloading = true;
    if (this.timeout !== null) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
    try {
      const exported = buildCharacterExport(result.baseline, request.drafts);
      downloadCharacterJson(
        exported.json,
        exported.filename,
        request.fileHandle
      ).then(
        () => {
          if (this.pending === request) {
            this.finish();
          }
        },
        (error) => {
          if (this.pending === request) {
            this.finish(
              error?.name === 'AbortError'
                ? null
                : 'Could not download the character JSON. Click to try again.'
            );
          }
        }
      );
    } catch {
      this.finish('Could not download the character JSON. Click to try again.');
    }
  }

  componentWillUnmount() {
    this.clearPending();
  }

  private clearPending() {
    if (this.timeout !== null) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
    this.pending = null;
  }

  private finish(error: string | null = null) {
    this.clearPending();
    this.setState({ pending: false, error });
  }

  private handleExportCharacter = async () => {
    if (this.props.disabled || this.pending) {
      return;
    }
    let request: PendingExport | null = null;
    try {
      const id = `character-export-${Date.now()}-${++this.sequence}`;
      request = this.pending = {
        id,
        drafts: JSON.parse(JSON.stringify(this.props.collectDrafts())),
        fileHandle: null,
      };
      this.setState({ pending: true, error: null });
      request.fileHandle = await pickCharacterExportFile(
        request.drafts.identity?.real_name ?? this.props.characterName
      );
      if (this.pending !== request) {
        return;
      }
      this.timeout = setTimeout(() => {
        this.finish('The export timed out. Click to try again.');
      }, 30000);
      this.props.act('export_character_json', { request_id: id });
    } catch (error) {
      if (this.pending === request) {
        this.finish(
          error?.name === 'AbortError'
            ? null
            : 'The character could not be exported. Click to try again.'
        );
      }
    }
  };

  render() {
    return (
      <Button
        className={`${CHIP_BUTTON_CLASS} RogueStar__characterExport`}
        icon={this.state.pending ? 'spinner-third' : 'file-export'}
        iconSpin={this.state.pending}
        disabled={this.props.disabled || this.state.pending}
        color={this.state.error ? 'bad' : undefined}
        tooltip={
          this.state.error ||
          'Download this character as JSON, including unsaved changes.'
        }
        onClick={this.handleExportCharacter}>
        {this.state.pending
          ? 'Exporting...'
          : this.state.error
            ? 'Retry export'
            : 'Export JSON'}
      </Button>
    );
  }
}
