import Quill from "quill";
var TurndownService = require("turndown");

const WYSIWYG_editor = {
    mounted() {
        const view = this;
        const toolbarOptions = [
          ["bold", "italic", "underline", "strike"], // toggled buttons
          ["blockquote", "image", "link"],
          [{ list: "ordered" }, { list: "bullet" }, { list: "check" }],
          [{ header: [1, 2, 3, 4, 5, 6, false] }],
          ["clean"], // remove formatting button
        ];
        const editor = new Quill("#editor", {
          theme: "snow",
          modules: { toolbar: toolbarOptions },
        });

        editor.on("text-change", () => {
          view.pushEvent("content-text-change", { content: editor.getText() });
        });

        view.handleEvent("form_submitted", () => {
          const html = editor.container.firstChild.innerHTML;

          if (editor.getText() == "") {
            view.pushEvent("editor_content_markdown", { message: "" });
          } else {
            var turndownService = new TurndownService();
            const markdown = turndownService.turndown(html);
            view.pushEvent("editor_content_markdown", { message: markdown });
          }

      });


    }
}

export default WYSIWYG_editor
