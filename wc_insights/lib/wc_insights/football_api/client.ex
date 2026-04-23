defmodule WcInsights.FootballApi.Client do
  @moduledoc """
  Raw HTTP client for TheSportsDB.
  """

  @base_url "https://www.thesportsdb.com/api/v1/json"
  @api_key Application.compile_env(:wc_insights, :thesportsdb_api_key, "3")
  @world_cup_league_id "4429"

  def get_fixtures(season \\ "2026") do
    request("/eventsseason.php", %{id: @world_cup_league_id, s: season})
  end

  def get_event(event_id) do
    request("/lookupevent.php", %{id: event_id})
  end

  def get_team_by_name(team_name) do
    request("/searchteams.php", %{t: team_name})
  end

  def get_team(team_id) do
    request("/lookupteam.php", %{id: team_id})
  end

  def get_last_events(team_id) do
    request("/eventslast.php", %{id: team_id})
  end

  def get_next_events(team_id) do
    request("/eventsnext.php", %{id: team_id})
  end

  def get_squad(team_id) do
    request("/lookup_all_players.php", %{id: team_id})
  end

  defp request(endpoint, params) do
    url = "#{@base_url}/#{@api_key}#{endpoint}"

    case Req.get(url, params: params, retry: false, receive_timeout: 5_000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end
end
