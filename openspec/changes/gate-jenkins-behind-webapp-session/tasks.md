## 1. Forward-auth endpoint

- [ ] 1.1 Add `forward_auth_view` (`GET /api/v1/auth/forward/`): `IsAuthenticated`, returns `200` with empty body and `X-Auth-User` / `X-Auth-Role` response headers; document with `extend_schema`
- [ ] 1.2 Register the route in `ngcn/api/urls.py` alongside the other `auth/` routes
- [ ] 1.3 Tests: authenticated session → 200 + both headers; no session → 401/403 and no identity headers; token auth is not accepted (session-only)
- [ ] 1.4 Regenerate `openapi.yaml` and confirm `test_openapi_drift.py` passes

## 2. nginx gate

- [ ] 2.1 Add the `internal` auth location `/_auth/jenkins` proxying to `/api/v1/auth/forward/` with request body and `Content-Length` dropped and `X-Original-URI` set
- [ ] 2.2 Add `auth_request /_auth/jenkins;` and `error_page 401 403 = @jenkins_login;` to `location /jenkins/`
- [ ] 2.3 Add named location `@jenkins_login` returning `302 /login?next=$request_uri`
- [ ] 2.4 Verify with the compose stack: anonymous `GET /jenkins/` → 302 to `/login?next=/jenkins/`; with a logged-in session cookie → Jenkins page loads with assets

## 3. Login page `next` handling

- [ ] 3.1 `LoginPage` reads `next` from the query string; after successful login navigates to it when it is a same-origin relative path (`/…`, not `//…`, no scheme), otherwise to `/`
- [ ] 3.2 Tests in `LoginPage.test.tsx`: valid `next` is followed; `//evil`, `https://…`, and absent `next` all land on `/`
- [ ] 3.3 `npm run lint` and `npm test` pass

## 4. Authenticated console stream

- [ ] 4.1 Extract the Basic-auth header construction from `robot_summary` into a module-private helper in `jenkins_jobs.py`
- [ ] 4.2 Use the helper in `progressive_text_events` so every `progressiveText` request carries `Authorization`
- [ ] 4.3 Test in `test_api_streaming.py`: the `Request` passed to `urllib.request.urlopen` has an `Authorization: Basic …` header; existing generator and view tests still pass

## 5. Build cause

- [ ] 5.1 Add a `cause` keyword to `invoke_job` and pass it through to `jenkinsapi` `Job.invoke`
- [ ] 5.2 Action trigger, network create and network delete pass `cause=f"Started by {request.user.username} via NITA"`
- [ ] 5.3 Tests: `invoke_job` forwards `cause`; the trigger view passes the acting user's name (extend the existing mocked-Jenkins tests in `test_api.py`)

## 6. Validation

- [ ] 6.1 `pytest` green; `openspec validate gate-jenkins-behind-webapp-session --strict` passes
- [ ] 6.2 End-to-end on the compose stack: log in → open a network → "Jenkins ↗" opens the job page; log out → same link redirects to login and returns to the job page after signing in; trigger an action → build page shows `Started by <user> via NITA`; console stream and Robot summary still render
- [ ] 6.3 Update `README.md` release notes
