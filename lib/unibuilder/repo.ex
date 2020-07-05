defmodule Unibuilder.Repo do
  use Ecto.Repo,
    otp_app: :unibuilder,
    adapter: Ecto.Adapters.Postgres
end
