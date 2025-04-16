defmodule Editor.Repo.Migrations.CreateBlogs do
  use Ecto.Migration

  def change do
    create table(:blogs) do
      add :title, :string
      add :content, :text

      timestamps(type: :utc_datetime)
    end
  end
end
