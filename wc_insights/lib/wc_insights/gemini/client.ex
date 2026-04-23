defmodule WcInsights.Gemini.Client do
  @moduledoc """
  Google Gemini client using Req for match predictions.
  Replaces OpenAI as the AI provider.
  """

  @endpoint "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

  @spec predict(%{prompt: String.t()}) :: {:ok, map()} | {:error, String.t()}
  def predict(%{prompt: prompt}) do
    api_key = System.get_env("GEMINI_API_KEY")

    if is_nil(api_key) or api_key == "" do
      {:error, "GEMINI_API_KEY not set"}
    else
      do_predict(api_key, prompt)
    end
  end

  defp do_predict(api_key, prompt) do
    url = "#{@endpoint}?key=#{api_key}"

    body = %{
      contents: [
        %{
          parts: [
            %{text: build_system_prompt() <> "\n\n" <> prompt}
          ]
        }
      ],
      generationConfig: %{
        responseMimeType: "application/json"
      }
    }

    case Req.post(url,
           headers: [{"content-type", "application/json"}],
           json: body
         ) do
      {:ok, %{status: 200, body: response}} ->
        parse_gemini_response(response)

      {:ok, %{status: status, body: body}} ->
        {:error, "Gemini HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp build_system_prompt do
    """
    You are a football match prediction assistant.
    Return only valid JSON with exactly these keys:
    - "winner_pick": must be exactly "home", "away", or "draw"
    - "reasoning": a short 1-2 sentence explanation
    - "confidence": a number from 0.0 to 1.0 representing your certainty
    """
  end

  defp parse_gemini_response(%{"candidates" => [%{"content" => %{"parts" => [%{"text" => raw_json}]}} | _]}) do
    case Jason.decode(raw_json) do
      {:ok, %{"winner_pick" => _, "reasoning" => _} = result} ->
        result = Map.put_new(result, "confidence", 0.50)
        {:ok, result}

      {:ok, _} ->
        {:error, "Invalid prediction JSON shape from Gemini"}

      {:error, reason} ->
        {:error, "Gemini JSON decode error: #{inspect(reason)}"}
    end
  end

  defp parse_gemini_response(%{"error" => error}) do
    {:error, "Gemini API error: #{inspect(error)}"}
  end

  defp parse_gemini_response(_), do: {:error, "Unexpected Gemini response format"}
end
