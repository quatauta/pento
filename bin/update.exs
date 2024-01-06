#!/usr/bin/env elixir

defmodule Setup do
  @moduledoc false
  def project_root do
    Path.dirname(__DIR__)
  end

  def asdf_update do
    ".tool-versions"
    |> File.stream!()
    |> Stream.map(&Regex.replace(~r{\s.*}, &1, ""))
    |> Enum.to_list()
    |> Enum.each(fn tool ->
      cmd(~w(asdf install #{tool} latest))
      cmd(~w(asdf local #{tool} latest))
    end)
  end

  def brew_bundle_install do
    if File.exists?("Brewfile") do
      cmd(~w(brew bundle install))
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

  defp cmd([command | args], opts \\ []) do
    (["+"] ++ [command | args]) |> Enum.join(" ") |> IO.puts()
    System.cmd(command, args, [into: IO.stream()] ++ opts)
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

Setup.asdf_update()
Setup.brew_bundle_install()
Setup.mix_local_hex()
Setup.mix_local_rebar()
Setup.mix_deps_update()
Setup.esbuild()
Setup.tailwind()
Setup.mix_setup()
