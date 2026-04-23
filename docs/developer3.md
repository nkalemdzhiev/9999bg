# Developer 3 Notes

## Current Status

The repo does not have a Phoenix or Mix scaffold yet, so the Developer 3 work is prepared as pure Elixir modules under `lib/world_cup_insights`.

These files are intended to be moved or renamed into the final app namespace once the main project is scaffolded.

## Files Added

- `lib/world_cup_insights/openai/client.ex`
- `lib/world_cup_insights/predictions.ex`
- `lib/world_cup_insights/team_status.ex`
- `lib/world_cup_insights/fixtures.ex`
- `priv/data/team_honors.json`

## Contracts

### `WorldCupInsights.Predictions`

- `predict_match/1`
- `get_cached_prediction/1`

Expected long-term input:

- normalized match context, not only a bare match record
- home and away players for the current fixture
- expected or confirmed lineups when available
- missing players
- recent player stats
- recent team form and team stats

Prediction payload:

- `match_id`
- `winner_pick`
- `reasoning`
- `generated_at`
- `source`

### `WorldCupInsights.TeamStatus`

- `get_team_status/1`

Team status payload:

- `team`
- `players`
- `recent_matches`
- `honors`

## Integration Plan

- Replace `WorldCupInsights.Fixtures` calls with `FootballData` once Developer 1 lands the data layer.
- Replace simple fixture-only prediction input with `FootballData.get_match_context!/1`.
- Replace pass-through cache behavior with ETS, Cachex, or DB if needed.
- Keep the return shapes stable so Developer 2 can wire the UI immediately.
