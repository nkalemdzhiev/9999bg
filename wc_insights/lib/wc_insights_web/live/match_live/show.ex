defmodule WcInsightsWeb.MatchLive.Show do
  use WcInsightsWeb, :live_view

  alias WcInsights.{FootballData, Predictions, OddsComparison}
  alias WcInsightsWeb.Navigation

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    match = safe_call(fn -> FootballData.get_match!(id) end, nil)
    prediction = if match, do: safe_call(fn -> Predictions.predict_match(match) end, nil), else: nil
    odds_comparison = if match && prediction, do: safe_call(fn -> OddsComparison.compare(match, prediction) end, nil), else: nil

    socket =
      socket
      |> assign(:page_title, "Match Details")
      |> assign(:match_id, id)
      |> assign(:match, match)
      |> assign(:prediction, prediction)
      |> assign(:odds_comparison, odds_comparison)

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
        <%!-- Scoreboard --%>
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
        </div>

        <%!-- AI Prediction --%>
        <section class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-xl font-semibold text-slate-950">AI Prediction</h2>

          <div :if={!@prediction} class="mt-4 rounded-lg bg-slate-50 p-4 text-sm text-slate-600">
            Prediction is not available. Set OPENAI_API_KEY to enable AI predictions.
          </div>

          <div :if={@prediction} class="mt-4 space-y-3">
            <div>
              <p class="text-sm font-medium text-slate-500">Winner Pick</p>
              <p class="text-2xl font-bold text-emerald-700"><%= value(@prediction, :winner_pick, "Unavailable") %></p>
            </div>

            <div>
              <p class="text-sm font-medium text-slate-500">Confidence</p>
              <p class="text-lg font-semibold text-slate-800"><%= format_percent(value(@prediction, :confidence, 0.50)) %></p>
            </div>

            <div>
              <p class="text-sm font-medium text-slate-500">Reasoning</p>
              <p class="mt-1 text-slate-700"><%= value(@prediction, :reasoning, "No reasoning returned.") %></p>
            </div>

            <p class="text-xs text-slate-500">Generated: <%= value(@prediction, :generated_at, "unknown") %></p>
            <p class="text-xs text-slate-400">Source: <%= value(@prediction, :source, "unknown") %></p>
          </div>
        </section>

        <%!-- Odds Comparison --%>
        <section :if={@odds_comparison} class="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
            <h2 class="text-xl font-semibold text-slate-950">Odds Comparison</h2>
            <span class={"rounded-full border px-3 py-1 text-xs font-bold uppercase #{OddsComparison.recommendation_color(@odds_comparison.recommendation)}"}>
              <%= OddsComparison.recommendation_label(@odds_comparison.recommendation) %>
            </span>
          </div>

          <%!-- Bookmaker odds row --%>
          <div class="mb-6 grid grid-cols-3 gap-4 text-center">
            <div>
              <p class="text-xs font-medium uppercase text-slate-500"><%= value(@match, :home_team_name, "Home") %> Odds</p>
              <p class="text-xl font-bold text-slate-900"><%= format_decimal(@odds_comparison.odds.home_odds) %></p>
            </div>
            <div>
              <p class="text-xs font-medium uppercase text-slate-500">Draw Odds</p>
              <p class="text-xl font-bold text-slate-900"><%= format_decimal(@odds_comparison.odds.draw_odds) %></p>
            </div>
            <div>
              <p class="text-xs font-medium uppercase text-slate-500"><%= value(@match, :away_team_name, "Away") %> Odds</p>
              <p class="text-xl font-bold text-slate-900"><%= format_decimal(@odds_comparison.odds.away_odds) %></p>
            </div>
          </div>

          <%!-- Implied probability bars --%>
          <div class="mb-6 space-y-3">
            <.probability_bar
              label={value(@match, :home_team_name, "Home")}
              value={@odds_comparison.implied.home}
              highlight={@odds_comparison.ai_pick == "home"}
            />
            <.probability_bar label="Draw" value={@odds_comparison.implied.draw} highlight={@odds_comparison.ai_pick == "draw"} />
            <.probability_bar
              label={value(@match, :away_team_name, "Away")}
              value={@odds_comparison.implied.away}
              highlight={@odds_comparison.ai_pick == "away"}
            />
          </div>

          <%!-- AI vs Bookie comparison --%>
          <div class="rounded-lg bg-slate-50 p-4">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p class="text-sm font-medium text-slate-500">AI Confidence</p>
                <p class="text-lg font-semibold text-slate-800"><%= format_percent(@odds_comparison.ai_confidence) %></p>
              </div>
              <div class="text-center">
                <p class="text-xs font-medium uppercase text-slate-400">vs</p>
              </div>
              <div class="text-right">
                <p class="text-sm font-medium text-slate-500">Bookie Implied</p>
                <p class="text-lg font-semibold text-slate-800"><%= format_percent(@odds_comparison.bookie_confidence) %></p>
              </div>
            </div>

            <div class="mt-3 border-t border-slate-200 pt-3 text-center">
              <p class="text-sm font-medium text-slate-500">Edge</p>
              <p class={"text-2xl font-black #{edge_color(@odds_comparison.edge)}"}>
                <%= OddsComparison.format_edge(@odds_comparison.edge) %>
              </p>
            </div>
          </div>

          <p class="mt-3 text-xs text-slate-400">
            Odds source:
            <%= source_label(@odds_comparison.odds.source) %>
          </p>
        </section>
      </section>
    </main>
    """
  end

  # ------------------------------------------------------------------
  # Components
  # ------------------------------------------------------------------

  defp probability_bar(assigns) do
    pct = Float.round(assigns.value * 100, 1)
    width = min(pct, 100)

    bar_color =
      if assigns.highlight do
        "bg-emerald-500"
      else
        "bg-slate-300"
      end

    assigns =
      assigns
      |> assign(:pct, pct)
      |> assign(:width, width)
      |> assign(:bar_color, bar_color)

    ~H"""
    <div>
      <div class="mb-1 flex justify-between text-sm">
        <span class={if @highlight, do: "font-bold text-emerald-700", else: "text-slate-600"}>
          <%= @label %>
        </span>
        <span class="font-medium text-slate-700"><%= @pct %>%</span>
      </div>
      <div class="h-3 w-full rounded-full bg-slate-100">
        <div class={"h-3 rounded-full #{@bar_color}"} style={"width: #{@width}%"}></div>
      </div>
    </div>
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

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp scoreline(match) do
    home = value(match, :score_home, nil)
    away = value(match, :score_away, nil)

    if is_nil(home) and is_nil(away), do: "vs", else: "#{home || 0}-#{away || 0}"
  end

  defp format_datetime(nil), do: "TBD"
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  defp format_datetime(other), do: to_string(other)

  defp format_percent(val) when is_number(val), do: "#{Float.round(val * 100, 1)}%"
  defp format_percent(_), do: "N/A"

  defp format_decimal(nil), do: "—"
  defp format_decimal(val) when is_integer(val), do: "#{val}.00"
  defp format_decimal(val) when is_float(val), do: :erlang.float_to_binary(val, decimals: 2)
  defp format_decimal(val), do: to_string(val)

  defp edge_color(edge) when edge > 0.05, do: "text-emerald-600"
  defp edge_color(edge) when edge < -0.05, do: "text-rose-600"
  defp edge_color(_), do: "text-amber-600"

  defp source_label(:live), do: "Live via SharpAPI"
  defp source_label(:demo), do: "Demo odds"
  defp source_label(:fallback), do: "Auto-generated fallback"
  defp source_label(_), do: "Unknown"

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
