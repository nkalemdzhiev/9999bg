defmodule WorldCupInsights.TeamStatus do
  @moduledoc """
  Team status aggregator for the MVP.

  Uses fixture data plus local honors fallback until the football data service
  is integrated.
  """

  alias WorldCupInsights.Fixtures

  @honors_path Path.expand("../../../priv/data/team_honors.json", __DIR__)

  @type team_status :: %{
          team: map(),
          players: [map()],
          recent_matches: [map()],
          honors: [String.t()]
        }

  @spec get_team_status(String.t()) :: team_status()
  def get_team_status(team_id) when is_binary(team_id) do
    %{
      team: Fixtures.sample_team(team_id),
      players: Fixtures.sample_players(team_id),
      recent_matches: Fixtures.sample_recent_matches(team_id),
      honors: fetch_honors(team_id)
    }
  end

  defp fetch_honors(team_id) do
    honors_map =
      @honors_path
      |> File.read!()
      |> Jason.decode!()

    Map.get(honors_map, team_id, [])
  end
end
