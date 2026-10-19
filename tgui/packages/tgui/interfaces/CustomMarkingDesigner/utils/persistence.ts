// ////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
// ////////////////////////////////////////////////////////////////////////////////////

export type AppearancePersistenceState = {
  persist_size: boolean;
  persist_weight: boolean;
  persist_organs: boolean;
};

export const buildAppearancePersistenceState = (
  values?: Partial<AppearancePersistenceState> | null
): AppearancePersistenceState => ({
  persist_size: !!(values?.persist_size ?? true),
  persist_weight: !!(values?.persist_weight ?? false),
  persist_organs: !!(values?.persist_organs ?? true),
});
