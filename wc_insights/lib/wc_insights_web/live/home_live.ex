defmodule WcInsightsWeb.HomeLive do
  use WcInsightsWeb, :live_view

  alias WcInsights.{FootballData, PredictionSampleData, Predictions}
  alias WcInsightsWeb.Navigation

  @impl true
  def mount(_params, _session, socket) do
    matches = safe_call(&FootballData.list_matches/0, [])

    socket =
      socket
      |> assign(:page_title, "World Cup 2026 Matches")
      |> assign(:matches, normalize_list(matches))
      |> assign(:groups, group_matches(matches))
      |> assign(:predictions, predictions_by_match(matches))

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

          <.link navigate={~p"/matches/#{value(match, :id)}"} class="mt-5 inline-flex text-sm font-semibold text-emerald-700 hover:text-emerald-900">
            Match details →
          </.link>

          <div :if={prediction = @predictions[value(match, :id)]} class="mt-4 rounded-lg bg-emerald-50 p-3">
            <p class="text-xs font-bold uppercase text-emerald-700">Predicted winner</p>
            <div class="mt-1 flex flex-wrap items-center justify-between gap-2">
              <span class="text-base font-bold text-slate-950"><%= prediction_winner(match, prediction) %></span>
              <span class="rounded-full bg-white px-3 py-1 text-xs font-bold uppercase text-emerald-700 ring-1 ring-emerald-200">
                <%= prediction_confidence(prediction) %> confidence
              </span>
            </div>
          </div>
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

  defp predictions_by_match(matches) do
    matches
    |> normalize_list()
    |> Map.new(fn match ->
      prediction =
        safe_call(fn ->
          match
          |> home_match_context()
          |> local_home_prediction()
        end, nil)

      {value(match, :id), prediction}
    end)
  end

  defp home_match_context(match) do
    overrides =
      PredictionSampleData.match_overrides(
        value(match, :id),
        value(match, :home_team_id),
        value(match, :away_team_id)
      )

    %{
      match: match,
      home_team: %{id: value(match, :home_team_id), name: value(match, :home_team_name, "Home")},
      away_team: %{id: value(match, :away_team_id), name: value(match, :away_team_name, "Away")},
      expected_lineups: overrides.expected_lineups,
      missing_players: overrides.missing_players,
      recent_team_form: overrides.recent_team_form,
      team_stats: overrides.team_stats,
      context_label: overrides.context_label
    }
  end

  defp local_home_prediction(match_context) do
    previous_client = Application.get_env(:wc_insights, :ai_prediction_client)

    try do
      Application.put_env(:wc_insights, :ai_prediction_client, WcInsightsWeb.HomeLive.LocalPredictionClient)
      Predictions.predict_match(match_context)
    after
      if previous_client do
        Application.put_env(:wc_insights, :ai_prediction_client, previous_client)
      else
        Application.delete_env(:wc_insights, :ai_prediction_client)
      end
    end
  end

  defp prediction_winner(match, prediction) do
    case value(prediction, :winner_pick, "Unavailable") do
      "home" -> value(match, :home_team_name, "Home")
      "away" -> value(match, :away_team_name, "Away")
      "draw" -> "Draw"
      other -> other
    end
  end

  defp prediction_confidence(prediction) do
    value(prediction, :confidence, "medium")
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

  defmodule LocalPredictionClient do
    def predict(_request), do: {:error, :skip_external_ai_on_home_page}
  end
end
