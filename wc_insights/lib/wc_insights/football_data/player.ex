defmodule FootballData.Player do
  defstruct [
    :id,
    :name,
    :age,
    :number,
    :position,
    :photo
  ]

  @type t :: %__MODULE__{
    id: integer(),
    name: String.t(),
    age: integer() | nil,
    number: integer() | nil,
    position: String.t() | nil,
    photo: String.t() | nil
  }
end
