defmodule WcInsights.Odds do
  @moduledoc """
  Fetches bookmaker odds for a match.
  Tries live SharpAPI first, falls back to static demo odds JSON.
  Also provides implied probability calculations.
  """

  alias WcInsights.Odds.SharpApiClient

  @type odds_map :: %{
          match_id: String.t(),
          home_team: String.t(),
          away_team: String.t(),
          home_odds: float(),
          draw_odds: float(),
          away_odds: float(),
          bookmaker: String.t(),
          source: atom()
        }

  @doc """
  Fetch odds for a match by ID.
  Returns {:ok, odds_map} or {:error, reason}.
  """
  @spec fetch_odds(integer() | String.t(), String.t(), String.t()) :: {:ok, odds_map()} | {:error, String.t()}
  def fetch_odds(match_id, home_team \\ "", away_team \\ "") do
    match_id_str = to_string(match_id)

    case SharpApiClient.get_odds(match_id_str, home_team, away_team) do
      {:ok, odds} -> {:ok, Map.put(odds, :source, :live)}
      {:error, _} -> fetch_demo_odds(match_id_str)
    end
  end

  @doc """
  Convert decimal odds to implied probabilities.
  Removes the bookmaker overround so probabilities sum to 100%.
  """
  @spec implied_probabilities(odds_map()) :: %{
          home: float(),
          draw: float(),
          away: float()
        }
  def implied_probabilities(%{home_odds: h, draw_odds: d, away_odds: a}) do
    raw_home = 1.0 / h
    raw_draw = 1.0 / d
    raw_away = 1.0 / a

    total = raw_home + raw_draw + raw_away

    %{
      home: Float.round(raw_home / total, 4),
      draw: Float.round(raw_draw / total, 4),
      away: Float.round(raw_away / total, 4)
    }
  end

  @doc """
  Generate fallback odds deterministically from team names.
  Used when no demo or live odds exist.
  """
  @spec fallback_odds(String.t(), String.t()) :: odds_map()
  def fallback_odds(home_team, away_team) do
    hash = :erlang.phash2({home_team, away_team})

    # Generate realistic odds between 1.4 and 6.0
    home_base = 1.4 + rem(hash, 350) / 100.0
    away_base = 1.8 + rem(hash * 7, 420) / 100.0
    draw_base = 3.0 + rem(hash * 13, 200) / 100.0

    %{
      match_id: nil,
      home_team: home_team,
      away_team: away_team,
      home_odds: Float.round(home_base, 2),
      draw_odds: Float.round(draw_base, 2),
      away_odds: Float.round(away_base, 2),
      bookmaker: "Auto-generated",
      source: :fallback
    }
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp fetch_demo_odds(match_id_str) do
    path = Path.join(:code.priv_dir(:wc_insights), "data/demo_odds.json")

    if File.exists?(path) do
      path
      |> File.read!()
      |> Jason.decode!()
      |> Map.get("odds", [])
      |> Enum.find(fn o -> to_string(o["match_id"]) == match_id_str end)
      |> case do
        nil -> {:error, "No demo odds for match #{match_id_str}"}
        odds -> {:ok, atomize_odds(odds)}
      end
    else
      {:error, "Demo odds file not found"}
    end
  end

  defp atomize_odds(odds) do
    %{
      match_id: to_string(odds["match_id"]),
      home_team: odds["home_team"],
      away_team: odds["away_team"],
      home_odds: odds["home_odds"],
      draw_odds: odds["draw_odds"],
      away_odds: odds["away_odds"],
      bookmaker: odds["bookmaker"],
      source: :demo
    }
  end
end
