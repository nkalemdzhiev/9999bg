defmodule WcInsights.PredictionsTest do
  use ExUnit.Case, async: true

  alias WcInsights.FootballData
  alias WcInsights.Predictions

  @sample_match_id 2_461_105
  @sample_match_id_with_context 2_391_728

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

  test "match context includes expected lineups and missing players" do
    context = FootballData.get_match_context!(@sample_match_id_with_context)

    assert length(context.expected_lineups.home) >= 4
    assert length(context.expected_lineups.away) >= 4
    assert is_list(context.missing_players.home)
    assert is_list(context.missing_players.away)
    assert is_map(context.team_stats.home)
    assert is_map(context.team_stats.away)
  end

  test "predict_match returns gemini output when available" do
    Application.put_env(:wc_insights, :ai_prediction_client, GeminiClientStub)
    context = FootballData.get_match_context!(@sample_match_id)

    assert {:ok, result} = Predictions.predict_match(context)
    assert result.source == :gemini
    assert result.winner_pick == "France"
    assert result.confidence == "medium"
    assert result.reasoning =~ "France gets the edge"
    assert is_binary(result.generated_at)
  end

  test "predict_match returns an error when gemini is unavailable" do
    Application.put_env(:wc_insights, :ai_prediction_client, ErrorClientStub)
    context = FootballData.get_match_context!(@sample_match_id)

    assert {:error, :missing_api_key} = Predictions.predict_match(context)
  end
end