// /////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Occupation //
// /////////////////////////////////////////////////////////////////////////////////

import type {
  OccupationCatalog,
  OccupationDraft,
  OccupationJob,
  OccupationPreview,
  OccupationPriority,
} from '../occupationTypes';

export const OCCUPATION_PRIORITIES: ReadonlyArray<{
  value: OccupationPriority;
  label: string;
}> = [
  { value: 4, label: 'Never' },
  { value: 3, label: 'Low' },
  { value: 2, label: 'Medium' },
  { value: 1, label: 'High' },
];

export const OCCUPATION_FALLBACKS = [
  'Get a random job',
  'Be an assistant',
  'Return to lobby',
];

export const cloneOccupationDraft = (
  draft: OccupationDraft
): OccupationDraft => ({
  ...draft,
  priorities: { ...draft.priorities },
  titles: { ...draft.titles },
  reset: !!draft.reset,
  persist_spawn: !!(draft.persist_spawn ?? true),
  vantag_volunteer: !!draft.vantag_volunteer,
});

const recordsEqual = (
  left: Record<string, string | number>,
  right: Record<string, string | number>
) =>
  Object.keys(left).length === Object.keys(right).length &&
  Object.keys(left).every((key) => left[key] === right[key]);

export const occupationDraftsEqual = (
  left: OccupationDraft | null,
  right: OccupationDraft | null
) =>
  !!left &&
  !!right &&
  left.reset === right.reset &&
  left.alternate_option === right.alternate_option &&
  left.spawnpoint === right.spawnpoint &&
  (left.persist_spawn ?? true) === (right.persist_spawn ?? true) &&
  !!left.vantag_volunteer === !!right.vantag_volunteer &&
  left.vantag_preference === right.vantag_preference &&
  recordsEqual(left.priorities, right.priorities) &&
  recordsEqual(left.titles, right.titles);

export const setOccupationPriority = (
  draft: OccupationDraft,
  id: string,
  priority: OccupationPriority
): OccupationDraft => {
  const next = cloneOccupationDraft(draft);
  if (priority === 1) {
    for (const name of Object.keys(next.priorities)) {
      if (next.priorities[name] === 1) {
        next.priorities[name] = 2;
      }
    }
  }
  next.priorities[id] = priority;
  return next;
};

export const resetOccupationDraft = (
  draft: OccupationDraft
): OccupationDraft => ({
  ...draft,
  reset: true,
  priorities: Object.fromEntries(
    Object.keys(draft.priorities).map((id) => [id, 4 as const])
  ),
  titles: Object.fromEntries(Object.keys(draft.titles).map((id) => [id, id])),
});

export const getOccupationPreviewKey = (
  catalog: OccupationCatalog,
  draft: OccupationDraft
) => {
  const assistant = catalog.jobs.find(
    (job) => job.assistant && draft.priorities[job.id] === 3
  );
  const job =
    assistant ||
    (!catalog.suppress_job_preview &&
      catalog.jobs.find((entry) => draft.priorities[entry.id] === 1));
  return job ? `${job.id}\n${draft.titles[job.id] || job.id}` : 'none';
};

export const occupationMatchesSearch = (job: OccupationJob, search: string) => {
  const terms = search.trim().toLowerCase().split(/\s+/);
  const text = [job.id, job.department, ...job.titles].join(' ').toLowerCase();
  return terms.every((term) => text.includes(term));
};

export const occupationPreviewRecipes = (
  preview: OccupationPreview,
  showJobGear: boolean
) => {
  if (!preview.silicon || !showJobGear) {
    return preview.gear;
  }
  return {
    ...preview.gear,
    loadout: {},
    equipment: Object.fromEntries(
      Object.entries(preview.gear.equipment).map(([dir, overlays]) => [
        dir,
        overlays.filter((overlay) => overlay.slot !== 'back'),
      ])
    ),
  };
};
