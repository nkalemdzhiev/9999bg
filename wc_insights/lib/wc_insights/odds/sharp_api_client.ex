defmodule WcInsights.Odds.SharpApiClient do
  @moduledoc """
  HTTP client for SharpAPI odds.
  Reads SHARP_API_KEY from environment. If unset, returns error immediately
  so the caller falls back to demo odds.
  """

  @spec get_odds(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_odds(_match_id) do
    api_key = System.get_env("SHARP_API_KEY")

    if is_nil(api_key) or api_key == "" do
      {:error, "SHARP_API_KEY not set"}
    else
      # SharpAPI free tier is generous (12 req/min).
      # TODO: Replace with real Req.get call once endpoint is verified.
      # For now, return a placeholder so the architecture is ready.
      {:ok,
       %{
         match_id: nil,
         home_team: nil,
         away_team: nil,
         home_odds: 2.0,
         draw_odds: 3.2,
         away_odds: 3.8,
         bookmaker: "SharpAPI"
       }}
    end
  end
end
