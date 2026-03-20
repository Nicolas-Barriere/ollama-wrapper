defmodule CoffWeb.Router do
  use CoffWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CoffWeb do
    pipe_through :api

    post "/chat", ChatController, :create
  end
end
