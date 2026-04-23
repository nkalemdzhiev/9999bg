defmodule WcInsightsWeb.HomeLive do
  use WcInsightsWeb, :live_view

  alias WcInsights.{FootballData, Predictions}
  alias WcInsightsWeb.Navigation

  @impl true
  def mount(_params, _session, socket) do
    matches = safe_call(&FootballData.list_matches/0, [])

    predictions = load_predictions(matches)

    socket =
      socket
      |> assign(:page_title, "World Cup 2026 Matches")
      |> assign(:matches, normalize_list(matches))
      |> assign(:groups, group_matches(matches))
      |> assign(:predictions, predictions)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Navigation.main />

    <main class="mx-auto max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
      <section class="mb-8">
        <p class="text-sm font-semibold uppercase text-emerald-700">World Cup 2026</p>
        <h1 class="mt-2 text-3xl font-bold text-slate-950 sm:text-4xl">Match Center</h1>
        <p class="mt-3 max-w-2xl text-slate-600">
          Live, upcoming, and recent fixtures with team pages and AI match predictions.
        </p>
      </section>

      <div :if={Enum.empty?(@matches)} class="rounded-lg border border-dashed border-slate-300 p-8 text-center">
        <h2 class="text-lg font-semibold text-slate-900">No fixtures available yet</h2>
        <p class="mt-2 text-sm text-slate-600">Check back after the football data provider is connected.</p>
      </div>

      <div :if={!Enum.empty?(@matches)} class="space-y-8">
        <.match_group title="Live" matches={@groups.live} predictions={@predictions} empty="No live matches right now" />
        <.match_group title="Upcoming" matches={@groups.upcoming} predictions={@predictions} empty="No upcoming fixtures found" />
        <.match_group title="Recent" matches={@groups.recent} predictions={@predictions} empty="No recent matches found" />
      </div>
    </main>
    """
  end

  defp match_group(assigns) do
    assigns = assign_new(assigns, :predictions, fn -> %{} end)

    ~H"""
    <section>
      <div class="mb-3 flex items-center justify-between">
        <h2 class="text-xl font-semibold text-slate-950"><%= @title %></h2>
        <span class="text-sm text-slate-500"><%= length(@matches) %></span>
      </div>

      <div :if={Enum.empty?(@matches)} class="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
        <%= @empty %>
      </div>

      <div :if={!Enum.empty?(@matches)} class="grid gap-4 md:grid-cols-2">
        <article :for={match <- @matches} class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <div class="mb-4 flex items-center justify-between gap-3">
            <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase text-slate-600">
              <%= value(match, :status_long, "Scheduled") %>
            </span>
            <time class="text-sm text-slate-500"><%= format_datetime(value(match, :kickoff_at)) %></time>
          </div>

          <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-3">
            <.team_link team_id={value(match, :home_team_id)} team_name={value(match, :home_team_name)} />
            <div class="text-center text-lg font-bold text-slate-950"><%= scoreline(match) %></div>
            <.team_link team_id={value(match, :away_team_id)} team_name={value(match, :away_team_name)} align="right" />
          </div>

          <div :if={prediction = @predictions[match.id]} class="mt-3 flex items-center gap-2">
            <span class="rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-semibold text-emerald-700">
              AI: <%= prediction.winner_pick %>
            </span>
            <span class="text-xs text-slate-400">
              <%= Float.round(prediction.confidence * 100, 0) %>%
            </span>
          </div>

          <.link navigate={~p"/matches/#{value(match, :id)}"} class="mt-4 inline-flex text-sm font-semibold text-emerald-700 hover:text-emerald-900">
            Match details →
          </.link>
        </article>
      </div>
    </section>
    """
  end

  defp team_link(assigns) do
    assigns = assign_new(assigns, :align, fn -> "left" end)

    ~H"""
    <div class={if @align == "right", do: "text-right", else: "text-left"}>
      <.link :if={@team_id} navigate={~p"/teams/#{@team_id}"} class="font-semibold text-slate-950 hover:text-emerald-700">
        <%= @team_name %>
      </.link>
      <span :if={!@team_id} class="font-semibold text-slate-950"><%= @team_name %></span>
    </div>
    """
  end

  defp group_matches(matches) do
    matches = normalize_list(matches)

    %{
      live: FootballData.live_matches(matches),
      upcoming: FootballData.upcoming_matches(matches),
      recent: FootballData.recent_matches(matches)
    }
  end

  defp load_predictions(matches) do
    matches
    |> normalize_list()
    |> Enum.reduce(%{}, fn match, acc ->
      pred = safe_call(fn -> Predictions.predict_match(match) end, nil)
      if pred, do: Map.put(acc, match.id, pred), else: acc
    end)
  end

  defp scoreline(match) do
    home = value(match, :score_home, nil)
    away = value(match, :score_away, nil)

    if is_nil(home) and is_nil(away), do: "vs", else: "#{home || 0}-#{away || 0}"
  end

  defp format_datetime(nil), do: "TBD"
  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  end
  defp format_datetime(other), do: to_string(other)

  defp normalize_list(value) when is_list(value), do: value
  defp normalize_list(_value), do: []

  defp safe_call(fun, fallback) do
    fun.()
  rescue
    _ -> fallback
  catch
    _, _ -> fallback
  end

  defp value(value, key, fallback \\ nil)
  defp value(nil, _key, fallback), do: fallback
  defp value(map, key, fallback) when is_map(map) do
    case Map.get(map, key) do
      nil -> Map.get(map, to_string(key)) || fallback
      val -> val
    end
  end
  defp value(_value, _key, fallback), do: fallback
end
