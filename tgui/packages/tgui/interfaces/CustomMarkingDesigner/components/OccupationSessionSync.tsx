// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Occupation //
// /////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import type {
  BasicAppearancePayload,
  BodyMarkingsPayload,
  CustomMarkingDesignerData,
} from '../types';
import type { OccupationSession } from '../services/occupationSession';

type Props = {
  readonly session: OccupationSession;
  readonly data: CustomMarkingDesignerData;
  readonly ready: boolean;
  readonly onChange: () => void;
  readonly onSaved: () => void;
  readonly onBodyPreview: (payload: BodyMarkingsPayload) => void;
  readonly onBasicPreview: (payload: BasicAppearancePayload) => void;
};
export class OccupationSessionSync extends Component<Props> {
  private bodyRefresh: {
    previous: Props['data']['body_markings_payload'];
  } | null = null;
  private basicRefresh: {
    previous: Props['data']['basic_appearance_payload'];
  } | null = null;

  componentDidMount() {
    this.sync();
  }
  componentDidUpdate() {
    this.sync();
  }
  componentWillUnmount() {
    this.props.session.dispose();
  }
  private sync() {
    const { session, data, ready, onChange, onSaved } = this.props;
    session.onChange = onChange;
    session.onSaved = () => {
      this.bodyRefresh = { previous: this.props.data.body_markings_payload };
      this.basicRefresh = {
        previous: this.props.data.basic_appearance_payload,
      };
      onSaved();
    };
    session.sync(data, ready);
    const bodyPayload = this.props.data.body_markings_payload;
    if (
      this.bodyRefresh &&
      bodyPayload &&
      bodyPayload !== this.bodyRefresh.previous
    ) {
      this.bodyRefresh = null;
      this.props.onBodyPreview(bodyPayload);
    }
    const basicPayload = this.props.data.basic_appearance_payload;
    if (
      this.basicRefresh &&
      basicPayload &&
      basicPayload !== this.basicRefresh.previous
    ) {
      this.basicRefresh = null;
      this.props.onBasicPreview(basicPayload);
    }
  }
  render() {
    return null;
  }
}
