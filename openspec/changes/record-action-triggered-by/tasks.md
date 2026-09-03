## 1. Backend — model and migration

- [ ] 1.1 Add `triggered_by_username = models.CharField(max_length=150,
  blank=True, default="")` to `ActionHistory` in `ngcn/models.py`
- [ ] 1.2 Generate the migration (`AddField`, no data migration) and confirm it
  applies cleanly against a database containing existing history rows

## 2. Backend — capture the actor

- [ ] 2.1 In the trigger action of `CampusNetworkViewSet`, pass
  `triggered_by_username=request.user.username` to the `ActionHistory(...)`
  construction
- [ ] 2.2 Confirm no other code path creates `ActionHistory` rows (`StatusUpdater`
  only mutates `status` on existing rows)

## 3. Backend — expose the field

- [ ] 3.1 Add `triggered_by_username` as a read-only field on
  `ActionHistorySerializer`
- [ ] 3.2 Confirm it is returned by both list and retrieve

## 4. Backend — tests

- [ ] 4.1 Triggering an action records the requesting user's username
- [ ] 4.2 A second user triggering on the same network records their own username
- [ ] 4.3 Rows created before the migration serialize as `""`
- [ ] 4.4 The recorded value is unchanged after the user is renamed
- [ ] 4.5 The recorded value survives deletion of the user, and the deletion is
  not blocked by the presence of history rows

## 5. OpenAPI

- [ ] 5.1 Document the new `triggered_by_username` response field; regenerate
  `openapi.yaml`; keep the drift test green

## 6. Frontend — History tab

- [ ] 6.1 Add `triggered_by_username` to the `ActionHistory` interface in
  `NetworkDetailPage.tsx`
- [ ] 6.2 Add a **Triggered by** column to the History tab table, rendering an
  empty value as `—`
- [ ] 6.3 `npm run lint` and `npm run build` green

## 7. Verify

- [ ] 7.1 Backend `pytest` suite green
- [ ] 7.2 Manual check: trigger an action, confirm the History tab names the
  triggering user; confirm older rows show `—`
