import Config

config :git_ops,
  mix_project: Mix.Project.get!(),
  changelog_file: "CHANGELOG.md",
  repository_url: "https://harton.dev/james/ina219",
  manage_mix_version?: true,
  manage_readme_version: "README.md",
  version_tag_prefix: "v"
