import { BooleanLike } from 'common/react';
import { useBackend } from '../backend';
import { Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';

type Data = {
  bought: { id: string; name: string; on: BooleanLike }[];
  not_bought: { id: string; name: string; ram: number }[];
  available_ram: number;
  emotions: { id: string; name: string }[];
  current_emotion: string;
  dark_mode?: BooleanLike; // RS Add: Off duty AI support (Lira, November 2025)
};

export const pAIInterface = (props, context) => {
  const { act, data } = useBackend<Data>(context);

  // RS Edit Start: Off duty AI support (Lira, November 2025)
  const {
    bought,
    not_bought,
    available_ram,
    emotions,
    current_emotion,
    dark_mode,
  } = data;
  const showDarkMode = dark_mode !== undefined;
  const darkModeEnabled = !!dark_mode;
  // RS Edit End

  return (
    <Window width={450} height={600} resizable>
      <Window.Content scrollable>
        <Section title="Emotion">
          {/* RS Add Start: Off duty AI support (Lira, November 2025) */}
          {showDarkMode && (
            <Button
              icon="adjust"
              content={`Dark Mode: ${darkModeEnabled ? 'On' : 'Off'}`}
              selected={darkModeEnabled}
              onClick={() => act('toggle_dark_mode')}
            />
          )}
          {/* RS Add End */}
          {emotions.map((emote) => (
            <Button
              key={emote.id}
              content={emote.name}
              selected={emote.id === current_emotion}
              onClick={() => act('image', { 'image': emote.id })}
            />
          ))}
        </Section>
        <Section title={'Software (Available RAM: ' + available_ram + ')'}>
          <LabeledList>
            <LabeledList.Item label="Installed">
              {bought.map((app) => (
                <Button
                  key={app.id}
                  content={app.name}
                  selected={app.on}
                  onClick={() => act('software', { 'software': app.id })}
                />
              ))}
            </LabeledList.Item>
            <LabeledList.Divider />
            <LabeledList.Item label="Downloadable">
              {not_bought.map((app) => (
                <Button
                  key={app.id}
                  content={app.name + ' (' + app.ram + ')'}
                  disabled={app.ram > available_ram}
                  onClick={() => act('purchase', { 'purchase': app.id })}
                />
              ))}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
