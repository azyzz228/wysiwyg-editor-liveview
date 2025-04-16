defmodule Editor.BlogsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Editor.Blogs` context.
  """

  @doc """
  Generate a blog.
  """
  def blog_fixture(attrs \\ %{}) do
    {:ok, blog} =
      attrs
      |> Enum.into(%{
        content: "some content",
        title: "some title"
      })
      |> Editor.Blogs.create_blog()

    blog
  end
end
