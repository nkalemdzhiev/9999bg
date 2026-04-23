# 9999bg Hackathon MVP

Elixir/Phoenix LiveView MVP for World Cup match insights.

The app should provide:

- fresh World Cup match data
- team status pages with squad and recent matches
- AI-based match winner prediction

## MVP Scope

- One tournament only: World Cup
- Public fan-facing UI
- English only
- No auth
- No admin panel

## Planned Structure

- `docs/architecture.md` defines the app architecture and module contracts
- `docs/tasks.md` defines team ownership and delivery order

## Expected Environment Variables

- `FOOTBALL_API_KEY`
- `OPENAI_API_KEY`
- `FOOTBALL_COMPETITION_ID`

## Planned Demo Flow

1. Open home page and show live/upcoming World Cup matches
2. Open one match and show details plus AI prediction
3. Open one team page and show squad, recent matches, and honors

## Notes

- For hackathon speed, the app should prefer direct integrations and minimal abstraction.
- If database setup takes too long, use local fallback data for honors and simple in-memory caching for predictions.
- Implementation should run in autonomous mode: make normal code changes directly without waiting for approval on each edit.
- Still surface blockers only for external credentials, destructive actions, or irreversible environment changes.
