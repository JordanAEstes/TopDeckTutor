defmodule TopDeckTutor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TopDeckTutorWeb.Telemetry,
      TopDeckTutor.Repo,
      {DNSCluster, query: Application.get_env(:top_deck_tutor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TopDeckTutor.PubSub},
      # Start a worker by calling: TopDeckTutor.Worker.start_link(arg)
      # {TopDeckTutor.Worker, arg},
      # Start to serve requests, typically the last entry
      TopDeckTutorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TopDeckTutor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TopDeckTutorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
