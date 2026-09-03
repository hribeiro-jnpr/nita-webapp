## 1. Backend — scope the queryset

- [ ] 1.1 In `ActionHistoryViewSet.get_queryset()`, apply the network visibility
  filter before the query-parameter filters: admins and power users see all;
  otherwise filter on
  `Q(campus_network_id__owner=user) | Q(campus_network_id__team__members=user)`
- [ ] 1.2 Add `.distinct()` to the filtered branch (many-to-many team join)
- [ ] 1.3 Confirm the existing `?campus_network_id=` and `?action_category_id=`
  filters still apply on top of the scoped queryset

## 2. Backend — tests

- [ ] 2.1 A `role=user` listing `/api/v1/action-history/` sees only entries for
  networks they own or share via a team
- [ ] 2.2 A `role=user` passing `?campus_network_id=<another user's network>`
  receives an empty result set (not 403, not that network's rows)
- [ ] 2.3 A `role=user` receives 404 on `/{id}/`, `/{id}/console/`,
  `/{id}/stream/` and `/{id}/robot-summary/` for an out-of-scope entry
- [ ] 2.4 A team member sees history for a team-shared network they do not own
- [ ] 2.5 `power_user` and `admin` still see all entries
- [ ] 2.6 Invariant test: every `network_name` in a user's action-history
  response also appears in that user's `GET /api/v1/networks/` response
- [ ] 2.7 No duplicate rows are returned for a user in a multi-member team

## 3. OpenAPI

- [ ] 3.1 Document the 404 response on the action-history detail routes for
  entries outside the caller's scope; regenerate `openapi.yaml`; keep the drift
  test green

## 4. Verify

- [ ] 4.1 Backend `pytest` suite green
- [ ] 4.2 Manual check: as a `role=user`, `GET /api/v1/action-history/` returns
  only that user's networks; the History tab on an owned network is unchanged
