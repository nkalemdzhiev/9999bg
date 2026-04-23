defmodule Nine999BgWeb.MatchLive.Show do
  use Nine999BgWeb, :live_view

  alias Nine999Bg.{FootballData, Predictions}
  alias Nine999BgWeb.Navigation

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    match = safe_call(fn -> FootballData.get_match!(id) end, nil)
    prediction = if match, do: safe_call(fn -> Predictions.predict_match(match) end, nil), else: nil

    socket =
      socket
      |> assign(:page_title, "Match details")
      |> assign(:match_id, id)
      |> assign(:match, match)
      |> assign(:prediction, prediction)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Navigation.main />

    <main class="mx-auto max-w-5xl px-4 py-8 sm:px-6 lg:px-8">
      <.link navigate={~p"/"} class="mb-6 inline-flex text-sm font-semibold text-emerald-700 hover:text-emerald-900">
        Back to matches
      </.link>

      <div :if={!@match} class="rounded-lg border border-dashed border-slate-300 p-8 text-center">
        <h1 class="text-xl font-semibold text-slate-950">Match not available</h1>
        <p class="mt-2 text-sm text-slate-600">The match could not be loaded yet.</p>
      </div>

      <section :if={@match} class="space-y-6">
        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <div class="mb-6 flex flex-wrap items-center justify-between gap-3">
            <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase text-slate-600">
              <%= value(@match, :status, "Scheduled") %>
            </span>
            <time class="text-sm text-slate-500"><%= value(@match, :kickoff_at, "TBD") %></time>
          </div>

          <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-4">
            <.team_block team={value(@match, :home_team)} />
            <div class="text-center text-3xl font-black text-slate-950"><%= scoreline(@match) %></div>
            <.team_block team={value(@match, :away_team)} align="right" />
          </div>
        </div>

        <section class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-xl font-semibold text-slate-950">AI prediction</h2>

          <div :if={!@prediction} class="mt-4 rounded-lg bg-slate-50 p-4 text-sm text-slate-600">
            Prediction is not available yet.
          </div>

          <div :if={@prediction} class="mt-4 space-y-3">
            <div>
              <p class="text-sm font-medium text-slate-500">Winner pick</p>
              <p class="text-2xl font-bold text-emerald-700"><%= value(@prediction, :winner_pick, "Unavailable") %></p>
            </div>

            <div>
              <p class="text-sm font-medium text-slate-500">Reasoning</p>
              <p class="mt-1 text-slate-700"><%= value(@prediction, :reasoning, "No reasoning returned.") %></p>
            </div>

            <p class="text-xs text-slate-500">Generated: <%= value(@prediction, :generated_at, "unknown") %></p>
          </div>
        </section>
      </section>
    </main>
    """
  end

  defp team_block(assigns) do
    assigns = assign_new(assigns, :align, fn -> "left" end)

    ~H"""
    <div class={if @align == "right", do: "text-right", else: "text-left"}>
      <.link :if={team_id(@team)} navigate={~p"/teams/#{team_id(@team)}"} class="text-xl font-bold text-slate-950 hover:text-emerald-700">
        <%= team_name(@team) %>
      </.link>
      <span :if={!team_id(@team)} class="text-xl font-bold text-slate-950"><%= team_name(@team) %></span>
    </div>
    """
  end

  defp scoreline(match) do
    home = value(match, :home_score, nil) || value(match, :score_home, nil)
    away = value(match, :away_score, nil) || value(match, :score_away, nil)

    if is_nil(home) and is_nil(away), do: "vs", else: "#{home || 0}-#{away || 0}"
  end

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
