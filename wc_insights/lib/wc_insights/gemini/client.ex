defmodule WcInsights.Gemini.Client do
  @moduledoc """
  Google Gemini client using Req for match predictions.
  """

  @base_url "https://generativelanguage.googleapis.com/v1beta/models"

  @spec predict(map()) :: {:ok, map()} | {:error, term()}
  def predict(%{system_prompt: system_prompt, user_prompt: user_prompt}) do
    api_key = System.get_env("GEMINI_API_KEY") || "AIzaSyBFQYwEQITzpdzlknhWbTyyrlY0di1Rn8c"

    if is_nil(api_key) or api_key == "" do
      {:error, :missing_api_key}
    else
      do_predict(api_key, system_prompt, user_prompt)
    end
  end

  defp do_predict(api_key, system_prompt, user_prompt) do
    model = System.get_env("GEMINI_MODEL") || "gemini-2.5-flash"

    body = %{
      contents: [
        %{
          role: "user",
          parts: [
            %{
              text: """
              #{system_prompt}

              #{user_prompt}
              """
            }
          ]
        }
      ],
      generationConfig: %{
        responseMimeType: "application/json",
        responseJsonSchema: %{
          type: "object",
          additionalProperties: false,
          required: ["winner_pick", "reasoning", "confidence"],
          properties: %{
            winner_pick: %{type: "string", description: "The predicted winner: home, away, or draw."},
            reasoning: %{type: "string", description: "Short fan-friendly explanation in no more than two sentences."},
            confidence: %{type: "number", description: "Confidence from 0.0 to 1.0"}
          }
        }
      }
    }

    case Req.post(
           "#{@base_url}/#{model}:generateContent?key=#{api_key}",
           headers: [{"content-type", "application/json"}],
           json: body
         ) do
      {:ok, %{status: 200, body: response}} ->
        parse_response(response)

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_response(%{"candidates" => [%{"content" => %{"parts" => [%{"text" => text} | _]}} | _]}) do
    case Jason.decode(text) do
      {:ok, %{} = result} -> {:ok, result}
      {:error, reason} -> {:error, {:json_decode, reason}}
    end
  end

  defp parse_response(%{"promptFeedback" => feedback}) when is_map(feedback) do
    {:error, {:prompt_feedback, feedback}}
  end

  defp parse_response(response), do: {:error, {:unexpected_response, response}}
end
