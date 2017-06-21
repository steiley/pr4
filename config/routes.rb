Rails.application.routes.draw do
  post "/ping" => ->(_env) { [200, { "Content-Type" => "text/plain" }, ["pong"]] }
end
