defmodule Massdriver.Database.Migrations.AlterReposUuidPrimaryKey do
  use Ecto.Migration

  # SQLite3 cannot alter primary keys in-place

  def up do
    drop table(:repos)

    create table(:repos, primary_key: false) do
      add :uuid,       :binary_id, primary_key: true, null: false
      add :guild_id,   :string,    null: false
      add :channel_id, :string,    null: false
      add :owner_id,   :string,    null: false
      add :enabled,    :boolean,   default: true

      timestamps()
    end
  end

  def down do
    drop table(:repos)

    create table(:repos) do
      add :uuid,       :uuid,   null: false
      add :guild_id,   :string, null: false
      add :channel_id, :string, null: false
      add :owner_id,   :string, null: false
      add :enabled,    :boolean, default: true

      timestamps()
    end

    create unique_index(:repos, [:uuid])
  end
end
