## ADDED Requirements

### Requirement: Jenkins route requires a webapp session
The reverse proxy SHALL forward a request under `/jenkins/` to Jenkins only
after a sub-request to the webapp's forward-auth endpoint
(`GET /api/v1/auth/forward/`) returns 2xx. The sub-request SHALL carry the
original cookies but not the body, and SHALL use an `internal` location. The
authentication decision SHALL be made by the webapp, not the proxy.

#### Scenario: Authenticated browser reaches Jenkins
- GIVEN a browser holding a valid webapp `sessionid` cookie
- WHEN it requests `https://<host>/jenkins/job/<job>/`
- THEN the proxy's sub-request to the forward-auth endpoint returns 200
- AND the request is forwarded to Jenkins and the job page loads with its assets

#### Scenario: Anonymous browser does not reach Jenkins
- GIVEN a browser with no webapp session
- WHEN it requests any URL under `/jenkins/`
- THEN the request is NOT forwarded to Jenkins

#### Scenario: Auth location is internal
- GIVEN the proxy configuration
- WHEN a client requests the auth sub-request location directly from outside
- THEN the proxy returns 404

### Requirement: Denied Jenkins requests redirect to the login page
When the authentication sub-request for a `/jenkins/` request is denied, the
proxy SHALL respond with a `302` redirect to `/login?next=<original request URI>`
rather than an error page, so that the browser can authenticate and return to
the originally requested Jenkins page.

#### Scenario: Deep link round-trips through login
- GIVEN an unauthenticated browser
- WHEN it requests `/jenkins/job/test-robot-net1/`
- THEN it receives a 302 to `/login?next=/jenkins/job/test-robot-net1/`
- AND after a successful login the SPA navigates to `/jenkins/job/test-robot-net1/`
- AND that request is now forwarded to Jenkins
