defmodule WcInsights.TeamStatus do
  @moduledoc """
  Team status aggregator combining real football data + honors fallback.
  """

  alias FootballData.{Match, Player, Team}
  alias WcInsights.FootballData

  @type status :: %{
          team: Team.t(),
          players: [Player.t()],
          recent_matches: [Match.t()],
          honors: [String.t()]
        }

  @spec get_team_status(integer() | String.t()) :: status()
  def get_team_status(team_id) do
    team = FootballData.get_team!(team_id)
    players = FootballData.list_team_players(team_id)
    recent_matches = FootballData.list_team_recent_matches(team_id)
    honors = fetch_honors(team.name)

    %{
      team: team,
      players: players,
      recent_matches: recent_matches,
      honors: honors
    }
  end

  defp fetch_honors(team_name) do
    path = Path.join(:code.priv_dir(:wc_insights), "data/team_honors.json")

    if File.exists?(path) do
      path
      |> File.read!()
      |> Jason.decode!()
      |> Map.get(team_name, [])
    else
      []
    end
  end
end
