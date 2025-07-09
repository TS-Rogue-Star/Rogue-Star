import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Button, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const Medigun = (props, context) => {
  const { act, data } = useBackend(context);

  let body = <MedigunContent />;

  return (
    <Window width={450} height={550} resizable>
      <Window.Content scrollable>{body}</Window.Content>
    </Window>
  );
};

const powerStatusMap = {
  1: {
    color: 'good',
    GeneratorText: 'Generator Running',
  },
  0: {
    color: 'bad',
    GeneratorText: 'Generator Offline',
  },
};

const gridStatusMap = {
  3: {
    color: 'bad',
    WirelessText: '',
  },
  2: {
    color: 'good',
    WirelessText: 'Using Grid',
  },
  1: {
    color: 'average',
    WirelessText: 'Grid Available',
  },
  0: {
    color: 'bad',
    WirelessText: 'Off Grid',
  },
};

const MedigunContent = (props, context) => {
  const { act, data } = useBackend(context);
  const GeneratorStatus = powerStatusMap[data.Generator] || powerStatusMap[0];
  const WirelessStatus = gridStatusMap[data.Gridstatus] || gridStatusMap[0];
  const adjustedCellChange = data.powerCellStatus / 100;
  const adjustedPhoronChange = data.PhoronStatus / 100;
  const adjustedBruteChange = data.BrutehealCharge / 100;
  const adjustedBurnChange = data.BurnhealCharge / 100;
  const adjustedToxChange = data.ToxhealCharge / 100;
  const brutevol = data.BrutehealVol;
  const burnvol = data.BurnhealVol;
  const toxvol = data.ToxhealVol;
  const patientname = data.patientname;
  const patienthealth = data.patienthealth / 100;
  const patientbrute = data.patientbrute;
  const patientburn = data.patientburn;
  const patienttox = data.patienttox;
  const patientoxy = data.patientoxy;

  return (
    <Fragment>
      <Section title="Power Status">
        <LabeledList>
          <LabeledList.Item label="Power Cell">
            <ProgressBar color="good" value={adjustedCellChange} />
          </LabeledList.Item>

          {data.Gridstatus !== 3 && (
            <LabeledList.Item
              label="Wireless Power"
              color={WirelessStatus.color}>
              <b>{WirelessStatus.WirelessText}</b>
            </LabeledList.Item>
          )}

          <LabeledList.Item
            label="Phoron Generator"
            color={GeneratorStatus.color}
            buttons={
              <Button
                content={data.Generator ? 'On' : 'Off'}
                selected={data.Generator}
                color={data.Generator ? '' : 'bad'}
                onClick={() => act('gentoggle')}
              />
            }>
            [ {GeneratorStatus.GeneratorText} ]
          </LabeledList.Item>
          <LabeledList.Item label="Phoron Volume">
            <ProgressBar color="Magenta" value={adjustedPhoronChange} />
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title="Heal Charge Status">
        <LabeledList>
          <LabeledList.Item label="Brute Charge">
            <ProgressBar color="bad" value={adjustedBruteChange} />
          </LabeledList.Item>
          <LabeledList.Item label="Burn Charge">
            <ProgressBar color="average" value={adjustedBurnChange} />
          </LabeledList.Item>
          <LabeledList.Item label="Tox Charge">
            <ProgressBar color="good" value={adjustedToxChange} />
          </LabeledList.Item>
          <LabeledList.Item label="Brute Reserve">
            <b>{brutevol}</b>
          </LabeledList.Item>
          <LabeledList.Item label="Burn Reserve">
            <b>{burnvol}</b>
          </LabeledList.Item>
          <LabeledList.Item label="Tox Reserve">
            <b>{toxvol}</b>
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title="Patient Status">
        <LabeledList.Item label="Name">
          <b>{patientname}</b>
        </LabeledList.Item>
        {data.patientname !== 'No Target' && (
          <LabeledList.Item label="Total Health">
            <ProgressBar
              ranges={{
                good: [0.5, Infinity],
                average: [0.25, 0.5],
                bad: [-Infinity, 0.25],
              }}
              value={patienthealth}
            />
          </LabeledList.Item>
        )}
        {data.patientname !== 'No Target' && (
          <LabeledList.Item label="Brute Damage">
            <b>{patientbrute}</b>
          </LabeledList.Item>
        )}
        {data.patientname !== 'No Target' && (
          <LabeledList.Item label="Burn Damage">
            <b>{patientburn}</b>
          </LabeledList.Item>
        )}
        {data.patientname !== 'No Target' && (
          <LabeledList.Item label="Tox Damage">
            <b>{patienttox}</b>
          </LabeledList.Item>
        )}
        {data.patientname !== 'No Target' && (
          <LabeledList.Item label="Oxy Damage">
            <b>{patientoxy}</b>
          </LabeledList.Item>
        )}
      </Section>
    </Fragment>
  );
};
