defmodule WcInsights.OpenAI.Client do
  @moduledoc """
  OpenAI client using Req for match predictions.
  """

  @endpoint "https://api.openai.com/v1/chat/completions"
  @default_model "gpt-4o-mini"

  @spec predict(%{prompt: String.t()}) :: {:ok, map()} | {:error, String.t()}
  def predict(%{prompt: prompt}) do
    api_key = System.get_env("OPENAI_API_KEY")

    if is_nil(api_key) or api_key == "" do
      {:error, "OPENAI_API_KEY not set"}
    else
      body = %{
        model: System.get_env("OPENAI_MODEL") || @default_model,
        messages: [
          %{
            role: "system",
            content:
              "You are a football match prediction assistant. Return only JSON with keys: winner_pick, reasoning, confidence. winner_pick must be exactly 'home', 'away', or 'draw'. confidence is a number from 0.0 to 1.0 representing your certainty."
          },
          %{role: "user", content: prompt}
        ],
        response_format: %{type: "json_object"}
      }

      case Req.post(@endpoint,
             headers: [
               {"authorization", "Bearer #{api_key}"},
               {"content-type", "application/json"}
             ],
             json: body
           ) do
        {:ok, %{status: 200, body: response}} ->
          parse_chat_response(response)

        {:ok, %{status: status, body: body}} ->
          {:error, "OpenAI HTTP #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    end
  end

  defp parse_chat_response(%{"choices" => [%{"message" => %{"content" => raw_json}} | _]}) do
    case Jason.decode(raw_json) do
      {:ok, %{"winner_pick" => _, "reasoning" => _} = result} ->
        result = Map.put_new(result, "confidence", 0.50)
        {:ok, result}

      {:ok, _} ->
        {:error, "Invalid prediction JSON shape"}

      {:error, reason} ->
        {:error, "JSON decode error: #{inspect(reason)}"}
    end
  end

  defp parse_chat_response(_), do: {:error, "Unexpected OpenAI response format"}
end
