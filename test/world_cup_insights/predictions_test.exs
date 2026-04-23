defmodule WorldCupInsights.PredictionsTest do
  use ExUnit.Case, async: true

  alias WorldCupInsights.Fixtures
  alias WorldCupInsights.Predictions

  test "build_prompt embeds the normalized match payload" do
    match = Fixtures.sample_match()
    prompt = Predictions.build_prompt(match)

    assert prompt =~ "football match prediction"
    assert prompt =~ "\"id\":\"#{match.id}\""
    assert prompt =~ "\"name\":\"Argentina\""
    assert prompt =~ "\"name\":\"France\""
  end

  test "fallback prediction chooses the home team when home form is stronger" do
    match = Fixtures.sample_match()
    result = Predictions.predict_match(match)

    assert result.match_id == match.id
    assert result.winner_pick == "Argentina"
    assert result.source in [:openai, :fallback]
    assert is_binary(result.reasoning)
    assert is_binary(result.generated_at)
  end

  test "predict_match accepts a match id and loads fixture data" do
    result = Predictions.predict_match("match_arg_fra")

    assert result.match_id == "match_arg_fra"
    assert result.winner_pick in ["Argentina", "France"]
  end
end
