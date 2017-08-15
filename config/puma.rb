port        ENV.fetch("PORT") { 3500 }
daemonize false
state_path "tmp/pids/puma.state"
pidfile "tmp/pids/puma.pid"
threads 0,16
workers 4
environment ENV.fetch("RAILS_ENV") { "development" }
