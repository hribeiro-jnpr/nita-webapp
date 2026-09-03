## 1. Frontend — polling hook

- [ ] 1.1 Add a `usePollWhile(active, callback, intervalMs)` hook under
  `frontend/src/hooks/` that runs `callback` every `intervalMs` while `active`
  is true and does nothing while it is false
- [ ] 1.2 Clear the interval on unmount and whenever `active` becomes false
- [ ] 1.3 Keep the hook free of any action-history knowledge (boolean + callback
  only) so the dashboard change can reuse it

## 2. Frontend — History tab

- [ ] 2.1 Derive an in-flight predicate from the loaded history rows:
  at least one entry with `status === 'Running'`
- [ ] 2.2 Drive `usePollWhile` from that predicate at a 15 s interval, calling
  the existing `fetchHistory`, and only while `activeTab === 'history'`
- [ ] 2.3 Confirm polled refreshes keep existing rows visible and do not show the
  loading indicator (existing `fetchHistory` behaviour — verify, do not change)
- [ ] 2.4 Abort any in-flight request on tab change and unmount
- [ ] 2.5 `npm run lint` and `npm run build` green

## 3. Frontend — tests

- [ ] 3.1 A list containing a `Running` entry issues a refetch after the interval
- [ ] 3.2 A list with no `Running` entry issues no refetch
- [ ] 3.3 Polling stops once the last `Running` entry reaches a terminal status
- [ ] 3.4 Polling stops when the History tab is left and when the page unmounts
- [ ] 3.5 Rows remain rendered across a polled refresh (no loading flash)

## 4. Verify

- [ ] 4.1 Manual check: trigger an action, stay on the History tab without
  interacting, and confirm the row moves from `Running` to its terminal status
  on its own within ~45 s
- [ ] 4.2 Manual check: on a network whose runs are all finished, confirm no
  action-history requests are issued while the tab sits open
