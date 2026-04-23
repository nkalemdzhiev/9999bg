defmodule WcInsights.Odds.SharpApiClient do
  @moduledoc """
  HTTP client for SharpAPI odds.

  Reads SHARP_API_KEY from environment. If unset, returns error immediately
  so the caller falls back to demo odds.

  Endpoint: GET https://api.sharpapi.io/api/v1/odds
  Docs: https://docs.sharpapi.io/en/api-reference/odds

  Query strategy for soccer matches:
    - sport=soccer
    - market=moneyline
    - limit=200
  Then filter the response by home/away team names.

  SharpAPI free tier: 12 req/min, 2 sportsbooks (DraftKings, FanDuel),
  60-second data delay. No credit card required.
  Sign up: https://sharpapi.io
  """

  @base_url "https://api.sharpapi.io/api/v1/odds"

  @spec get_odds(String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_odds(_match_id, home_team, away_team) do
    api_key = System.get_env("SHARP_API_KEY")

    if is_nil(api_key) or api_key == "" do
      {:error, "SHARP_API_KEY not set"}
    else
      do_fetch(api_key, home_team, away_team)
    end
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp do_fetch(api_key, home_team, away_team) do
    params = [
      sport: "soccer",
      market: "moneyline",
      limit: 200
    ]

    headers = [
      {"x-api-key", api_key},
      {"accept", "application/json"}
    ]

    case Req.get(@base_url, headers: headers, params: params) do
      {:ok, %{status: 200, body: body}} ->
        parse_response(body, home_team, away_team)

      {:ok, %{status: 401}} ->
        {:error, "SharpAPI: Invalid or missing API key"}

      {:ok, %{status: 429}} ->
        {:error, "SharpAPI: Rate limit exceeded"}

      {:ok, %{status: status, body: body}} ->
        {:error, "SharpAPI HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "SharpAPI request failed: #{inspect(reason)}"}
    end
  end

  defp parse_response(%{"data" => odds_list}, home_team, away_team) when is_list(odds_list) do
    normalized_home = normalize_name(home_team)
    normalized_away = normalize_name(away_team)

    match_odds =
      Enum.filter(odds_list, fn odd ->
        ht = normalize_name(odd["home_team"] || "")
        at = normalize_name(odd["away_team"] || "")
        (ht == normalized_home and at == normalized_away) or
          (ht == normalized_away and at == normalized_home)
      end)

    if length(match_odds) >= 2 do
      # Group by selection_type to extract home / away / draw
      by_selection =
        match_odds
        |> Enum.group_by(& &1["selection_type"])

      home = decimal_from_group(by_selection, "home")
      away = decimal_from_group(by_selection, "away")
      draw = decimal_from_group(by_selection, "draw")

      # If draw is missing, estimate it from home/away using the overround formula
      draw = draw || estimate_draw_odds(home, away)

      if home && away do
        {:ok,
         %{
           match_id: nil,
           home_team: home_team,
           away_team: away_team,
           home_odds: home,
           draw_odds: draw,
           away_odds: away,
           bookmaker: bookmaker_label(match_odds)
         }}
      else
        {:error, "SharpAPI: Could not extract home/away odds for #{home_team} vs #{away_team}"}
      end
    else
      {:error, "SharpAPI: No odds found for #{home_team} vs #{away_team}"}
    end
  end

  defp parse_response(%{"error" => error}, _home, _away) do
    {:error, "SharpAPI error: #{error["message"] || inspect(error)}"}
  end

  defp parse_response(_body, _home, _away) do
    {:error, "SharpAPI: Unexpected response format"}
  end

  defp decimal_from_group(grouped, key) do
    case grouped[key] do
      [first | _] -> first["odds_decimal"]
      _ -> nil
    end
  end

  # Estimate draw odds when SharpAPI only returns home/away (no 1X2 draw)
  # Using the formula: 1/draw = 1 - 1/home - 1/away (with margin assumption)
  defp estimate_draw_odds(home, away) when is_number(home) and is_number(away) do
    margin = 1.0 / home + 1.0 / away
    remaining = max(1.0 - margin, 0.05)
    Float.round(1.0 / remaining, 2)
  end

  defp estimate_draw_odds(_, _), do: 3.2

  defp bookmaker_label(odds_list) do
    odds_list
    |> Enum.map(& &1["sportsbook"])
    |> Enum.uniq()
    |> Enum.join(", ")
    |> case do
      "" -> "SharpAPI"
      books -> "SharpAPI (#{books})"
    end
  end

  defp normalize_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
