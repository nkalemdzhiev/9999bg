defmodule FootballData.Team do
  defstruct [
    :id,
    :name,
    :code,
    :country,
    :founded,
    :national,
    :logo,
    :venue_name,
    :venue_city,
    :venue_capacity
  ]

  @type t :: %__MODULE__{
    id: integer(),
    name: String.t(),
    code: String.t() | nil,
    country: String.t(),
    founded: integer() | nil,
    national: boolean(),
    logo: String.t() | nil,
    venue_name: String.t() | nil,
    venue_city: String.t() | nil,
    venue_capacity: integer() | nil
  }
end
