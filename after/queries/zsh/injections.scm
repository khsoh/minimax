; extends

((heredoc_redirect
  (heredoc_body) @injection.content
  (heredoc_end) @injection.language)
 (#match? @injection.language "_[a-zA-Z0-9_-]+$")
 (#gsub! @injection.language "^.*_([a-zA-Z0-9_-]+)$" "%1"))

