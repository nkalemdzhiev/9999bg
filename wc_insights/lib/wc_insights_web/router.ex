defmodule WcInsightsWeb.Router do
  use WcInsightsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WcInsightsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WcInsightsWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/matches/:id", MatchLive.Show, :show
    live "/teams/:id", TeamLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", WcInsightsWeb do
  #   pipe_through :api
  # end
end
