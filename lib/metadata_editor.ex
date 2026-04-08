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

defmodule Massdriver.MetadataEditor do
  use GenServer
  require Logger

  alias Massdriver.Metadata
  alias Nostrum.Api
  alias Massdriver.MetadataFormatter

  # might as well add these boilerplate

  # client api (registry lookup)
  def via_tuple(thread_id) do
    {:via, Registry, {Massdriver.ThreadRegistry, thread_id}}
  end

  def start_link(thread_id, owner_id) do
    GenServer.start_link(__MODULE__, {thread_id, owner_id}, name: via_tuple(thread_id))
  end

  def get_metadata(thread_id) do
    GenServer.call(via_tuple(thread_id), :get_metadata)
  end

  def update_metadata(thread_id, field, value) do
    GenServer.call(via_tuple(thread_id), {:update_metadata, field, value})
  end

  def set_message_id(thread_id, message_id) do
    GenServer.cast(via_tuple(thread_id), {:set_message_id, message_id})
  end

  def get_message_id(thread_id) do
    GenServer.call(via_tuple(thread_id), :get_message_id)
  end

  def set_awaiting(thread_id, user_id, field) do
    GenServer.cast(via_tuple(thread_id), {:set_awaiting, user_id, field})
  end

  def get_awaiting(thread_id) do
    GenServer.call(via_tuple(thread_id), :get_awaiting)
  end

  def clear_awaiting(thread_id) do
    GenServer.cast(via_tuple(thread_id), :clear_awaiting)
  end

  def get_owner(thread_id) do
    GenServer.call(via_tuple(thread_id), :get_owner)
  end

  # callbacks
  @impl true
  def init({thread_id, owner_id}) do
    Logger.info("Starting MetadataEditor for thread #{thread_id}")

    state = %{
      thread_id: thread_id,
      owner_id: owner_id,
      message_id: nil,
      metadata: %Metadata{},
      awaiting: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_metadata, _from, state) do
    {:reply, state.metadata, state}
  end

  def handle_call({:update_metadata, field, value}, _from, state) do
    field_atom = String.to_existing_atom(field)
    updated = %{state.metadata | field_atom => value}
    new_state = %{state | metadata: updated}

    # refresh embed if id exists
    if state.message_id do
      refresh_embed(state.thread_id, state.message_id, updated)
    end

    {:reply, :ok, new_state}
  end

  def handle_call(:get_awaiting, _from, state) do
    {:reply, state.awaiting, state}
  end

  def handle_call(:get_owner, _from, state) do
    {:reply, state.owner_id, state}
  end

  @impl true
  def handle_call(:get_message_id, _from, state) do
    {:reply, state.message_id, state}
  end

  @impl true
  def handle_cast({:set_message_id, message_id}, state) do
    {:noreply, %{state | message_id: message_id}}
  end

  def handle_cast({:set_awaiting, user_id, field}, state) do
    {:noreply, %{state | awaiting: {user_id, field}}}
  end

  def handle_cast(:clear_awaiting, state) do
    {:noreply, %{state | awaiting: nil}}
  end

  # render it again
  defp refresh_embed(thread_id, message_id, metadata) do
    embed = MetadataFormatter.build_embed(metadata)

    case Api.Message.edit(thread_id, message_id, embeds: [embed]) do
      {:ok, _} ->
        Logger.debug("Embed updated in thread #{thread_id}")

      {:error, error} ->
        Logger.error("Failed to edit embed in thread #{thread_id}: #{inspect(error)}")
    end
  end
end
