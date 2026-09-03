## 1. Prerequisites

- [ ] 1.1 Confirm `scope-action-history-visibility` is implemented and deployed —
  the unfiltered feed must not be built against an unscoped endpoint
- [ ] 1.2 Confirm `record-action-triggered-by` supplies `triggered_by_username`
- [ ] 1.3 Confirm `refresh-inflight-action-status` supplies the `usePollWhile`
  hook

## 2. Frontend — data layer

- [ ] 2.1 Fetch `GET /api/v1/action-history/` once on mount via `useApiResource`
- [ ] 2.2 Add an `ActionHistory` type for the dashboard covering `id`, `status`,
  `timestamp`, `action_name`, `network_name`, `campus_network_id`,
  `triggered_by_username`
- [ ] 2.3 Implement the grouping comparator: in-progress (`Running`), then
  attention (`Failure`, `Failed`, `Aborted`, `Unstable`), then the rest; each
  group newest-first; comparisons case-insensitive
- [ ] 2.4 Take the first ten entries after sorting
- [ ] 2.5 Drive `usePollWhile` at 15 s from "at least one displayed row is
  `Running`"

## 3. Frontend — presentation

- [ ] 3.1 Replace the welcome text in `DashboardPage.tsx` with a Recent activity
  list rendering status, action name, network name, triggered-by and relative
  time
- [ ] 3.2 Render an empty `triggered_by_username` as `—`
- [ ] 3.3 Link each row to `/networks/{campus_network_id}?tab=history`
- [ ] 3.4 Visually distinguish in-progress and attention rows from the rest
- [ ] 3.5 Render an empty state when there is no activity
- [ ] 3.6 Render an error state when the request fails, without breaking the page
- [ ] 3.7 Keep rows visible during a polled refresh (no loading flash)
- [ ] 3.8 `npm run lint` and `npm run build` green

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

- [ ] 5.1 Supersede the Dashboard Shell Placeholder requirement in
  `frontend-skeleton` with the real dashboard requirements

## 6. Verify

- [ ] 6.1 Manual check as `role=user`: the feed shows only that user's own and
  team-shared networks
- [ ] 6.2 Manual check: trigger an action, confirm it appears at the top of the
  dashboard and reaches its terminal status without a manual refresh
- [ ] 6.3 Manual check: a row's link lands on the correct network's History tab
- [ ] 6.4 Manual check: with nothing running, no background requests are issued
