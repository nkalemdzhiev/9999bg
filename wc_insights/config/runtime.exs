import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/wc_insights start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :wc_insights, WcInsightsWeb.Endpoint, server: true
end

config :wc_insights, WcInsightsWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

config :wc_insights,
  thesportsdb_api_key: System.get_env("THESPORTSDB_API_KEY") || "3",
  gemini_api_key: System.get_env("GEMINI_API_KEY"),
  gemini_model: System.get_env("GEMINI_MODEL") || "gemini-2.5-flash"

config :wc_insights, :openai_model, System.get_env("OPENAI_MODEL") || "gpt-4o-mini"

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :wc_insights, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :wc_insights, WcInsightsWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base
end
