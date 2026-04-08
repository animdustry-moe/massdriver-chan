#  Copyright 2026 animdustry.moe
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

defmodule Massdriver.Consumer do
  @behaviour Nostrum.Consumer
  require Logger

  alias Nostrum.Api.{Message, Interaction}
  alias Nostrum.Struct.Component
  alias Massdriver.MetadataEditor
  alias Massdriver.MetadataFormatter

  @select_menu_custom_id "select_metadata_field"
  @publish_button_custom_id "publish_metadata"

  @field_options [
    %{label: "Title", value: "title", description: "Post / page title"},
    %{label: "Date", value: "date", description: "Publish time (YYYY-mm-dd HH:MM)"},
    %{label: "Updated", value: "updated", description: "Updated time"},
    %{label: "Description", value: "description", description: "Summary callout text"},
    %{label: "Link", value: "link", description: "Absolute path, e.g., /my-post"},
    %{label: "Cover", value: "cover", description: "Thumbnail URL"},
    %{label: "Tags", value: "tags", description: "Comma-separated list"},
    %{label: "Categories", value: "categories", description: "Comma-separated list of paths"},
    %{label: "Sticky", value: "sticky", description: "true/false"},
    %{label: "Catalog", value: "catalog", description: "true/false (legacy)"},
    %{label: "Subtitle", value: "subtitle", description: "true/false (legacy)"}
  ]

  # make per thread editor and menu
  def handle_event({:THREAD_CREATE, %{id: thread_id, owner_id: owner_id}, _ws_state}) do
    case MetadataEditor.start_link(thread_id, owner_id) do
      {:ok, _pid} ->
        Logger.info("MetadataEditor started for thread #{thread_id}")

        embed =
          %Massdriver.Metadata{}
          |> MetadataFormatter.build_embed()
          |> add_author()

        components = [
          # select menu
          %Component{
            type: 1,
            components: [
              %Component{
                type: 3,
                custom_id: @select_menu_custom_id,
                options:
                  Enum.map(@field_options, fn opt ->
                    %{label: opt.label, value: opt.value, description: opt.description}
                  end),
                placeholder: "Choose a field to edit...",
                min_values: 1,
                max_values: 1
              }
            ]
          },
          %Component{
            type: 1,
            components: [
              %Component{
                type: 2,
                # green as success
                style: 3,
                label: "Publish",
                custom_id: @publish_button_custom_id
              }
            ]
          }
        ]

        case Message.create(thread_id, embeds: [embed], components: components) do
          {:ok, message} ->
            MetadataEditor.set_message_id(thread_id, message.id)
            Logger.info("Metadata editor sent to thread #{thread_id}")

          {:error, error} ->
            Logger.error("Failed to send metadata editor: #{inspect(error)}")
        end

      {:error, reason} ->
        Logger.error("Failed to start MetadataEditor for thread #{thread_id}: #{inspect(reason)}")
    end
  end

  # publish
  def handle_event(
        {:INTERACTION_CREATE,
         %Nostrum.Struct.Interaction{
           type: 3,
           data: %{custom_id: @publish_button_custom_id},
           channel_id: thread_id,
           user: %{id: user_id}
         } = interaction, _ws_state}
      ) do
    case MetadataEditor.get_owner(thread_id) do
      ^user_id ->
        # get the metadata
        metadata = MetadataEditor.get_metadata(thread_id)

        IO.inspect(metadata, label: "publishing metadata for thread #{thread_id}")

        case MetadataEditor.get_message_id(thread_id) do
          nil ->
            Logger.warning("No message_id stored for thread #{thread_id}")

          message_id ->
            published_embed =
              metadata
              |> MetadataFormatter.build_embed()
              |> Map.put(:title, "Post Metadata (Published)")
              |> Map.put(
                :description,
                "This metadata has been published and can no longer be edited."
              )
              # grey out
              |> Map.put(:color, 0x808080)

            # remove component
            Nostrum.Api.Message.edit(thread_id, message_id,
              embeds: [published_embed],
              components: []
            )
        end

        success_embed = %Nostrum.Struct.Embed{
          title: "Publishing Successful",
          description: "The metadata has been published.",
          color: 0x00FF00,
          timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
        }

        Interaction.create_response(interaction, %{
          type: 4,
          data: %{embeds: [success_embed]}
        })

        # kill actor
        GenServer.stop(MetadataEditor.via_tuple(thread_id), :normal)
        Logger.info("MetadataEditor for thread #{thread_id} terminated")

      _owner_id ->
        Interaction.create_response(interaction, %{
          type: 4,
          data: %{content: "Only the thread creator can publish.", flags: 64}
        })
    end
  end

  # handle select menu
  def handle_event(
        {:INTERACTION_CREATE,
         %Nostrum.Struct.Interaction{
           type: 3,
           data: %{custom_id: @select_menu_custom_id, values: [selected_value]},
           channel_id: thread_id,
           user: %{id: user_id}
         } = interaction, _ws_state}
      ) do
    # only owner gets to do this
    case MetadataEditor.get_owner(thread_id) do
      ^user_id ->
        label = Enum.find_value(@field_options, &(&1.value == selected_value && &1.label))

        Interaction.create_response(interaction, %{
          type: 4,
          data: %{content: "You selected **#{label}**. Please enter the value now."}
        })

        MetadataEditor.set_awaiting(thread_id, user_id, selected_value)
        Logger.info("Thread #{thread_id}: awaiting #{selected_value}")

      owner_id ->
        Interaction.create_response(interaction, %{
          type: 4,
          data: %{content: "Only the thread creator can edit metadata.", flags: 64}
        })

        Logger.warning("user #{user_id} tried to edit thread #{thread_id} (owner: #{owner_id})")
    end
  end

  # ignore other types
  def handle_event({:INTERACTION_CREATE, %Nostrum.Struct.Interaction{type: 3}, _ws_state}) do
    :ignore
  end

  # process input
  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           channel_id: thread_id,
           author: %{id: user_id},
           content: content
         }, _ws_state}
      ) do
    case MetadataEditor.get_awaiting(thread_id) do
      {^user_id, field} ->
        process_field_input(thread_id, field, content)
        MetadataEditor.clear_awaiting(thread_id)

      _ ->
        :ignore
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content do
      "!ping" -> Message.create(msg.channel_id, "pong")
      _ -> :ignore
    end
  end

  def handle_event({event_name, _, _}) do
    Logger.info("Unhandled event: #{event_name}")
  end

  def handle_event(_), do: :ok

  # utilities
  defp process_field_input(thread_id, field, raw_value) do
    value = parse_field_value(field, raw_value)

    case MetadataEditor.update_metadata(thread_id, field, value) do
      :ok ->
        Message.create(thread_id, "**#{String.capitalize(field)}** updated successfully.")
        Logger.info("Thread #{thread_id}: #{field} set to #{inspect(value)}")

      error ->
        Logger.error("Failed to update metadata: #{inspect(error)}")
        Message.create(thread_id, "Failed to update metadata. Please try again.")
    end
  end

  defp parse_field_value("title", val), do: val
  defp parse_field_value("date", val), do: val
  defp parse_field_value("updated", val), do: val
  defp parse_field_value("description", val), do: val
  defp parse_field_value("link", val), do: val
  defp parse_field_value("cover", val), do: val

  defp parse_field_value("tags", val),
    do: String.split(val, ",", trim: true) |> Enum.map(&String.trim/1)

  defp parse_field_value("categories", val),
    do: String.split(val, ",", trim: true) |> Enum.map(&String.trim/1)

  # we like options
  defp parse_field_value("sticky", val), do: val in ["true", "1", "yes"]
  defp parse_field_value("catalog", val), do: val in ["true", "1", "yes"]
  defp parse_field_value("subtitle", val), do: val in ["true", "1", "yes"]
  defp parse_field_value(_, val), do: val

  defp add_author(embed) do
    bot_user = Nostrum.Cache.Me.get()

    %{
      embed
      | author: %{name: bot_user.username, icon_url: Nostrum.Struct.User.avatar_url(bot_user)}
    }
  end
end
