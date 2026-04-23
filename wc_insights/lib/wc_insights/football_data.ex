defmodule WcInsights.FootballData do
  @moduledoc """
  Normalized football data layer using TheSportsDB.
  """

  alias FootballData.Match
  alias FootballData.Team
  alias FootballData.Player

  def list_matches do
    case WcInsights.FootballApi.Client.get_fixtures("2026") do
      {:ok, %{"events" => events}} when is_list(events) ->
        Enum.map(events, &parse_event/1)

      {:ok, %{"events" => nil}} ->
        load_mock_matches()

      {:error, _reason} ->
        load_mock_matches()
    end
  end

  def get_match!(match_id) do
    match_id_str = to_string(match_id)

    list_matches()
    |> Enum.find(fn m -> to_string(m.id) == match_id_str end)
    |> case do
      nil -> find_mock_match(match_id_str)
      match -> match
    end
  end

  def get_team!(team_id) do
    team_id_str = to_string(team_id)
    matches = list_matches()

    team_name =
      Enum.find_value(matches, fn m ->
        cond do
          to_string(m.home_team_id) == team_id_str -> m.home_team_name
          to_string(m.away_team_id) == team_id_str -> m.away_team_name
          true -> nil
        end
      end)

    if team_name do
      case WcInsights.FootballApi.Client.get_team_by_name(team_name) do
        {:ok, %{"teams" => [team | _]}} -> parse_team(team)
        _ -> build_placeholder_team(team_id, team_name)
      end
    else
      build_placeholder_team(team_id, "Team #{team_id}")
    end
  end

  def list_team_recent_matches(team_id) do
    case WcInsights.FootballApi.Client.get_last_events(team_id) do
      {:ok, %{"results" => events}} when is_list(events) ->
        Enum.map(events, &parse_event/1)

      _ ->
        []
    end
  end

  def list_team_players(team_id) do
    case WcInsights.FootballApi.Client.get_squad(team_id) do
      {:ok, %{"player" => players}} when is_list(players) ->
        players
        |> Enum.reject(fn p -> p["strPosition"] in ["Manager", "Coach", "Head Coach", ""] end)
        |> Enum.map(&parse_player/1)

      _ ->
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

  defp parse_event(event) do
    %Match{
      id: parse_integer(event["idEvent"]),
      home_team_id: parse_integer(event["idHomeTeam"]),
      away_team_id: parse_integer(event["idAwayTeam"]),
      home_team_name: event["strHomeTeam"] || "TBD",
      away_team_name: event["strAwayTeam"] || "TBD",
      home_team_logo: event["strHomeTeamBadge"],
      away_team_logo: event["strAwayTeamBadge"],
      kickoff_at: parse_datetime(event["strTimestamp"]),
      status: map_status(event["strStatus"]),
      status_long: event["strStatus"] || "Not Started",
      round: event["intRound"] |> to_string() |> format_round(),
      venue_name: event["strVenue"],
      venue_city: event["strCity"],
      score_home: parse_integer(event["intHomeScore"]),
      score_away: parse_integer(event["intAwayScore"]),
      score_halftime_home: nil,
      score_halftime_away: nil
    }
  end

  defp parse_team(team) do
    %Team{
      id: parse_integer(team["idTeam"]),
      name: team["strTeam"] || "Unknown",
      code: team["strTeamShort"],
      country: team["strCountry"] || "Unknown",
      founded: parse_integer(team["intFormedYear"]),
      national: team["strLeague"] in ["FIFA World Cup", "International Friendlies", "World Cup Qualifying CONMEBOL"],
      logo: team["strTeamBadge"],
      venue_name: team["strStadium"],
      venue_city: parse_city(team["strLocation"]),
      venue_capacity: parse_integer(team["intStadiumCapacity"])
    }
  end

  defp parse_player(player) do
    %Player{
      id: player["idPlayer"],
      name: player["strPlayer"] || "Unknown",
      age: calculate_age(player["dateBorn"]),
      number: parse_integer(player["strNumber"]),
      position: player["strPosition"],
      photo: player["strThumb"] || player["strCutout"]
    }
  end

  defp map_status(nil), do: "NS"
  defp map_status("Not Started"), do: "NS"
  defp map_status("Match Finished"), do: "FT"
  defp map_status("First Half"), do: "1H"
  defp map_status("Halftime"), do: "HT"
  defp map_status("Second Half"), do: "2H"
  defp map_status("Extra Time"), do: "ET"
  defp map_status("Penalty Shootout"), do: "P"
  defp map_status("After Extra Time"), do: "AET"
  defp map_status("After Penalty"), do: "PEN"
  defp map_status("Suspended"), do: "SUSP"
  defp map_status("Interrupted"), do: "INT"
  defp map_status("Postponed"), do: "PST"
  defp map_status("Cancelled"), do: "CANC"
  defp map_status(status), do: status

  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil
  defp parse_datetime(string) when is_binary(string) do
    case NaiveDateTime.from_iso8601(string) do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> nil
    end
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(""), do: nil
  defp parse_integer(int) when is_integer(int), do: int
  defp parse_integer(string) when is_binary(string) do
    case Integer.parse(string) do
      {num, _} -> num
      :error -> nil
    end
  end

  defp calculate_age(nil), do: nil
  defp calculate_age(""), do: nil
  defp calculate_age(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, birth_date} ->
        today = Date.utc_today()
        years = today.year - birth_date.year
        if Date.before?(today, %{birth_date | year: today.year}), do: years - 1, else: years

      _ ->
        nil
    end
  end

  defp parse_city(nil), do: nil
  defp parse_city(location) when is_binary(location) do
    location
    |> String.split(",")
    |> List.first()
    |> String.trim()
  end

  defp format_round(""), do: nil
  defp format_round(round) when is_binary(round), do: "Round #{round}"
  defp format_round(_), do: nil

  defp build_placeholder_team(team_id, name) do
    %Team{
      id: parse_integer(team_id),
      name: name,
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

  defp load_mock_matches do
    path = Path.join(:code.priv_dir(:wc_insights), "data/sample_fixtures.json")

    if File.exists?(path) do
      path
      |> File.read!()
      |> Jason.decode!()
      |> case do
        %{"events" => events} -> Enum.map(events, &parse_event/1)
        list when is_list(list) -> Enum.map(list, &parse_event/1)
        _ -> []
      end
    else
      []
    end
  end

  defp find_mock_match(match_id) do
    match_id_str = to_string(match_id)

    load_mock_matches()
    |> Enum.find(fn m -> to_string(m.id) == match_id_str end)
    |> case do
      nil -> raise "Match not found"
      match -> match
    end
  end
end
