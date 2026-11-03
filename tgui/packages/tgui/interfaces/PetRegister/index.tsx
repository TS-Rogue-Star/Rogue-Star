// ////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Pet Register Interface //
// ////////////////////////////////////////////////////////////////////////

import { Component } from 'inferno';
import { useBackend } from '../../backend';
import { UI_DISABLED, UI_INTERACTIVE, UI_UPDATE } from '../../constants';
import {
  Box,
  Button,
  Dropdown,
  Icon,
  Input,
  Modal,
  ProgressBar,
  TextArea,
} from '../../components';
import { Window } from '../../layouts';
import Eye1IconAsset from '../../../../public/Icons/Rogue Star/eye 1.png';
import Eye2IconAsset from '../../../../public/Icons/Rogue Star/eye 2.png';
import Eye3IconAsset from '../../../../public/Icons/Rogue Star/eye 3.png';
import { PetRegisterOpening } from './Opening';
import {
  Candidate,
  draftIsDirty,
  filterPets,
  Pet,
  PetDraft,
  PetRegisterData,
  replacementFor,
} from './model';

const CHIP = 'RogueStar__chip';
const POSITIVE = `${CHIP} RogueStar__glowButton--positive`;
type Params = Record<string, string | number>;
type Confirmation = {
  title: string;
  text: string;
  button: string;
  action: string;
  params: Params;
};
type WorkspaceProps = {
  readonly data: PetRegisterData;
  readonly act: (action: string, params?: Params) => void;
};
type WorkspaceState = {
  search: string;
  selectedId: string;
  draft: PetDraft | null;
  discardTarget: string | null;
  confirmation: Confirmation | null;
  waiting: boolean;
  requestResult: number;
  savingName: string | null;
  replacement: string;
};

const Portrait = (
  props: Readonly<{ portrait?: string | null; large?: boolean }>
) => (
  <Box
    className={`PetRegister__portrait${props.large ? ' PetRegister__portrait--large' : ''}`}>
    <Box className="PetRegister__orbit" />
    {props.portrait ? (
      <img src={`data:image/png;base64,${props.portrait}`} alt="" />
    ) : (
      <Box className="PetRegister__silhouette">
        <Icon name="paw" size={props.large ? 4 : 2.5} />
        <Box>Portrait unavailable</Box>
      </Box>
    )}
  </Box>
);

const Badge = (props: Readonly<{ active?: boolean; legacy?: boolean }>) => (
  <Box
    className={`PetRegister__badge${props.active ? ' PetRegister__badge--active' : ''}`}>
    <Icon name={props.active ? 'paw' : props.legacy ? 'history' : 'moon'} />
    {props.active ? 'With you' : props.legacy ? 'Legacy record' : 'Stored'}
  </Box>
);

export const PetRegister = (_props, context) => {
  const { data, act, config } = useBackend<PetRegisterData>(context);
  const statusIcons = {
    [UI_INTERACTIVE]: Eye1IconAsset,
    [UI_UPDATE]: Eye2IconAsset,
    [UI_DISABLED]: Eye3IconAsset,
  };
  return (
    <Window
      title="PET System"
      width={1200}
      height={760}
      resizable
      theme="nanotrasen rogue-star-window"
      statusIcon={
        <img
          className="TitleBar__statusIcon RogueStar__statusIcon"
          src={statusIcons[config.status] || Eye3IconAsset}
          alt=""
        />
      }>
      <Window.Content scrollable className="PetRegister__content">
        <PetWorkspace data={data} act={act} />
      </Window.Content>
      <PetRegisterOpening />
    </Window>
  );
};

export class PetWorkspace extends Component<WorkspaceProps, WorkspaceState> {
  state: WorkspaceState;
  constructor(props: WorkspaceProps) {
    super(props);
    this.state = {
      search: '',
      selectedId: props.data.pets?.[0]?.id || '',
      draft: null,
      discardTarget: null,
      confirmation: null,
      waiting: false,
      requestResult: props.data.resultId,
      savingName: null,
      replacement: '',
    };
  }

  componentDidUpdate() {
    const { data } = this.props;
    const { waiting, requestResult, savingName } = this.state;
    if (waiting && data.resultId !== requestResult) {
      if (savingName && !data.messageError && data.savedName) {
        this.setState({
          waiting: false,
          savingName: null,
          draft: null,
          selectedId: `saved:${data.savedName}`,
        });
      } else {
        this.setState({ waiting: false, savingName: null });
      }
    }
  }

  send = (action: string, params: Params) => {
    this.setState({
      waiting: true,
      requestResult: this.props.data.resultId,
      confirmation: null,
    });
    this.props.act(action, params);
  };

  select = (id: string) => {
    if (id === this.state.selectedId && !this.props.data.candidate) {
      return;
    }
    if (draftIsDirty(this.state.draft)) {
      this.setState({ discardTarget: id });
      return;
    }
    this.finishSelect(id);
  };

  finishSelect = (id: string) => {
    if (this.props.data.candidate) {
      this.props.act('cancel_candidate');
    }
    this.setState({
      selectedId: id,
      draft: null,
      discardTarget: null,
      replacement: '',
    });
  };

  renderProfile(selected: Pet, busy: boolean) {
    const { data } = this.props;
    const pets = data.pets || [];
    const { draft } = this.state;
    const staleDraft = !!draft && draft.revision !== data.revision;
    const replacement = replacementFor(
      pets,
      selected.name,
      data.slots,
      this.state.replacement
    );
    return (
      <Box
        className={`PetRegister__detail${draft ? ' PetRegister__detail--editing' : ''}`}>
        <Box className="PetRegister__detailTop">
          <span className="PetRegister__eyebrow">Pet profile</span>
          <Badge active={selected.active} legacy={selected.legacy} />
        </Box>
        <Portrait portrait={selected.portrait} large />
        <Box className="PetRegister__profileName">{selected.name}</Box>
        <Box className="PetRegister__profileSpecies">{selected.species}</Box>
        {draft ? (
          <Box className="PetRegister__editor">
            <label>
              Name{' '}
              <span>
                {draft.name.length}/{data.nameLimit}
              </span>
            </label>
            <Input
              fluid
              value={draft.name}
              maxLength={data.nameLimit}
              disabled={busy}
              onInput={(_, value) =>
                this.setState({ draft: { ...draft, name: value } })
              }
            />
            <label>
              Pet notes{' '}
              <span>
                {draft.note.length}/{data.noteLimit}
              </span>
            </label>
            <TextArea
              fluid
              height="110px"
              value={draft.note}
              maxLength={data.noteLimit}
              disabled={busy}
              dontUseTabForIndent
              onInput={(_, value) =>
                this.setState({ draft: { ...draft, note: value } })
              }
            />
            {staleDraft && (
              <Box className="PetRegister__notice">
                Your records changed. Reload the saved details before editing
                again.
              </Box>
            )}
            <Box className="PetRegister__actions">
              <Button
                className={POSITIVE}
                icon="check"
                disabled={
                  busy ||
                  staleDraft ||
                  !draft.name.trim() ||
                  !draftIsDirty(draft) ||
                  pets.some(
                    (pet) =>
                      !pet.legacy &&
                      pet.id !== draft.pet.id &&
                      pet.name === draft.name.trim()
                  )
                }
                onClick={() => {
                  this.setState({ savingName: draft.name.trim() });
                  this.send('save_details', {
                    name: draft.pet.name,
                    newName: draft.name,
                    note: draft.note,
                    revision: draft.revision,
                  });
                }}>
                Save Changes
              </Button>
              <Button
                className={CHIP}
                disabled={busy}
                onClick={() => this.setState({ draft: null })}>
                {staleDraft ? 'Reload Details' : 'Cancel'}
              </Button>
            </Box>
          </Box>
        ) : (
          <>
            <Box className="PetRegister__notes">
              <Box className="PetRegister__notesHeading">
                <Icon name="feather-alt" /> Pet notes
              </Box>
              <Box className={!selected.note ? 'PetRegister__muted' : ''}>
                {selected.note || 'No notes recorded.'}
              </Box>
            </Box>
            {!!selected.legacy && (
              <Box className="PetRegister__notice">
                This pet is in your previous pet storage. Retrieve them to bring
                their record into this registry.
              </Box>
            )}
            {!!selected.legacy && replacement.required && (
              <Box className="PetRegister__replacement">
                <label>Replace a stored record</label>
                {replacement.collision ? (
                  <Box>{replacement.target?.name} already has a record.</Box>
                ) : (
                  <Dropdown
                    fluid
                    options={replacement.options}
                    selected={this.state.replacement}
                    placeholder="Choose a pet record"
                    onSelected={(value) =>
                      this.setState({ replacement: value })
                    }
                  />
                )}
              </Box>
            )}
            {selected.active ? (
              <Box className="PetRegister__activeHint">
                <Icon name="paw" /> Your pet is with you. Return them to storage
                to edit their details or retrieve another pet.
              </Box>
            ) : (
              <>
                <Button
                  fluid
                  className={`${POSITIVE} PetRegister__retrieve`}
                  icon="paw"
                  disabled={
                    busy ||
                    data.retrievalBlocked ||
                    !selected.valid ||
                    (selected.legacy && !replacement.valid)
                  }
                  onClick={() => {
                    const params = {
                      name: selected.name,
                      revision: data.revision,
                      confirm: 1,
                      replacement: selected.legacy
                        ? replacement.target?.name || ''
                        : '',
                    };
                    if (selected.legacy) {
                      this.setState({
                        confirmation: {
                          title: 'Import legacy pet',
                          text: `Import and retrieve ${selected.name}?${replacement.target ? ` This replaces ${replacement.target.name}'s stored record.` : ''}`,
                          button: 'Import & Retrieve',
                          action: 'retrieve_legacy',
                          params,
                        },
                      });
                    } else {
                      this.send('retrieve', params);
                    }
                  }}>
                  {selected.legacy ? 'Import & Retrieve' : 'Retrieve Pet'}
                </Button>
                {!!data.retrievalBlocked && (
                  <Box className="PetRegister__footnote">
                    Return your active pet before retrieving another.
                  </Box>
                )}
                {!selected.valid && (
                  <Box className="PetRegister__notice">
                    This pet type is unavailable. The stored record has been
                    kept.
                  </Box>
                )}
              </>
            )}
            <Button
              fluid
              className={CHIP}
              icon="pen"
              disabled={busy || selected.active || selected.legacy}
              onClick={() =>
                this.setState({
                  draft: {
                    pet: selected,
                    name: selected.name,
                    note: selected.note,
                    revision: data.revision,
                  },
                })
              }>
              Edit Details
            </Button>
          </>
        )}
      </Box>
    );
  }

  render() {
    const { data } = this.props;
    const pets = data.pets || [];
    const { draft, confirmation, discardTarget, search } = this.state;
    const selected =
      pets.find((pet) => pet.id === this.state.selectedId) ||
      draft?.pet ||
      pets[0];
    const busy = data.busy || this.state.waiting;
    const progress = Math.max(0, Math.min(1, data.progress || 0));
    const operation =
      data.operation || 'Another PET System is processing your request…';
    const filtered = filterPets(pets, search);
    return (
      <Box className="RogueStar RogueStar--petRegister">
        <Box className="PetRegister__header">
          <Box className="PetRegister__brandIcon">
            <Icon name="paw" />
          </Box>
          <Box className="PetRegister__heading">
            <Box className="PetRegister__eyebrow">
              Petatronic energy transport
            </Box>
            <Box className="PetRegister__title">Pet registry</Box>
            <Box className="PetRegister__subtitle">
              {data.characterName}&apos;s registered pets
            </Box>
          </Box>
          <Box className="PetRegister__headerStatus">
            <Icon name={data.registrationUsed ? 'check-circle' : 'star'} />
            {data.registrationUsed
              ? 'Registered this shift'
              : 'One new registration available'}
          </Box>
        </Box>

        <Box className="PetRegister__account">
          <Box className="PetRegister__stat">
            <Icon name="paw" />
            <span>
              <b>
                {data.usedSlots} / {data.slots}
              </b>{' '}
              pet slots
            </span>
          </Box>
          <Box className="PetRegister__slotTrack">
            {Array.from({ length: data.slots || 1 }, (_, i) => (
              <span
                key={i}
                className={i < data.usedSlots ? 'PetRegister__slot--used' : ''}
              />
            ))}
          </Box>
          <Box className="PetRegister__stat">
            <span className="PetRegister__triangle">◬</span>
            <span>
              <b>{data.triangles}</b> banked
            </span>
          </Box>
          <Button
            className={CHIP}
            icon="plus"
            disabled={
              busy ||
              data.slots >= data.maxSlots ||
              data.triangles < data.slotCost
            }
            tooltip={
              data.slots >= data.maxSlots
                ? 'Your storage is fully expanded.'
                : `Add one pet slot for ${data.slotCost} triangles. Deposit triangles at an electronic lockbox.`
            }
            onClick={() =>
              this.setState({
                confirmation: {
                  title: 'Expand pet storage',
                  text: `Purchase one pet slot for ${data.slotCost} ◬? Your capacity will increase to ${data.slots + 1}.`,
                  button: `Purchase · ${data.slotCost} ◬`,
                  action: 'purchase_slot',
                  params: {
                    revision: data.revision,
                    cost: data.slotCost,
                    confirm: 1,
                  },
                },
              })
            }>
            {data.slots >= data.maxSlots
              ? 'Storage fully expanded'
              : `Expand Storage · ${data.slotCost} ◬`}
          </Button>
        </Box>

        {!!data.sessionOnly && (
          <Box className="PetRegister__notice">
            Event character: these pet changes last for this session.
          </Box>
        )}
        {!!data.legacySlotMismatch && (
          <Box className="PetRegister__notice">
            Older pet records could not be checked because your Character Setup
            selection does not match your current character&apos;s name. Select
            the matching character slot, then close and reopen the PET System to
            try again.
          </Box>
        )}
        {!!data.legacyLoadFailed && (
          <Box className="PetRegister__notice">
            An older pet record could not be read. Your current pet records are
            still available. Please contact an administrator for help recovering
            the older record.
          </Box>
        )}
        {!!data.busy && (
          <Box
            className={`PetRegister__progress${data.operation ? '' : ' PetRegister__progress--indeterminate'}`}>
            <Box className="PetRegister__progressIcon">
              <Icon name="paw" />
            </Box>
            <Box className="PetRegister__progressBody">
              <Box className="PetRegister__progressHeader">
                <span role="status">{operation}</span>
                <span className="PetRegister__progressValue">
                  {data.operation
                    ? `${Math.round(progress * 100)}%`
                    : 'Please wait'}
                </span>
              </Box>
              <ProgressBar
                className="PetRegister__progressBar"
                value={data.operation ? progress : 0.3}
                role="progressbar"
                aria-label={operation}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={
                  data.operation ? Math.round(progress * 100) : undefined
                }>
                {''}
              </ProgressBar>
            </Box>
          </Box>
        )}
        {!!data.message && (
          <Box
            role="status"
            className={`PetRegister__notice${data.messageError ? ' PetRegister__notice--error' : ' PetRegister__notice--success'}`}>
            <Icon
              name={data.messageError ? 'exclamation-circle' : 'check-circle'}
            />{' '}
            {data.message}
          </Box>
        )}

        <Box className="PetRegister__workspace">
          <Box className="PetRegister__collection">
            <Box className="PetRegister__sectionHeading">
              <span className="PetRegister__eyebrow">Registered pets</span>
            </Box>
            <Input
              fluid
              className="PetRegister__search"
              placeholder="Search by name or species…"
              value={search}
              onInput={(_, value) => this.setState({ search: value })}
            />
            {filtered.length ? (
              <Box className="PetRegister__gallery">
                {filtered.map((pet) => (
                  <Button
                    key={pet.id}
                    className={`PetRegister__card${selected?.id === pet.id && !data.candidate ? ' PetRegister__card--selected' : ''}`}
                    disabled={busy}
                    onClick={() => this.select(pet.id)}
                    tooltip={`${pet.name} · ${pet.species}`}>
                    <Portrait portrait={pet.portrait} />
                    <Box className="PetRegister__cardName">{pet.name}</Box>
                    <Box className="PetRegister__species">{pet.species}</Box>
                    <Badge active={pet.active} legacy={pet.legacy} />
                  </Button>
                ))}
              </Box>
            ) : (
              <Box className="PetRegister__empty">
                <Icon name={pets.length ? 'search' : 'paw'} size={3} />
                <h2>
                  {pets.length ? 'No matching pets' : 'No pets registered'}
                </h2>
                <p>
                  {pets.length
                    ? 'Try another name or species.'
                    : 'Drag a creature onto the PET System to register them.'}
                </p>
              </Box>
            )}
            <Box className="PetRegister__dropHint">
              <Icon name="hand-pointer" />
              <span>
                Drag a pet onto the <b>machine</b> to register them or return
                them to storage.
              </span>
            </Box>
            <Box className="PetRegister__footnote">
              <Icon name="paw" /> One active pet at a time.
            </Box>
          </Box>

          {data.candidate ? (
            <CandidatePanel
              key={data.candidate.token}
              candidate={data.candidate}
              data={data}
              busy={busy}
              send={this.send}
              cancel={() => this.props.act('cancel_candidate')}
            />
          ) : selected ? (
            this.renderProfile(selected, busy)
          ) : (
            <Box className="PetRegister__detail PetRegister__welcome">
              <Icon name="cat" size={3} />
              <h2>Pet registration &amp; storage</h2>
              <p>Register pets and retrieve them on future shifts.</p>
              <Box className="PetRegister__welcomeStep">
                <Icon name="hand-pointer" />
                <span>Bring a pet to the machine.</span>
              </Box>
              <Box className="PetRegister__welcomeStep">
                <Icon name="id-card" />
                <span>Set name and description.</span>
              </Box>
              <Box className="PetRegister__welcomeStep">
                <Icon name="paw" />
                <span>Retrieve them on a future shift.</span>
              </Box>
            </Box>
          )}
        </Box>

        {confirmation && (
          <Modal className="PetRegister__modal" width="390px">
            <Icon name="paw" size={2} />
            <h2>{confirmation.title}</h2>
            <p>{confirmation.text}</p>
            {confirmation.params.revision !== data.revision && (
              <Box className="PetRegister__notice">
                Your records changed. Cancel and review the action again.
              </Box>
            )}
            <Box className="PetRegister__actions">
              <Button
                className={POSITIVE}
                disabled={
                  busy || confirmation.params.revision !== data.revision
                }
                onClick={() =>
                  this.send(confirmation.action, confirmation.params)
                }>
                {confirmation.button}
              </Button>
              <Button
                className={CHIP}
                onClick={() => this.setState({ confirmation: null })}>
                Cancel
              </Button>
            </Box>
          </Modal>
        )}
        {discardTarget !== null && (
          <Modal className="PetRegister__modal" width="370px">
            <h2>Discard these edits?</h2>
            <p>Your saved pet details will stay as they are.</p>
            <Box className="PetRegister__actions">
              <Button
                className={CHIP}
                onClick={() => this.setState({ discardTarget: null })}>
                Keep Editing
              </Button>
              <Button
                className={`${CHIP} RogueStar__glowButton--negative`}
                onClick={() => this.finishSelect(discardTarget)}>
                Discard Edits
              </Button>
            </Box>
          </Modal>
        )}
      </Box>
    );
  }
}

type CandidateProps = {
  readonly candidate: Candidate;
  readonly data: PetRegisterData;
  readonly busy: boolean;
  readonly send: (action: string, params: Params) => void;
  readonly cancel: () => void;
};

type CandidateState = {
  name: string;
  destination: string;
  replacement: string;
};

class CandidatePanel extends Component<CandidateProps, CandidateState> {
  state: CandidateState;
  constructor(props: CandidateProps) {
    super(props);
    this.state = {
      name: props.candidate.name.slice(0, props.data.nameLimit),
      destination: 'personal',
      replacement: '',
    };
  }

  render() {
    const { candidate, data, busy, send, cancel } = this.props;
    const { name, destination } = this.state;
    const replacement = replacementFor(
      data.pets,
      name,
      data.slots,
      this.state.replacement
    );
    const storing = candidate.registered;
    const blocked =
      !storing &&
      (data.registrationUsed ||
        !name.trim() ||
        (destination === 'personal' &&
          (data.retrievalBlocked || !replacement.valid)) ||
        (destination === 'station' && !candidate.stationAllowed));
    return (
      <Box className="PetRegister__detail PetRegister__candidate">
        <Box className="PetRegister__detailTop">
          <span className="PetRegister__eyebrow">
            {storing ? 'Return to storage' : 'New pet registration'}
          </span>
        </Box>
        <Portrait portrait={candidate.portrait} large />
        <Box className="PetRegister__profileName">{candidate.name}</Box>
        <Box className="PetRegister__profileSpecies">{candidate.species}</Box>
        {storing ? (
          <Box className="PetRegister__activeHint">
            Return {candidate.name} to storage? Their saved appearance will be
            updated, and you can retrieve another pet.
          </Box>
        ) : (
          <Box className="PetRegister__editor">
            <label>
              Registered name{' '}
              <span>
                {name.length}/{data.nameLimit}
              </span>
            </label>
            <Input
              fluid
              value={name}
              maxLength={data.nameLimit}
              disabled={busy}
              onInput={(_, value) => this.setState({ name: value })}
            />
            <label>Register with</label>
            <Box className="PetRegister__destinations">
              <Button
                className={CHIP}
                selected={destination === 'personal'}
                disabled={busy}
                icon="paw"
                onClick={() => this.setState({ destination: 'personal' })}>
                My pets
              </Button>
              <Button
                className={CHIP}
                selected={destination === 'station'}
                disabled={busy || !candidate.stationAllowed}
                icon="building"
                onClick={() => this.setState({ destination: 'station' })}>
                Station
              </Button>
            </Box>
            <Box className="PetRegister__footnote">
              {destination === 'station'
                ? 'Contribute this pet to the station pool for future shifts.'
                : 'Your pet stays with you after registration. Drag them onto the machine again to store them.'}
            </Box>
            {destination === 'personal' && replacement.required && (
              <Box className="PetRegister__replacement">
                <label>
                  {replacement.collision
                    ? 'This name is already registered'
                    : 'Your storage is full'}
                </label>
                {replacement.collision ? (
                  <Box>
                    Registering will replace {replacement.target?.name}&apos;s
                    stored record.
                  </Box>
                ) : (
                  <Dropdown
                    fluid
                    options={replacement.options}
                    selected={this.state.replacement}
                    placeholder="Choose a record to replace"
                    onSelected={(value) =>
                      this.setState({ replacement: value })
                    }
                  />
                )}
              </Box>
            )}
            {!!data.registrationUsed && (
              <Box className="PetRegister__notice">
                You have already registered a new pet this shift.
              </Box>
            )}
            {destination === 'personal' && !!data.retrievalBlocked && (
              <Box className="PetRegister__notice">
                Return your current pet before registering another personal pet.
              </Box>
            )}
          </Box>
        )}
        <Box className="PetRegister__actions">
          <Button
            className={POSITIVE}
            icon={storing ? 'moon' : 'paw'}
            disabled={busy || blocked}
            onClick={() => {
              if (storing) {
                send('store', {
                  token: candidate.token,
                  revision: data.revision,
                  confirm: 1,
                });
                return;
              }
              send('register', {
                token: candidate.token,
                name: name.trim(),
                destination,
                replacement:
                  destination === 'personal'
                    ? replacement.target?.name || ''
                    : '',
                revision: data.revision,
                confirm: 1,
              });
            }}>
            {storing ? 'Return to Storage' : 'Register Pet'}
          </Button>
          <Button className={CHIP} disabled={busy} onClick={cancel}>
            Cancel
          </Button>
        </Box>
      </Box>
    );
  }
}
