defmodule WcInsights.PredictionSampleData do
  @moduledoc """
  Local match-context enrichments used by the heuristic predictor until live
  lineup and player-stat endpoints are integrated.
  """

  def match_overrides(match_id, home_team_id, away_team_id) do
    %{
      expected_lineups: %{
        home: team_lineup(home_team_id),
        away: team_lineup(away_team_id)
      },
      missing_players: %{
        home: team_absences(home_team_id),
        away: team_absences(away_team_id)
      },
      recent_team_form: %{
        home: team_form(home_team_id),
        away: team_form(away_team_id)
      },
      team_stats: %{
        home: team_stats(home_team_id),
        away: team_stats(away_team_id)
      },
      context_label: context_label(match_id)
    }
  end

  def fallback_players(team_id, team_name) do
    team_lineup(team_id)
    |> Enum.map(fn player ->
      player
      |> Map.take([:id, :name, :position, :number])
      |> Map.put(:team_name, team_name)
    end)
  end

  defp context_label(239625), do: "Opening group-stage match with both teams near full strength."
  defp context_label(239626), do: "Heavyweight matchup where attacking quality should decide the edge."
  defp context_label(_match_id), do: "Heuristic local prediction using projected lineups and recent player form."

  defp team_form(24), do: ["W", "W", "D", "W", "W"]
  defp team_form(2), do: ["W", "L", "W", "D", "W"]
  defp team_form(26), do: ["D", "W", "L", "W", "D"]
  defp team_form(6), do: ["W", "W", "W", "D", "W"]
  defp team_form(14), do: ["W", "D", "W", "L", "W"]
  defp team_form(15), do: ["W", "W", "D", "W", "L"]
  defp team_form(10), do: ["W", "W", "D", "W", "L"]
  defp team_form(21), do: ["W", "D", "W", "W", "D"]
  defp team_form(27), do: ["W", "L", "D", "W", "W"]
  defp team_form(3), do: ["W", "W", "W", "D", "L"]
  defp team_form(_team_id), do: ["W", "D", "L", "W", "D"]

  defp team_stats(24), do: %{goals_scored_recent: 9, goals_conceded_recent: 3, clean_sheets_recent: 2}
  defp team_stats(2), do: %{goals_scored_recent: 8, goals_conceded_recent: 4, clean_sheets_recent: 1}
  defp team_stats(26), do: %{goals_scored_recent: 6, goals_conceded_recent: 5, clean_sheets_recent: 1}
  defp team_stats(6), do: %{goals_scored_recent: 11, goals_conceded_recent: 3, clean_sheets_recent: 3}
  defp team_stats(14), do: %{goals_scored_recent: 8, goals_conceded_recent: 4, clean_sheets_recent: 2}
  defp team_stats(15), do: %{goals_scored_recent: 10, goals_conceded_recent: 5, clean_sheets_recent: 1}
  defp team_stats(10), do: %{goals_scored_recent: 9, goals_conceded_recent: 4, clean_sheets_recent: 2}
  defp team_stats(21), do: %{goals_scored_recent: 8, goals_conceded_recent: 3, clean_sheets_recent: 2}
  defp team_stats(27), do: %{goals_scored_recent: 7, goals_conceded_recent: 5, clean_sheets_recent: 1}
  defp team_stats(3), do: %{goals_scored_recent: 9, goals_conceded_recent: 4, clean_sheets_recent: 2}
  defp team_stats(_team_id), do: %{goals_scored_recent: 6, goals_conceded_recent: 6, clean_sheets_recent: 1}

  defp team_absences(26) do
    [%{name: "Edson Alvarez", reason: "muscle issue", impact: 4}]
  end

  defp team_absences(2) do
    [%{name: "Theo Hernandez", reason: "suspension risk", impact: 3}]
  end

  defp team_absences(10) do
    [%{name: "Luke Shaw", reason: "fitness concern", impact: 2}]
  end

  defp team_absences(_team_id), do: []

  defp team_lineup(24) do
    [
      player(2400, "Emiliano Martinez", "Goalkeeper", 23, %{rating: 7.1, clean_sheets: 2, saves: 11, minutes: 450}),
      player(2401, "Cristian Romero", "Defender", 13, %{rating: 7.2, tackles: 13, interceptions: 8, minutes: 430}),
      player(2402, "Nicolas Otamendi", "Defender", 19, %{rating: 7.0, tackles: 11, interceptions: 9, minutes: 450}),
      player(2403, "Nahuel Molina", "Defender", 16, %{rating: 6.9, assists: 1, tackles: 9, minutes: 400}),
      player(2404, "Nicolas Tagliafico", "Defender", 3, %{rating: 6.8, tackles: 10, key_passes: 4, minutes: 390}),
      player(2405, "Rodrigo De Paul", "Midfielder", 7, %{rating: 7.1, assists: 2, key_passes: 9, minutes: 420}),
      player(2406, "Enzo Fernandez", "Midfielder", 8, %{rating: 7.4, goals: 1, assists: 2, key_passes: 10, minutes: 410}),
      player(2407, "Alexis Mac Allister", "Midfielder", 20, %{rating: 7.0, goals: 1, assists: 1, key_passes: 8, minutes: 400}),
      player(2408, "Lionel Messi", "Forward", 10, %{rating: 8.6, goals: 4, assists: 3, key_passes: 16, minutes: 430}),
      player(2409, "Julian Alvarez", "Forward", 9, %{rating: 7.9, goals: 3, assists: 1, key_passes: 6, minutes: 370}),
      player(2410, "Angel Di Maria", "Forward", 11, %{rating: 7.3, goals: 2, assists: 2, key_passes: 9, minutes: 320})
    ]
  end

  defp team_lineup(26) do
    [
      player(2600, "Guillermo Ochoa", "Goalkeeper", 13, %{rating: 7.0, clean_sheets: 1, saves: 14, minutes: 450}),
      player(2601, "Cesar Montes", "Defender", 3, %{rating: 7.0, tackles: 14, interceptions: 10, minutes: 450}),
      player(2602, "Johan Vasquez", "Defender", 5, %{rating: 6.9, tackles: 12, interceptions: 7, minutes: 430}),
      player(2603, "Jorge Sanchez", "Defender", 2, %{rating: 6.7, assists: 1, tackles: 8, minutes: 390}),
      player(2604, "Jesus Gallardo", "Defender", 23, %{rating: 6.8, key_passes: 4, tackles: 7, minutes: 410}),
      player(2605, "Luis Chavez", "Midfielder", 24, %{rating: 7.2, goals: 1, key_passes: 8, minutes: 420}),
      player(2606, "Luis Romo", "Midfielder", 7, %{rating: 6.9, assists: 1, key_passes: 5, minutes: 390}),
      player(2607, "Orbelin Pineda", "Midfielder", 17, %{rating: 7.0, goals: 1, assists: 1, key_passes: 7, minutes: 360}),
      player(2608, "Hirving Lozano", "Forward", 22, %{rating: 7.3, goals: 2, assists: 1, key_passes: 8, minutes: 350}),
      player(2609, "Santiago Gimenez", "Forward", 11, %{rating: 7.4, goals: 3, assists: 1, key_passes: 4, minutes: 330}),
      player(2610, "Henry Martin", "Forward", 20, %{rating: 6.8, goals: 1, assists: 1, key_passes: 3, minutes: 280})
    ]
  end

  defp team_lineup(2) do
    [
      player(200, "Mike Maignan", "Goalkeeper", 16, %{rating: 7.1, clean_sheets: 1, saves: 12, minutes: 450}),
      player(201, "Jules Kounde", "Defender", 5, %{rating: 7.0, tackles: 11, interceptions: 8, minutes: 420}),
      player(202, "Dayot Upamecano", "Defender", 4, %{rating: 7.0, tackles: 12, interceptions: 9, minutes: 410}),
      player(203, "William Saliba", "Defender", 17, %{rating: 7.2, tackles: 10, interceptions: 10, minutes: 430}),
      player(204, "Theo Hernandez", "Defender", 22, %{rating: 7.3, assists: 2, key_passes: 8, minutes: 360}),
      player(205, "Aurelien Tchouameni", "Midfielder", 8, %{rating: 7.2, goals: 1, key_passes: 7, minutes: 430}),
      player(206, "Adrien Rabiot", "Midfielder", 14, %{rating: 7.0, goals: 1, assists: 1, key_passes: 5, minutes: 410}),
      player(207, "Antoine Griezmann", "Midfielder", 7, %{rating: 7.8, goals: 2, assists: 4, key_passes: 15, minutes: 420}),
      player(208, "Ousmane Dembele", "Forward", 11, %{rating: 7.4, goals: 1, assists: 3, key_passes: 10, minutes: 370}),
      player(209, "Kylian Mbappe", "Forward", 10, %{rating: 8.5, goals: 5, assists: 2, key_passes: 13, minutes: 400}),
      player(210, "Randal Kolo Muani", "Forward", 12, %{rating: 7.1, goals: 2, assists: 1, key_passes: 4, minutes: 300})
    ]
  end

  defp team_lineup(6) do
    [
      player(600, "Alisson", "Goalkeeper", 1, %{rating: 7.3, clean_sheets: 3, saves: 10, minutes: 450}),
      player(601, "Danilo", "Defender", 2, %{rating: 7.0, tackles: 10, interceptions: 8, minutes: 390}),
      player(602, "Marquinhos", "Defender", 4, %{rating: 7.2, tackles: 11, interceptions: 10, minutes: 430}),
      player(603, "Eder Militao", "Defender", 3, %{rating: 7.1, tackles: 10, interceptions: 8, minutes: 410}),
      player(604, "Guilherme Arana", "Defender", 16, %{rating: 7.0, assists: 2, key_passes: 7, minutes: 360}),
      player(605, "Bruno Guimaraes", "Midfielder", 8, %{rating: 7.3, goals: 1, assists: 2, key_passes: 9, minutes: 420}),
      player(606, "Casemiro", "Midfielder", 5, %{rating: 7.1, goals: 1, tackles: 14, key_passes: 4, minutes: 400}),
      player(607, "Lucas Paqueta", "Midfielder", 7, %{rating: 7.2, goals: 2, assists: 2, key_passes: 8, minutes: 390}),
      player(608, "Vinicius Junior", "Forward", 10, %{rating: 8.1, goals: 4, assists: 2, key_passes: 12, minutes: 380}),
      player(609, "Rodrygo", "Forward", 11, %{rating: 7.8, goals: 3, assists: 2, key_passes: 8, minutes: 340}),
      player(610, "Raphinha", "Forward", 19, %{rating: 7.5, goals: 2, assists: 3, key_passes: 10, minutes: 360})
    ]
  end

  defp team_lineup(14) do
    [
      player(1400, "Marc-Andre ter Stegen", "Goalkeeper", 1, %{rating: 7.0, clean_sheets: 2, saves: 10, minutes: 450}),
      player(1401, "Joshua Kimmich", "Defender", 6, %{rating: 7.6, assists: 2, key_passes: 12, tackles: 8, minutes: 420}),
      player(1402, "Antonio Rudiger", "Defender", 2, %{rating: 7.2, tackles: 12, interceptions: 8, minutes: 430}),
      player(1403, "Jonathan Tah", "Defender", 4, %{rating: 7.0, tackles: 10, interceptions: 10, minutes: 420}),
      player(1404, "David Raum", "Defender", 3, %{rating: 7.1, assists: 2, key_passes: 8, minutes: 380}),
      player(1405, "Ilkay Gundogan", "Midfielder", 21, %{rating: 7.4, goals: 2, assists: 2, key_passes: 10, minutes: 390}),
      player(1406, "Jamal Musiala", "Midfielder", 10, %{rating: 8.3, goals: 4, assists: 3, key_passes: 13, minutes: 370}),
      player(1407, "Florian Wirtz", "Midfielder", 17, %{rating: 8.0, goals: 3, assists: 3, key_passes: 11, minutes: 350}),
      player(1408, "Leroy Sane", "Forward", 19, %{rating: 7.5, goals: 2, assists: 2, key_passes: 8, minutes: 330}),
      player(1409, "Kai Havertz", "Forward", 7, %{rating: 7.3, goals: 2, assists: 1, key_passes: 6, minutes: 340}),
      player(1410, "Niclas Fullkrug", "Forward", 9, %{rating: 7.2, goals: 3, assists: 0, key_passes: 3, minutes: 280})
    ]
  end

  defp team_lineup(15) do
    [
      player(1500, "Unai Simon", "Goalkeeper", 23, %{rating: 7.0, clean_sheets: 1, saves: 9, minutes: 450}),
      player(1501, "Dani Carvajal", "Defender", 2, %{rating: 7.1, assists: 1, key_passes: 8, tackles: 9, minutes: 400}),
      player(1502, "Aymeric Laporte", "Defender", 14, %{rating: 7.0, tackles: 10, interceptions: 7, minutes: 410}),
      player(1503, "Robin Le Normand", "Defender", 3, %{rating: 7.1, tackles: 9, interceptions: 8, minutes: 390}),
      player(1504, "Alejandro Balde", "Defender", 18, %{rating: 7.0, assists: 2, key_passes: 7, minutes: 350}),
      player(1505, "Rodri", "Midfielder", 16, %{rating: 8.1, goals: 2, assists: 2, key_passes: 9, tackles: 14, minutes: 430}),
      player(1506, "Pedri", "Midfielder", 8, %{rating: 7.7, goals: 1, assists: 3, key_passes: 12, minutes: 390}),
      player(1507, "Gavi", "Midfielder", 9, %{rating: 7.4, goals: 1, assists: 2, key_passes: 8, minutes: 350}),
      player(1508, "Lamine Yamal", "Forward", 19, %{rating: 8.2, goals: 3, assists: 4, key_passes: 14, minutes: 340}),
      player(1509, "Nico Williams", "Forward", 11, %{rating: 7.8, goals: 2, assists: 3, key_passes: 10, minutes: 330}),
      player(1510, "Alvaro Morata", "Forward", 7, %{rating: 7.2, goals: 3, assists: 1, key_passes: 4, minutes: 300})
    ]
  end

  defp team_lineup(10) do
    [
      player(1000, "Jordan Pickford", "Goalkeeper", 1, %{rating: 7.0, clean_sheets: 2, saves: 9, minutes: 450}),
      player(1001, "Kyle Walker", "Defender", 2, %{rating: 7.0, tackles: 8, interceptions: 7, minutes: 390}),
      player(1002, "John Stones", "Defender", 5, %{rating: 7.1, tackles: 9, interceptions: 8, minutes: 410}),
      player(1003, "Marc Guehi", "Defender", 6, %{rating: 7.0, tackles: 10, interceptions: 9, minutes: 420}),
      player(1004, "Kieran Trippier", "Defender", 12, %{rating: 7.2, assists: 2, key_passes: 11, minutes: 380}),
      player(1005, "Declan Rice", "Midfielder", 4, %{rating: 7.4, tackles: 13, key_passes: 7, minutes: 430}),
      player(1006, "Jude Bellingham", "Midfielder", 10, %{rating: 8.4, goals: 4, assists: 3, key_passes: 14, minutes: 400}),
      player(1007, "Phil Foden", "Midfielder", 11, %{rating: 7.8, goals: 3, assists: 2, key_passes: 10, minutes: 360}),
      player(1008, "Bukayo Saka", "Forward", 7, %{rating: 8.0, goals: 3, assists: 3, key_passes: 11, minutes: 350}),
      player(1009, "Harry Kane", "Forward", 9, %{rating: 8.2, goals: 5, assists: 2, key_passes: 8, minutes: 410}),
      player(1010, "Anthony Gordon", "Forward", 17, %{rating: 7.1, goals: 1, assists: 2, key_passes: 5, minutes: 260})
    ]
  end

  defp team_lineup(21) do
    [
      player(2100, "Diogo Costa", "Goalkeeper", 1, %{rating: 7.1, clean_sheets: 2, saves: 10, minutes: 450}),
      player(2101, "Joao Cancelo", "Defender", 20, %{rating: 7.4, assists: 2, key_passes: 10, tackles: 7, minutes: 390}),
      player(2102, "Ruben Dias", "Defender", 3, %{rating: 7.3, tackles: 11, interceptions: 9, minutes: 420}),
      player(2103, "Pepe", "Defender", 4, %{rating: 7.0, tackles: 9, interceptions: 10, minutes: 360}),
      player(2104, "Nuno Mendes", "Defender", 19, %{rating: 7.2, assists: 1, key_passes: 7, minutes: 340}),
      player(2105, "Bruno Fernandes", "Midfielder", 8, %{rating: 8.1, goals: 3, assists: 4, key_passes: 15, minutes: 410}),
      player(2106, "Joao Neves", "Midfielder", 15, %{rating: 7.3, goals: 1, assists: 2, key_passes: 8, minutes: 350}),
      player(2107, "Bernardo Silva", "Midfielder", 10, %{rating: 7.7, goals: 2, assists: 3, key_passes: 11, minutes: 390}),
      player(2108, "Rafael Leao", "Forward", 17, %{rating: 7.8, goals: 3, assists: 2, key_passes: 9, minutes: 330}),
      player(2109, "Cristiano Ronaldo", "Forward", 7, %{rating: 7.6, goals: 4, assists: 1, key_passes: 5, minutes: 320}),
      player(2110, "Pedro Neto", "Forward", 11, %{rating: 7.1, goals: 1, assists: 2, key_passes: 6, minutes: 280})
    ]
  end

  defp team_lineup(27) do
    [
      player(2700, "Matt Turner", "Goalkeeper", 1, %{rating: 6.9, clean_sheets: 1, saves: 12, minutes: 450}),
      player(2701, "Sergino Dest", "Defender", 2, %{rating: 7.0, assists: 1, key_passes: 7, minutes: 380}),
      player(2702, "Chris Richards", "Defender", 3, %{rating: 7.0, tackles: 11, interceptions: 9, minutes: 420}),
      player(2703, "Tim Ream", "Defender", 13, %{rating: 6.8, tackles: 8, interceptions: 10, minutes: 400}),
      player(2704, "Antonee Robinson", "Defender", 5, %{rating: 7.2, assists: 2, key_passes: 9, minutes: 420}),
      player(2705, "Tyler Adams", "Midfielder", 4, %{rating: 7.3, tackles: 15, key_passes: 5, minutes: 430}),
      player(2706, "Weston McKennie", "Midfielder", 8, %{rating: 7.1, goals: 1, assists: 1, key_passes: 6, minutes: 370}),
      player(2707, "Giovanni Reyna", "Midfielder", 7, %{rating: 7.4, goals: 2, assists: 2, key_passes: 10, minutes: 300}),
      player(2708, "Christian Pulisic", "Forward", 10, %{rating: 7.9, goals: 3, assists: 3, key_passes: 12, minutes: 360}),
      player(2709, "Folarin Balogun", "Forward", 9, %{rating: 7.5, goals: 3, assists: 1, key_passes: 5, minutes: 320}),
      player(2710, "Tim Weah", "Forward", 11, %{rating: 7.2, goals: 2, assists: 2, key_passes: 7, minutes: 340})
    ]
  end

  defp team_lineup(3) do
    [
      player(300, "Bart Verbruggen", "Goalkeeper", 1, %{rating: 7.1, clean_sheets: 2, saves: 10, minutes: 450}),
      player(301, "Denzel Dumfries", "Defender", 22, %{rating: 7.4, goals: 1, assists: 2, key_passes: 9, minutes: 380}),
      player(302, "Virgil van Dijk", "Defender", 4, %{rating: 7.5, tackles: 10, interceptions: 12, minutes: 430}),
      player(303, "Nathan Ake", "Defender", 5, %{rating: 7.2, tackles: 10, interceptions: 9, minutes: 420}),
      player(304, "Micky van de Ven", "Defender", 15, %{rating: 7.0, tackles: 9, interceptions: 8, minutes: 340}),
      player(305, "Frenkie de Jong", "Midfielder", 21, %{rating: 7.8, goals: 1, assists: 3, key_passes: 11, minutes: 410}),
      player(306, "Tijjani Reijnders", "Midfielder", 14, %{rating: 7.3, goals: 2, assists: 2, key_passes: 8, minutes: 360}),
      player(307, "Xavi Simons", "Midfielder", 7, %{rating: 7.9, goals: 3, assists: 2, key_passes: 12, minutes: 340}),
      player(308, "Cody Gakpo", "Forward", 11, %{rating: 8.0, goals: 4, assists: 2, key_passes: 10, minutes: 360}),
      player(309, "Memphis Depay", "Forward", 10, %{rating: 7.5, goals: 2, assists: 2, key_passes: 6, minutes: 300}),
      player(310, "Donyell Malen", "Forward", 18, %{rating: 7.3, goals: 2, assists: 1, key_passes: 5, minutes: 280})
    ]
  end

  defp team_lineup(_team_id) do
    [
      player(1, "Demo Keeper", "Goalkeeper", 1, %{rating: 6.8, clean_sheets: 1, saves: 8, minutes: 450}),
      player(2, "Demo Defender", "Defender", 4, %{rating: 6.8, tackles: 8, interceptions: 7, minutes: 420}),
      player(3, "Demo Midfielder", "Midfielder", 8, %{rating: 7.0, goals: 1, assists: 1, key_passes: 6, minutes: 380}),
      player(4, "Demo Forward", "Forward", 9, %{rating: 7.2, goals: 2, assists: 1, key_passes: 5, minutes: 320})
    ]
  end

  defp player(id, name, position, number, recent_stats) do
    %{
      id: id,
      name: name,
      position: position,
      number: number,
      expected_starter: true,
      recent_stats: recent_stats
    }
  end
end
