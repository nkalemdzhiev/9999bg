defmodule WcInsights.Predictions do
  @moduledoc """
  Match prediction service.

  Uses Gemini when configured, with the local lineup-aware heuristic as a
  fallback.
  """

  @position_weights %{
    "Goalkeeper" => 0.9,
    "Defender" => 1.0,
    "Midfielder" => 1.1,
    "Forward" => 1.2
  }

  @type prediction_result :: %{
          winner_pick: String.t(),
          reasoning: String.t(),
          generated_at: String.t(),
          source: atom(),
          home_score: float(),
          away_score: float(),
          confidence: String.t()
        }

  @spec predict_match(map()) :: prediction_result()
  def predict_match(match_context) when is_map(match_context) do
    baseline = local_prediction(match_context)

    case client_module().predict(%{
           system_prompt: system_prompt(),
           user_prompt: build_user_prompt(match_context, baseline)
         }) do
      {:ok, %{"winner_pick" => winner_pick, "reasoning" => reasoning, "confidence" => confidence}} ->
        baseline
        |> Map.put(:winner_pick, winner_pick)
        |> Map.put(:reasoning, reasoning)
        |> Map.put(:confidence, confidence)
        |> Map.put(:source, :gemini)

      {:error, _reason} ->
        baseline
    end
  end

  @spec build_user_prompt(map(), prediction_result()) :: String.t()
  def build_user_prompt(match_context, baseline) do
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
      team_stats: match_context.team_stats,
      local_model_baseline: %{
        winner_pick: baseline.winner_pick,
        home_score: baseline.home_score,
        away_score: baseline.away_score,
        confidence: baseline.confidence
      }
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

  defp local_prediction(match_context) do
    home_score = side_score(match_context, :home)
    away_score = side_score(match_context, :away)

    {winner_pick, loser_pick, winner_side, loser_side, winner_score, loser_score} =
      if home_score >= away_score do
        {
          match_context.home_team.name,
          match_context.away_team.name,
          :home,
          :away,
          home_score,
          away_score
        }
      else
        {
          match_context.away_team.name,
          match_context.home_team.name,
          :away,
          :home,
          away_score,
          home_score
        }
      end

    %{
      winner_pick: winner_pick,
      reasoning:
        build_reasoning(
          match_context,
          winner_pick,
          loser_pick,
          winner_side,
          loser_side,
          winner_score,
          loser_score
        ),
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      source: :local_lineup_model,
      home_score: Float.round(home_score, 1),
      away_score: Float.round(away_score, 1),
      confidence: confidence_label(abs(home_score - away_score))
    }
  end

  defp side_score(match_context, side) do
    lineup = get_in(match_context, [:expected_lineups, side]) || []
    absences = get_in(match_context, [:missing_players, side]) || []
    form = get_in(match_context, [:recent_team_form, side]) || []
    team_stats = get_in(match_context, [:team_stats, side]) || %{}

    lineup_score(lineup) + form_score(form) + team_stats_score(team_stats) - absence_penalty(absences)
  end

  defp lineup_score(players) do
    Enum.reduce(players, 0.0, fn player, acc ->
      stats = Map.get(player, :recent_stats, %{})
      position_weight = Map.get(@position_weights, Map.get(player, :position), 1.0)

      base =
        Map.get(stats, :rating, 6.5) * 8.0 +
          Map.get(stats, :goals, 0) * 4.5 +
          Map.get(stats, :assists, 0) * 3.0 +
          Map.get(stats, :key_passes, 0) * 0.9 +
          Map.get(stats, :tackles, 0) * 0.6 +
          Map.get(stats, :interceptions, 0) * 0.5 +
          Map.get(stats, :clean_sheets, 0) * 1.5 +
          Map.get(stats, :saves, 0) * 0.25 +
          recent_minutes_score(Map.get(stats, :minutes, 0))

      acc + base * position_weight
    end)
  end

  defp recent_minutes_score(minutes), do: min(minutes / 90.0, 5.0) * 1.2

  defp form_score(results) do
    Enum.reduce(results, 0.0, fn
      "W", acc -> acc + 3.0
      "D", acc -> acc + 1.0
      "L", acc -> acc - 0.5
      _, acc -> acc
    end)
  end

  defp team_stats_score(stats) do
    Map.get(stats, :goals_scored_recent, 0) * 1.4 -
      Map.get(stats, :goals_conceded_recent, 0) * 0.9 +
      Map.get(stats, :clean_sheets_recent, 0) * 1.5
  end

  defp absence_penalty(absences) do
    Enum.reduce(absences, 0.0, fn absence, acc ->
      acc + Map.get(absence, :impact, 1) * 4.5
    end)
  end

  defp build_reasoning(match_context, winner_pick, loser_pick, winner_side, loser_side, winner_score, loser_score) do
    winner_star = side_star(match_context, winner_side)
    loser_star = side_star(match_context, loser_side)
    winner_absences = missing_names(match_context, winner_side)
    loser_absences = missing_names(match_context, loser_side)
    margin = Float.round(winner_score - loser_score, 1)

    availability_sentence =
      case {winner_absences, loser_absences} do
        {[], []} ->
          "#{winner_pick} projects better because the expected lineup has more in-form individual production."

        {_, []} ->
          "#{winner_pick} still stays ahead even with #{Enum.join(winner_absences, ", ")} missing or limited."

        {[], _} ->
          "#{loser_pick} is slightly hurt by the likely absence of #{Enum.join(loser_absences, ", ")}."

        {_, _} ->
          "Both teams have availability issues, but #{loser_pick} loses more projected impact through #{Enum.join(loser_absences, ", ")}."
      end

    "#{winner_pick} gets the local edge by #{margin} points. The projected lineup is led by #{winner_star}, while #{loser_pick} relies most on #{loser_star}. #{availability_sentence}"
  end

  defp side_star(match_context, side) do
    match_context
    |> get_in([:expected_lineups, side])
    |> List.wrap()
    |> Enum.max_by(fn player -> Map.get(player.recent_stats, :rating, 0.0) end, fn -> %{name: "their key player"} end)
    |> Map.get(:name)
  end

  defp missing_names(match_context, side) do
    match_context
    |> get_in([:missing_players, side])
    |> List.wrap()
    |> Enum.map(& &1.name)
  end

  defp confidence_label(margin) when margin >= 18.0, do: "high"
  defp confidence_label(margin) when margin >= 8.0, do: "medium"
  defp confidence_label(_margin), do: "low"
end
