defmodule Mix.Tasks.Invoice.Monthly do

  import Mix.Tasks.Invoice, only: [build_invoice: 1, write_invoice: 1]
  # for recipient <- Path.wildcard("priv/recipients/*.json") do
  #   [[customer_id]] = Regex.scan(~r/_(\d+)\.json/, recipient, capture: :all_but_first)
  #   note = File.read!(recipient)
  #   IO.inspect Mite.Api.set_customer_note(customer_id, note)
  # end

  def run(args) do
    Application.ensure_all_started(:mite)
    this_month = Timex.beginning_of_month(DateTime.utc_now())
    to_date = Timex.shift(this_month, days: -1)
    from_date = Timex.beginning_of_month(to_date)
    year = Timex.format!(DateTime.utc_now(), "%Y", :strftime)

    [datastore] = Mite.Api.archived_customers(name: "mite.invoice")
    %{last_number: last_number} = Poison.decode!(datastore.note, keys: :atoms)
    [[last_no]] = Regex.scan(~r/\d{4}(\d{3})/, last_number, capture: :all_but_first)
    {last_no, _} = Integer.parse(last_no)

    {opts, _args, _invalid} = OptionParser.parse(args, switches: [skip: [:string, :keep]])
    skip_regex = opts
                 |> Keyword.take([:skip])
                 |> Keyword.values
                 |> Enum.join("|")
                 |> Regex.compile!([:caseless])

    Enum.reduce(Mite.Api.customers(), last_no, fn
      customer, last_no ->
        if Regex.match?(skip_regex, customer.name) do
          last_no
        else
          recipient = Poison.decode!(customer.note, keys: :atoms)
          num = last_no + 1
          args = %{
            number: invoice_number(year, num),
            from: strftime(from_date),
            to: strftime(to_date),
            customer: customer,
            recipient: recipient
          }
          case build_invoice(args) do
            %{time_entries: list} = state when length(list) > 0 ->
              write_invoice(state)
              num

            _ ->
              last_no
          end
        end
    end)

  end

  def strftime(datetime) do
    Timex.format!(datetime, "%Y-%m-%d", :strftime)
  end

  def invoice_number(year, num) do
    num = to_string(num) |> String.pad_leading(3, "0")
    year <> num
  end
end

