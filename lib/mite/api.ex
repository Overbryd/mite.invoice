defmodule Mite.Api do
  use HTTPoison.Base

  def config do
    Application.get_env(:mite, :api)
  end

  def process_url(url) do
    "https://#{config().account}.mite.yo.lk" <> url
  end

  def process_request_headers(headers) do
    headers ++ [
      {"User-Agent", "mit.ex/v0.1 (https://github.com/Overbryd/mit.ex)"},
      {"X-MiteApiKey", config().key}
    ]
  end

  def process_response_body(body), do: Poison.Parser.parse!(body)

  def time_entries(params \\ []) do
    get!("/time_entries.json", [], params: params)
    |> pull_objects("time_entry", ~w[billable created_at customer_id customer_name date_at hourly_rate id locked minutes note project_id project_name revenue service_id service_name updated_at user_id user_name])
  end

  def time_entry_groups(group_by, params \\ []) do
    get!("/time_entries.json", [], params: Keyword.put(params, :group_by, group_by))
    |> pull_objects("time_entry_group", ~w[from to minutes revenue user_id user_name service_name service_id customer_id customer_name project_id project_name day week month year])
  end


  def customers(params \\ []) do
    get!("/customers.json", [], params: params)
    |> pull_objects("customer", ~w[active_hourly_rate archived created_at hourly_rate hourly_rates_per_service id name note updated_at])
  end

  defp pull_objects(%HTTPoison.Response{body: response}, key, fields) do
    Enum.map(response, fn %{^key => object} ->
      Map.take(object, fields)
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Enum.into(%{})
    end)
  end

end
