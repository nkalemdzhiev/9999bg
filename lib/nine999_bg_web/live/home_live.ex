defmodule Nine999BgWeb.HomeLive do
  use Nine999BgWeb, :live_view

  alias Nine999Bg.FootballData
  alias Nine999BgWeb.Navigation

  @impl true
  def mount(_params, _session, socket) do
    matches = safe_call(&FootballData.list_matches/0, [])

    socket =
      socket
      |> assign(:page_title, "World Cup matches")
      |> assign(:matches, normalize_list(matches))
      |> assign(:groups, group_matches(matches))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Navigation.main />

    <main class="mx-auto max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
      <section class="mb-8">
        <p class="text-sm font-semibold uppercase text-emerald-700">World Cup</p>
        <h1 class="mt-2 text-3xl font-bold text-slate-950 sm:text-4xl">Match center</h1>
        <p class="mt-3 max-w-2xl text-slate-600">
          Live, upcoming, and recent fixtures with team pages and AI match predictions.
        </p>
      </section>

      <div :if={Enum.empty?(@matches)} class="rounded-lg border border-dashed border-slate-300 p-8 text-center">
        <h2 class="text-lg font-semibold text-slate-900">No fixtures available yet</h2>
        <p class="mt-2 text-sm text-slate-600">Check back after the football data provider is connected.</p>
      </div>

      <div :if={!Enum.empty?(@matches)} class="space-y-8">
        <.match_group title="Live" matches={@groups.live} empty="No live matches right now" />
        <.match_group title="Upcoming" matches={@groups.upcoming} empty="No upcoming fixtures found" />
        <.match_group title="Recent" matches={@groups.recent} empty="No recent matches found" />
      </div>
    </main>
    """
  end

  defp match_group(assigns) do
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
              <%= value(match, :status, "Scheduled") %>
            </span>
            <time class="text-sm text-slate-500"><%= value(match, :kickoff_at, "TBD") %></time>
          </div>

          <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-3">
            <.team_link team={value(match, :home_team)} />
            <div class="text-center text-lg font-bold text-slate-950"><%= scoreline(match) %></div>
            <.team_link team={value(match, :away_team)} align="right" />
          </div>

          <.link navigate={~p"/matches/#{value(match, :id)}"} class="mt-5 inline-flex text-sm font-semibold text-emerald-700 hover:text-emerald-900">
            Match details
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
      <.link :if={team_id(@team)} navigate={~p"/teams/#{team_id(@team)}"} class="font-semibold text-slate-950 hover:text-emerald-700">
        <%= team_name(@team) %>
      </.link>
      <span :if={!team_id(@team)} class="font-semibold text-slate-950"><%= team_name(@team) %></span>
    </div>
    """
  end

  defp group_matches(matches) do
    matches = normalize_list(matches)

    %{
      live: Enum.filter(matches, &(status_bucket(&1) == :live)),
      upcoming: Enum.filter(matches, &(status_bucket(&1) == :upcoming)),
      recent: Enum.filter(matches, &(status_bucket(&1) == :recent))
    }
  end

  defp status_bucket(match) do
    status = match |> value(:status, "") |> to_string() |> String.downcase()

    cond do
      status in ["live", "in_play", "in progress", "1h", "2h", "ht"] -> :live
      status in ["finished", "full_time", "ft", "completed"] -> :recent
      true -> :upcoming
    end
  end

  defp scoreline(match) do
    home = value(match, :home_score, nil) || value(match, :score_home, nil)
    away = value(match, :away_score, nil) || value(match, :score_away, nil)

    if is_nil(home) and is_nil(away), do: "vs", else: "#{home || 0}-#{away || 0}"
  end

  defp normalize_list(value) when is_list(value), do: value
  defp normalize_list(_value), do: []

  defp safe_call(fun, fallback) do
    fun.()
  rescue
    _ -> fallback
  catch
    _, _ -> fallback
  end

  defp team_id(nil), do: nil
  defp team_id(team), do: value(team, :id, nil)

  defp team_name(nil), do: "TBD"
  defp team_name(team) when is_binary(team), do: team
  defp team_name(team), do: value(team, :name, "TBD")

  defp value(value, key, fallback \\ nil)
  defp value(nil, _key, fallback), do: fallback
  defp value(map, key, fallback) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key)) || fallback
  defp value(_value, _key, fallback), do: fallback
end
