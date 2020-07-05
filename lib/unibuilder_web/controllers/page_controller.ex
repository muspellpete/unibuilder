defmodule UnibuilderWeb.PageController do
  use UnibuilderWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
