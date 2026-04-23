defmodule WorldCupInsights.Predictions do
  @moduledoc """
  Match prediction service.

  Works with normalized match input and falls back to a deterministic local
  prediction if the OpenAI call is unavailable.
  """

  alias WorldCupInsights.Fixtures
  alias WorldCupInsights.OpenAI.Client

  @type match_input :: map()
  @type prediction_result :: %{
          match_id: String.t(),
          winner_pick: String.t(),
          reasoning: String.t(),
          generated_at: String.t(),
          source: atom()
        }

  @spec predict_match(match_input() | String.t()) :: prediction_result()
  def predict_match(match_or_id) do
    match = normalize_match_input(match_or_id)

    case Client.predict(%{prompt: build_prompt(match)}) do
      {:ok, %{"winner_pick" => winner_pick, "reasoning" => reasoning}} ->
        prediction_payload(match, winner_pick, reasoning, :openai)

      {:error, _reason} ->
        fallback_prediction(match)
    end
  end

  @spec get_cached_prediction(match_input() | String.t()) :: prediction_result()
  def get_cached_prediction(match_or_id) do
    # For the MVP this is a pass-through. Swap this for Cachex/ETS/DB later.
    predict_match(match_or_id)
  end

  @spec build_prompt(match_input()) :: String.t()
  def build_prompt(match) do
    """
    You are generating a football match prediction for a fan-facing World Cup app.
    Use only the structured data below.
    Return JSON with keys winner_pick and reasoning.

    Match:
    #{Jason.encode!(match)}
    """
  end

  defp normalize_match_input(match_id) when is_binary(match_id) do
    Fixtures.sample_match(match_id)
  end

  defp normalize_match_input(match) when is_map(match), do: match

  defp fallback_prediction(match) do
    home_wins = count_results(match, :home, "W")
    away_wins = count_results(match, :away, "W")

    winner_pick =
      if home_wins >= away_wins do
        match.home_team.name
      else
        match.away_team.name
      end

    reasoning =
      "#{winner_pick} edges the demo prediction based on stronger recent form in the local fallback data."

    prediction_payload(match, winner_pick, reasoning, :fallback)
  end

  defp count_results(match, side, expected_result) do
    match
    |> get_in([:recent_form, side])
    |> List.wrap()
    |> Enum.count(&(&1 == expected_result))
  end

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
