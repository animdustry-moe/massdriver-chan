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

defmodule Massdriver.Commands do
  alias Massdriver.Commands
  @commands [
    Commands.RegisterSite
  ]

  def commands do
    Map.new(@commands, fn cmd ->
      {cmd.definition().name, cmd}
    end)
  end

  def register_commands do   # change defp -> def
    alias Nostrum.Api.ApplicationCommand

    Enum.each(@commands, fn cmd ->
      case Mix.env() do
        :prod -> ApplicationCommand.create_global_command(cmd.definition())
        _ ->
          guild_id = "DEV_GUILD_ID" |> System.get_env() |> String.to_integer()
          ApplicationCommand.create_guild_command(guild_id, cmd.definition())
      end
    end)
  end
end
