defmodule Nine999BgWeb.Navigation do
  use Nine999BgWeb, :html

  def main(assigns) do
    ~H"""
    <header class="border-b border-slate-200 bg-white">
      <div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
        <.link navigate={~p"/"} class="text-lg font-bold text-slate-950">
          9999bg
        </.link>

        <nav class="flex items-center gap-4 text-sm font-medium text-slate-600">
          <.link navigate={~p"/"} class="hover:text-slate-950">Matches</.link>
        </nav>
      </div>
    </header>
    """
  end
end
