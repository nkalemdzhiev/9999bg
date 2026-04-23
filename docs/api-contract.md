# API Contract — API-Football (API-Sports)

## Provider Choice: API-Football

**Why this provider:**
- Free tier: 100 requests/day (plenty for a hackathon demo)
- No credit card required
- Covers World Cup 2026 natively (`league=1`, `season=2026`)
- Comprehensive data: fixtures, lineups, standings, players, statistics, injuries
- Simple REST JSON API with consistent schema
- Fast, reliable, industry standard for football apps

**Provider:** https://www.api-football.com/  
**Dashboard:** https://dashboard.api-sports.io/  
**Docs:** https://www.api-football.com/documentation-v3

---

## Authentication

```
Header: x-apisports-key: YOUR_API_KEY
```

No query-parameter auth. The key is free upon signup.

---

## Base URL

```
https://v3.football.api-sports.io
```

---

## World Cup Parameters

| Param | Value | Meaning |
|-------|-------|---------|
| `league` | `1` | FIFA World Cup |
| `season` | `2026` | Tournament year |

---

## Endpoints We Use

### 1. List All Matches

```
GET /fixtures?league=1&season=2026
```

**Use for:** `FootballData.list_matches/0`

**Sample response (trimmed):**
```json
{
  "get": "/fixtures",
  "parameters": { "league": "1", "season": "2026" },
  "response": [
    {
      "fixture": {
        "id": 239625,
        "date": "2026-06-11T19:00:00+00:00",
        "timestamp": 1779793200,
        "status": { "short": "NS", "long": "Not Started" },
        "venue": { "id": 1, "name": "Azteca Stadium", "city": "Mexico City" }
      },
      "league": { "id": 1, "name": "World Cup", "season": 2026, "round": "Group Stage - 1" },
      "teams": {
        "home": { "id": 26, "name": "Mexico", "logo": "..." },
        "away": { "id": 24, "name": "Argentina", "logo": "..." }
      },
      "goals": { "home": null, "away": null },
      "score": {
        "halftime": { "home": null, "away": null },
        "fulltime": { "home": null, "away": null }
      }
    }
  ]
}
```

**Key status codes:**
| Code | Meaning |
|------|---------|
| `NS` | Not Started |
| `1H` | First Half |
| `HT` | Halftime |
| `2H` | Second Half |
| `ET` | Extra Time |
| `P`  | Penalty Shootout |
| `FT` | Match Finished |
| `AET`| After Extra Time |
| `PEN`| After Penalty |
| `SUSP` | Suspended |
| `INT` | Interrupted |
| `PST` | Postponed |
| `CANC`| Cancelled |
| `ABD` | Abandoned |
| `AWD` | Technical Loss |
| `WO`  | Walkover |

---

### 2. Get Single Match

```
GET /fixtures?id={fixture_id}
```

**Use for:** `FootballData.get_match!/1`

Same response shape as above, but `response` array has one element.

---

### 3. Get Team

```
GET /teams?id={team_id}
```

**Use for:** `FootballData.get_team!/1`

**Sample response:**
```json
{
  "response": [
    {
      "team": {
        "id": 26,
        "name": "Mexico",
        "code": "MEX",
        "country": "Mexico",
        "founded": 1927,
        "national": true,
        "logo": "https://media.api-sports.io/football/teams/26.png"
      },
      "venue": {
        "id": 1,
        "name": "Azteca Stadium",
        "city": "Mexico City",
        "capacity": 87523
      }
    }
  ]
}
```

---

### 4. List Team Recent Matches

```
GET /fixtures?team={team_id}&last=5&league=1&season=2026
```

**Use for:** `FootballData.list_team_recent_matches/1`

**Note:** `last=5` returns the last 5 fixtures for that team across all competitions by default. Filter with `league=1&season=2026` if you want only World Cup matches, or omit for all recent form.

---

### 5. List Team Players (Squad)

```
GET /players/squads?team={team_id}
```

**Use for:** `FootballData.list_team_players/1`

**Sample response:**
```json
{
  "response": [
    {
      "team": { "id": 26, "name": "Mexico", "logo": "..." },
      "players": [
        {
          "id": 1234,
          "name": "G. Ochoa",
          "age": 39,
          "number": 13,
          "position": "Goalkeeper",
          "photo": "https://media.api-sports.io/football/players/1234.png"
        }
      ]
    }
  ]
}
```

---

## Rate Limits

- Free tier: **100 requests/day**
- Paid tier: **100 requests/minute** ($19/month)

**Hackathon strategy:** Cache aggressively in memory. One boot-time fetch of all fixtures is ~1 request. After that, fetch only on demand.

---

## Error Handling

The API returns HTTP 200 even for errors, with an `errors` object:

```json
{ "get": "/fixtures", "parameters": {}, "errors": { "..." }, "response": [] }
```

Our client must check for `errors` and raise or return `{:error, reason}`.

---

## Environment Variables

```
FOOTBALL_API_KEY=your-api-sports-key
FOOTBALL_BASE_URL=https://v3.football.api-sports.io
```
