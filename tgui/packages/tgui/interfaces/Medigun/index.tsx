import { useBackend, useLocalState } from '../../backend';
import { MedigunParts } from './MedigunTabs/MedigunParts';
import { Stack, Tabs } from '../../components';
import { Window } from '../../layouts';
import { Data } from './types';
import { MedigunContent } from './MedigunTabs/MedigunContent';
import { MedigunComponents } from './MedigunTabs/MedigunComponents';

export const Medigun = (props, context) => {
  const { data } = useBackend<Data>(context);
  const { examine_data } = data;
  const [selectedTab, setSelectedTab] = useLocalState(context, 'mediGunTab', 0);

  const tab: InfernoElement<JSX.Element>[] = [];
  tab[0] = <MedigunContent />;
  tab[1] = <MedigunParts examineData={examine_data} />;
  tab[2] = <MedigunComponents examineData={examine_data} />;

  return (
    <Window width={450} height={470}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab onClick={() => setSelectedTab(0)}>
                Medigun Content
              </Tabs.Tab>
              <Tabs.Tab onClick={() => setSelectedTab(1)}>
                Medigun Parts
              </Tabs.Tab>
              <Tabs.Tab onClick={() => setSelectedTab(2)}>
                Medigun Components
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>{tab[selectedTab]}</Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
