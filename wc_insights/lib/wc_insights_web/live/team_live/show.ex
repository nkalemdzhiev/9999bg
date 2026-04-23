defmodule WcInsightsWeb.TeamLive.Show do
  use WcInsightsWeb, :live_view

  alias WcInsights.TeamStatus
  alias WcInsightsWeb.Navigation

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    status = safe_call(fn -> TeamStatus.get_team_status(id) end, nil)

    socket =
      socket
      |> assign(:page_title, "Team Status")
      |> assign(:team_id, id)
      |> assign(:status, status)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Navigation.main />

    <main class="mx-auto max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
      <.link navigate={~p"/"} class="mb-6 inline-flex text-sm font-semibold text-emerald-700 hover:text-emerald-900">
        ← Back to matches
      </.link>

      <div :if={!@status} class="rounded-lg border border-dashed border-slate-300 p-8 text-center">
        <h1 class="text-xl font-semibold text-slate-950">Team not available</h1>
        <p class="mt-2 text-sm text-slate-600">The team status could not be loaded.</p>
      </div>

      <section :if={@status} class="space-y-8">
        <header>
          <p class="text-sm font-semibold uppercase text-emerald-700">Team Status</p>
          <h1 class="mt-2 text-3xl font-bold text-slate-950 sm:text-4xl">
            <%= team_name(value(@status, :team)) %>
          </h1>
        </header>

        <section>
          <h2 class="mb-3 text-xl font-semibold text-slate-950">Squad</h2>
          <div :if={Enum.empty?(players(@status))} class="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
            No squad data available.
          </div>
          <div :if={!Enum.empty?(players(@status))} class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <article :for={player <- players(@status)} class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <h3 class="font-semibold text-slate-950"><%= value(player, :name, "Unknown player") %></h3>
              <p class="mt-1 text-sm text-slate-600">
                <%= value(player, :position, "Position unavailable") %>
                <%= if value(player, :number), do: " · ##{value(player, :number)}", else: "" %>
              </p>
            </article>
          </div>
        </section>

        <section>
          <h2 class="mb-3 text-xl font-semibold text-slate-950">Recent Matches</h2>
          <div :if={Enum.empty?(recent_matches(@status))} class="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
            No recent matches available.
          </div>
          <div :if={!Enum.empty?(recent_matches(@status))} class="space-y-3">
            <article :for={match <- recent_matches(@status)} class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <p class="font-semibold text-slate-950"><%= fixture_name(match) %></p>
                <span class="text-sm text-slate-500"><%= format_datetime(value(match, :kickoff_at)) %></span>
              </div>
              <p class="mt-1 text-sm text-slate-600"><%= value(match, :status_long, "Finished") %></p>
            </article>
          </div>
        </section>

        <section>
          <h2 class="mb-3 text-xl font-semibold text-slate-950">Honors</h2>
          <div :if={Enum.empty?(honors(@status))} class="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
            No honors available.
          </div>
          <ul :if={!Enum.empty?(honors(@status))} class="grid gap-3 sm:grid-cols-2">
            <li :for={honor <- honors(@status)} class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
              <span class="font-semibold text-slate-950"><%= honor %></span>
            </li>
          </ul>
        </section>
      </section>
    </main>
    """
  end

  defp fixture_name(match) do
    home = value(match, :home_team_name, "TBD")
    away = value(match, :away_team_name, "TBD")
    "#{home} vs #{away}"
  end

  defp players(status), do: status |> value(:players, []) |> normalize_list()
  defp recent_matches(status), do: status |> value(:recent_matches, []) |> normalize_list()
  defp honors(status), do: status |> value(:honors, []) |> normalize_list()

  defp normalize_list(value) when is_list(value), do: value
  defp normalize_list(_value), do: []

  defp safe_call(fun, fallback) do
    fun.()
  rescue
    _ -> fallback
  catch
    _, _ -> fallback
  end

  defp team_name(nil), do: "TBD"
  defp team_name(team) when is_binary(team), do: team
  defp team_name(team), do: value(team, :name, "TBD")

  defp format_datetime(nil), do: "TBD"
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  defp format_datetime(other), do: to_string(other)

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
