# Cactus Bug Tracker Implementation Plan

## 1. Purpose

This document is the working implementation plan for the standalone `Cactus Bug Tracker` Rails application.

The goal is not just to build a bug tracker UI. The real MVP is:

1. capture tickets in a structured way,
2. force `Gate 1` and `Gate 2` discipline,
3. record the final verified resolution,
4. turn resolved tickets into reviewable training examples,
5. export approved examples into `JSONL`.

The application should be useful before any AI integration exists.

---

## 2. Current State

The following is already implemented:

- separate Rails app in `D:\work\bug_tracker`
- Docker-based local development setup
- PostgreSQL-backed app booting in Docker
- `User` model with roles:
  - `reporter`
  - `developer`
  - `reviewer`
  - `admin`
- login/logout and `current_user`
- seeded development users
- `Ticket` CRUD
- `TicketGateOne` and `TicketGateTwo`
- basic status/severity/domain handling
- comments and event log
- themed UI with light/dark mode
- improved dashboard, ticket list, ticket show, ticket create/edit pages

This means the app already has the shell of the product.

What is still missing is the real product workflow: permissions, transitions, training examples, review, and export.

---

## 3. Target MVP Flow

The intended end-to-end flow is:

1. Reporter creates a ticket.
2. Reporter fills `Gate 1`.
3. Ticket moves into active work.
4. Developer investigates and fills `Gate 2`.
5. Ticket is resolved/closed only when both gates are complete.
6. A `TrainingExample` is generated from the resolved ticket.
7. Reviewer approves or rejects the training example.
8. Only approved examples are exported to `JSONL`.

That is the core workflow the backend should enforce.

---

## 4. Implementation Principles

These rules should guide all next work:

- Prefer workflow correctness over UI polish.
- Keep the product useful without AI.
- Do not auto-generate training examples without review state.
- Keep roles and permissions explicit.
- Put logic in services/models, not only in views/controllers.
- Use reviewable structured data, not free-form only.

---

## 5. Phase 1: Workflow Enforcement

### Goal

Turn `status` into a real controlled workflow instead of a free editable field.

### Required Behavior

- `draft`
- `needs_info`
- `open`
- `in_progress`
- `needs_review`
- `resolved`
- `closed`

Expected rules:

- without complete `Gate 1`, ticket cannot move to:
  - `open`
  - `in_progress`
  - `needs_review`
- without complete `Gate 1` and `Gate 2`, ticket cannot move to:
  - `resolved`
  - `closed`
- invalid transitions should be rejected by backend, not only hinted in UI

### Implementation Tasks

- [ ] Introduce a dedicated transition service, for example:
  - `app/services/ticket_transition_service.rb`
- [ ] Move transition rules out of ad-hoc controller checks
- [ ] Define allowed transition matrix
- [ ] Return clear failure reason when transition is blocked
- [ ] Ensure event log records status transitions consistently

### Suggested Service Shape

- input:
  - `ticket`
  - `target_status`
  - `actor`
- output:
  - success/failure
  - error message
  - maybe old/new status

### Acceptance Criteria

- invalid transition cannot be saved through controller
- event log shows every real status transition
- transition rules are testable independently from controllers

---

## 6. Phase 2: Role Permissions

### Goal

Enforce who can do what.

### Required Role Model

- `reporter`
- `developer`
- `reviewer`
- `admin`

### Minimum Permission Rules

#### Reporter

- can create tickets
- can edit own ticket content while ticket is still in early stages
- can add comments
- cannot close tickets
- cannot approve training examples

#### Developer

- can update ticket metadata
- can take ownership
- can edit `Gate 2`
- can move ticket through active work stages
- can add commit references

#### Reviewer

- can review and approve/reject generated training examples
- can comment on tickets
- can inspect gates and resolution details

#### Admin

- can do everything

### Implementation Tasks

- [ ] Add policy layer, for example:
  - `app/policies/ticket_policy.rb`
  - `app/policies/training_example_policy.rb`
- [ ] Restrict ticket edit/update actions by role
- [ ] Restrict transition actions by role
- [ ] Restrict review/export actions by role
- [ ] Show clear access denied behavior

### Acceptance Criteria

- role restrictions are enforced server-side
- restricted users cannot bypass UI by manual requests

---

## 7. Phase 3: Commit and PR Linking

### Goal

Attach implementation evidence to the ticket.

### Why This Matters

The final training example should not only say what was fixed. It should point to what code or PR implemented the fix.

### Recommended Model

- `TicketCommit`

Suggested fields:

- `ticket_id`
- `author_id`
- `commit_sha`
- `pull_request_url`
- `repository_name`
- `notes`

### Implementation Tasks

- [ ] Create `TicketCommit` model and migration
- [ ] Allow multiple linked commits per ticket
- [ ] Build simple UI on ticket show page
- [ ] Keep `primary_commit_sha` in `Gate 2` if useful, but prefer dedicated linked records for extensibility

### Acceptance Criteria

- a ticket can have one or more linked commits
- linked commits are visible on ticket show
- training example generation can read commit data

---

## 8. Phase 4: Training Example Model

### Goal

Turn a resolved ticket into a structured training artifact.

### Recommended Model

- `TrainingExample`

Suggested fields:

- `ticket_id`
- `status`
  - `draft`
  - `approved`
  - `rejected`
- `title`
- `problem_description`
- `reproduction_steps`
- `expected_behavior`
- `actual_behavior`
- `environment_context`
- `root_cause`
- `fix_summary`
- `verification_steps`
- `metadata_json`
- `exported_at`

### Data Sources

- `Ticket`
- `TicketGateOne`
- `TicketGateTwo`
- linked commits / PRs
- ticket metadata:
  - severity
  - domain
  - status
  - reporter/assignee

### Implementation Tasks

- [ ] Create `TrainingExample` model + migration
- [ ] Add builder service, for example:
  - `app/services/training_example_builder.rb`
- [ ] Generate draft example when ticket becomes `resolved` or `closed`
- [ ] Prevent duplicate draft generation per ticket unless explicitly regenerated

### Acceptance Criteria

- a closed ticket can produce a structured training example
- training example data is readable and reviewable in-app

---

## 9. Phase 5: Reviewer Queue

### Goal

Introduce human validation before export.

### Required Review States

- `draft`
- `approved`
- `rejected`

### Implementation Tasks

- [ ] Add `TrainingExamplesController`
- [ ] Add pages:
  - `index`
  - `show`
  - `approve`
  - `reject`
- [ ] Filter queue by state
- [ ] Restrict access to `reviewer` and `admin`
- [ ] Log review decisions in ticket events or training example events

### Acceptance Criteria

- reviewer can inspect generated examples
- reviewer can approve or reject
- export uses approved examples only

---

## 10. Phase 6: JSONL Export

### Goal

Produce training-ready output from approved examples.

### Output Requirements

Export should include only approved examples.

Recommended output:

- one JSON object per line
- deterministic field naming
- enough metadata for traceability

Possible fields:

- `ticket_id`
- `title`
- `problem`
- `repro_steps`
- `expected`
- `actual`
- `root_cause`
- `fix`
- `verification`
- `domain`
- `severity`
- `commits`
- `review_status`

### Implementation Tasks

- [ ] Create exporter service:
  - `app/services/training_examples/jsonl_exporter.rb`
- [ ] Add download action or rake task
- [ ] Add export timestamp tracking
- [ ] Decide whether exports are:
  - generated on demand
  - persisted in `storage/exports`

### Acceptance Criteria

- export contains approved examples only
- output is valid JSONL
- export can be re-run safely

---

## 11. Phase 7: Workflow Polish and Data Integrity

### Goal

Remove ambiguity from the working ticket lifecycle.

### Tasks

- [ ] Add transition buttons instead of relying only on generic edit form
- [ ] Surface gate completeness warnings on ticket pages
- [ ] Improve event payloads so timeline is more meaningful
- [ ] Normalize comments/events ordering and filtering
- [ ] Add audit-friendly metadata where useful

### Acceptance Criteria

- users can move tickets through the workflow in an obvious way
- activity feed is meaningful enough for review and debugging

---

## 12. Phase 8: External Integrations

This is not the next step, but it should be planned.

### Asana Import

- [ ] importer service for legacy tasks
- [ ] mark imported tickets as legacy if fields are incomplete
- [ ] optionally generate draft training examples from imported records

### Git / PR Integration

- [ ] start with manual links
- [ ] later add webhook-based automation

### Acceptance Criteria

- imports do not break the structured workflow
- imported data is clearly marked when incomplete

---

## 13. Phase 9: AI Integration

AI should come after the manual workflow is solid.

### First AI Features

- [ ] `Gate 1` completeness helper
- [ ] generated summary/category/domain suggestions
- [ ] `Gate 2` resolution drafting helper
- [ ] training example quality checks

### Important Rule

AI should assist the workflow, not replace the workflow.

Do not make the product depend on LLM output for basic operation.

---

## 14. Recommended Implementation Order

This is the order we should actually follow:

### Step 1

- [ ] Workflow enforcement
- [ ] transition service
- [ ] backend transition rules

### Step 2

- [ ] Role permissions
- [ ] policy layer
- [ ] restrict actions by role

### Step 3

- [ ] Commit/PR linking

### Step 4

- [ ] TrainingExample model
- [ ] builder service

### Step 5

- [ ] Reviewer queue
- [ ] approve/reject flow

### Step 6

- [ ] JSONL export

### Step 7

- [ ] Integrations

### Step 8

- [ ] AI helpers

---

## 15. Immediate Next Task

The next implementation task should be:

### Workflow Enforcement + Role Permissions

Specifically:

- create transition service
- define allowed transitions
- add role-based restrictions for status changes and ticket editing
- wire the controller layer to the service instead of direct status assignment

This is the right next step because:

- without workflow enforcement, tickets are still just editable records
- without permissions, review/export logic will be weak
- `TrainingExample` should be built on top of a reliable state machine

---

## 16. Not a Priority Right Now

These items should wait:

- more visual redesign work
- advanced dashboard analytics
- full webhook automation
- AI chat assistant
- model fine-tuning pipeline implementation

The correct near-term priority is:

**workflow correctness -> reviewability -> exportability**

---

## 17. Definition of MVP Done

The MVP should be considered done when:

- a reporter can create a ticket
- `Gate 1` and `Gate 2` are enforced
- roles are respected
- developer can link commits/PRs
- reviewer can approve/reject training examples
- approved examples can be exported to JSONL

At that point the application is already valuable even before AI is connected.
