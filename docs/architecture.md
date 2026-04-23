# Architecture Plan

## Goal

Build a hackathon MVP in Elixir/Phoenix LiveView for World Cup match insights. The app should show fresh football data, a team status page, and an AI-generated match prediction.

The architecture is intentionally simple so three people can work in parallel and finish within 3-4 hours.

## System Shape

- One Phoenix LiveView app
- One football data API integration
- One OpenAI integration for predictions
- Minimal persistence only if it is fast to set up
- No admin panel
- No auth
- No background job system required for v1

## Main Pages

### Home Page

- List upcoming, live, and recent World Cup matches
- Link to match details
- Link to team status pages when available

### Match Page

- Show home and away team
- Show kickoff time, status, and score
- Show recent form if available
- Show expected lineup or key absences if available
- Show AI prediction card

### Team Status Page

- Show team metadata
- Show squad/players
- Show recent matches
- Show trophies or honors from API or local fallback data

## Module Layout

### Data Layer

`FootballApi.Client`

- Raw HTTP calls to the football data provider
- Returns provider payloads

`FootballData`

- Normalizes provider payloads for the rest of the app
- Exposes a stable internal contract

Functions to implement:

- `list_matches/0`
- `get_match!/1`
- `get_match_context!/1`
- `get_team!/1`
- `list_team_recent_matches/1`
- `list_team_players/1`

Suggested `get_match_context!/1` payload:

- `match`
- `home_team`
- `away_team`
- `home_players`
- `away_players`
- `expected_lineups` or `confirmed_lineups`
- `missing_players`
- `recent_team_form`
- `recent_player_stats`
- `team_stats`

### Prediction Layer

`OpenAI.Client`

- Sends prompts to OpenAI
- Returns the raw model response

`Predictions`

- Builds prompt input from normalized football data with lineup-aware match context
- Parses and returns a UI-friendly result
- Optionally caches per-match output for the MVP

Functions to implement:

- `predict_match/1`
- `get_cached_prediction/1`

Prediction input should prioritize:

- expected or confirmed players for the current match
- missing or unavailable players
- recent player contributions
- team form and team-level stats
- tournament context if available

Suggested prediction shape:

- `match_id`
- `winner_pick`
- `reasoning`
- `generated_at`

### Team Status Layer

`TeamStatus`

- Combines normalized team data, squad, recent matches, and honors fallback data

Function to implement:

- `get_team_status/1`

Suggested return shape:

- `team`
- `players`
- `recent_matches`
- `honors`

## Web Layer

LiveViews to create:

- `HomeLive`
- `MatchLive.Show`
- `TeamLive.Show`

Responsibilities:

- Keep UI thin
- Call service modules only
- Handle missing data safely
- Render loading and error states without crashing the demo

## Data Flow

### Home Page Flow

1. `HomeLive` calls `FootballData.list_matches/0`
2. Render fixtures grouped as live, upcoming, or recent

### Match Page Flow

1. `MatchLive.Show` calls `FootballData.get_match_context!/1`
2. `Predictions.predict_match/1` generates or loads a cached prediction
3. Render score, status, lineup context, and prediction card

### Team Page Flow

1. `TeamLive.Show` calls `TeamStatus.get_team_status/1`
2. `TeamStatus` fetches team, players, recent matches, and honors
3. Render team status page

## Configuration

Environment variables expected:

- `FOOTBALL_API_KEY`
- `OPENAI_API_KEY`
- `FOOTBALL_COMPETITION_ID` if the provider requires it

## Hackathon Defaults

- Focus on one tournament only: World Cup
- English-only MVP
- Prefer direct provider integration over abstractions beyond the listed modules
- If DB setup slows the team down, keep honors in a local file and cache predictions in memory
