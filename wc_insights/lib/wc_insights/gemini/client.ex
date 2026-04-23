defmodule WcInsights.Gemini.Client do
  @moduledoc """
  Minimal Gemini client for match predictions using structured JSON output.
  """

  @base_url "https://generativelanguage.googleapis.com/v1beta/models"

  @spec predict(map()) :: {:ok, map()} | {:error, term()}
  def predict(%{system_prompt: system_prompt, user_prompt: user_prompt}) do
    with {:ok, api_key} <- fetch_api_key(),
         {:ok, response} <- request(api_key, system_prompt, user_prompt) do
      parse_response(response)
    end
  end

  defp fetch_api_key do
    case Application.get_env(:wc_insights, :gemini_api_key) do
      nil -> {:error, :missing_api_key}
      "" -> {:error, :missing_api_key}
      api_key -> {:ok, api_key}
    end
  end

  defp request(api_key, system_prompt, user_prompt) do
    model = Application.get_env(:wc_insights, :gemini_model, "gemini-2.5-flash")

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
            winner_pick: %{type: "string", description: "The predicted winner team name."},
            reasoning: %{type: "string", description: "Short fan-friendly explanation in no more than two sentences."},
            confidence: %{type: "string", enum: ["low", "medium", "high"]}
          }
        }
      }
    }

    case Req.post(
           "#{@base_url}/#{model}:generateContent",
           headers: [
             {"x-goog-api-key", api_key},
             {"content-type", "application/json"}
           ],
           json: body
         ) do
      {:ok, %{status: 200, body: response}} -> {:ok, response}
      {:ok, %{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_response(%{"candidates" => [%{"content" => %{"parts" => [%{"text" => text} | _]}} | _]}) do
    Jason.decode(text)
  end

  defp parse_response(%{"promptFeedback" => feedback}) when is_map(feedback) do
    {:error, {:prompt_feedback, feedback}}
  end

  defp parse_response(response), do: {:error, {:unexpected_response, response}}
end
