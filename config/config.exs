# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :unibuilder,
  ecto_repos: [Unibuilder.Repo]

# Configures the endpoint
config :unibuilder, UnibuilderWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "X0i1UwqTl+yXwgtPnP0JSz2fv/YtGupM746wPwoT8MYXNHReZoKKqleAqu6OU4As",
  render_errors: [view: UnibuilderWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Unibuilder.PubSub,
  live_view: [signing_salt: "883//p1g"],
  http: [port: 4000, protocol_options: [idle_timeout: 5_000_000]]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
