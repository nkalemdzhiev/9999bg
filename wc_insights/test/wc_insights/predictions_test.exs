defmodule WcInsights.PredictionsTest do
  use ExUnit.Case, async: true

  alias WcInsights.FootballData
  alias WcInsights.Predictions

  defmodule GeminiClientStub do
    def predict(_payload) do
      {:ok,
       %{
         "winner_pick" => "France",
         "reasoning" => "France gets the edge because the projected attacking unit is stronger and more complete.",
         "confidence" => "medium"
       }}
    end
  end

  defmodule ErrorClientStub do
    def predict(_payload), do: {:error, :missing_api_key}
  end

  setup do
    previous = Application.get_env(:wc_insights, :ai_prediction_client)
    on_exit(fn -> Application.put_env(:wc_insights, :ai_prediction_client, previous) end)
    :ok
  end

  test "predict_match uses lineup-aware context and returns a local result" do
    Application.put_env(:wc_insights, :ai_prediction_client, ErrorClientStub)
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

  test "predict_match uses gemini output when available" do
    Application.put_env(:wc_insights, :ai_prediction_client, GeminiClientStub)
    context = FootballData.get_match_context!(239625)
    result = Predictions.predict_match(context)

    assert result.source == :gemini
    assert result.winner_pick == "France"
    assert result.confidence == "medium"
    assert result.reasoning =~ "France gets the edge"
    assert is_float(result.home_score)
    assert is_float(result.away_score)
  end
end
