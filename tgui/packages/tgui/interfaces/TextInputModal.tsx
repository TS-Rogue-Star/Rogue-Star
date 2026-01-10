import { Loader } from './common/Loader';
import { InputButtons } from './common/InputButtons';
import { useBackend, useLocalState } from '../backend';
import { Box, Section, Stack, TextArea } from '../components';
import { Window } from '../layouts';

type TextInputData = {
  large_buttons: boolean;
  max_length: number;
  message: string;
  multiline: boolean;
  placeholder: string;
  timeout: number;
  title: string;
  prevent_enter: boolean;
  window_scale: number; // RS Add: TGUI window scaling (Lira, January 2026)
};

export const TextInputModal = (props, context) => {
  const { act, data } = useBackend<TextInputData>(context);
  const {
    large_buttons,
    max_length,
    message = '',
    multiline,
    placeholder,
    timeout,
    title,
    prevent_enter,
    window_scale, // RS Add: TGUI window scaling (Lira, January 2026)
  } = data;
  const [input, setInput] = useLocalState<string>(
    context,
    'input',
    placeholder || ''
  );
  const onType = (value: string) => {
    if (value === input) {
      return;
    }
    setInput(value);
  };
  // Dynamically changes the window height based on the message. || RS Edit Start: TGUI window scaling (Lira, January 2026)
  const windowScale = Math.min(Math.max(window_scale || 1, 1), 3);
  const baseWindowHeight =
    135 +
    (message.length > 30 ? Math.ceil(message.length / 4) : 0) +
    (multiline || input.length >= 30 ? 75 : 0) +
    (message.length && large_buttons ? 5 : 0);
  const windowHeight = baseWindowHeight * windowScale;
  const windowWidth = 325 * windowScale;
  // RS Edit End

  return (
    // RS Edit: TGUI window scaling (Lira, January 2026)
    <Window title={title} width={windowWidth} height={windowHeight}>
      {timeout && <Loader value={timeout} />}
      <Window.Content
        onEscape={() => act('cancel')}
        onEnter={(event) => {
          if (!prevent_enter) {
            act('submit', { entry: input });
            event.preventDefault();
          }
        }}>
        <Section fill>
          <Stack fill vertical>
            <Stack.Item>
              <Box color="label">{message}</Box>
            </Stack.Item>
            <Stack.Item grow>
              <InputArea input={input} onType={onType} />
            </Stack.Item>
            <Stack.Item>
              <InputButtons
                input={input}
                message={`${input.length}/${max_length}`}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

/** Gets the user input and invalidates if there's a constraint. */
const InputArea = (props, context) => {
  const { act, data } = useBackend<TextInputData>(context);
  const { max_length, multiline, prevent_enter } = data;
  const { input, onType } = props;

  return (
    <TextArea
      autoFocus
      autoSelect
      height={multiline || input.length >= 30 ? '100%' : '1.8rem'}
      maxLength={max_length}
      onEscape={() => act('cancel')}
      onEnter={(event) => {
        if (!prevent_enter) {
          act('submit', { entry: input });
          event.preventDefault();
        }
      }}
      onInput={(_, value) => onType(value)}
      placeholder="Type something..."
      value={input}
    />
  );
};
