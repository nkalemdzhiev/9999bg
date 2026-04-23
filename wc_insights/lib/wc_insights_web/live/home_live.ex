defmodule WcInsightsWeb.HomeLive do
  use WcInsightsWeb, :live_view

  def mount(_params, _session, socket) do
    matches = WcInsights.FootballData.list_matches()
    {:ok, assign(socket, matches: matches)}
  end
end
