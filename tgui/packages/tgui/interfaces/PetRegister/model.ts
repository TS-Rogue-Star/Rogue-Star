// ////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Pet Register Interface //
// ////////////////////////////////////////////////////////////////////////

export type Pet = {
  id: string;
  name: string;
  species: string;
  portrait?: string | null;
  note: string;
  active: boolean;
  legacy: boolean;
  valid: boolean;
};

export type Candidate = {
  token: number;
  name: string;
  species: string;
  portrait?: string | null;
  registered: boolean;
  stationAllowed: boolean;
};

export type PetRegisterData = {
  pets: Pet[];
  legacySlotMismatch: boolean;
  legacyLoadFailed: boolean;
  characterName: string;
  revision: number;
  slots: number;
  maxSlots: number;
  usedSlots: number;
  triangles: number;
  slotCost: number;
  nameLimit: number;
  noteLimit: number;
  retrievalBlocked: boolean;
  registrationUsed: boolean;
  sessionOnly: boolean;
  busy: boolean;
  operation?: string;
  progress: number;
  message?: string;
  messageError: boolean;
  resultId: number;
  savedName?: string;
  candidate?: Candidate | null;
};

export type PetDraft = {
  pet: Pet;
  revision: number;
  name: string;
  note: string;
};

export const draftIsDirty = (draft: PetDraft | null) =>
  !!draft && (draft.name !== draft.pet.name || draft.note !== draft.pet.note);

export const filterPets = (pets: Pet[], search: string) => {
  const query = search.trim().toLocaleLowerCase();
  return pets.filter((pet) =>
    `${pet.name}\n${pet.species}`.toLocaleLowerCase().includes(query)
  );
};

export const replacementFor = (
  pets: Pet[],
  name: string,
  slots: number,
  chosen: string
) => {
  const saved = pets.filter((pet) => !pet.legacy);
  const collision = saved.find((pet) => pet.name === name.trim());
  const required = !!collision || saved.length >= slots;
  const target = collision || saved.find((pet) => pet.name === chosen);
  return {
    required,
    collision: !!collision,
    target: required ? target : undefined,
    valid: !required || (!!target && !target.active),
    options: saved.filter((pet) => !pet.active).map((pet) => pet.name),
  };
};
