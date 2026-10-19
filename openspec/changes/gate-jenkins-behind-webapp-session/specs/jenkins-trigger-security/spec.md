## MODIFIED Requirements

### Requirement: Internal Jenkins Communication Is Authenticated
The Django application SHALL communicate with the internal Jenkins service using
authenticated requests — a username and password (`JENKINS_SERVER_USER` /
`JENKINS_SERVER_PASS`) — and SHALL supply a CSRF crumb for build requests via a
`CrumbRequester`. This applies to **every** Django→Jenkins HTTP path without
exception: triggering an action, the network create/delete jobs, build-status
polling, lifecycle history, the Robot Framework summary relay, and the
progressive console text used by the SSE stream. The Django application SHALL
NOT depend on Jenkins granting any permission to the `anonymous` user. The
internal base URL SHALL target the Jenkins service under its `/jenkins` context
path (e.g. `http://jenkins:8080/jenkins`).

All Jenkins communication SHALL still originate from the Django application container to the
internal Jenkins service, never from the client browser directly.

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

### Requirement: Builds Carry the Triggering User as Cause
Every Jenkins build invoked by the Django application on behalf of a user SHALL
be submitted with a build cause of the form `Started by <username> via NITA`,
where `<username>` is the authenticated webapp user who made the request. This
applies to action triggers and to the network create and delete jobs.

#### Scenario: Action trigger records the cause
- GIVEN user `alice` triggers an action on a network
- WHEN the Jenkins build is invoked
- THEN the build's cause is `Started by alice via NITA`
- AND the Jenkins build page and `GET /job/{job}/{build}/api/json` show that cause

#### Scenario: Network create records the cause
- GIVEN user `bob` creates a network
- WHEN the `network_template_mgr` build is invoked
- THEN the build's cause is `Started by bob via NITA`
