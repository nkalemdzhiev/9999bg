# Team Tasks

## Goal

Split work across three people so the MVP can be demo-ready in 3-4 hours with minimal merge conflicts.

## Ownership

### Engineer 1: Project Setup and Football Data

Owns:

- Phoenix LiveView project bootstrap
- Router and base navigation
- `FootballApi.Client`
- `FootballData`

Deliverables:

- App starts locally
- Home page can load World Cup matches
- Stable internal functions are available for the UI team

Required interface:

- `FootballData.list_matches/0`
- `FootballData.get_match!/1`
- `FootballData.get_team!/1`
- `FootballData.list_team_recent_matches/1`
- `FootballData.list_team_players/1`

### Engineer 2: UI and LiveViews

Owns:

- `HomeLive`
- `MatchLive.Show`
- `TeamLive.Show`
- shared UI layout and navigation

Deliverables:

- Home page with fixtures
- Match page with match details and prediction area
- Team page with squad and recent matches
- Safe fallback UI when data is missing

Dependencies:

- Uses normalized functions from `FootballData`
- Uses prediction output contract from `Predictions`

### Engineer 3: AI Prediction and Team Status Enrichment

Owns:

- `OpenAI.Client`
- `Predictions`
- honors/trophies fallback data
- `TeamStatus`

Deliverables:

- Match prediction works for at least one fixture
- Prediction card returns a stable UI payload
- Team status includes honors from API or local fallback file

Required prediction payload:

- `winner_pick`
- `reasoning`
- `generated_at`

## Build Order

1. Engineer 1 bootstraps Phoenix app and routes.
2. Engineer 1 lands football data functions.
3. Engineer 2 builds page shells and wires them to placeholder or real data.
4. Engineer 3 lands OpenAI client and prediction contract.
5. Engineer 2 connects prediction UI.
6. Engineer 3 adds honors fallback data and `TeamStatus`.
7. All three stabilize the demo flow and handle missing data.

## Parallel Work Rules

- Engineer 1 owns data contracts. Do not rename function signatures without telling the team.
- Engineer 2 should not call the raw API client directly. Use service modules only.
- Engineer 3 should return a stable prediction shape early so UI work does not block.
- Keep commits small and frequent.
- Avoid editing the same files unless coordinated first.

## Demo-Ready Acceptance

- Home page shows World Cup matches
- Match page shows real data
- Match page shows AI prediction
- Team page shows players and recent matches
- Honors appear from API or fallback data
- App does not crash on missing fields or failed prediction
