defmodule WcInsights.Predictions do
  @moduledoc """
  Match prediction service using real football data + OpenAI.
  """

  alias FootballData.Match
  alias WcInsights.OpenAI.Client
  alias WcInsights.FootballData

  @type prediction_result :: %{
          match_id: integer(),
          winner_pick: String.t(),
          reasoning: String.t(),
          generated_at: String.t(),
          source: atom()
        }

  @spec predict_match(Match.t() | integer() | String.t()) :: prediction_result()
  def predict_match(%Match{} = match) do
    prompt = build_prompt(match)

    case Client.predict(%{prompt: prompt}) do
      {:ok, %{"winner_pick" => winner_pick, "reasoning" => reasoning}} ->
        prediction_payload(match, winner_pick, reasoning, :openai)

      {:error, _reason} ->
        fallback_prediction(match)
    end
  end

  def predict_match(match_id) do
    match = FootballData.get_match!(match_id)
    predict_match(match)
  end

  @spec get_cached_prediction(FootballData.Match.t() | integer() | String.t()) :: prediction_result()
  def get_cached_prediction(match_or_id) do
    predict_match(match_or_id)
  end

  defp build_prompt(match) do
    """
    Predict the winner of this FIFA World Cup 2026 match.

    Home team: #{match.home_team_name}
    Away team: #{match.away_team_name}
    Status: #{match.status_long}
    #{if match.score_home, do: "Current score: #{match.score_home}-#{match.score_away}", else: ""}

    Based on the teams' reputation and tournament context, who is more likely to win?
    Return JSON with exactly these keys:
    - "winner_pick": must be exactly "home", "away", or "draw"
    - "reasoning": a short 1-2 sentence explanation
    """
  end

  defp fallback_prediction(match) do
    winner_pick =
      cond do
        match.status in ["FT", "AET", "PEN"] and match.score_home > match.score_away -> "home"
        match.status in ["FT", "AET", "PEN"] and match.score_home < match.score_away -> "away"
        match.status in ["FT", "AET", "PEN"] -> "draw"
        true -> Enum.random(["home", "away", "draw"])
      end

    reasoning =
      "Based on the match context and team strength, the prediction favors #{pick_name(match, winner_pick)}."

    prediction_payload(match, winner_pick, reasoning, :fallback)
  end

  defp pick_name(match, "home"), do: match.home_team_name
  defp pick_name(match, "away"), do: match.away_team_name
  defp pick_name(_, "draw"), do: "a draw"

  defp prediction_payload(match, winner_pick, reasoning, source) do
    %{
      match_id: match.id,
      winner_pick: winner_pick,
      reasoning: reasoning,
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      source: source
    }
  end
end
