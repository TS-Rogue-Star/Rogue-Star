// //////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2025: New TGUI system for choosing your pAI chassis ///
// //////////////////////////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type ChassisEntry = {
  id: string;
  name: string;
  isCurrent: boolean;
  preview?: string | null;
};

type Data = {
  currentChassis: string | null;
  currentChassisId: string | null;
  entries: ChassisEntry[];
};

export const pAIChassisSelect = (_props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { entries = [], currentChassis, currentChassisId } = data;

  const [pendingId, setPendingId] = useLocalState<string | null>(
    context,
    'pendingId',
    null
  );

  const sortedEntries = [...entries].sort((a, b) =>
    a.name.localeCompare(b.name)
  );
  const pendingEntry =
    pendingId && sortedEntries.length
      ? sortedEntries.find((entry) => entry.id === pendingId)
      : null;
  const hasPending = !!pendingEntry;
  const instructions = hasPending
    ? 'Click your highlighted chassis again to close the selector.'
    : 'Click a chassis to select it. Click again to close the selector.';

  return (
    <Window width={800} height={620}>
      <Window.Content scrollable>
        <Section title="Select pAI Chassis">
          <NoticeBox info>
            {currentChassis ? (
              <>
                Current selection: <b>{currentChassis}</b>. {instructions}
              </>
            ) : (
              <>Select a chassis to define your appearance. {instructions}</>
            )}
          </NoticeBox>
          {sortedEntries.length ? (
            <Flex
              wrap="wrap"
              spacing={1}
              mt={1}
              align="stretch"
              justify="flex-start">
              {sortedEntries.map((entry) => {
                const { id, name, isCurrent, preview } = entry;
                const isPending = pendingEntry?.id === id;
                const isSelected = isPending || (!hasPending && isCurrent);
                const previewSrc = preview
                  ? `data:image/png;base64,${preview}`
                  : null;

                let statusText = 'Click to select';
                let statusColor: string | undefined = 'label';

                if (isPending) {
                  statusText = 'Click again to close';
                  statusColor = undefined;
                } else if (id === currentChassisId) {
                  statusText = 'Current selection';
                  statusColor = 'good';
                }

                const handleClick = () => {
                  if (isPending) {
                    act('selectChassis', { id, finalize: 1 });
                    setPendingId(null);
                  } else {
                    act('selectChassis', { id, finalize: 0 });
                    setPendingId(id);
                  }
                };

                return (
                  <Flex.Item
                    key={id}
                    width="220px"
                    maxWidth="220px"
                    minWidth="220px"
                    grow={0}
                    shrink={0}>
                    <Button
                      fluid
                      selected={isSelected}
                      onClick={handleClick}
                      style={{
                        minHeight: '220px',
                        padding: '1rem',
                      }}>
                      <Stack
                        vertical
                        fill
                        align="center"
                        justify="space-between"
                        spacing={1}>
                        <Stack.Item>
                          <Box bold textAlign="center">
                            {name}
                          </Box>
                        </Stack.Item>
                        <Stack.Item>
                          {previewSrc ? (
                            <Box
                              as="img"
                              src={previewSrc}
                              width="128px"
                              height="128px"
                              style={{ imageRendering: 'pixelated' }}
                            />
                          ) : (
                            <Box color="label">No preview</Box>
                          )}
                        </Stack.Item>
                        <Stack.Item>
                          <Box color={statusColor} textAlign="center">
                            {statusText}
                          </Box>
                        </Stack.Item>
                      </Stack>
                    </Button>
                  </Flex.Item>
                );
              })}
            </Flex>
          ) : (
            <Box color="bad" mt={1}>
              No chassis are available right now.
            </Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
