# Data Structures — Internal Contracts

These structs are the **stable interface** between the data layer, prediction layer, and web layer. Once defined, do not rename fields without team agreement.

---

## FootballData.Match

```elixir
defmodule FootballData.Match do
  defstruct [
    :id,
    :home_team_id,
    :away_team_id,
    :home_team_name,
    :away_team_name,
    :home_team_logo,
    :away_team_logo,
    :kickoff_at,
    :status,
    :status_long,
    :round,
    :venue_name,
    :venue_city,
    :score_home,
    :score_away,
    :score_halftime_home,
    :score_halftime_away
  ]
end
```

| Field | Type | Source |
|-------|------|--------|
| `id` | integer | `fixture.id` |
| `home_team_id` | integer | `teams.home.id` |
| `away_team_id` | integer | `teams.away.id` |
| `home_team_name` | string | `teams.home.name` |
| `away_team_name` | string | `teams.away.name` |
| `home_team_logo` | string (url) | `teams.home.logo` |
| `away_team_logo` | string (url) | `teams.away.logo` |
| `kickoff_at` | DateTime | `fixture.date` (ISO 8601) |
| `status` | string | `fixture.status.short` |
| `status_long` | string | `fixture.status.long` |
| `round` | string | `league.round` |
| `venue_name` | string | `fixture.venue.name` |
| `venue_city` | string | `fixture.venue.city` |
| `score_home` | integer or nil | `goals.home` or `score.fulltime.home` |
| `score_away` | integer or nil | `goals.away` or `score.fulltime.away` |
| `score_halftime_home` | integer or nil | `score.halftime.home` |
| `score_halftime_away` | integer or nil | `score.halftime.away` |

---

## FootballData.Team

```elixir
defmodule FootballData.Team do
  defstruct [
    :id,
    :name,
    :code,
    :country,
    :founded,
    :national,
    :logo,
    :venue_name,
    :venue_city,
    :venue_capacity
  ]
end
```

| Field | Type | Source |
|-------|------|--------|
| `id` | integer | `team.id` |
| `name` | string | `team.name` |
| `code` | string | `team.code` |
| `country` | string | `team.country` |
| `founded` | integer | `team.founded` |
| `national` | boolean | `team.national` |
| `logo` | string (url) | `team.logo` |
| `venue_name` | string | `venue.name` |
| `venue_city` | string | `venue.city` |
| `venue_capacity` | integer | `venue.capacity` |

---

## FootballData.Player

```elixir
defmodule FootballData.Player do
  defstruct [
    :id,
    :name,
    :age,
    :number,
    :position,
    :photo
  ]
end
```

| Field | Type | Source |
|-------|------|--------|
| `id` | integer | `player.id` |
| `name` | string | `player.name` |
| `age` | integer | `player.age` |
| `number` | integer | `player.number` |
| `position` | string | `player.position` |
| `photo` | string (url) | `player.photo` |

---

## Predictions.Prediction

```elixir
defmodule Predictions.Prediction do
  defstruct [
    :match_id,
    :winner_pick,
    :reasoning,
    :confidence,
    :generated_at
  ]
end
```

| Field | Type | Meaning |
|-------|------|---------|
| `match_id` | integer | Which match this prediction is for |
| `winner_pick` | string | `"home"`, `"away"`, or `"draw"` |
| `reasoning` | string | Human-readable explanation from AI |
| `confidence` | string | `"high"`, `"medium"`, or `"low"` |
| `generated_at` | DateTime | When the prediction was created |

**Important:** `winner_pick` must be one of exactly `"home"`, `"away"`, `"draw"`. The UI depends on this.

---

## TeamStatus.Status

```elixir
defmodule TeamStatus.Status do
  defstruct [
    :team,
    :players,
    :recent_matches,
    :honors
  ]
end
```

| Field | Type | Meaning |
|-------|------|---------|
| `team` | `FootballData.Team` | Team metadata |
| `players` | list of `FootballData.Player` | Current squad |
| `recent_matches` | list of `FootballData.Match` | Last 5 matches |
| `honors` | list of `TeamStatus.Honor` | Trophies and achievements |

---

## TeamStatus.Honor

```elixir
defmodule TeamStatus.Honor do
  defstruct [
    :competition,
    :year,
    :place
  ]
end
```

| Field | Type | Meaning |
|-------|------|---------|
| `competition` | string | e.g. `"FIFA World Cup"` |
| `year` | string | e.g. `"2018"` |
| `place` | string | e.g. `"Winner"`, `"Runner-up"`, `"Quarter-finals"` |

---

## Status Grouping Helpers

The `FootballData` module should expose helper functions for the UI to group matches:

```elixir
FootballData.live_matches(matches)      # status in ["1H", "HT", "2H", "ET", "P"]
FootballData.upcoming_matches(matches)   # status == "NS" and kickoff in future
FootballData.recent_matches(matches)     # status in ["FT", "AET", "PEN"] and kickoff in past
```

These are pure functions on the list of `Match` structs. They do not call the API.
