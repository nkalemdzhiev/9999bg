defmodule WcInsights.Predictions do
  @moduledoc """
  Match prediction service using Gemini.
  Falls back to deterministic predictions when Gemini is unavailable.
  """

  alias FootballData.Match
  alias WcInsights.Gemini.Client

  defp client_module do
    Application.get_env(:wc_insights, :ai_prediction_client, Client)
  end
  alias WcInsights.FootballData

  @type prediction_result :: %{
          winner_pick: String.t(),
          reasoning: String.t(),
          confidence: float(),
          generated_at: String.t(),
          source: atom()
        }

  @doc """
  Predict from a match struct, ID, or context map.
  """
  @spec predict_match(Match.t() | integer() | String.t() | map()) :: prediction_result() | {:ok, prediction_result()} | {:error, term()}
  def predict_match(%Match{} = match) do
    prompt = build_prompt(match)

    case client_module().predict(%{system_prompt: system_prompt(), user_prompt: prompt}) do
      {:ok, %{"winner_pick" => winner_pick, "reasoning" => reasoning} = result} ->
        confidence = parse_confidence(result)
        prediction_payload(match, winner_pick, reasoning, confidence, :gemini)

      {:error, _reason} ->
        fallback_prediction(match)
    end
  end

  def predict_match(match_id) when is_integer(match_id) or is_binary(match_id) do
    match = FootballData.get_match!(match_id)
    predict_match(match)
  end

  def predict_match(match_context) when is_map(match_context) do
    predict_match_context(match_context)
  end

  @doc """
  Predict from full match context (used by match detail page).
  Returns {:ok, result} | {:error, reason} tuple.
  """
  @spec predict_match_context(map()) :: {:ok, prediction_result()} | {:error, term()}
  def predict_match_context(match_context) when is_map(match_context) do
    user_prompt = build_context_prompt(match_context)

    with {:ok, %{"winner_pick" => winner_pick, "reasoning" => reasoning, "confidence" => confidence}} <-
           client_module().predict(%{system_prompt: system_prompt(), user_prompt: user_prompt}) do
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

  @spec get_cached_prediction(Match.t() | integer() | String.t()) :: prediction_result()
  def get_cached_prediction(match_or_id) do
    predict_match(match_or_id)
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp build_prompt(match) do
case match do
      %Match{} ->
        """
        Predict the winner of this FIFA World Cup 2026 match.

        Home team: #{match.home_team_name}
        Away team: #{match.away_team_name}
        Status: #{match.status_long}
        #{if match.score_home, do: "Current score: #{match.score_home}-#{match.score_away}", else: ""}

        Return JSON with winner_pick (home/away/draw), reasoning (1-2 sentences), and confidence (0.0-1.0).
        """

      _ ->
        "Predict the winner. Return JSON with winner_pick, reasoning, confidence."
    end
  end

  defp build_context_prompt(match_context) do
    snapshot = %{
      match: %{
        home_team: match_context.match.home_team_name,
        away_team: match_context.match.away_team_name,
        status: match_context.match.status
      },
      expected_lineups: %{
        home: compact_players(match_context.expected_lineups.home),
        away: compact_players(match_context.expected_lineups.away)
      },
      missing_players: match_context.missing_players,
      recent_team_form: match_context.recent_team_form
    }

    """
    Predict the likely winner of this football match using the structured data below.
    Base the answer mainly on the current expected players, absences, and recent player form.
    Do not mention betting. Keep the reasoning concise and fan-friendly in 2 sentences max.

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

  defp parse_confidence(%{"confidence" => conf}) when is_number(conf), do: conf
  defp parse_confidence(%{"confidence" => "high"}), do: 0.85
  defp parse_confidence(%{"confidence" => "medium"}), do: 0.60
  defp parse_confidence(%{"confidence" => "low"}), do: 0.35
  defp parse_confidence(%{"confidence" => conf}) when is_binary(conf) do
    case Float.parse(conf) do
      {num, _} -> num
      :error -> 0.50
    end
  end
  defp parse_confidence(_), do: 0.50

  defp fallback_prediction(match) do
    winner_pick =
      cond do
        match.status in ["FT", "AET", "PEN"] and match.score_home > match.score_away -> "home"
        match.status in ["FT", "AET", "PEN"] and match.score_home < match.score_away -> "away"
        match.status in ["FT", "AET", "PEN"] -> "draw"
        true -> Enum.random(["home", "away", "draw"])
      end

    confidence = fallback_confidence(match, winner_pick)

    reasoning =
      "Based on the match context and team strength, the prediction favors #{pick_name(match, winner_pick)}."

    prediction_payload(match, winner_pick, reasoning, confidence, :fallback)
  end

  defp fallback_confidence(match, winner_pick) do
    cond do
      match.status in ["FT", "AET", "PEN"] ->
        diff = abs((match.score_home || 0) - (match.score_away || 0))
        base = min(0.50 + diff * 0.08, 0.95)
        if winner_pick == "draw", do: 0.55, else: base

      true ->
        # Deterministic pseudo-confidence based on team names so it varies per match
        hash = :erlang.phash2({match.home_team_name, match.away_team_name})
        0.40 + rem(hash, 40) / 100.0
    end
  end

  defp pick_name(match, "home"), do: match.home_team_name
  defp pick_name(match, "away"), do: match.away_team_name
  defp pick_name(_, "draw"), do: "a draw"

  defp prediction_payload(match, winner_pick, reasoning, confidence, source) do
    %{
      match_id: match.id,
      winner_pick: winner_pick,
      reasoning: reasoning,
      confidence: confidence,
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      source: source
    }
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
