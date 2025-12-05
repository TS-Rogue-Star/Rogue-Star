// ///////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Loading screen for custom marking designer //
// ///////////////////////////////////////////////////////////////////////////////////////////

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { LoadingOverlay } from '../CustomMarkingDesigner/components';

type LoadingData = {
  width?: number;
  height?: number;
};

export const CustomMarkingDesignerLoading = (_props, context) => {
  const { data } = useBackend<LoadingData>(context);
  const width = data?.width || 1720;
  const height = data?.height || 950;

  return (
    <Window
      theme="nanotrasen rogue-star-window"
      width={width}
      height={height}
      resizable={false}
      canClose={false}>
      <Window.Content>
        <LoadingOverlay />
      </Window.Content>
    </Window>
  );
};

export default CustomMarkingDesignerLoading;
