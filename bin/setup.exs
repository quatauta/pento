#!/usr/bin/env elixir

defmodule Setup do
  @moduledoc false
  def project_root do
    Path.dirname(__DIR__)
  end

  def mise_install do
    cmd(~w(mise install))
  end

  def brew_bundle_install do
    if File.exists?("Brewfile") do
      cmd(~w(brew bundle install))
    end
  end

  def mix_local_hex do
    cmd(~w(mix local.hex --force --if-missing))
  end

  def mix_local_rebar do
    cmd(~w(mix local.rebar --force --if-missing))
  end

  def mix_archive_phx_new do
    cmd(~w(mix archive.install hex phx_new --force))
  end

  def mix_deps_get do
    cmd(~w(mix deps.get))
  end

  def mix_setup do
    cmd(~w(mix setup))
  end

  defp cmd([command | args], opts \\ []) do
    (["+"] ++ [command | args]) |> Enum.join(" ") |> IO.puts()
    System.cmd(command, args, [into: IO.stream()] ++ opts)
  end
end

File.cd!(Setup.project_root())

Setup.mise_install()
Setup.brew_bundle_install()
Setup.mix_local_hex()
Setup.mix_local_rebar()
Setup.mix_archive_phx_new()
Setup.mix_deps_get()
Setup.mix_setup()
