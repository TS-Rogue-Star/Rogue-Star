import { useBackend } from '../backend';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Table,
} from '../components';
import { Window } from '../layouts';

type Need = {
  name: string;
  level: number;
  pressure: number;
  settable: boolean;
};

type Task = {
  index: number;
  name: string;
  tier: number;
  score: number;
  bored: number;
  weight: number;
  sleeping: boolean;
  why_zero: string | null;
  current: boolean;
};

type Note = {
  key: string;
  value: string;
  left: number | null;
};

type OpenPromise = {
  what: string;
  asked: string;
  who: string;
  state: string;
  left: number;
};

type Opinion = {
  name: string;
  opinion: number;
  opinion_label: string;
  danger: number;
  danger_label: string;
};

type Assignment = {
  name: string;
  with: string;
  left: number;
};

type Seen = {
  what: string;
  place: string;
  amount: number;
  age: number;
  kept: boolean;
};

type Data = {
  gone?: boolean;
  name: string;
  job: string;
  role: string;
  place: string;
  health: string;
  state: string;
  nutrition: number;
  workplace: string;
  trace: boolean;
  escaping: boolean;
  control: string;
  character: string;
  personality: string;
  needs: Need[];
  task: string | null;
  plan: string[];
  plan_step: number;
  planning: number | null;
  destination: string | null;
  walk_why: string | null;
  path_left: number;
  route_left: number;
  tasks: Task[];
  notes: Note[];
  crossed: Note[];
  promises: OpenPromise[];
  opinions: Opinion[];
  assignments: Assignment[];
  seen: Seen[];
  seen_total: number;
  seen_matching: number;
  seen_filter: string;
};

const TIERS = ['', 'idle', 'fulfillment', 'social', 'needs', 'survival'];

const ChangeButtons = (props: {
  readonly onChange: (by: number | null) => void;
}) => (
  <>
    <Button content="-10" onClick={() => props.onChange(-10)} />
    <Button content="+10" onClick={() => props.onChange(10)} />
    <Button content="Set" onClick={() => props.onChange(null)} />
  </>
);

export const NpcPanel = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  if (data.gone) {
    return (
      <Window width={500} height={200}>
        <Window.Content>
          <NoticeBox>This worker is gone.</NoticeBox>
        </Window.Content>
      </Window>
    );
  }
  const {
    needs = [],
    plan = [],
    tasks = [],
    notes = [],
    crossed = [],
    promises = [],
    opinions = [],
    assignments = [],
    seen = [],
  } = data;
  return (
    <Window width={620} height={800}>
      <Window.Content scrollable>
        <Section
          title={data.name}
          buttons={
            <Button
              icon="file-alt"
              selected={data.trace}
              content={data.trace ? 'Trace on' : 'Trace off'}
              onClick={() => act('trace')}
            />
          }>
          <LabeledList>
            <LabeledList.Item label="Job">
              {data.job} ({data.role})
            </LabeledList.Item>
            <LabeledList.Item label="Where">{data.place}</LabeledList.Item>
            <LabeledList.Item label="Workplace">
              {data.workplace}
            </LabeledList.Item>
            <LabeledList.Item label="State">{data.state}</LabeledList.Item>
            <LabeledList.Item label="Control">{data.control}</LabeledList.Item>
            <LabeledList.Item label="Character">
              {data.character}
            </LabeledList.Item>
            <LabeledList.Item label="Personality">
              {data.personality}
            </LabeledList.Item>
            <LabeledList.Item label="Health">{data.health}</LabeledList.Item>
            <LabeledList.Item label="Nutrition">
              {data.nutrition}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Needs">
          <Table>
            <Table.Row header>
              <Table.Cell>Need</Table.Cell>
              <Table.Cell>Level</Table.Cell>
              <Table.Cell>Pressure</Table.Cell>
              <Table.Cell />
            </Table.Row>
            {needs.map((need) => (
              <Table.Row key={need.name}>
                <Table.Cell>{need.name}</Table.Cell>
                <Table.Cell>{need.level}</Table.Cell>
                <Table.Cell>{need.pressure}</Table.Cell>
                <Table.Cell>
                  {need.settable && (
                    <Button
                      content="Set"
                      onClick={() => act('set_need', { name: need.name })}
                    />
                  )}
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
        <Section
          title="Doing"
          buttons={
            <Button
              icon="times"
              content="Drop task"
              disabled={!data.task}
              onClick={() => act('drop_task')}
            />
          }>
          <LabeledList>
            <LabeledList.Item label="Task">
              {data.task || 'nothing'}
            </LabeledList.Item>
            {data.planning !== null && (
              <LabeledList.Item label="Planning">
                {data.planning} tries so far
              </LabeledList.Item>
            )}
            <LabeledList.Item label="Plan">
              {plan.length === 0
                ? 'none'
                : plan.map((step, i) => (
                    <Box
                      key={i}
                      bold={i + 1 === data.plan_step}
                      color={
                        i + 1 === data.plan_step
                          ? 'good'
                          : i + 1 < data.plan_step
                            ? 'grey'
                            : undefined
                      }>
                      {i + 1}. {step}
                    </Box>
                  ))}
            </LabeledList.Item>
            <LabeledList.Item label="Walking to">
              {data.escaping
                ? 'escaping danger'
                : data.destination || 'nowhere'}
            </LabeledList.Item>
            {!!data.destination && (
              <LabeledList.Item label="Left">
                {data.route_left} rooms, {data.path_left} tiles of this leg
              </LabeledList.Item>
            )}
            {!!data.walk_why && (
              <LabeledList.Item label="Last walk note">
                {data.walk_why}
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        <Section title="Tasks">
          <Table>
            <Table.Row header>
              <Table.Cell>Task</Table.Cell>
              <Table.Cell>Tier</Table.Cell>
              <Table.Cell>Score</Table.Cell>
              <Table.Cell>Bored</Table.Cell>
              <Table.Cell>Weight</Table.Cell>
              <Table.Cell>Why zero</Table.Cell>
              <Table.Cell />
            </Table.Row>
            {tasks.map((task) => (
              <Table.Row key={task.index}>
                <Table.Cell bold={task.current}>{task.name}</Table.Cell>
                <Table.Cell>{TIERS[task.tier]}</Table.Cell>
                <Table.Cell>{task.score}</Table.Cell>
                <Table.Cell>{task.bored}</Table.Cell>
                <Table.Cell>
                  <Button
                    content={task.weight}
                    onClick={() => act('task_weight', { index: task.index })}
                  />
                </Table.Cell>
                <Table.Cell>{task.why_zero || ''}</Table.Cell>
                <Table.Cell>
                  <Button
                    content="Force"
                    onClick={() => act('force_task', { index: task.index })}
                  />
                  <Button
                    content="Wake"
                    disabled={!task.sleeping}
                    onClick={() => act('wake_task', { index: task.index })}
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
        <Section title="Promises">
          {promises.length === 0 ? (
            'none'
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>For</Table.Cell>
                <Table.Cell>Asked</Table.Cell>
                <Table.Cell>Bringing it</Table.Cell>
                <Table.Cell>State</Table.Cell>
                <Table.Cell>Seconds left</Table.Cell>
              </Table.Row>
              {promises.map((promise, i) => (
                <Table.Row key={i}>
                  <Table.Cell>{promise.what}</Table.Cell>
                  <Table.Cell>{promise.asked}</Table.Cell>
                  <Table.Cell>{promise.who}</Table.Cell>
                  <Table.Cell>{promise.state}</Table.Cell>
                  <Table.Cell>{promise.left}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
        <Section
          title="Crossed off"
          buttons={
            <Button
              icon="eraser"
              content="Clear all"
              disabled={crossed.length === 0}
              onClick={() => act('clear_crossed')}
            />
          }>
          {crossed.length === 0 ? (
            'none'
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>What</Table.Cell>
                <Table.Cell>Why</Table.Cell>
                <Table.Cell>Seconds left</Table.Cell>
              </Table.Row>
              {crossed.map((thing) => (
                <Table.Row key={thing.key}>
                  <Table.Cell>{thing.key}</Table.Cell>
                  <Table.Cell>{thing.value}</Table.Cell>
                  <Table.Cell>{thing.left ?? ''}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
        <Section
          title="Notes"
          buttons={
            <Button
              icon="eraser"
              content="Clear all"
              disabled={notes.length === 0}
              onClick={() => act('clear_notes')}
            />
          }>
          {notes.length === 0 ? (
            'none'
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Note</Table.Cell>
                <Table.Cell>Value</Table.Cell>
                <Table.Cell>Seconds left</Table.Cell>
              </Table.Row>
              {notes.map((note) => (
                <Table.Row key={note.key}>
                  <Table.Cell>{note.key}</Table.Cell>
                  <Table.Cell>{note.value}</Table.Cell>
                  <Table.Cell>{note.left}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
        <Section title="Opinions">
          {opinions.length === 0 ? (
            'none'
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Person</Table.Cell>
                <Table.Cell>Opinion</Table.Cell>
                <Table.Cell />
                <Table.Cell>Danger</Table.Cell>
                <Table.Cell />
              </Table.Row>
              {opinions.map((opinion) => (
                <Table.Row key={opinion.name}>
                  <Table.Cell>{opinion.name}</Table.Cell>
                  <Table.Cell>
                    {opinion.opinion} ({opinion.opinion_label})
                  </Table.Cell>
                  <Table.Cell>
                    <ChangeButtons
                      onChange={(by) =>
                        act('opinion', { name: opinion.name, by: by })
                      }
                    />
                  </Table.Cell>
                  <Table.Cell>
                    {opinion.danger}
                    {opinion.danger_label
                      ? ' (' + opinion.danger_label + ')'
                      : ''}
                  </Table.Cell>
                  <Table.Cell>
                    <ChangeButtons
                      onChange={(by) =>
                        act('danger', { name: opinion.name, by: by })
                      }
                    />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
        <Section title="Assignments">
          {assignments.length === 0 ? (
            'none'
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>What</Table.Cell>
                <Table.Cell>With</Table.Cell>
                <Table.Cell>Left</Table.Cell>
              </Table.Row>
              {assignments.map((assignment) => (
                <Table.Row key={assignment.name}>
                  <Table.Cell>{assignment.name}</Table.Cell>
                  <Table.Cell>{assignment.with}</Table.Cell>
                  <Table.Cell>{assignment.left}s</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
        <Section
          title={
            'Memory (nearest ' +
            seen.length +
            ' of ' +
            (data.seen_filter
              ? data.seen_matching + ' matching, ' + data.seen_total + ' in all'
              : data.seen_total) +
            ')'
          }>
          <Input
            fluid
            placeholder="Search things or places"
            value={data.seen_filter}
            onInput={(e, value) => act('seen_filter', { text: value })}
          />
          <Table>
            <Table.Row header>
              <Table.Cell>Thing</Table.Cell>
              <Table.Cell>Where</Table.Cell>
              <Table.Cell>How many</Table.Cell>
              <Table.Cell>Seen (s ago)</Table.Cell>
            </Table.Row>
            {seen.map((thing, i) => (
              <Table.Row key={i}>
                <Table.Cell>
                  {thing.what}
                  {thing.kept ? ' (work room)' : ''}
                </Table.Cell>
                <Table.Cell>{thing.place}</Table.Cell>
                <Table.Cell>{thing.amount}</Table.Cell>
                <Table.Cell>{thing.age}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
