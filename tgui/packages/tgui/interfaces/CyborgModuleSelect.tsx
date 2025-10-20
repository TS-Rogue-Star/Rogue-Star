// ////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2025: New TGUI system for choosing your borg model //
// ////////////////////////////////////////////////////////////////////////////////////////////

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type ModuleEntry = {
  id: string;
  name: string;
  description: string;
  isWhitelisted: boolean;
};

type SpriteEntry = {
  id: string;
  name: string;
  isCurrent: boolean;
  isDefault: boolean;
  isWhitelisted: boolean;
  preview?: string | null;
};

type Data = {
  hasModule: boolean;
  currentModule: string | null;
  modules: ModuleEntry[];
  isShell: boolean;
  sprites: SpriteEntry[];
  iconSelected: boolean;
  iconSelectionTries: number;
  currentSprite: string | null;
  isTransforming: boolean;
  iconLocked: boolean;
};

export const CyborgModuleSelect = () => {
  return (
    <Window width={960} height={720}>
      <Window.Content scrollable>
        <ModulePanel />
      </Window.Content>
    </Window>
  );
};

const ModulePanel = (_props, context) => {
  const { act, data } = useBackend<Data>(context);
  const {
    hasModule,
    currentModule,
    modules = [],
    isShell,
    sprites = [],
    iconSelected,
    iconSelectionTries,
    currentSprite,
    isTransforming,
    iconLocked,
  } = data;

  const [pendingSprite, setPendingSprite] = useLocalState<string | null>(
    context,
    'pendingSprite',
    null
  );

  const reselectionsRemaining = Math.max(iconSelectionTries ?? 0, 0);
  const previewsExhausted = reselectionsRemaining <= 0;
  const transformLocked = !!isTransforming;
  const canSelectMore = !transformLocked && reselectionsRemaining > 0;
  const pendingSpriteData = pendingSprite
    ? sprites.find((sprite) => sprite.id === pendingSprite)
    : null;
  const previewCountText =
    reselectionsRemaining > 0
      ? `${reselectionsRemaining} preview${
        reselectionsRemaining === 1 ? '' : 's'
      } remaining`
      : 'No previews remaining';
  const previewCountSentence = hasModule ? `${previewCountText}.` : '';
  const finalizeHint =
    hasModule && !transformLocked && previewsExhausted && !iconSelected
      ? 'Click your highlighted sprite again to lock it in.'
      : '';

  if (pendingSprite && (!hasModule || iconLocked || !pendingSpriteData)) {
    setTimeout(() => setPendingSprite(null), 0);
  }

  const sortedModules = [...modules].sort((a, b) =>
    a.name.localeCompare(b.name)
  );

  return (
    <>
      <Section title="Select Cyborg Module">
        <NoticeBox info>
          {hasModule ? (
            <>
              Module locked in as <b>{currentModule || 'Unknown'}</b>.
            </>
          ) : isShell ? (
            'Shell platforms have access to a limited module set.'
          ) : (
            'Choose a module to finalize your chassis configuration.'
          )}
        </NoticeBox>

        {sortedModules.length ? (
          <Flex
            wrap="wrap"
            spacing={1}
            mt={1}
            align="stretch"
            justify="flex-start">
            {sortedModules.map((module) => {
              const isActive = currentModule === module.id;
              return (
                <Flex.Item
                  key={module.id}
                  width="220px"
                  maxWidth="220px"
                  minWidth="220px"
                  grow={0}
                  shrink={0}>
                  <Button
                    fluid
                    selected={isActive}
                    disabled={hasModule && !isActive}
                    onClick={() => act('selectModule', { id: module.id })}
                    style={{ minHeight: '88px', padding: '1rem' }}>
                    <Box bold textAlign="center">
                      {module.name}
                    </Box>
                  </Button>
                </Flex.Item>
              );
            })}
          </Flex>
        ) : (
          <Box color="bad" mt={1}>
            No modules are available right now.
          </Box>
        )}
      </Section>

      <Section title="Select Appearance">
        <NoticeBox info>
          {!hasModule ? (
            'Select a module to unlock appearance options.'
          ) : iconLocked ? (
            <>
              Icon locked in as <b>{currentSprite || 'Unknown'}</b>. Reset your
              module to change it.
              {previewCountSentence && (
                <>
                  {' '}
                  {previewCountSentence}
                  {finalizeHint && <> {finalizeHint}</>}
                </>
              )}
            </>
          ) : pendingSpriteData ? (
            <>
              Highlighted <b>{pendingSpriteData.name}</b>. Click it again to
              confirm and close the selector.
              {previewCountSentence && (
                <>
                  {' '}
                  {previewCountSentence}
                  {finalizeHint && <> {finalizeHint}</>}
                </>
              )}
            </>
          ) : (
            <>
              {currentSprite && (
                <>
                  Current icon: <b>{currentSprite}</b>.{' '}
                </>
              )}
              Click a tile to highlight it, then click again to lock in your
              appearance.
              {previewCountSentence && (
                <>
                  {' '}
                  {previewCountSentence}
                  {finalizeHint && <> {finalizeHint}</>}
                </>
              )}
            </>
          )}
        </NoticeBox>
        {transformLocked && hasModule && (
          <Box color="average" mt={1}>
            Chassis is transforming—please wait for it to finish before making
            another selection.
          </Box>
        )}

        {!hasModule ? (
          <Box color="label" mt={1}>
            Choose a module before selecting an icon.
          </Box>
        ) : sprites.length ? (
          <Flex
            wrap="wrap"
            spacing={1}
            mt={1}
            align="stretch"
            justify="flex-start">
            {[...sprites]
              .sort((a, b) => a.name.localeCompare(b.name))
              .map((sprite) => {
                const { id, name, isCurrent, isWhitelisted, preview } = sprite;
                const isPending = pendingSprite === id;
                const isSelected = pendingSprite ? isPending : isCurrent;
                const disabled =
                  transformLocked ||
                  iconLocked ||
                  (!canSelectMore && !isCurrent && !isPending);
                const previewSrc =
                  preview && preview.length
                    ? `data:image/png;base64,${preview}`
                    : null;

                let statusText = 'Click to select';
                let statusColor = 'label';

                if (transformLocked) {
                  statusText = 'Transforming...';
                  statusColor = 'average';
                } else if (isPending) {
                  statusText = 'Click again to confirm';
                } else if (isCurrent) {
                  statusText = 'Current icon';
                  statusColor = 'good';
                } else if (iconLocked) {
                  statusText = 'Icon locked';
                  statusColor = 'bad';
                } else if (!canSelectMore && !isCurrent) {
                  statusText = 'No reselections remaining';
                  statusColor = 'bad';
                } else if (isWhitelisted) {
                  statusText = 'Requires whitelist';
                  statusColor = 'average';
                }

                const handleClick = () => {
                  if (disabled) {
                    return;
                  }
                  if (isPending) {
                    act('selectSprite', { id, finalize: 1 });
                    setPendingSprite(null);
                  } else {
                    act('selectSprite', { id, finalize: 0 });
                    setPendingSprite(id);
                  }
                };

                const statusColorProp = isSelected ? undefined : statusColor;
                const statusStyle = isSelected ? { color: '#111' } : undefined;

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
                      disabled={disabled}
                      onClick={handleClick}
                      style={{
                        height: '100%',
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
                        {statusText && (
                          <Stack.Item>
                            <Box
                              color={statusColorProp}
                              textAlign="center"
                              style={statusStyle}>
                              {statusText}
                            </Box>
                          </Stack.Item>
                        )}
                      </Stack>
                    </Button>
                  </Flex.Item>
                );
              })}
          </Flex>
        ) : (
          <Box color="bad" mt={1}>
            No alternative icons are available for this module.
          </Box>
        )}
      </Section>
    </>
  );
};
