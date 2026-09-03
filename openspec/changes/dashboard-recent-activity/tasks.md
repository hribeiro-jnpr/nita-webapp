## 1. Prerequisites

- [x] 1.1 Confirm `scope-action-history-visibility` is implemented and deployed —
  the unfiltered feed must not be built against an unscoped endpoint
- [x] 1.2 Confirm `record-action-triggered-by` supplies `triggered_by_username`
- [x] 1.3 Confirm `refresh-inflight-action-status` supplies the `usePollWhile`
  hook

## 2. Frontend — data layer

- [x] 2.1 Fetch `GET /api/v1/action-history/` once on mount via `useApiResource`
- [x] 2.2 Add an `ActionHistory` type for the dashboard covering `id`, `status`,
  `timestamp`, `action_name`, `network_name`, `campus_network_id`,
  `triggered_by_username`
- [x] 2.3 Implement the grouping comparator: in-progress (`Running`), then
  attention (`Failure`, `Failed`, `Aborted`, `Unstable`), then the rest; each
  group newest-first; comparisons case-insensitive
- [x] 2.4 Take the first ten entries after sorting
- [x] 2.5 Drive `usePollWhile` at 15 s from "at least one displayed row is
  `Running`"

## 3. Frontend — presentation

- [x] 3.1 Replace the welcome text in `DashboardPage.tsx` with a Recent activity
  list rendering status, action name, network name, triggered-by and relative
  time
- [x] 3.2 Render an empty `triggered_by_username` as `—`
- [x] 3.3 Link each row to `/networks/{campus_network_id}?tab=history`
- [x] 3.4 Visually distinguish in-progress and attention rows from the rest
- [x] 3.5 Render an empty state when there is no activity
- [x] 3.6 Render an error state when the request fails, without breaking the page
- [x] 3.7 Keep rows visible during a polled refresh (no loading flash)
- [x] 3.8 `npm run lint` and `npm run build` green

## 4. Frontend — tests

- [ ] 4.1 In-progress rows sort above attention rows, which sort above the rest
- [ ] 4.2 Within each group, entries are newest-first
- [ ] 4.3 At most ten rows are rendered
- [ ] 4.4 An in-progress run is not displaced by newer completed runs
- [ ] 4.5 An unrecognised status string renders in the neutral group rather than
  being hidden
- [ ] 4.6 Each row links to `/networks/{id}?tab=history` for its own network
- [ ] 4.7 An empty `triggered_by_username` renders as `—`
- [ ] 4.8 The empty state renders when the response contains no entries
- [ ] 4.9 Polling runs while a `Running` row is displayed and stops when none is

## 5. Spec cleanup

- [x] 5.1 Supersede the Dashboard Shell Placeholder requirement in
  `frontend-skeleton` with the real dashboard requirements

## 6. Verify

- [ ] 6.1 Manual check as `role=user`: the feed shows only that user's own and
  team-shared networks
- [ ] 6.2 Manual check: trigger an action, confirm it appears at the top of the
  dashboard and reaches its terminal status without a manual refresh
- [ ] 6.3 Manual check: a row's link lands on the correct network's History tab
- [ ] 6.4 Manual check: with nothing running, no background requests are issued

## Verification notes

`npm run lint` and `npm run build` are green; the backend suite is unaffected
(204 passed).

**The feed logic was extracted to `frontend/src/pages/dashboardFeed.ts`** — a
React-free module holding `statusGroup`, `sortForFeed`, `selectFeed` and the
presentation helpers. This keeps the ordering rules, which are the substance of
this change, independently exercisable, and it is what makes section 4 cheap to
complete once a test runner exists.

**Section 4 is not ticked** because no committed automated tests exist (see
Blockers). However, the ordering requirements were verified directly against the
real module using Node's type stripping, covering the spec scenarios:

```
ok - in-progress sorts above attention, above the rest
ok - newest first within a group
ok - Unstable is treated as needing attention
ok - at most ten rows
ok - in-progress run is not displaced by newer completed runs
ok - unrecognised status is shown in the neutral group
ok - status matching is case-insensitive
ok - relative time formatting
8 checks passed
```

That scratch script was **not** committed — it is not wired into any runner and
would rot. It maps 1:1 onto tasks 4.1–4.5 and 4.7, which can be transcribed into
real tests once a harness lands. Tasks 4.6, 4.8 and 4.9 are component-level
(routing, empty state, polling lifecycle) and were **not** verified
automatically.

## Blockers

**No frontend test infrastructure (blocks section 4).** Same gap recorded under
`refresh-inflight-action-status`: `frontend/package.json` declares no `test`
script and no vitest/testing-library dependency, and there are no test files under
`frontend/src`. Standing up a harness is a project-infrastructure decision and was
not taken unilaterally as part of this change.

**Section 6** requires a running deployment with Jenkins and has not been
performed.
