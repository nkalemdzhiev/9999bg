defmodule WcInsightsWeb.MatchLive.Show do
  use WcInsightsWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    match = WcInsights.FootballData.get_match!(String.to_integer(id))
    {:ok, assign(socket, match: match)}
  end
end
