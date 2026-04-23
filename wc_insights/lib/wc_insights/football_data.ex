defmodule WcInsights.FootballData do
  @moduledoc """
  Normalized football data layer.
  """

  alias FootballData.Match
  alias FootballData.Team
  alias FootballData.Player

  def list_matches do
    case WcInsights.FootballApi.Client.get_fixtures(%{league: 1, season: 2026}) do
      {:ok, %{"response" => fixtures}} ->
        Enum.map(fixtures, &parse_match/1)

      {:error, _reason} ->
        load_mock_matches()
    end
  end

  def get_match!(match_id) do
    case WcInsights.FootballApi.Client.get_fixtures(%{id: match_id}) do
      {:ok, %{"response" => [fixture | _]}} ->
        parse_match(fixture)

      {:ok, %{"response" => []}} ->
        load_mock_matches()
        |> Enum.find(&(&1.id == match_id))
        |> case do
          nil -> raise "Match not found"
          match -> match
        end

      {:error, _reason} ->
        load_mock_matches()
        |> Enum.find(&(&1.id == match_id))
        |> case do
          nil -> raise "Match not found"
          match -> match
        end
    end
  end

  def get_team!(team_id) do
    case WcInsights.FootballApi.Client.get_team(team_id) do
      {:ok, %{"response" => [data | _]}} ->
        parse_team(data)

      {:ok, %{"response" => []}} ->
        raise "Team not found"

      {:error, _reason} ->
        %Team{
          id: team_id,
          name: "Team #{team_id}",
          code: nil,
          country: "Unknown",
          founded: nil,
          national: true,
          logo: nil,
          venue_name: nil,
          venue_city: nil,
          venue_capacity: nil
        }
    end
  end

  def list_team_recent_matches(team_id) do
    case WcInsights.FootballApi.Client.get_fixtures(%{team: team_id, last: 5}) do
      {:ok, %{"response" => fixtures}} ->
        Enum.map(fixtures, &parse_match/1)

      {:error, _reason} ->
        []
    end
  end

  def list_team_players(team_id) do
    case WcInsights.FootballApi.Client.get_squad(team_id) do
      {:ok, %{"response" => [%{"players" => players} | _]}} ->
        Enum.map(players, &parse_player/1)

      {:error, _reason} ->
        []
    end
  end

  def live_matches(matches) do
    live_statuses = ["1H", "HT", "2H", "ET", "P"]
    Enum.filter(matches, &(&1.status in live_statuses))
  end

  def upcoming_matches(matches) do
    now = DateTime.utc_now()

    Enum.filter(matches, fn m ->
      m.status == "NS" and not is_nil(m.kickoff_at) and DateTime.compare(m.kickoff_at, now) == :gt
    end)
  end

  def recent_matches(matches) do
    finished_statuses = ["FT", "AET", "PEN"]
    Enum.filter(matches, &(&1.status in finished_statuses))
  end

  defp parse_match(fixture) do
    %Match{
      id: get_in(fixture, ["fixture", "id"]),
      home_team_id: get_in(fixture, ["teams", "home", "id"]),
      away_team_id: get_in(fixture, ["teams", "away", "id"]),
      home_team_name: get_in(fixture, ["teams", "home", "name"]) || "TBD",
      away_team_name: get_in(fixture, ["teams", "away", "name"]) || "TBD",
      home_team_logo: get_in(fixture, ["teams", "home", "logo"]),
      away_team_logo: get_in(fixture, ["teams", "away", "logo"]),
      kickoff_at: parse_datetime(get_in(fixture, ["fixture", "date"])),
      status: get_in(fixture, ["fixture", "status", "short"]) || "NS",
      status_long: get_in(fixture, ["fixture", "status", "long"]) || "Not Started",
      round: get_in(fixture, ["league", "round"]),
      venue_name: get_in(fixture, ["fixture", "venue", "name"]),
      venue_city: get_in(fixture, ["fixture", "venue", "city"]),
      score_home: get_in(fixture, ["goals", "home"]),
      score_away: get_in(fixture, ["goals", "away"]),
      score_halftime_home: get_in(fixture, ["score", "halftime", "home"]),
      score_halftime_away: get_in(fixture, ["score", "halftime", "away"])
    }
  end

  defp parse_team(data) do
    %Team{
      id: get_in(data, ["team", "id"]),
      name: get_in(data, ["team", "name"]) || "Unknown",
      code: get_in(data, ["team", "code"]),
      country: get_in(data, ["team", "country"]) || "Unknown",
      founded: get_in(data, ["team", "founded"]),
      national: get_in(data, ["team", "national"]) || false,
      logo: get_in(data, ["team", "logo"]),
      venue_name: get_in(data, ["venue", "name"]),
      venue_city: get_in(data, ["venue", "city"]),
      venue_capacity: get_in(data, ["venue", "capacity"])
    }
  end

  defp parse_player(player) do
    %Player{
      id: player["id"],
      name: player["name"] || "Unknown",
      age: player["age"],
      number: player["number"],
      position: player["position"],
      photo: player["photo"]
    }
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(string) when is_binary(string) do
    case DateTime.from_iso8601(string) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp load_mock_matches do
    path = Path.join(:code.priv_dir(:wc_insights), "data/sample_fixtures.json")

    if File.exists?(path) do
      path
      |> File.read!()
      |> Jason.decode!()
      |> Enum.map(&parse_match/1)
    else
      []
    end
  end
end
