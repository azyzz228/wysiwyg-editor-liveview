defmodule Editor.Blogs.Blog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blogs" do
    field :title, :string
    field :content, :string
    field :meta, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blog, attrs) do
    blog
    |> cast(attrs, [:title, :content, :meta])
    |> validate_required([:title, :content])
    |> validate_length(:content, min: 10)
  end
end
