defmodule WcInsightsWeb.PageController do
  use WcInsightsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
