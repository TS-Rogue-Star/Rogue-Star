import { Fragment } from 'inferno';
import { useBackend } from '../../../backend';
import { Blink, Box, Button, LabeledList, ProgressBar, Section, Stack } from '../../../components';
import { Data } from '../types';
import { gridStatusToColor, gridStatusToText, powerToColor, powerToText, statToColor, statToString } from '../constants';
import { ChargeStatus } from '../MedigunHelpers/ChargeStatus';

export const MedigunContent = (props, context) => {
  const { act, data } = useBackend<Data>(context);

  const {
    maintenance,
    tankmax,
    Generator,
    Gridstatus,
    powerCellStatus,
    PhoronStatus,
    BrutehealCharge,
    BurnhealCharge,
    ToxhealCharge,
    BrutehealVol,
    BurnhealVol,
    ToxhealVol,
    patientname,
    patienthealth,
    patientbrute,
    patientburn,
    patienttox,
    patientoxy,
    bloodStatus,
    patientstatus,
  } = data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Power Status">
          <LabeledList>
            <LabeledList.Item label="Power Cell">
              {maintenance ? (
                <Box color="red">Maintenance Hatch Open</Box>
              ) : powerCellStatus !== null ? (
                <ProgressBar
                  ranges={{
                    good: [50, Infinity],
                    average: [25, 50],
                    bad: [-Infinity, 25],
                  }}
                  minValue={0}
                  maxValue={100}
                  value={powerCellStatus}
                />
              ) : (
                <Box color="red">Missing Cell</Box>
              )}
            </LabeledList.Item>
            {Gridstatus !== 3 && (
              <LabeledList.Item
                label="Wireless Power"
                color={gridStatusToColor[Gridstatus]}>
                {gridStatusToText[Gridstatus] || 'Unavailable'}
              </LabeledList.Item>
            )}
            <LabeledList.Item
              label="Phoron Generator"
              color={powerToColor[Generator]}
              buttons={
                <Button
                  content={Generator ? 'On' : 'Off'}
                  selected={Generator}
                  color={Generator ? '' : 'bad'}
                  onClick={() => act('gentoggle')}
                />
              }>
              [ {powerToText[Generator] || 'Unavailable'} ]
            </LabeledList.Item>
            {PhoronStatus !== null ? (
              <LabeledList.Item label="Phoron Volume">
                <ProgressBar color="pink" value={PhoronStatus} />
              </LabeledList.Item>
            ) : (
              <Box color="red">Missing Bin</Box>
            )}
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Heal Charge Status">
          <LabeledList>
            <ChargeStatus
              name="Brute Charge"
              color="bad"
              charge={BrutehealCharge}
              max={tankmax}
              volume={BrutehealVol}
            />
            <ChargeStatus
              name="Burn Charge"
              color="average"
              charge={BurnhealCharge}
              max={tankmax}
              volume={BurnhealVol}
            />
            <ChargeStatus
              name="Tox Charge"
              color="good"
              charge={ToxhealCharge}
              max={tankmax}
              volume={ToxhealVol}
            />
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill title="Patient Status">
          <Stack vertical fill>
            {patienthealth !== null &&
            patientbrute !== null &&
            patientburn !== null &&
            patienttox !== null &&
            patientoxy !== null ? (
              <Fragment>
                <Stack.Item>
                  <LabeledList>
                    <LabeledList.Item label="Name">
                      {patientname ? (
                        <Stack>
                          <Stack.Item grow>{patientname}</Stack.Item>
                          <Stack.Item>
                            <Button
                              color="red"
                              onClick={() => act('cancel_healing')}>
                              Stop Healing
                            </Button>
                          </Stack.Item>
                        </Stack>
                      ) : (
                        'No Target'
                      )}
                    </LabeledList.Item>
                    {!!data.patientname && (
                      <>
                        <LabeledList.Item label="Total Health">
                          <ProgressBar
                            ranges={{
                              good: [0.5, Infinity],
                              average: [0.25, 0.5],
                              bad: [-Infinity, 0.25],
                            }}
                            value={patienthealth}>
                            {patientstatus ? (
                              <Stack>
                                <Stack.Item grow />
                                <Stack.Item>
                                  <Blink>
                                    <Box
                                      bold
                                      color={statToColor[patientstatus]}>
                                      {statToString[patientstatus]}
                                    </Box>
                                  </Blink>
                                </Stack.Item>
                                <Stack.Item>
                                  {`${(patienthealth * 100).toFixed()}%`}
                                </Stack.Item>
                              </Stack>
                            ) : (
                              `${statToString[patientstatus || 0]} ${(
                                patienthealth * 100
                              ).toFixed()}%`
                            )}
                          </ProgressBar>
                        </LabeledList.Item>
                        <LabeledList.Item label="Blood Volume">
                          {bloodStatus ? (
                            <ProgressBar
                              color="red"
                              value={
                                bloodStatus.volume / bloodStatus.max_volume
                              }
                            />
                          ) : (
                            <Blink>
                              <Box color="red">No Blood Detected</Box>
                            </Blink>
                          )}
                        </LabeledList.Item>
                      </>
                    )}
                  </LabeledList>
                </Stack.Item>
                <Stack.Item>
                  {!!data.patientname && (
                    <Stack>
                      <Stack.Item width="200px">
                        <LabeledList>
                          <LabeledList.Item label="Brute Damage">
                            <Box color="red">{patientbrute}</Box>
                          </LabeledList.Item>
                          <LabeledList.Item label="Burn Damage">
                            <Box color="orange">{patientburn}</Box>
                          </LabeledList.Item>
                        </LabeledList>
                      </Stack.Item>
                      <Stack.Item>
                        <LabeledList>
                          <LabeledList.Item label="Tox Damage">
                            <Box color="green">{patienttox}</Box>
                          </LabeledList.Item>
                          <LabeledList.Item label="Oxy Damage">
                            <Box color="blue">{patientoxy}</Box>
                          </LabeledList.Item>
                        </LabeledList>
                      </Stack.Item>
                    </Stack>
                  )}
                </Stack.Item>
              </Fragment>
            ) : (
              <Box color="red">Missing Scanning Module</Box>
            )}
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
