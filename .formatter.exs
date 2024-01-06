[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Styler, Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{bin,config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    ".formatter.exs"
  ]
]
