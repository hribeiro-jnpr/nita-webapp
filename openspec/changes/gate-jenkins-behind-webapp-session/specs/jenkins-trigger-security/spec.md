## MODIFIED Requirements

### Requirement: Internal Jenkins Communication Is Authenticated
The Django application SHALL communicate with the internal Jenkins service using
authenticated requests — a username and password (`JENKINS_SERVER_USER` /
`JENKINS_SERVER_PASS`) — and SHALL supply a CSRF crumb for build requests via a
`CrumbRequester`. This applies to **every** Django→Jenkins HTTP path without
exception: action triggers, network create/delete jobs, network-type
validation, build-status polling, lifecycle history, the Robot Framework
summary relay, and the progressive console text used by the SSE stream. The
Django application SHALL NOT depend on Jenkins granting any permission to the
`anonymous` user. The
internal base URL SHALL target the Jenkins service under its `/jenkins` context
path (e.g. `http://jenkins:8080/jenkins`).

All Django-initiated Jenkins API and job-operation requests SHALL originate
from the Django application container to the internal Jenkins service. Browser
access to the Jenkins UI SHALL use only the session-gated reverse proxy; the
browser SHALL NOT connect to the internal Jenkins service directly or receive
Jenkins credentials.

#### Scenario: Trigger uses authenticated Jenkins client with a crumb
- GIVEN a valid NITA session and configured Jenkins credentials
- WHEN POST /api/v1/networks/{id}/trigger/{action_id}/ is called
- THEN the Django backend authenticates to Jenkins with username/password
- AND a CSRF crumb is obtained before the build is invoked
- AND the Jenkins job is invoked successfully

#### Scenario: Create/delete jobs use the authenticated Jenkins server
- GIVEN configured Jenkins credentials
- WHEN a network create or delete runs the `network_template_mgr` job
- THEN the job is submitted through the authenticated Jenkins server
- AND anonymous (credential-less) submission is not used

#### Scenario: Console stream requests carry credentials
- GIVEN configured Jenkins credentials
- WHEN the SSE console generator requests `/job/{job}/{build}/logText/progressiveText`
- THEN each request includes an `Authorization: Basic` header built from `JENKINS_SERVER_USER` / `JENKINS_SERVER_PASS`

#### Scenario: Console stream works without anonymous Job/Read
- GIVEN Jenkins grants no permissions to the `anonymous` user
- WHEN an authenticated NITA user opens the console stream for a running build
- THEN log lines are streamed and the stream ends with `event: done`

#### Scenario: Internal base URL includes the /jenkins prefix
- GIVEN Jenkins serves under the `/jenkins` context path
- WHEN the Django Jenkins client constructs `JENKINS_SERVER_URL`
- THEN the base URL includes the `/jenkins` path prefix (e.g. `http://jenkins:8080/jenkins`)

#### Scenario: Container startup scripts use the prefixed base URL
- GIVEN Jenkins serves under the `/jenkins` context path
- WHEN the webapp entrypoint runs its Jenkins readiness gate and job bootstrap (`ping_jenkins.py`, `configure_jenkins.py`, `add_jenkins_job.py`)
- THEN each script targets `http://jenkins:8080/jenkins` and the startup gate succeeds so Django boots

## ADDED Requirements

### Requirement: Builds Are Attributed to the Triggering Webapp User
Every Jenkins build invoked on behalf of a user SHALL assert that user's
identity to Jenkins via the `X-Forwarded-User` header, so Jenkins records a
`UserIdCause` for `<username>`. All other webapp→Jenkins calls SHALL assert the
`JENKINS_USER` service identity the same way. The webapp SHALL NOT send a
password to Jenkins.

#### Scenario: Action trigger is attributed to the user
- GIVEN user `alice` triggers an action on a network
- WHEN the Jenkins build is invoked
- THEN the build request carries `X-Forwarded-User: alice`
- AND `GET /job/{job}/{build}/api/json` lists a `hudson.model.Cause$UserIdCause` with `userId` `alice`

#### Scenario: Network create is attributed to the user
- GIVEN user `bob` creates a network
- WHEN the `network_template_mgr` build is invoked
- THEN the build request carries `X-Forwarded-User: bob`

#### Scenario: Network-type validation is attributed to the user
- GIVEN user `carol` uploads a network type for validation
- WHEN the `network_type_validator` build is invoked
- THEN the build request carries `X-Forwarded-User: carol`

#### Scenario: Service calls use the service identity without a password
- GIVEN the webapp relays a console stream or Robot summary, or polls build status
- WHEN it calls Jenkins
- THEN the request carries `X-Forwarded-User: <JENKINS_USER>` and no `Authorization` header
