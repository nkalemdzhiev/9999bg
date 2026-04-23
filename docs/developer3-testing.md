# Developer 3 Testing

## What is testable now

These tests cover the pure Developer 3 contracts without waiting for the real football API layer:

- prompt generation
- fallback prediction behavior
- fixture-based prediction input
- team status assembly
- honors fallback lookup

## Test Files

- `test/world_cup_insights/predictions_test.exs`
- `test/world_cup_insights/team_status_test.exs`

## Current Limitation

The current machine does not have `elixir` or `mix` installed, so the tests were added but not executed here.

## Run Once Elixir Is Available

From the app root:

```powershell
mix test test/world_cup_insights/predictions_test.exs
mix test test/world_cup_insights/team_status_test.exs
```

Or run the full suite:

```powershell
mix test
```

## Expected Follow-Up

- Replace fixture-backed tests with tests against `FootballData` contracts once Developer 1 lands the real data layer.
- Keep the prediction payload contract stable for the UI team.
