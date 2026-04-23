defmodule WcInsights.Predictions do
  @moduledoc """
  Match prediction service.

  Uses Gemini only. If Gemini is unavailable or returns an invalid payload,
  the caller should surface prediction unavailability instead of using a local fallback.
  """

  @type prediction_result :: %{
          winner_pick: String.t(),
          reasoning: String.t(),
          generated_at: String.t(),
          source: atom(),
          confidence: String.t()
        }

  @spec predict_match(map()) :: {:ok, prediction_result()} | {:error, term()}
  def predict_match(match_context) when is_map(match_context) do
    with {:ok, %{"winner_pick" => winner_pick, "reasoning" => reasoning, "confidence" => confidence}} <-
           client_module().predict(%{
             system_prompt: system_prompt(),
             user_prompt: build_user_prompt(match_context)
           }) do
      {:ok,
       %{
         winner_pick: winner_pick,
         reasoning: reasoning,
         confidence: confidence,
         generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
         source: :gemini
       }}
    else
      {:ok, payload} -> {:error, {:invalid_prediction_payload, payload}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec build_user_prompt(map()) :: String.t()
  def build_user_prompt(match_context) do
    snapshot = %{
      match: %{
        id: match_context.match.id,
        home_team: match_context.home_team.name,
        away_team: match_context.away_team.name,
        kickoff_at: match_context.match.kickoff_at,
        status: match_context.match.status,
        round: match_context.match.round
      },
      expected_lineups: %{
        home: compact_players(match_context.expected_lineups.home),
        away: compact_players(match_context.expected_lineups.away)
      },
      missing_players: match_context.missing_players,
      recent_team_form: match_context.recent_team_form,
      team_stats: match_context.team_stats
    }

    """
    Predict the likely winner of this football match using the structured data below.
    Base the answer mainly on the current expected players, absences, and recent player form.
    Do not mention betting.
    Keep the reasoning concise and fan-friendly in 2 sentences max.

    #{Jason.encode!(snapshot)}
    """
  end

  defp system_prompt do
    """
    You are an expert football match analyst for a World Cup web app.
    Return only structured JSON with winner_pick, reasoning, and confidence.
    Use the supplied match context only.
    """
  end

  defp client_module do
    Application.get_env(:wc_insights, :ai_prediction_client, WcInsights.Gemini.Client)
  end

  defp compact_players(players) do
    Enum.map(players, fn player ->
      %{
        name: player.name,
        position: player.position,
        expected_starter: Map.get(player, :expected_starter, false),
        recent_stats: Map.get(player, :recent_stats, %{})
      }
    end)
  end
end
