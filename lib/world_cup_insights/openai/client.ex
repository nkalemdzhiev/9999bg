defmodule WorldCupInsights.OpenAI.Client do
  @moduledoc """
  Thin OpenAI client for match prediction requests.

  If the API key is missing, the caller can still use local fallback flows.
  """

  @default_model "gpt-5.4-mini"
  @endpoint "https://api.openai.com/v1/responses"

  @type request_payload :: map()
  @type response_result :: {:ok, map()} | {:error, term()}

  @spec predict(request_payload()) :: response_result()
  def predict(payload) when is_map(payload) do
    with {:ok, api_key} <- fetch_api_key(),
         {:ok, body} <- encode_body(build_request(payload)),
         {:ok, response} <- post_request(body, api_key) do
      parse_response(response)
    end
  end

  defp fetch_api_key do
    case System.get_env("OPENAI_API_KEY") do
      nil -> {:error, :missing_api_key}
      "" -> {:error, :missing_api_key}
      api_key -> {:ok, api_key}
    end
  end

  defp build_request(%{prompt: prompt}) do
    %{
      model: System.get_env("OPENAI_MODEL", @default_model),
      input: prompt,
      text: %{
        format: %{
          type: "json_schema",
          name: "match_prediction",
          schema: %{
            type: "object",
            additionalProperties: false,
            required: ["winner_pick", "reasoning"],
            properties: %{
              winner_pick: %{type: "string"},
              reasoning: %{type: "string"}
            }
          }
        }
      }
    }
  end

  defp encode_body(body) do
    Jason.encode(body)
  end

  defp post_request(body, api_key) do
    headers = [
      {'authorization', 'Bearer ' ++ String.to_charlist(api_key)},
      {'content-type', 'application/json'}
    ]

    request = {@endpoint, headers, 'application/json', String.to_charlist(body)}

    :inets.start()
    :ssl.start()

    case :httpc.request(:post, request, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _response_headers, response_body}} ->
        Jason.decode(response_body)

      {:ok, {{_, status, _}, _response_headers, response_body}} ->
        {:error, {:http_error, status, response_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_response(%{"output" => output}) when is_list(output) do
    text =
      output
      |> Enum.flat_map(fn item -> Map.get(item, "content", []) end)
      |> Enum.find_value(fn content ->
        case content do
          %{"text" => value} -> value
          _ -> nil
        end
      end)

    case text do
      nil -> {:error, :missing_output_text}
      raw_json -> Jason.decode(raw_json)
    end
  end

  defp parse_response(response), do: {:error, {:unexpected_response, response}}
end
