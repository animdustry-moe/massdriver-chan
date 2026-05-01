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

defmodule Massdriver.Commands.RegisterSite do
  @behaviour Massdriver.Commands.Command

  @impl true
  def definition do
    %{
      name: "register_site",
      description: "Tell Massdriver-Chan to manage a website",
      # Permissions:
      # - Manage Server
      # - Manage Channels
      default_member_permissions: "48",
      options: [
        %{type: 3, name: "url", description: "URL to the site repo", required: true},
        %{type: 7, name: "channel", description: "Channel to bind", required: true},
        %{type: 6, name: "owner", description: "Site owner", required: true}
      ],
    }
  end

  @impl true
  def execute(interaction) do
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 4,
      data: %{content: "TODO"}
    })
  end
end
