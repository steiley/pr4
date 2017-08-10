Rails.application.routes.draw do
  resource :session, only: :create
  resource :random_request_review, only: :create

  post "/ping" => ->(_env) { [200, { "Content-Type" => "text/plain" }, ["pong"]] }
end
