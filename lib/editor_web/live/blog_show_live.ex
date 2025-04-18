defmodule EditorWeb.BlogShowLive do
  use EditorWeb, :live_view
  alias Editor.Blogs
  require Logger

  def mount(%{"id" => id}, _, socket) do
    blog = Blogs.get_blog!(id)

    socket =
      socket
      |> assign(:blog, blog)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-12 w-1/2">
      <h1>{@blog.title}</h1>

      <div class="prose py-12">
        {MDEx.to_html!(@blog.content) |> Phoenix.HTML.raw()}
      </div>
    </div>
    """
  end
end
