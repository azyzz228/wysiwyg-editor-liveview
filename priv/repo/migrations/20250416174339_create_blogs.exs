defmodule Editor.Repo.Migrations.CreateBlogs do
  use Ecto.Migration

  def change do
    create table(:blogs) do
      add :title, :string
      add :content, :text
      add :meta, :map

      timestamps(type: :utc_datetime)
    end
  end
end
