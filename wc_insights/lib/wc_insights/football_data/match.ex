defmodule FootballData.Match do
  defstruct [
    :id,
    :home_team_id,
    :away_team_id,
    :home_team_name,
    :away_team_name,
    :home_team_logo,
    :away_team_logo,
    :kickoff_at,
    :status,
    :status_long,
    :round,
    :venue_name,
    :venue_city,
    :score_home,
    :score_away,
    :score_halftime_home,
    :score_halftime_away
  ]

  @type t :: %__MODULE__{
    id: integer(),
    home_team_id: integer(),
    away_team_id: integer(),
    home_team_name: String.t(),
    away_team_name: String.t(),
    home_team_logo: String.t() | nil,
    away_team_logo: String.t() | nil,
    kickoff_at: DateTime.t() | nil,
    status: String.t(),
    status_long: String.t(),
    round: String.t() | nil,
    venue_name: String.t() | nil,
    venue_city: String.t() | nil,
    score_home: integer() | nil,
    score_away: integer() | nil,
    score_halftime_home: integer() | nil,
    score_halftime_away: integer() | nil
  }
end
