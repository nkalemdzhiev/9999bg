# Developer 1 Tasks — Project Setup & Football Data

**Agent:** `coder` + Kimi K2.6  
**Yolo:** ON (auto-approve all operations)  
**Goal:** Bootstrap the Phoenix app and build the stable football data layer so Engineers 2 and 3 can start immediately.

---

## Part A: Phoenix Bootstrap (15–20 min)

### Task A1: Create Phoenix App
```bash
mix phx.new wc_insights --no-ecto --no-mailer --no-dashboard --no-gettext
```
> We skip Ecto for hackathon speed. If we need DB later, we can add it.

### Task A2: Configure Router
File: `lib/wc_insights_web/router.ex`

Add routes:
```elixir
scope "/", WcInsightsWeb do
  pipe_through :browser

  live "/", HomeLive, :index
  live "/matches/:id", MatchLive.Show, :show
  live "/teams/:id", TeamLive.Show, :show
end
```

### Task A3: Add Dependencies
In `mix.exs`, add:
```elixir
{:req, "~> 0.5"},
{:jason, "~> 1.4"}
```
Then run:
```bash
mix deps.get
```

### Task A4: Environment Variables
In `config/runtime.exs`, read:
```elixir
config :wc_insights,
  football_api_key: System.get_env("FOOTBALL_API_KEY"),
  football_base_url: System.get_env("FOOTBALL_BASE_URL") || "https://v3.football.api-sports.io"
```

Create `.env.example`:
```
FOOTBALL_API_KEY=your-api-sports-key
OPENAI_API_KEY=your-openai-key
```

### Task A5: Verify App Starts
```bash
mix phx.server
```
> Should start without errors. Ctrl-C twice to stop.

**Deliverable:** App boots. Other engineers can run `mix phx.server`.

---

## Part B: FootballApi.Client (15 min)

### Task B1: Create Client Module
File: `lib/wc_insights/football_api/client.ex`

Responsibilities:
- Raw HTTP GET to API-Football
- Inject `x-apisports-key` header
- Return raw JSON body
- Handle HTTP errors and API errors

Required functions:
```elixir
def get_fixtures(params \\ %{})
def get_team(team_id)
def get_squad(team_id)
```

**Contract:**
- Success: `{:ok, map()}` (parsed JSON)
- Error: `{:error, String.t()}`

### Task B2: Test Client Manually
In `iex -S mix`:
```elixir
WcInsights.FootballApi.Client.get_fixtures(%{league: 1, season: 2026})
```
> Should return fixtures list. If you don't have an API key yet, use mock data or skip to Task C2.

**Deliverable:** Client makes real HTTP calls and returns parsed JSON.

---

## Part C: FootballData — Structs & Normalization (20 min)

### Task C1: Create Struct Modules
Files:
- `lib/wc_insights/football_data/match.ex`
- `lib/wc_insights/football_data/team.ex`
- `lib/wc_insights/football_data/player.ex`

See `docs/data-structures.md` for exact field names.

### Task C2: Create Main Module
File: `lib/wc_insights/football_data.ex`

Required public functions:
```elixir
def list_matches() :: [FootballData.Match.t()]
def get_match!(match_id) :: FootballData.Match.t()
def get_team!(team_id) :: FootballData.Team.t()
def list_team_recent_matches(team_id) :: [FootballData.Match.t()]
def list_team_players(team_id) :: [FootballData.Player.t()]
```

Plus UI helpers:
```elixir
def live_matches(matches)
def upcoming_matches(matches)
def recent_matches(matches)
```

### Task C3: Normalization Logic
Map API-Football response fields to struct fields exactly per `docs/data-structures.md`.

Key mappings:
| API Field | Struct Field |
|-----------|-------------|
| `fixture.id` | `id` |
| `fixture.date` | `kickoff_at` (parse to DateTime) |
| `fixture.status.short` | `status` |
| `teams.home.name` | `home_team_name` |
| `teams.home.logo` | `home_team_logo` |
| `goals.home` | `score_home` |

### Task C4: Mock Data Fallback (Optional but Recommended)
If no API key is available during development, add a `priv/data/sample_fixtures.json` with 3–5 matches so Engineer 2 can start building UI immediately.

**Deliverable:** All 5 public functions return correct structs. UI helpers work on lists.

---

## Part D: Home Page Skeleton (10 min)

### Task D1: Create Placeholder LiveViews
Create empty modules so the router compiles:

`lib/wc_insights_web/live/home_live.ex`:
```elixir
defmodule WcInsightsWeb.HomeLive do
  use WcInsightsWeb, :live_view

  def mount(_params, _session, socket) do
    matches = WcInsights.FootballData.list_matches()
    {:ok, assign(socket, matches: matches)}
  end
end
```

`lib/wc_insights_web/live/match_live/show.ex` and `lib/wc_insights_web/live/team_live/show.ex`:
Same pattern — empty `mount` that assigns placeholder data.

### Task D2: Create Minimal Templates
`lib/wc_insights_web/live/home_live.html.heex`:
```heex
<h1>World Cup 2026</h1>
<ul>
  <li :for={match <- @matches}>
    <%= match.home_team_name %> vs <%= match.away_team_name %>
  </li>
</ul>
```

**Deliverable:** Home page loads and shows match list (even if basic).

---

## Part E: Handoff & Communication (5 min)

### Task E1: Commit & Push
```bash
git add .
git commit -m "feat: bootstrap Phoenix + FootballData layer"
git push origin main
```

### Task E2: Notify Team
Tell Engineers 2 and 3:
- "Data layer is ready. Use `FootballData.*` functions only."
- "API key needed: get one free at dashboard.api-sports.io"
- "Run `mix phx.server` to verify"

---

## Checkpoint: Done When

- [ ] `mix phx.server` starts without errors
- [ ] `FootballData.list_matches/0` returns a list of `Match` structs
- [ ] `FootballData.get_match!/1` returns a single `Match` struct
- [ ] `FootballData.get_team!/1` returns a `Team` struct
- [ ] `FootballData.list_team_recent_matches/1` returns matches
- [ ] `FootballData.list_team_players/1` returns players
- [ ] Home page renders a list of matches
- [ ] All code is committed and pushed

---

## Time Budget

| Part | Time |
|------|------|
| A: Bootstrap | 15–20 min |
| B: API Client | 15 min |
| C: Data Layer | 20 min |
| D: Home Skeleton | 10 min |
| E: Handoff | 5 min |
| **Total** | **~65–70 min** |

---

## Files You Own

```
lib/wc_insights/
├── application.ex
├── football_api/
│   └── client.ex
├── football_data.ex
└── football_data/
    ├── match.ex
    ├── team.ex
    └── player.ex

lib/wc_insights_web/
├── router.ex
├── live/
│   ├── home_live.ex
│   ├── home_live.html.heex
│   ├── match_live/
│   │   ├── show.ex
│   │   └── show.html.heex
│   └── team_live/
│       ├── show.ex
│       └── show.html.heex
└── components/layouts/
    ├── app.html.heex
    └── root.html.heex

config/
├── config.exs
├── dev.exs
├── prod.exs
├── runtime.exs
├── test.exs

mix.exs
.env.example
```

## Files You Do NOT Touch

```
lib/wc_insights/
├── open_ai/
│   └── client.ex          # Engineer 3
├── predictions.ex          # Engineer 3
└── team_status.ex          # Engineer 3

lib/wc_insights_web/live/
├── match_live/show.ex       # Engineer 2 (after skeleton)
└── team_live/show.ex        # Engineer 2 (after skeleton)
```
