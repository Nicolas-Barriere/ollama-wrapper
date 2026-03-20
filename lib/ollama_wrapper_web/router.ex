defmodule OllamaWrapperWeb.Router do
  use OllamaWrapperWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", OllamaWrapperWeb do
    pipe_through :api

    post "/chat", ChatController, :create
  end
end
