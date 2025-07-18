import { useBackend, useLocalState } from '../../backend';
import { MedigunParts } from './MedigunTabs/MedigunParts';
import { Stack, Tabs } from '../../components';
import { Window } from '../../layouts';
import { Data } from './types';
import { MedigunContent } from './MedigunTabs/MedigunContent';

export const Medigun = (props, context) => {
  const { data } = useBackend<Data>(context);
  const { maintenance, examine_data } = data;
  const [selectedTab, setSelectedTab] = useLocalState(context, 'mediGunTab', 0);

  const tab: InfernoElement<JSX.Element>[] = [];
  tab[0] = <MedigunContent />;
  tab[1] = (
    <MedigunParts examineData={examine_data} maintenance={maintenance} />
  );

  return (
    <Window width={450} height={490}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={selectedTab === 0}
                onClick={() => setSelectedTab(0)}>
                Medigun Content
              </Tabs.Tab>
              <Tabs.Tab
                selected={selectedTab === 1}
                onClick={() => setSelectedTab(1)}>
                Medigun Parts
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>{tab[selectedTab]}</Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
