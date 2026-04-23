defmodule WcInsightsWeb.MatchLive.Show do
  use WcInsightsWeb, :live_view

  alias WcInsights.{FootballData, Predictions}
  alias WcInsightsWeb.Navigation

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    match_context = safe_call(fn -> FootballData.get_match_context!(id) end, nil)
    match = if match_context, do: match_context.match, else: nil

    prediction =
      if match_context do
        safe_call(
          fn ->
            case Predictions.predict_match(match_context) do
              {:ok, result} -> result
              {:error, _reason} -> nil
            end
          end,
          nil
        )
      else
        nil
      end

    socket =
      socket
      |> assign(:page_title, "Match Details")
      |> assign(:match_id, id)
      |> assign(:match_context, match_context)
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
        ← Back to matches
      </.link>

      <div :if={!@match} class="rounded-lg border border-dashed border-slate-300 p-8 text-center">
        <h1 class="text-xl font-semibold text-slate-950">Match not available</h1>
        <p class="mt-2 text-sm text-slate-600">The match could not be loaded.</p>
      </div>

      <section :if={@match} class="space-y-6">
        <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <div class="mb-6 flex flex-wrap items-center justify-between gap-3">
            <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase text-slate-600">
              <%= value(@match, :status_long, "Scheduled") %>
            </span>
            <time class="text-sm text-slate-500"><%= format_datetime(value(@match, :kickoff_at)) %></time>
          </div>

          <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-4">
            <.team_block team_id={value(@match, :home_team_id)} team_name={value(@match, :home_team_name)} />
            <div class="text-center text-3xl font-black text-slate-950"><%= scoreline(@match) %></div>
            <.team_block team_id={value(@match, :away_team_id)} team_name={value(@match, :away_team_name)} align="right" />
          </div>

          <p :if={@match_context} class="mt-4 text-sm text-slate-500">
            Model note: <%= value(@match_context, :context_label, "Projected from fresh lineup context.") %>
          </p>
        </div>

        <section class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-xl font-semibold text-slate-950">AI Prediction</h2>

          <div :if={!@prediction} class="mt-4 rounded-lg bg-slate-50 p-4 text-sm text-slate-600">
            Prediction is not available. Set GEMINI_API_KEY to enable AI predictions.
          </div>

          <div :if={@prediction} class="mt-4 space-y-3">
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div>
                <p class="text-sm font-medium text-slate-500">Winner Pick</p>
                <p class="text-2xl font-bold text-emerald-700"><%= value(@prediction, :winner_pick, "Unavailable") %></p>
              </div>

              <div class="text-right">
                <p class="text-sm font-medium text-slate-500">Confidence</p>
                <p class="font-semibold text-slate-700"><%= value(@prediction, :confidence, "unknown") %></p>
              </div>
            </div>

            <div>
              <p class="text-sm font-medium text-slate-500">Reasoning</p>
              <p class="mt-1 text-slate-700"><%= value(@prediction, :reasoning, "No reasoning returned.") %></p>
            </div>

            <p class="text-xs text-slate-500">Generated: <%= value(@prediction, :generated_at, "unknown") %></p>
            <p class="text-xs text-slate-400">Source: <%= value(@prediction, :source, "unknown") %></p>
          </div>
        </section>

        <section :if={@match_context} class="grid gap-6 lg:grid-cols-2">
          <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
            <h2 class="text-lg font-semibold text-slate-950"><%= value(@match, :home_team_name) %> expected key players</h2>
            <ul class="mt-4 space-y-2 text-sm text-slate-700">
              <li :for={player <- Enum.take(value(@match_context, :expected_lineups, %{})[:home] || [], 5)}>
                <span class="font-medium"><%= player.name %></span>
                <span class="text-slate-500">(<%= player.position %>) rating <%= player.recent_stats.rating %></span>
              </li>
            </ul>
          </div>

          <div class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
            <h2 class="text-lg font-semibold text-slate-950"><%= value(@match, :away_team_name) %> expected key players</h2>
            <ul class="mt-4 space-y-2 text-sm text-slate-700">
              <li :for={player <- Enum.take(value(@match_context, :expected_lineups, %{})[:away] || [], 5)}>
                <span class="font-medium"><%= player.name %></span>
                <span class="text-slate-500">(<%= player.position %>) rating <%= player.recent_stats.rating %></span>
              </li>
            </ul>
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
      <.link :if={@team_id} navigate={~p"/teams/#{@team_id}"} class="text-xl font-bold text-slate-950 hover:text-emerald-700">
        <%= @team_name %>
      </.link>
      <span :if={!@team_id} class="text-xl font-bold text-slate-950"><%= @team_name %></span>
    </div>
    """
  end

  defp scoreline(match) do
    home = value(match, :score_home, nil)
    away = value(match, :score_away, nil)

    if is_nil(home) and is_nil(away), do: "vs", else: "#{home || 0}-#{away || 0}"
  end

  defp format_datetime(nil), do: "TBD"
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  defp format_datetime(other), do: to_string(other)

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
