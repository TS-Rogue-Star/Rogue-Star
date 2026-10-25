// ////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Occupation /////
// ////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
// ////////////////////////////////////////////////////////////////////////////////////

import { Color } from 'common/color';
import { useLocalState } from '../../backend';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  NoticeBox,
  Section,
  Tooltip,
} from '../../components';
import type { PreviewDirectionEntry } from '../../utils/character-preview';
import { LivePreviewCard } from './components';
import { PersistenceToggle } from './components/PersistenceToggle';
import { CHIP_BUTTON_CLASS } from './constants';
import type { EquipmentTabProps } from './EquipmentTab';
import { IdentitySaveSection } from './IdentityTab';
import type { OccupationDraft, OccupationJob } from './occupationTypes';
import type { OccupationSession } from './services/occupationSession';
import {
  getOccupationPreviewKey,
  occupationMatchesSearch,
  occupationPreviewRecipes,
  OCCUPATION_FALLBACKS,
  OCCUPATION_PRIORITIES,
  resetOccupationDraft,
  setOccupationPriority,
} from './utils/occupation';

type Props = Omit<EquipmentTabProps, 'session'> & {
  readonly session: OccupationSession;
};

const DEPARTMENT_COLOR_OVERRIDES: Record<string, string> = {
  Civilian: '#d3d3d3',
  Synthetic: '#3f823f',
};

const DEPARTMENT_COLUMNS: Record<string, number> = {
  Command: 0,
  Security: 0,
  Engineering: 0,
  Medical: 1,
  Research: 1,
  Cargo: 2,
  Synthetic: 2,
  'ITV Talon': 2,
  Civilian: 3,
};

const previewCaches = new WeakMap<
  OccupationSession,
  { signature: string; preview: PreviewDirectionEntry[] }
>();

const OccupationJobDetails = ({
  job,
  title,
}: {
  readonly job: OccupationJob;
  readonly title: string;
}) => (
  <Box className="RogueStar__occupationDetails">
    {(job.descriptions[title] || []).map((paragraph, index) => (
      <Box key={index} mb={1} style={{ 'white-space': 'pre-line' }}>
        {paragraph}
      </Box>
    ))}
    <Box mb={0.5}>
      <b>Departments:</b> {job.departments.join(', ')}
    </Box>
    {!!job.manages.length && (
      <Box mb={0.5}>
        <b>Manages:</b> {job.manages.join(', ')}
      </Box>
    )}
    {!!job.supervisors && (
      <Box mb={0.5}>
        <b>Reports to:</b> {job.supervisors}
      </Box>
    )}
  </Box>
);

const OccupationJobRow = ({
  job,
  draft,
  locked,
  assistantEnabled,
  expanded,
  onExpand,
  onUpdate,
}: {
  readonly job: OccupationJob;
  readonly draft: OccupationDraft;
  readonly locked: boolean;
  readonly assistantEnabled: boolean;
  readonly expanded: boolean;
  readonly onExpand: () => void;
  readonly onUpdate: (draft: OccupationDraft) => void;
}) => {
  const priority = draft.priorities[job.id];
  const title = draft.titles[job.id] || job.id;
  const disabled = locked || (assistantEnabled && !job.assistant);
  return (
    <Box
      className={`RogueStar__occupationJob${!job.available ? ' RogueStar__occupationJob--unavailable' : ''}`}>
      <Flex align="center" justify="space-between" gap={0.5}>
        <Flex.Item grow minWidth={0}>
          <Button
            className={`${CHIP_BUTTON_CLASS} RogueStar__occupationJobName`}
            icon={expanded ? 'chevron-down' : 'chevron-right'}
            selected={expanded}
            fluid
            aria-expanded={expanded}
            onClick={onExpand}>
            {job.id}
          </Button>
        </Flex.Item>
        <Flex.Item shrink={0}>
          <Box
            className="RogueStar__occupationPriorities"
            role="group"
            aria-label={`${job.id} preference`}>
            {job.assistant ? (
              <Button.Checkbox
                className={CHIP_BUTTON_CLASS}
                checked={priority === 3}
                disabled={disabled || (!job.available && priority !== 3)}
                aria-label={`Always be ${job.id}`}
                onClick={() =>
                  onUpdate(
                    setOccupationPriority(draft, job.id, priority === 3 ? 4 : 3)
                  )
                }>
                {priority === 3 ? 'Yes' : 'No'}
              </Button.Checkbox>
            ) : (
              <Box
                className={`RogueStar__occupationPriorityControl RogueStar__occupationPriority--${priority}`}>
                <Box className="RogueStar__occupationPriorityTrack">
                  <Box
                    className="RogueStar__occupationPriorityFill"
                    style={{ transform: `scaleX(${(4 - priority) / 3})` }}
                  />
                  {OCCUPATION_PRIORITIES.map((choice) => (
                    <Button
                      key={choice.value}
                      className={`RogueStar__occupationPriorityStop${
                        choice.value > priority
                          ? ' RogueStar__occupationPriorityStop--filled'
                          : ''
                      }`}
                      selected={priority === choice.value}
                      role="button"
                      aria-label={`${job.id}: ${choice.label}`}
                      aria-pressed={priority === choice.value}
                      tooltip={`${job.id}: ${choice.label}`}
                      tooltipPosition="bottom"
                      disabled={
                        disabled || (!job.available && choice.value !== 4)
                      }
                      onClick={() =>
                        onUpdate(
                          setOccupationPriority(draft, job.id, choice.value)
                        )
                      }
                    />
                  ))}
                </Box>
                <Box className="RogueStar__occupationPriorityValue">
                  {
                    OCCUPATION_PRIORITIES.find(
                      (choice) => choice.value === priority
                    )?.label
                  }
                </Box>
              </Box>
            )}
          </Box>
        </Flex.Item>
      </Flex>
      {job.titles.length > 1 && (
        <Flex align="center" gap={0.5} mt={0.5}>
          <Box color="label">Title</Box>
          <Flex.Item grow minWidth={0}>
            <Dropdown
              className={`${CHIP_BUTTON_CLASS} RogueStar__identityDropdown RogueStar__occupationDropdown`}
              controlContentClassName="Button__content RogueStar__identityDropdownContent"
              dropdownStyle="rogue-star"
              width="100%"
              options={job.titles}
              selected={title}
              disabled={disabled || !job.available}
              onSelected={(value) =>
                onUpdate({
                  ...draft,
                  titles: { ...draft.titles, [job.id]: value },
                })
              }
            />
          </Flex.Item>
        </Flex>
      )}
      {job.restriction && (
        <Box mt={0.5} color="average">
          {job.restriction}
        </Box>
      )}
      {expanded && <OccupationJobDetails job={job} title={title} />}
    </Box>
  );
};

export const OccupationTab = (props: Props, context) => {
  const { session, stateToken } = props;
  const [search, setSearch] = useLocalState(
    context,
    `occupationSearch-${stateToken}`,
    ''
  );
  const [expanded, setExpanded] = useLocalState<string | null>(
    context,
    `occupationExpanded-${stateToken}`,
    null
  );
  const { draft, catalog } = session;
  if (!draft || !catalog) {
    return (
      <Section title="Occupation">
        <NoticeBox danger={!!session.error}>
          {session.error || 'Loading occupations…'}
        </NoticeBox>
        {!!session.error && (
          <Button
            className={CHIP_BUTTON_CLASS}
            disabled={session.loading}
            onClick={() => session.load()}>
            Retry
          </Button>
        )}
      </Section>
    );
  }
  const locked = props.uiLocked || session.loading || session.saving;
  const assistant = catalog.jobs.find((job) => job.assistant);
  const assistantEnabled = !!assistant && draft.priorities[assistant.id] === 3;
  const fallbacks = OCCUPATION_FALLBACKS.map((label, index) =>
    index === 1 && assistant ? `Join as ${assistant.id}` : label
  );
  const jobs = catalog.jobs.filter((job) =>
    occupationMatchesSearch(job, search)
  );
  const departments = catalog.departments
    .map((department) => ({
      ...department,
      jobs: jobs.filter((job) => job.department === department.id),
    }))
    .filter((department) => department.jobs.length);
  const departmentColumns = [0, 1, 2, 3].map((column) =>
    departments.filter(
      (department) => (DEPARTMENT_COLUMNS[department.id] ?? 2) === column
    )
  );
  const renderDepartment = (department: (typeof departments)[number]) => {
    const color = DEPARTMENT_COLOR_OVERRIDES[department.id] || department.color;
    const fill = Color.fromHex(color);
    fill.a = 0.14;
    return (
      <Section
        key={department.id}
        title={department.id}
        className="RogueStar__occupationDepartment"
        style={{
          'border-top-color': color,
          'background-image': `linear-gradient(${fill.toString()}, ${fill.toString()})`,
        }}>
        {department.jobs.map((job) => (
          <OccupationJobRow
            key={job.id}
            job={job}
            draft={draft}
            locked={locked}
            assistantEnabled={assistantEnabled}
            expanded={expanded === job.id}
            onExpand={() => setExpanded(expanded === job.id ? null : job.id)}
            onUpdate={(next) => session.update(next)}
          />
        ))}
      </Section>
    );
  };
  const key = getOccupationPreviewKey(catalog, draft);
  const selectedPreview = session.previews.get(key);
  let cache = previewCaches.get(session);
  if (!cache) {
    cache = { signature: '', preview: [] };
    previewCaches.set(session, cache);
  }
  const signature = `${key}|${session.previewSignature}|${props.previewSignature}|${props.assetRevision}|${props.showEquipment}|${props.showJobGear}|${props.showLoadoutGear}|${props.canvasWidth}x${props.canvasHeight}`;
  if (selectedPreview && props.previewReady && signature !== cache.signature) {
    cache.preview = props.renderPreview(
      occupationPreviewRecipes(selectedPreview, props.showJobGear),
      false
    );
    cache.signature = signature;
  }
  const background = props.resolvedCanvasBackground?.asset;
  return (
    <Box className="RogueStar RogueStar__occupationTab" height="100%">
      <Flex direction="row" gap={1} wrap={false} height="100%">
        <Flex.Item basis="1258px" shrink={0} minWidth={0}>
          <Flex direction="column" gap={1} height="100%">
            <Flex.Item grow minHeight={0}>
              <Section
                title="Occupations"
                fill
                className="RogueStar__occupationWorkspace">
                <Input
                  fluid
                  placeholder="Search occupations, titles, or departments…"
                  value={search}
                  onInput={(_event, value) => setSearch(value)}
                />
                {assistantEnabled && (
                  <NoticeBox mt={1}>
                    Always joining as {assistant?.id}. Other occupation
                    preferences are retained.
                  </NoticeBox>
                )}
                <Box className="RogueStar__occupationDepartments">
                  {departmentColumns.map(
                    (column, index) =>
                      !!column.length && (
                        <Box
                          key={index}
                          className="RogueStar__occupationDepartmentColumn">
                          {column.map(renderDepartment)}
                        </Box>
                      )
                  )}
                  {!jobs.length && (
                    <NoticeBox>No occupations match your search.</NoticeBox>
                  )}
                </Box>
              </Section>
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Section>
                <Box className="RogueStar__occupationOptions">
                  <Box minWidth={0}>
                    <Box color="label" mb={0.5}>
                      Spawn Location
                    </Box>
                    <Flex align="center" gap={0.5}>
                      <Flex.Item grow minWidth={0}>
                        <Dropdown
                          className={`${CHIP_BUTTON_CLASS} RogueStar__identityDropdown RogueStar__occupationDropdown`}
                          controlContentClassName="Button__content RogueStar__identityDropdownContent"
                          dropdownStyle="rogue-star"
                          width="100%"
                          options={catalog.spawnpoint_options}
                          selected={draft.spawnpoint}
                          aria-label="Spawn Location"
                          disabled={locked}
                          onSelected={(value) =>
                            session.update({ ...draft, spawnpoint: value })
                          }
                        />
                      </Flex.Item>
                      <Flex.Item shrink={0}>
                        <PersistenceToggle
                          subject="spawn"
                          enabled={draft.persist_spawn ?? true}
                          disabled={locked}
                          onChange={(persist_spawn) =>
                            session.update({ ...draft, persist_spawn })
                          }
                        />
                      </Flex.Item>
                    </Flex>
                  </Box>
                  <Box minWidth={0}>
                    <Box color="label" mb={0.5}>
                      If preferences are unavailable
                    </Box>
                    <Dropdown
                      className={`${CHIP_BUTTON_CLASS} RogueStar__identityDropdown RogueStar__occupationDropdown`}
                      controlContentClassName="Button__content RogueStar__identityDropdownContent"
                      dropdownStyle="rogue-star"
                      width="100%"
                      options={fallbacks}
                      selected={fallbacks[draft.alternate_option]}
                      aria-label="If preferences are unavailable"
                      disabled={locked}
                      onSelected={(value) =>
                        session.update({
                          ...draft,
                          alternate_option: fallbacks.indexOf(value),
                        })
                      }
                    />
                  </Box>
                  <Box minWidth={0}>
                    <Box color="label" mb={0.5}>
                      Event Participant
                    </Box>
                    <Button.Checkbox
                      className={CHIP_BUTTON_CLASS}
                      fluid
                      checked={draft.vantag_volunteer}
                      disabled={locked}
                      aria-label="Event Participant"
                      tooltip="Volunteer to play an admin-selected event character."
                      onClick={() =>
                        session.update({
                          ...draft,
                          vantag_volunteer: !draft.vantag_volunteer,
                        })
                      }>
                      {draft.vantag_volunteer ? 'Yes' : 'No'}
                    </Button.Checkbox>
                  </Box>
                  <Box minWidth={0}>
                    <Box color="label" mb={0.5}>
                      Event Preference
                    </Box>
                    <Tooltip content="How you want to be involved with event characters, ERP-wise. They can see this choice on their HUD. Event characters are admin-selected players who may have assigned objectives and must respect your preferences and roleplay their actions.">
                      <Dropdown
                        className={`${CHIP_BUTTON_CLASS} RogueStar__identityDropdown RogueStar__occupationDropdown`}
                        controlContentClassName="Button__content RogueStar__identityDropdownContent"
                        dropdownStyle="rogue-star"
                        width="100%"
                        options={catalog.event_preference_options.map(
                          (option) => ({
                            value: option.value,
                            displayText: option.label,
                          })
                        )}
                        selected={draft.vantag_preference}
                        displayText={
                          catalog.event_preference_options.find(
                            (option) => option.value === draft.vantag_preference
                          )?.label
                        }
                        aria-label="Event Preference"
                        disabled={locked}
                        onSelected={(vantag_preference) =>
                          session.update({ ...draft, vantag_preference })
                        }
                      />
                    </Tooltip>
                  </Box>
                  <Button
                    className={CHIP_BUTTON_CLASS}
                    icon="rotate-left"
                    disabled={locked}
                    tooltip="Clear every occupation preference and reset alternate titles. The fallback option, spawn location, and event settings are retained."
                    onClick={() => session.update(resetOccupationDraft(draft))}>
                    Reset
                  </Button>
                </Box>
              </Section>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item grow minWidth={0}>
          <Flex direction="column" gap={1} height="100%" minHeight={0}>
            <Flex.Item
              basis="448px"
              shrink={0}
              minHeight={0}
              position="relative">
              <LivePreviewCard
                {...props}
                preview={cache.preview}
                previewBackgroundImage={
                  background?.png
                    ? `data:image/png;base64,${background.png}`
                    : null
                }
                previewBackgroundTileWidth={
                  background?.width
                    ? background.width * props.canvasBackgroundScale
                    : undefined
                }
                previewBackgroundTileHeight={
                  background?.height
                    ? background.height * props.canvasBackgroundScale
                    : undefined
                }
              />
              {(!selectedPreview || !props.previewReady || session.loading) && (
                <Box className="RogueStar__occupationPreviewStatus">
                  {session.previewError ||
                    (session.previewComplete && !selectedPreview
                      ? 'This outfit preview is unavailable.'
                      : 'Loading occupation outfit…')}
                  {(session.previewError || session.previewComplete) &&
                    !session.loading && (
                      <Button
                        className={CHIP_BUTTON_CLASS}
                        onClick={() => session.load()}>
                        Retry previews
                      </Button>
                    )}
                </Box>
              )}
            </Flex.Item>
            <Flex.Item shrink={0}>
              <IdentitySaveSection
                dirty={session.dirty}
                pendingSave={session.saving}
                pendingClose={session.closing}
                uiLocked={props.uiLocked || session.loading}
                saveError={session.error}
                validationError={null}
                onSave={() => session.save()}
                onSaveAndClose={() => session.save(true)}
                onDiscardAndClose={() => session.discard(true)}
              />
              {!!session.error && (
                <Button.Confirm
                  className={CHIP_BUTTON_CLASS}
                  disabled={locked}
                  content="Reload saved Occupation"
                  confirmContent="Discard draft and reload"
                  onClick={() => session.load(true)}
                />
              )}
            </Flex.Item>
            <Flex.Item grow minHeight={0}>
              <Section title="Department Hours" fill scrollable>
                <Box color="label" mb={1}>
                  Account-wide played hours and available paid time off.
                </Box>
                <table className="RogueStar__occupationHours">
                  <thead>
                    <tr>
                      <th>Department</th>
                      <th>Played (h)</th>
                      <th>PTO (h)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {catalog.hours.map((row) => (
                      <tr key={row.department}>
                        <td>{row.department}</td>
                        <td>{row.played.toFixed(1)}</td>
                        <td>{row.pto.toFixed(1)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </Section>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </Box>
  );
};
