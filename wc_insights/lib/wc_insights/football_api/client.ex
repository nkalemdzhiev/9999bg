defmodule WcInsights.FootballApi.Client do
  @moduledoc """
  Raw HTTP client for API-Football (API-Sports).
  """

  @base_url Application.compile_env(:wc_insights, :football_base_url, "https://v3.football.api-sports.io")

  def get_fixtures(params \\ %{}) do
    request("/fixtures", params)
  end

  def get_team(team_id) do
    request("/teams", %{id: team_id})
  end

  def get_squad(team_id) do
    request("/players/squads", %{team: team_id})
  end

  defp request(path, params) do
    api_key = Application.get_env(:wc_insights, :football_api_key)

    if is_nil(api_key) or api_key == "" do
      {:error, "FOOTBALL_API_KEY not configured"}
    else
      case Req.get(
             @base_url <> path,
             headers: [{"x-apisports-key", api_key}],
             params: params
           ) do
      {:ok, %{status: 200, body: body}} ->
        if is_map(body) and Map.has_key?(body, "errors") and body["errors"] != [] do
          {:error, inspect(body["errors"])}
        else
          {:ok, body}
        end

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, inspect(reason)}
      end
    end
  end
end
