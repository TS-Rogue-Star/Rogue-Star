// ////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Equipment //
// ////////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import type { EquipmentSession } from '../services/equipmentSession';
import type {
  BasicAppearancePayload,
  BodyMarkingsPayload,
  CustomMarkingDesignerData,
} from '../types';

type Props = Readonly<{
  session: EquipmentSession;
  data: CustomMarkingDesignerData;
  preloadReady: boolean;
  onChange: () => void;
  onSaved: () => void;
  onBodyPreview: (payload: BodyMarkingsPayload) => void;
  onBasicPreview: (payload: BasicAppearancePayload) => void;
}>;

export class EquipmentSessionSync extends Component<Props> {
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
    const { session, data, preloadReady, onChange, onSaved } = this.props;
    session.onChange = onChange;
    session.onSaved = () => {
      this.bodyRefresh = { previous: this.props.data.body_markings_payload };
      this.basicRefresh = {
        previous: this.props.data.basic_appearance_payload,
      };
      onSaved();
    };
    session.sync(data, preloadReady);
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
