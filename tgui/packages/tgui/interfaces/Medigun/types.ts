import { BooleanLike } from '../../../common/react';

export type Data = {
  maintenance: BooleanLike;
  tankmax: number;
  Generator: number;
  Gridstatus: number;
  powerCellStatus: number | null;
  PhoronStatus: number | null;
  BrutehealCharge: number | null;
  BurnhealCharge: number | null;
  ToxhealCharge: number | null;
  BrutehealVol: number | null;
  BurnhealVol: number | null;
  ToxhealVol: number | null;
  patientname: string | null;
  patienthealth: number | null;
  patientbrute: number | null;
  patientburn: number | null;
  patienttox: number | null;
  patientoxy: number | null;
  examine_data: ExamineData;
};

export type ExamineData = {
  smodule: { name: string; range: number; rating: number } | null;
  smanipulator: { name: string; rating: number } | null;
  slaser: { name: string; rating: number } | null;
  scapacitor: {
    name: string;
    chargecost: number;
    tankmax: number;
    rating: number;
  } | null;
  sbin: { name: string; chemcap: number; rating: number } | null;
};
