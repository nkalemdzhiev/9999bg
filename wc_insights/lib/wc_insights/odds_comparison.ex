defmodule WcInsights.OddsComparison do
  @moduledoc """
  Compares AI predictions against bookmaker odds to detect value bets.
  """

  alias WcInsights.Odds
  alias FootballData.Match

  @type comparison_result :: %{
          odds: Odds.odds_map() | nil,
          implied: %{home: float(), draw: float(), away: float()} | nil,
          ai_pick: String.t(),
          ai_confidence: float(),
          bookie_confidence: float(),
          edge: float(),
          recommendation: atom(),
          error: String.t() | nil
        }

  @doc """
  Compare AI prediction with bookmaker odds for a match.

  Returns a map with:
  - `:odds` — the raw odds map
  - `:implied` — implied probabilities (normalized to 100%)
  - `:ai_pick` — "home" | "away" | "draw"
  - `:ai_confidence` — 0.0 to 1.0
  - `:bookie_confidence` — implied probability for the same outcome
  - `:edge` — ai_confidence - bookie_confidence
  - `:recommendation` — :value_bet | :avoid | :neutral
  """
  @spec compare(Match.t(), map()) :: comparison_result()
  def compare(%Match{} = match, ai_prediction) do
    with {:ok, odds} <- Odds.fetch_odds(match.id, match.home_team_name, match.away_team_name),
         implied = Odds.implied_probabilities(odds) do
      ai_pick = ai_prediction[:winner_pick] || "home"
      ai_confidence = ai_prediction[:confidence] || 0.50

      bookie_confidence = Map.get(implied, String.to_atom(ai_pick), 0.33)
      edge = Float.round(ai_confidence - bookie_confidence, 4)

      %{
        odds: odds,
        implied: implied,
        ai_pick: ai_pick,
        ai_confidence: ai_confidence,
        bookie_confidence: bookie_confidence,
        edge: edge,
        recommendation: recommendation(edge),
        error: nil
      }
    else
      {:error, reason} ->
        # Even if odds fetch fails, return a struct with fallback odds
        fallback_odds = Odds.fallback_odds(match.home_team_name, match.away_team_name)
        implied = Odds.implied_probabilities(fallback_odds)
        ai_pick = ai_prediction[:winner_pick] || "home"
        ai_confidence = ai_prediction[:confidence] || 0.50
        bookie_confidence = Map.get(implied, String.to_atom(ai_pick), 0.33)
        edge = Float.round(ai_confidence - bookie_confidence, 4)

        %{
          odds: fallback_odds,
          implied: implied,
          ai_pick: ai_pick,
          ai_confidence: ai_confidence,
          bookie_confidence: bookie_confidence,
          edge: edge,
          recommendation: recommendation(edge),
          error: to_string(reason)
        }
    end
  end

  @doc """
  Human-readable label for a recommendation.
  """
  @spec recommendation_label(atom()) :: String.t()
  def recommendation_label(:value_bet), do: "VALUE BET"
  def recommendation_label(:avoid), do: "AVOID"
  def recommendation_label(:neutral), do: "FAIR VALUE"
  def recommendation_label(_), do: "UNKNOWN"

  @doc """
  CSS color class for a recommendation badge.
  """
  @spec recommendation_color(atom()) :: String.t()
  def recommendation_color(:value_bet), do: "bg-emerald-100 text-emerald-800 border-emerald-200"
  def recommendation_color(:avoid), do: "bg-rose-100 text-rose-800 border-rose-200"
  def recommendation_color(:neutral), do: "bg-amber-100 text-amber-800 border-amber-200"
  def recommendation_color(_), do: "bg-slate-100 text-slate-800 border-slate-200"

  @doc """
  Format edge as a signed percentage string, e.g. "+9.4%" or "−3.2%".
  """
  @spec format_edge(float()) :: String.t()
  def format_edge(edge) do
    pct = Float.round(edge * 100, 1)

    if pct >= 0 do
      "+#{pct}%"
    else
      "#{pct}%"
    end
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp recommendation(edge) when edge > 0.05, do: :value_bet
  defp recommendation(edge) when edge < -0.05, do: :avoid
  defp recommendation(_), do: :neutral
end
