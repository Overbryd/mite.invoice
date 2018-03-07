defmodule InvoiceTemplate do
  require EEx
  EEx.function_from_file :def, :safe_html, Path.join(:code.priv_dir(:mite), "invoice.html.eex"), [:assigns], engine: Phoenix.HTML.Engine

  def html(args) do
    html_iodata(args)
    |> IO.iodata_to_binary
  end

  def html_iodata(args) do
    {:safe, iodata} = safe_html(args)
    iodata
  end

  def cents_to_currency(number) do
    Decimal.new(number)
    |> Decimal.div(Decimal.new(100))
    |> Number.Currency.number_to_currency
  end

  def format_duration(minutes) do
    hours = Integer.floor_div(minutes, 60)
    minutes = minutes - hours*60
              |> to_string
              |> String.pad_leading(2, "0")
    "#{hours}:#{minutes}"
  end

  def format_date(datetime) do
    Timex.format!(datetime, "%d.%m.%Y", :strftime)
  end

  def format_daterange(from, to) do
    if from.month == to.month && from.year == to.year do
      Timex.format!(from, "%d.%m", :strftime) <> " - " <> format_date(to)
    else
      format_date(from) <> " - " <> format_date(to)
    end
  end

  def format_links(content) do
    result = content
    |> String.split(" ")
    |> Enum.map(fn blob ->
      case URI.parse(blob) do
        %URI{host: nil} ->
          Plug.HTML.html_escape(blob)

        %URI{} = url ->
          string = to_string(url)
          {:safe, iodata} = Phoenix.HTML.Link.link(string, to: string)
          IO.iodata_to_binary(iodata)
      end
    end)
    |> Enum.join(" ")
    {:safe, result}
  end

end

