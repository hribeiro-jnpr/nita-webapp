## Why

The Jenkins UI is reverse-proxied at `https://<host>/jenkins/` so the SPA can
deep-link to a job or build page. Nothing in front of that route checks who the
caller is. Combined with the Jenkins-side defaults (anonymous `Job/Build` and
`Job/Cancel`, CSRF disabled — being removed in the companion `nita-jenkins`
change), anyone who can reach the NITA host can browse every job, read every
console log, and start or abort builds without ever logging into the webapp.

The webapp already has the identity and the permission model: session login,
three roles, network ownership and team scoping. Jenkins should sit *behind*
that identity, not beside it. The first step — this change — is to make the
Jenkins route available only to callers who hold a valid webapp session, and to
close the one remaining place where the webapp itself still relies on Jenkins
being anonymous-readable.

Two facts shape the design:

- **The reverse proxy will change.** nginx is slated to be replaced by Traefik.
  Both support the same pattern — ask an external endpoint "is this request
  authenticated?" before forwarding (`auth_request` in nginx, `forwardAuth` in
  Traefik) — so the authentication contract must live in Django, not in proxy
  configuration.
- **Not every Django→Jenkins call is authenticated yet.** `invoke_job`,
  `robot_summary`, the status updater and the lifecycle history all send
  credentials. The live console stream in `progressive_text_events` does not:
  it issues a bare `urllib` request and works only because anonymous
  `Job/Read` is currently granted. Once Jenkins is tightened, that stream must
  carry credentials too.

## What Changes

- **Forward-auth endpoint.** A new `GET /api/v1/auth/forward/` that answers
  `200` with an empty body for a request carrying a valid webapp session and
  `401`/`403` otherwise. On success it also sets `X-Auth-User` and
  `X-Auth-Role` response headers describing the caller. This is the contract a
  reverse proxy consults before forwarding a request to Jenkins; it is
  proxy-agnostic by construction.
- **nginx gates `/jenkins/` on that endpoint.** The `location /jenkins/` block
  gains an `auth_request` sub-request to the forward-auth endpoint. A denial
  redirects the browser to `/login?next=<original path>` instead of showing a
  bare error. The webapp's own `/api/v1/` routes are unaffected.
- **Login page honours `?next=`.** After a successful login the SPA navigates
  to the `next` query parameter when it is a same-origin relative path, and to
  `/` otherwise. This completes the round-trip from a gated Jenkins deep link.
- **The SSE console stream authenticates to Jenkins.** `progressive_text_events`
  sends the same Basic `Authorization` header `robot_summary` already sends.
  No API shape change; the stream behaves identically from the SPA's view.
- **Builds record who asked for them.** Every `invoke_job` call passes a Jenkins
  build *cause* of the form `Started by <username> via NITA`, so Jenkins build
  pages name the webapp user instead of only the service account.

## Capabilities

### Modified Capabilities

- `auth`: adds the forward-auth endpoint used by the reverse proxy.
- `jenkins-reverse-proxy`: the `/jenkins/` route requires a valid webapp
  session and redirects unauthenticated browsers to the SPA login page.
- `jenkins-trigger-security`: *every* Django→Jenkins HTTP call is
  authenticated, explicitly including progressive console text and the Robot
  summary relay; builds carry the triggering user as their cause.
- `frontend-skeleton`: the login page redirects to a safe `next` target after
  success.

## Impact

- **Backend:** one new view and URL; one header added in `jenkins_jobs.py`;
  one `cause=` keyword threaded through `invoke_job` and its three callers
  (action trigger, network create, network delete). `openapi.yaml` is
  regenerated for the new endpoint.
- **Frontend:** `LoginPage` reads and validates `next`. No new dependencies.
- **Proxy:** `nginx/nginx.conf` gains an internal auth location, an
  `auth_request` directive in `location /jenkins/`, and a named location for
  the login redirect. The same file is what `nita/install.sh` publishes as the
  `proxy-config-cm` ConfigMap, so the k8s deployment picks it up on the next
  install/upgrade.
- **Operational:** every request under `/jenkins/` now costs one additional
  sub-request to Django (a session lookup). Jenkins pages load tens of assets,
  so this is noticeable but bounded; a short-lived cache keyed on the session
  cookie is a documented follow-up if it matters in practice.
- **Companion changes (separate repos, deploy together):**
  `nita-jenkins/revoke-anonymous-build-and-enable-csrf` removes the anonymous
  grants and re-enables CSRF; `nita/close-jenkins-direct-exposure` removes the
  host-port 8443 bypass and fixes the NetworkPolicy so the proxy pod may reach
  Jenkins. Without the `nita` change the gate can be walked around; without
  the `nita-jenkins` change in-cluster callers can still build anonymously.
  This change is safe to merge first: it only *adds* credentials and a gate.
