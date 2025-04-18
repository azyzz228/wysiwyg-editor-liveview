defmodule EditorWeb.BlogCreateLive do
  use EditorWeb, :live_view
  alias Editor.Blogs
  alias Editor.Blogs.Blog
  require Logger
  alias Editor.S3Config

  def mount(_, _, socket) do
    socket =
      socket
      |> assign(:form, to_form(Blogs.change_blog(%Blog{})))
      |> assign(:disabled?, false)
      |> assign(:loading?, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-12 w-1/2">
      <.form for={@form} id="upload-form" phx-submit="save" phx-change="validate" phx-throttle="300">
        <.input
          field={@form[:title]}
          type="text"
          label="Title"
          placeholder="Confucius institute in NYC"
        />

        <div class="mt-12" phx-update="ignore" id="editor-container">
          <div phx-update="ignore" phx-hook="WYSIWYG_editor" id="editor">
            <h2>Your epic story goes in here...</h2>

            <p>this editor supports text styles: bold, italic, underline</p>
          </div>
        </div>

        <div
          :if={not (@form.source.errors[:content] |> is_nil())}
          class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden"
        >
          <.icon name="hero-exclamation-circle-solid" class="mt-0.5 h-5 w-5 flex-none" />
          {@form.source.errors[:content] |> handle_error()}
        </div>

        <div class="my-8">
          <button
            :if={@form.source.valid? and not @disabled?}
            class="rounded-md bg-emerald-900 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm"
            type="submit"
          >
            Submit
          </button>

          <button
            :if={not @form.source.valid?}
            class="rounded-md opacity-30 bg-emerald-900 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm"
            disabled
          >
            Submit
          </button>

          <p :if={@loading?}>Loading...</p>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"blog" => params}, socket) do
    params = socket.assigns.form.source.params |> Map.merge(params)

    changeset = Blog.changeset(%Blog{}, params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", _params, socket) do
    socket =
      socket
      |> assign(:disabled?, true)
      |> assign(:loading?, true)
      |> push_event("form_submitted", %{})

    {:noreply, socket}
  end

  def handle_event("content-text-change", %{"content" => content}, socket) do
    content = content |> String.replace("\n", "") |> String.replace("-", "")

    params =
      socket.assigns.form.source.params
      |> Map.put("content", content)

    changeset = Blog.changeset(%Blog{}, params)

    socket =
      socket
      |> assign(form: to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("editor_content_markdown", %{"message" => msg}, socket) do
    alias ExAws.S3

    {msg, files} =
      extract_base64_images(msg)

    params =
      socket.assigns.form.source.params
      |> Map.put("content", msg)
      |> Map.put("meta", %{
        "files" => files
      })

    case Editor.Blogs.create_blog(params) do
      {:ok, %Blog{id: id} = blog} ->
        dbg(blog)
        {:noreply,
         socket
         |> push_navigate(to: "/blogs/#{id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        # diplay errors
        socket =
          socket
          |> assign(form: to_form(changeset, action: :validate))
          |> assign(:disabled?, false)

        {:noreply, socket}
    end
  end

  def extract_base64_images(markdown_text) do
    regex = ~r/!\[(.*?)\]\(data:(image\/[a-z]+);base64,([a-zA-Z0-9+\/=]+)\)/

    alias ExAws.S3

    {transformed_markdown, files} =
      Regex.scan(regex, markdown_text)
      |> Enum.reduce({markdown_text, []}, fn [match, alt_text, mime_type, base64_content],
                                             {acc_markdown, acc_files} ->
        extension = mime_type |> MIME.extensions() |> List.first()

        file = base64_content |> Base.decode64!()
        uuid = Ecto.UUID.generate()
        key = "#{S3Config.folder()}/#{uuid}.#{extension}"

        {:ok, url} =
          S3.put_object(S3Config.bucket(), key, file, [
            {:acl, :public_read},
            {:content_type, extension}
          ])
          |> ExAws.request()
          |> case do
            {:ok, _request} ->
              {:ok, S3Config.cdn_host() <> key}

            otherwise ->
              Logger.error(inspect(otherwise, pretty: true))
              {:error, :something_went_wrong}
          end

        file_meta = %{
          "origin_url" => S3Config.host() <> key,
          "cdn_url" => S3Config.cdn_host() <> key,
          "inserted_at" => DateTime.utc_now(),
          "uuid" => uuid,
          "extension" => extension,
          "alt_text" => alt_text
        }

        new_image_md = "![#{alt_text}](#{url})"

        acc =
          String.replace(acc_markdown, match, new_image_md, global: false)

        {acc, [file_meta | acc_files]}
      end)

    {transformed_markdown, files}
  end

  def handle_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(EditorWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(EditorWeb.Gettext, "errors", msg, opts)
    end
  end
end
