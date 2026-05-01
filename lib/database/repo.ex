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

defmodule Massdriver.Repo do
  use Ecto.Schema

  @primary_key {:uuid, :binary_id, autogenerate: true}

  schema "repos" do
    field :guild_id,   :string
    field :channel_id, :string
    field :owner_id,   :string
    field :enabled,    :boolean, default: true

    timestamps()
  end
end
