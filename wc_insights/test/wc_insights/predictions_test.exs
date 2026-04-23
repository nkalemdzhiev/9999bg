defmodule WcInsights.PredictionsTest do
  use ExUnit.Case, async: true

  alias WcInsights.FootballData
  alias WcInsights.Predictions

  test "predict_match uses lineup-aware context and returns a local result" do
    context = FootballData.get_match_context!(239625)
    result = Predictions.predict_match(context)

    assert result.source == :local_lineup_model
    assert result.winner_pick == "Argentina"
    assert result.home_score < result.away_score
    assert result.reasoning =~ "lineup"
    assert result.confidence in ["low", "medium", "high"]
  end

  test "match context includes expected lineups and missing players" do
    context = FootballData.get_match_context!(239626)

    assert length(context.expected_lineups.home) >= 5
    assert length(context.expected_lineups.away) >= 5
    assert is_list(context.missing_players.home)
    assert is_list(context.missing_players.away)
    assert is_map(context.team_stats.home)
    assert is_map(context.team_stats.away)
  end
end
