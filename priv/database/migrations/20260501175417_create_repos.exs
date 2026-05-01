defmodule Massdriver.Database.Migrations.CreateRepos do
  use Ecto.Migration

  def change do
    create table(:repos) do
      add :uuid,       :uuid,    null: false
      add :guild_id,   :string,  null: false
      add :channel_id, :string,  null: false
      add :owner_id,   :string,  null: false
      add :enabled,    :boolean, default: true

      timestamps()
    end

    create unique_index(:repos, [:uuid])
  end
end
