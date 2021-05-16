import { useBackend, useLocalState } from "../backend";
import { Window } from "../layouts";
import { NanoMap, Box } from "../components";

export const AdvTeleporter = () => {
  return (
    <Window 
      width={800}
      height={600}
      resizable>
      <Window.Content>
        <AdvTeleporterContent />
      </Window.Content>
    </Window>
  );
};

export const AdvTeleporterContent = (props, context) => {
  const { act, data, config } = useBackend(context);
  const [zoom, setZoom] = useLocalState(context, 'zoom', 1);

  return (
    <Box m={2}>
      <AdvTeleporterMapView />
    </Box>
  );
};

const AdvTeleporterMapView = (props, context) => {
  const { act, config, data } = useBackend(context);
  const [zoom, setZoom] = useLocalState(context, 'zoom', 1);
  return (
    <Box height="526px" mb="0.5rem" overflow="hidden">
      <NanoMap onZoom={v => setZoom(v)} onClick={e => act('mapClick', e)} />
    </Box>
  );
};
