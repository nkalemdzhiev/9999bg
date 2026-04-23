# API Contract — TheSportsDB

## Provider Choice: TheSportsDB

**Why this provider:**
- Completely free — no signup or credit card required
- Public test API key: `3`
- Real football data: fixtures, scores, teams, players, venues
- Has World Cup 2026 data available now
- Simple REST JSON API
- 30 requests/minute rate limit on free tier

**Provider:** https://www.thesportsdb.com/  
**Docs:** https://www.thesportsdb.com/api.php

---

## Authentication

```
No authentication required for basic access.
Free test key: 3
```

The API key is passed in the URL path:
```
https://www.thesportsdb.com/api/v1/json/3/{endpoint}
```

---

## Base URL

```
https://www.thesportsdb.com/api/v1/json/3
```

---

## World Cup Parameters

| Param | Value | Meaning |
|-------|-------|---------|
| `id` (league) | `4429` | FIFA World Cup |
| `s` (season) | `2026` | Tournament year |

---

## Endpoints We Use

### 1. List All Matches (Season)

```
GET /eventsseason.php?id=4429&s=2026
```

**Use for:** `FootballData.list_matches/0`

**Sample response (trimmed):**
```json
{
  "events": [
    {
      "idEvent": "2391728",
      "strTimestamp": "2026-06-11T19:00:00",
      "strEvent": "Mexico vs South Africa",
      "strSport": "Soccer",
      "idLeague": "4429",
      "strLeague": "FIFA World Cup",
      "strSeason": "2026",
      "strHomeTeam": "Mexico",
      "strAwayTeam": "South Africa",
      "intHomeScore": null,
      "intAwayScore": null,
      "intRound": "1",
      "strVenue": "Estadio Azteca",
      "strCity": "Mexico City, MX",
      "idHomeTeam": "134497",
      "idAwayTeam": "136482",
      "strHomeTeamBadge": "https://r2.thesportsdb.com/images/media/team/badge/3rmosi1748525208.png",
      "strAwayTeamBadge": "https://r2.thesportsdb.com/images/media/team/badge/xjz9j91553368824.png",
      "strStatus": "Not Started"
    }
  ]
}
```

**Key status values:**
| Value | Meaning |
|-------|---------|
| `Not Started` | Upcoming match |
| `Match Finished` | Completed match |
| `First Half` | Live - 1st half |
| `Halftime` | Live - halftime |
| `Second Half` | Live - 2nd half |
| `Extra Time` | Live - extra time |
| `Penalty Shootout` | Live - penalties |
| `Suspended` | Match suspended |
| `Postponed` | Match postponed |
| `Cancelled` | Match cancelled |

---

### 2. Get Single Match

```
GET /lookupevent.php?id={event_id}
```

**Use for:** `FootballData.get_match!/1`

Same response shape as above, but `events` array has one element.

---

### 3. Get Team

```
GET /lookupteam.php?id={team_id}
```

**Use for:** `FootballData.get_team!/1`

**Note:** This endpoint can be unreliable for some IDs. Fallback to `searchteams.php?t={team_name}` is implemented.

**Sample response:**
```json
{
  "teams": [
    {
      "idTeam": "134496",
      "strTeam": "Brazil",
      "strTeamShort": "BRA",
      "strCountry": "Brazil",
      "intFormedYear": "1916",
      "strSport": "Soccer",
      "strLeague": "FIFA World Cup",
      "strStadium": "Estádio do Maracanã",
      "strLocation": "Maracanã, Rio de Janeiro, Brazil",
      "intStadiumCapacity": "78838",
      "strTeamBadge": "https://r2.thesportsdb.com/images/media/team/badge/..."
    }
  ]
}
```

---

### 4. List Team Recent Matches

```
GET /eventslast.php?id={team_id}
```

**Use for:** `FootballData.list_team_recent_matches/1`

Returns the last 5 events for the team.

---

### 5. List Team Players (Squad)

```
GET /lookup_all_players.php?id={team_id}
```

**Use for:** `FootballData.list_team_players/1`

**Sample response:**
```json
{
  "player": [
    {
      "idPlayer": "34168981",
      "strPlayer": "Carlo Ancelotti",
      "dateBorn": "1959-06-10",
      "strNumber": "",
      "strPosition": "Manager",
      "strThumb": "https://r2.thesportsdb.com/images/media/player/thumb/..."
    }
  ]
}
```

**Note:** Response includes managers/coaches. Filter by `strPosition` to get players only.

---

## Rate Limits

- Free tier: **30 requests/minute**
- Premium: **100 requests/minute**

**Hackathon strategy:** Cache in memory. One fetch of all fixtures is ~1 request.

---

## Error Handling

The API returns HTTP 200 with empty arrays or `null` when no data is found.

Our client checks for:
- `events` / `teams` / `player` keys in response
- `nil` or empty list = no data
- HTTP errors return `{:error, reason}`

---

## Environment Variables

```
THESPORTSDB_API_KEY=3
```

The default key `3` is a public test key and works without registration.
