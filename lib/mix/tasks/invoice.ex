defmodule Mix.Tasks.Invoice do

  def run(args) do
    Application.ensure_all_started(:mite)
    {opts, _args, _invalid} =
      OptionParser.parse(
        args,
        switches: [
          for: [:string],
          number: [:string],
          date: [:string],
          due_days: [:integer]
        ]
      )
    opts
    |> build_invoice
    |> write_invoice
  end

  def build_invoice(input) do
    input
    |> Enum.into(%{})
    |> set_datetime
    |> build_customer
    |> build_recipient
    |> build_time_entries
    |> build_time_entry_groups
    |> build_invoice_state
    |> build_invoice_total
  end

  def set_datetime(%{date: input} = state) when is_binary(input), do: Map.put(state, :date, Timex.parse!(input, "%Y-%m-%d", :strftime))
  def set_datetime(state), do: Map.put(state, :date, Timex.now())

  def build_number(%{number: number} = state) when is_binary(number) do
    state
  end

  def build_customer(%{customer: customer} = state) when is_map(customer) do
    state
  end

  def build_customer(%{for: input} = state) do
    [customer] = Mite.Api.customers(name: input)
    Map.put(state, :customer, customer)
  end

  def build_recipient(%{recipient: recipient} = state) when is_map(recipient) do
    state
  end

  def build_recipient(%{customer: %{note: note}} = state) do
    recipient = Poison.decode!(note, keys: :atoms)
    Map.put(state, :recipient, recipient)
  end

  def build_time_entries(%{from: from, to: to, customer: %{id: id}} = state) do
    time_entries = Mite.Api.time_entries(customer_id: id, from: from, to: to)
    Map.put(state, :time_entries, time_entries)
  end

  def build_time_entry_groups(%{from: from, to: to, customer: %{id: id}} = state) do
    time_entry_groups = Mite.Api.time_entry_groups("service,project", customer_id: id, from: from, to: to)
    Map.put(state, :time_entry_groups, time_entry_groups)
  end

  def build_invoice_state(state) do
    Map.put(state, :invoice, %{
      no: state.number,
      date: state.date,
      from: Timex.parse!(state.from, "%Y-%m-%d", :strftime),
      to: Timex.parse!(state.to, "%Y-%m-%d", :strftime),
      due_days: state.recipient.due_days,
      due_date: Timex.shift(state.date, days: state.recipient.due_days)
    })
  end

  def build_invoice_total(%{recipient: recipient, invoice: invoice} = state) do
    line_total = sum_revenue(state.time_entries)
    tax_total = if recipient.vat_exempt do
      Decimal.new(0)
    else
      taxes(line_total)
    end
    total = Decimal.add(line_total, tax_total)
    invoice = Map.merge(invoice, %{line_total: line_total, tax_total: tax_total, total: total})
    %{state | invoice: invoice}
  end

  def sum_revenue(time_entries) do
    Enum.reduce(time_entries, Decimal.new(0), fn time_entry, sum ->
      Decimal.new(time_entry.revenue)
      |> Decimal.add(sum)
    end)
  end

  def taxes(%Decimal{} = decimal) do
    Decimal.mult(Decimal.new("0.19"), decimal)
  end

  def write_invoice(%{invoice: invoice} = state) do
    args = state
           |> Map.take([:invoice, :recipient, :time_entries, :time_entry_groups])
           |> Enum.into([])
    iodata = InvoiceTemplate.html_iodata([{:h, InvoiceTemplate} | args])
    File.write!("#{invoice.no}.html", iodata, [:write])
  end

end

