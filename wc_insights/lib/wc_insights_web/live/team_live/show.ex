defmodule WcInsightsWeb.TeamLive.Show do
  use WcInsightsWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    team = WcInsights.FootballData.get_team!(String.to_integer(id))
    {:ok, assign(socket, team: team)}
  end
end
