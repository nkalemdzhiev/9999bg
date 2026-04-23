defmodule WorldCupInsights.Fixtures do
  @moduledoc """
  Local demo fixtures used until the football data layer is available.
  """

  @type team_id :: String.t()
  @type match_id :: String.t()

  @spec sample_match(match_id()) :: map()
  def sample_match(match_id \\ "match_arg_fra") do
    %{
      id: match_id,
      competition: "FIFA World Cup",
      kickoff_at: "2026-06-11T18:00:00Z",
      status: "scheduled",
      home_team: %{id: "arg", name: "Argentina", fifa_code: "ARG"},
      away_team: %{id: "fra", name: "France", fifa_code: "FRA"},
      recent_form: %{
        home: ["W", "W", "D", "W", "W"],
        away: ["W", "L", "W", "D", "W"]
      },
      recent_results: %{
        home: [
          %{opponent: "Brazil", result: "W", score: "2-1"},
          %{opponent: "Uruguay", result: "W", score: "1-0"},
          %{opponent: "Germany", result: "D", score: "1-1"}
        ],
        away: [
          %{opponent: "Spain", result: "W", score: "2-0"},
          %{opponent: "England", result: "L", score: "0-1"},
          %{opponent: "Portugal", result: "W", score: "3-1"}
        ]
      },
      tournament_context: %{
        stage: "Group Stage",
        group: "A"
      }
    }
  end

  @spec sample_team(team_id()) :: map()
  def sample_team("arg") do
    %{
      id: "arg",
      name: "Argentina",
      code: "ARG",
      coach: "Lionel Scaloni",
      logo: nil
    }
  end

  def sample_team("fra") do
    %{
      id: "fra",
      name: "France",
      code: "FRA",
      coach: "Didier Deschamps",
      logo: nil
    }
  end

  def sample_team(team_id) do
    %{
      id: team_id,
      name: "Demo Team",
      code: String.upcase(team_id),
      coach: "Unknown",
      logo: nil
    }
  end

  @spec sample_players(team_id()) :: [map()]
  def sample_players("arg") do
    [
      %{id: "p_arg_1", name: "Lionel Messi", position: "FW", number: 10},
      %{id: "p_arg_2", name: "Julian Alvarez", position: "FW", number: 9},
      %{id: "p_arg_3", name: "Enzo Fernandez", position: "MF", number: 8}
    ]
  end

  def sample_players("fra") do
    [
      %{id: "p_fra_1", name: "Kylian Mbappe", position: "FW", number: 10},
      %{id: "p_fra_2", name: "Antoine Griezmann", position: "MF", number: 7},
      %{id: "p_fra_3", name: "Aurelien Tchouameni", position: "MF", number: 6}
    ]
  end

  def sample_players(_team_id), do: []

  @spec sample_recent_matches(team_id()) :: [map()]
  def sample_recent_matches("arg") do
    [
      %{opponent: "Brazil", result: "W", score: "2-1", played_at: "2026-03-10"},
      %{opponent: "Uruguay", result: "W", score: "1-0", played_at: "2026-03-05"},
      %{opponent: "Germany", result: "D", score: "1-1", played_at: "2026-02-26"}
    ]
  end

  def sample_recent_matches("fra") do
    [
      %{opponent: "Spain", result: "W", score: "2-0", played_at: "2026-03-09"},
      %{opponent: "England", result: "L", score: "0-1", played_at: "2026-03-04"},
      %{opponent: "Portugal", result: "W", score: "3-1", played_at: "2026-02-25"}
    ]
  end

  def sample_recent_matches(_team_id), do: []
end
