return {
  source_dir = "src",
  include_dir = { "src/typedefs", "src/relay_systems", "src/", "packages/" },
  include = {
    "**/**.tl",
  },
  scripts = {
    build = {
      post = {
        "scripts/copy_lua_packages.lua",
      },
    },
  },
  build_dir = "build-lua",
  global_env_def = "ao",
  module_name = "amm",
  gen_target = "5.3",
  dont_prune = { "build-lua/systems", "build-lua/systems/**/*" }
}
