// //////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Loadout //
// //////////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Tabs,
  TextArea,
} from '../../../components';
import { BasicAppearanceSaveSection } from '../BasicAppearanceTab';
import { CHIP_BUTTON_CLASS } from '../constants';
import type { LoadoutTweak, LoadoutValue } from '../loadoutTypes';
import type { LoadoutSession } from '../services/loadoutSession';
import {
  LOADOUT_IDENTITY_MATRIX,
  loadoutCost,
  loadoutMatrixError,
  selectedVariant,
  tweakValue,
} from '../utils/loadout';

const TweakEditor = ({
  tweak,
  value,
  savedValue,
  placeholder,
  disabled,
  onChange,
}: {
  readonly tweak: LoadoutTweak;
  readonly value: LoadoutValue;
  readonly savedValue: LoadoutValue;
  readonly placeholder?: string;
  readonly disabled: boolean;
  readonly onChange: (value: LoadoutValue) => void;
}) => {
  const locked = disabled || !!tweak.disabled;
  const dropdown = (options, selected, update) => (
    <Dropdown
      key={String(selected)}
      className="RogueStar__dropdown"
      dropdownStyle="rogue-star"
      aria-label={tweak.label}
      width="100%"
      options={options.map((option) => ({
        value: option.value,
        displayText: option.label,
      }))}
      selected={selected}
      displayText={
        options.find((option) => option.value === selected)?.label ?? selected
      }
      disabled={locked}
      onSelected={(next) => {
        if (!locked) {
          update(next);
        }
      }}
    />
  );
  let editor;
  if (tweak.kind === 'matrix') {
    const matrix =
      Array.isArray(value) && value.length
        ? (value.map((component) => component ?? 0) as number[])
        : LOADOUT_IDENTITY_MATRIX;
    const matrixError =
      JSON.stringify(value) === JSON.stringify(savedValue)
        ? null
        : loadoutMatrixError(value);
    const labels =
      matrix.length >= 16
        ? [
            'RR',
            'RG',
            'RB',
            'RA',
            'GR',
            'GG',
            'GB',
            'GA',
            'BR',
            'BG',
            'BB',
            'BA',
            'AR',
            'AG',
            'AB',
            'AA',
            'CR',
            'CG',
            'CB',
            'CA',
          ]
        : [
            'RR',
            'RG',
            'RB',
            'GR',
            'GG',
            'GB',
            'BR',
            'BG',
            'BB',
            'CR',
            'CG',
            'CB',
          ];
    editor = (
      <>
        <Flex wrap gap={0.5}>
          {matrix.map((component, index) => (
            <Flex.Item key={index} basis={matrix.length >= 16 ? '22%' : '30%'}>
              <Box color="label">{labels[index]}</Box>
              <NumberInput
                className="RogueStar__numberInput"
                width="100%"
                value={component}
                minValue={-10}
                maxValue={10}
                step={0.01}
                disabled={locked}
                onChange={(_, next) => {
                  if (!locked) {
                    const updated = [...matrix];
                    updated[index] = next;
                    onChange(updated);
                  }
                }}
              />
            </Flex.Item>
          ))}
        </Flex>
        {matrixError && <NoticeBox danger>{matrixError}</NoticeBox>}
      </>
    );
  } else if (tweak.kind === 'choices') {
    const values = Array.isArray(value) ? value : [];
    editor = (
      <LabeledList>
        {tweak.fields?.map((field, index) => (
          <LabeledList.Item key={index} label={field.label}>
            {dropdown(field.options, values[index], (next) => {
              const updated = [...values];
              updated[index] = next;
              onChange(updated);
            })}
          </LabeledList.Item>
        ))}
      </LabeledList>
    );
  } else if (tweak.options?.length) {
    editor = dropdown(tweak.options, value, onChange);
  } else if (tweak.multiline) {
    editor = (
      <TextArea
        fluid
        height="6em"
        value={String(value ?? '')}
        placeholder={placeholder}
        maxLength={tweak.max_length}
        disabled={locked}
        onInput={(_, next) => {
          if (!locked) {
            onChange(next);
          }
        }}
      />
    );
  } else {
    editor = (
      <Input
        fluid
        value={String(value ?? '')}
        placeholder={placeholder}
        maxLength={tweak.max_length}
        disabled={locked}
        onInput={(_, next) => {
          if (!locked) {
            onChange(next);
          }
        }}
      />
    );
  }
  return (
    <Box mb={1}>
      <Flex align="center" mb={0.5}>
        <Flex.Item grow>
          <Box bold>{tweak.label}</Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            className={CHIP_BUTTON_CLASS}
            icon="eraser"
            tooltip={`Reset ${tweak.label.toLowerCase()}`}
            disabled={locked}
            onClick={() => onChange(tweak.default)}>
            Reset
          </Button>
        </Flex.Item>
      </Flex>
      {!!tweak.disabled && (
        <Box color="label">
          Custom names and descriptions are unavailable for this account.
        </Box>
      )}
      {editor}
    </Box>
  );
};

type Props = {
  readonly session: LoadoutSession;
  readonly uiLocked: boolean;
  readonly focused: string | null;
  readonly onFocusItem: (id: string) => void;
};

export class LoadoutSettings extends Component<Props, { revision: number }> {
  state = { revision: 0 };
  private unsubscribe: (() => void) | null = null;
  private handleTextChange = () => {
    this.setState((state) => ({ revision: state.revision + 1 }));
  };
  componentDidMount() {
    this.unsubscribe = this.props.session.subscribeTextChanges(
      this.handleTextChange
    );
  }
  componentDidUpdate(previous: Props) {
    if (previous.session !== this.props.session) {
      this.unsubscribe?.();
      this.unsubscribe = this.props.session.subscribeTextChanges(
        this.handleTextChange
      );
    }
  }
  componentWillUnmount() {
    this.unsubscribe?.();
  }
  render() {
    const { session, uiLocked, focused } = this.props;
    const { draft, catalog } = session;
    if (!draft || !catalog) {
      return null;
    }
    const locked = uiLocked || session.saving || session.loading;
    const items = draft.slots[draft.active] || [];
    const cost = loadoutCost(items, catalog);
    const focusedItem = items.find((item) => item.id === focused) || items[0];
    const savedItem = session.saved?.slots[draft.active]?.find(
      (item) => item.id === focusedItem?.id
    );
    const focusedGear = catalog.items.find(
      (gear) => gear.id === focusedItem?.id
    );
    const focusedVariant =
      focusedGear && selectedVariant(focusedGear, focusedItem);
    return (
      <>
        <BasicAppearanceSaveSection
          pendingSave={session.saving && !session.closing}
          pendingClose={session.closing}
          uiLocked={locked}
          dirty={session.dirty}
          onSave={() => session.save()}
          onSaveAndClose={() => session.save(true)}
          onDiscardAndClose={() => session.discard(true)}
        />
        <Section title="Loadout" mt={1}>
          {session.previewError && (
            <>
              <NoticeBox warning>{session.previewError}</NoticeBox>
              <Button
                disabled={locked}
                content="Retry Previews"
                onClick={() => session.load()}
              />
            </>
          )}
          {session.error && (
            <>
              <NoticeBox danger>{session.error}</NoticeBox>
              <Button.Confirm
                disabled={locked}
                content="Reload Saved Loadout"
                confirmContent="Discard Draft & Reload"
                onClick={() => session.load(true)}
              />
            </>
          )}
          {session.validationError && (
            <NoticeBox danger>{session.validationError}</NoticeBox>
          )}
          {session.loading && <NoticeBox>Loading Loadout…</NoticeBox>}
          {items.some((item) => {
            const gear = catalog.items.find((entry) => entry.id === item.id);
            return gear && selectedVariant(gear, item)?.preview_pending;
          }) && <NoticeBox>Loading selected item previews…</NoticeBox>}
          <Box mb={1}>
            <Tabs>
              {Array.from(
                { length: catalog.slot_count },
                (_, index) => index + 1
              ).map((slot) => (
                <Tabs.Tab
                  key={slot}
                  selected={draft.active === slot}
                  onClick={() => {
                    if (!locked) {
                      session.update({ ...draft, active: slot });
                    }
                  }}>
                  Preset {slot}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Box>
          <Flex mb={1} align="center">
            <Flex.Item grow>
              <Box bold>
                {cost} / {catalog.max_cost} points
              </Box>
            </Flex.Item>
            <Flex.Item>
              <Button.Confirm
                className={CHIP_BUTTON_CLASS}
                icon="eraser"
                disabled={locked || !items.length}
                content="Clear Loadout"
                confirmContent="Clear this preset?"
                onClick={() =>
                  session.update({
                    ...draft,
                    slots: { ...draft.slots, [draft.active]: [] },
                  })
                }
              />
            </Flex.Item>
          </Flex>
          {!items.length && (
            <Box color="label">Select items from the gallery.</Box>
          )}
          {items.map((item) => {
            const gear = catalog.items.find((entry) => entry.id === item.id);
            const name = (gear && selectedVariant(gear, item)?.name) || item.id;
            return (
              <Box
                key={item.id}
                mb={0.5}
                className={`RogueStar__selectedTraitCard${
                  focusedItem?.id === item.id
                    ? ' RogueStar__selectedTraitCard--open'
                    : ''
                }`}>
                <Flex align="center" wrap={false}>
                  <Flex.Item grow minWidth={0}>
                    <Button
                      className="RogueStar__selectedTraitButton"
                      fluid
                      verticalAlignContent="middle"
                      tooltip={name}
                      selected={focusedItem?.id === item.id}
                      disabled={locked}
                      onClick={() => this.props.onFocusItem(item.id)}>
                      <Flex align="center" wrap={false}>
                        <Flex.Item grow minWidth={0}>
                          <Box className="RogueStar__selectedTraitName">
                            {name}
                          </Box>
                        </Flex.Item>
                        {gear && (
                          <Flex.Item shrink={0} ml={0.5}>
                            <Box
                              as="span"
                              className="RogueStar__loadoutItemPoints"
                              aria-label={`Loadout points: ${gear.cost}`}>
                              {gear.cost} pt
                            </Box>
                          </Flex.Item>
                        )}
                      </Flex>
                    </Button>
                  </Flex.Item>
                  <Flex.Item shrink={0}>
                    <Button
                      className="RogueStar__selectedTraitRemoveButton"
                      icon="times"
                      verticalAlignContent="middle"
                      tooltip={`Remove ${name}`}
                      aria-label={`Remove ${name}`}
                      disabled={locked}
                      onClick={() =>
                        session.update({
                          ...draft,
                          slots: {
                            ...draft.slots,
                            [draft.active]: items.filter(
                              (entry) => entry.id !== item.id
                            ),
                          },
                        })
                      }
                    />
                  </Flex.Item>
                </Flex>
              </Box>
            );
          })}
        </Section>
        {focusedGear && focusedItem && (
          <Section title="Item Settings">
            <Box bold mb={0.5}>
              {focusedGear.name}
            </Box>
            <Box mb={1}>{focusedGear.description}</Box>
            {!focusedGear.permitted && (
              <NoticeBox>
                This item will not equip for the current preview job or species.
              </NoticeBox>
            )}
            {focusedGear.tweaks.map((tweak) => (
              <TweakEditor
                key={tweak.id}
                tweak={tweak}
                value={tweakValue(focusedItem, tweak)}
                savedValue={
                  savedItem ? tweakValue(savedItem, tweak) : tweak.default
                }
                placeholder={
                  tweak.placeholder_key
                    ? focusedVariant?.[tweak.placeholder_key]
                    : undefined
                }
                disabled={locked}
                onChange={(value) =>
                  session.updateTweak(focusedItem.id, tweak, value)
                }
              />
            ))}
          </Section>
        )}
      </>
    );
  }
}
