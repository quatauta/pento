#!/usr/bin/env elixir

defmodule Setup do
  @moduledoc false

  def project_root do
    Path.dirname(__DIR__)
  end

  def mise_update do
    ".tool-versions"
    |> File.stream!()
    |> Stream.map(&Regex.replace(~r/\s.*/, &1, ""))
    |> Enum.to_list()
    |> Enum.each(fn tool ->
      cmd(~w(mise use --pin #{tool}))
    end)
  end

  def brew_bundle_install do
    if File.exists?("Brewfile") do
      cmd(~w(brew bundle install))
    end
  end

  def dockerfile do
    elixir_version = "elixir" |> mise_tool_version() |> String.replace(~r/-.*/, "")
    erlang_version = mise_tool_version("erlang")
    image_tags = docker_hub_image_tags("hexpm/elixir", "#{elixir_version}-erlang-#{erlang_version}-alpine")
    alpine_version = image_tags |> Enum.sort() |> List.last() |> String.replace(~r/.*-alpine-/, "")

    path = "Dockerfile"
    elixir_regex = ~r/(ARG ELIXIR_VERSION)=["']?[0-9.]+["']?/
    erlang_regex = ~r/(ARG ERLANG_VERSION)=["']?[0-9.]+["']?/
    alpine_regex = ~r/(ARG ALPINE_VERSION)=["']?[0-9.]+["']?/
    elixir_replacement = "\\1=\"#{elixir_version}\""
    erlang_replacement = "\\1=\"#{erlang_version}\""
    alpine_replacement = "\\1=\"#{alpine_version}\""

    content = File.read!(path)
    updated_content = Regex.replace(elixir_regex, content, elixir_replacement)
    updated_content = Regex.replace(erlang_regex, updated_content, erlang_replacement)
    updated_content = Regex.replace(alpine_regex, updated_content, alpine_replacement)

    if content != updated_content do
      IO.puts("+ update Dockerfile to Elixir #{elixir_version}, Erlang #{erlang_version}, Alpine #{alpine_version}")
      File.write!(path, updated_content)
    end
  end

  def esbuild do
    ensure_config_section_version("esbuild", github_latest_release("evanw/esbuild"))
  end

  def tailwind do
    ensure_config_section_version("tailwind", github_latest_release("tailwindlabs/tailwindcss"))
  end

  def mix_local_hex do
    cmd(~w(mix local.hex --force --if-missing))
  end

  def mix_local_rebar do
    cmd(~w(mix local.rebar --force --if-missing))
  end

  def mix_deps_update do
    cmd(~w(mix deps.update --all))
    cmd(~w(mix deps.clean --unused --unlock))
  end

  def mix_setup do
    cmd(~w(mix setup))
  end

  defp mise_tool_version(tool_name) do
    ".tool-versions"
    |> File.stream!()
    |> Stream.filter(fn x -> String.match?(x, ~r{^#{tool_name} [0-9]}) end)
    |> Stream.flat_map(&(&1 |> String.trim() |> String.split() |> Enum.take(-1)))
    |> Enum.to_list()
    |> Enum.fetch!(0)
  end

  defp cmd([command | args], opts \\ []) do
    (["+"] ++ [command | args]) |> Enum.join(" ") |> IO.puts()
    System.cmd(command, args, [into: IO.stream()] ++ opts)
  end

  defp docker_hub_image_tags(repository, name_pattern) do
    Mix.install([:jason])
    :inets.start()
    :ssl.start()

    url = "https://hub.docker.com/v2/repositories/#{repository}/tags/?name=#{name_pattern}"
    headers = [{~c"accept", ~c"application/json"}, {~c"user-agent", ~c"Erlang httpc"}]

    {:ok, {_status_line, _header, response}} = :httpc.request(:get, {url, headers}, [], [])
    results = Jason.decode!(response)
    Enum.map(results["results"], &Map.fetch!(&1, "name"))
  end

  defp ensure_config_section_version(section, latest_version) do
    path = "config/config.exs"
    regex = ~r/(config :#{section},\n\s*version:\s*)"[^"]+"/
    replacement = "\\1\"#{latest_version}\""

    content = File.read!(path)
    updated_content = Regex.replace(regex, content, replacement)

    if content != updated_content do
      IO.puts("+ update #{section} to #{latest_version}")
      File.write!(path, updated_content)
    end
  end

  defp github_latest_release(repository) do
    Mix.install([:jason])
    :inets.start()
    :ssl.start()

    url = "https://api.github.com/repos/#{repository}/releases/latest"
    headers = [{~c"accept", ~c"application/json"}, {~c"user-agent", ~c"Erlang httpc"}]

    {:ok, {_status_line, _header, response}} = :httpc.request(:get, {url, headers}, [], [])
    release = Jason.decode!(response)
    release_name = release["name"]
    release_version = Regex.replace(~r/^[^0-9]+/, release_name, "")
    release_version
  end
end

File.cd!(Setup.project_root())

Setup.mise_update()
Setup.brew_bundle_install()
Setup.dockerfile()
Setup.mix_local_hex()
Setup.mix_local_rebar()
Setup.mix_deps_update()
Setup.esbuild()
Setup.tailwind()
Setup.mix_setup()
