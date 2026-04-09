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

defmodule Massdriver do
  @moduledoc """
  starting point of the app
  """

  use Supervisor

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    bot_options = %{
      name: :massdriver,
      consumer: Massdriver.Consumer,
      intents: :all,
      request_guild_members: true,
      wrapped_token: fn -> System.fetch_env!("BOT_TOKEN") end
    }

    children = [
      {Nostrum.Bot, bot_options},
      {Registry, keys: :unique, name: Massdriver.ThreadRegistry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start(_type, _args) do
    start_link()
  end
end
