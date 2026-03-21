defmodule OllamaWrapperWeb.Router do
  use OllamaWrapperWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, html: {OllamaWrapperWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OllamaWrapperWeb do
    pipe_through :browser

    live "/dashboard", DashboardLive
  end

  scope "/api", OllamaWrapperWeb do
    pipe_through :api

    post "/chat", ChatController, :create
  end
end
