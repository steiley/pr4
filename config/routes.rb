Rails.application.routes.draw do
  resource :session, only: :create
  resource :assigned_notify, only: :create
  resource :random_assignment, only: :create

  post "/ping" => ->(_env) { [200, { "Content-Type" => "text/plain" }, ["pong"]] }
end
