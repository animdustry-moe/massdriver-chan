defmodule Massdriver.MetadataFormatter do
  @moduledoc """
  no boilerplate
  """

  def format_value(nil), do: "`(not set)`"
  def format_value(""), do: "`(empty)`"
  def format_value(val), do: "`#{val}`"

  def format_list([]), do: "`(none)`"
  def format_list(list), do: "`#{Enum.join(list, ", ")}`"

  def format_bool(true), do: "`true`"
  def format_bool(false), do: "`false`"

  def build_embed(metadata) do
    alias Nostrum.Struct.Embed

    fields = [
      %{name: "Title", value: format_value(metadata.title), inline: true},
      %{name: "Date", value: format_value(metadata.date), inline: true},
      %{name: "Updated", value: format_value(metadata.updated), inline: true},
      %{name: "Description", value: format_value(metadata.description), inline: false},
      %{name: "Link", value: format_value(metadata.link), inline: true},
      %{name: "Cover", value: format_value(metadata.cover), inline: true},
      %{name: "Tags", value: format_list(metadata.tags), inline: true},
      %{name: "Categories", value: format_list(metadata.categories), inline: true},
      %{name: "Sticky", value: format_bool(metadata.sticky), inline: true},
      %{name: "Catalog", value: format_bool(metadata.catalog), inline: true},
      %{name: "Subtitle", value: format_bool(metadata.subtitle), inline: true}
    ]

    %Embed{
      title: "Post Metadata",
      description: "Current metadata for this thread.",
      color: 0x00FF00,
      fields: fields,
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end
end
