defmodule AppUi.Router do
  use AppUi.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AppUi do
    pipe_through :api
    post "/calls", CallNotificationController, :notify
  end

  scope "/", AppUi do
    pipe_through :browser # Use the default browser stack
    get "/test",  PageController, :test
    get "/documents/:documentId", CustomerDocumentController, :show
    get "/*path", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppUi do
  #   pipe_through :api
  # end
end
