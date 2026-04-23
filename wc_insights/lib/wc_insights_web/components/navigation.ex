defmodule WcInsightsWeb.Navigation do
  use WcInsightsWeb, :html

  def main(assigns) do
    ~H"""
    <header class="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-3 sm:px-6 lg:px-8">
        <.link navigate={~p"/"} class="flex items-center gap-3 text-slate-950">
          <span class="grid h-11 w-11 place-items-center rounded-lg bg-slate-950 text-sm font-black text-white shadow-sm">
            9999
          </span>
          <span>
            <span class="block text-base font-black leading-5">9999.bg</span>
            <span class="block text-xs font-semibold text-slate-500">World Cup insights</span>
          </span>
        </.link>

        <nav class="flex items-center gap-2 text-sm font-semibold text-slate-600">
          <.link navigate={~p"/"} class="rounded-lg px-3 py-2 hover:bg-slate-100 hover:text-slate-950">Matches</.link>
        </nav>
      </div>
    </header>
    """
  end
end
