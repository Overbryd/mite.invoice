defmodule Mix.Tasks.Invoice.StoreLastNumber do

  def run([last_number]) do
    Application.ensure_all_started(:mite)
    [datastore] = Mite.Api.archived_customers(name: "mite.invoice")
    data = Poison.decode!(datastore.note)
    data = Map.merge(data, %{last_number: last_number})
    case Mite.Api.set_customer_note(datastore.id, Poison.encode!(data)) do
      %HTTPoison.Response{status_code: 200} ->
        IO.puts "ok"

      resp ->
        IO.inspect resp
    end
  end
end
