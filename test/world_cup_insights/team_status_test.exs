defmodule WorldCupInsights.TeamStatusTest do
  use ExUnit.Case, async: true

  alias WorldCupInsights.TeamStatus

  test "team status returns team, players, matches, and honors" do
    result = TeamStatus.get_team_status("arg")

    assert result.team.name == "Argentina"
    assert length(result.players) > 0
    assert length(result.recent_matches) > 0
    assert "FIFA World Cup: 1978, 1986, 2022" in result.honors
  end

  test "unknown team falls back to empty honors and players" do
    result = TeamStatus.get_team_status("unknown")

    assert result.team.id == "unknown"
    assert result.players == []
    assert result.recent_matches == []
    assert result.honors == []
  end
end
