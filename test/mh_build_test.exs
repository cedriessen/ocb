defmodule OcbTest do
  use ExUnit.Case
  alias Ocb.Options.Opts
  doctest Ocb

  test "argument parsing" do
    [
      {~w(), :help},
      {~w(--help), :help},
      {~w(-h), :help},
      {~w(-h -x), :help},
      {~w(-h -C), {
        %Opts{build: :all, deployment: :implicit, disable_checkstyle: true},
        ~w(install -Dcheckstyle.skip=true -DskipTests=false)
      }},
      {~w(-a), {
        %Opts{build: :all, deployment: :implicit},
        ~w(install -Dcheckstyle.skip=false -DskipTests=false)
      }},
      {~w(-s module1 module2), {
        %Opts{
          build: :selected, clean: false, deployment: :cache, disable_checkstyle: false,
          disable_test: false, make_dependents: false, modules: ["module1", "module2"], save_data: false},
        ~w(install -Dcheckstyle.skip=false -DskipTests=false),
      }},
      {~w(module1 -c), {
        %Opts{
          build: :selected, clean: true, deployment: :cache, disable_checkstyle: false,
          disable_test: false, make_dependents: false, modules: ["module1"], save_data: false},
        ~w(-Dcheckstyle.skip=false -DskipTests=false clean install)
      }},
      {~w(-s -T), {
        %Opts{build: :all, deployment: :implicit, disable_test: true, save_data: true},
        ~w(-Dcheckstyle.skip=false -DskipTests=true install)
      }},
      {~w(--fast-dev), {
        %Opts{
          build: :all, deployment: :implicit,
          disable_checkstyle: true, disable_test: true, save_data: true},
        ~w(-Dcheckstyle.skip=true -DskipTests=true install)
      }},
      {~w(--fast-dev module1 module2), {
        %Opts{
          build: :selected, clean: false, deployment: :cache, disable_checkstyle: true,
          disable_test: true, make_dependents: false, modules: ~w(module1 module2), save_data: false},
        ~w(-Dcheckstyle.skip=true -DskipTests=true install)
      }},
      {~w(--fast-dev -s -a), {
        %Opts{
          build: :all, clean: false, deployment: :implicit, disable_checkstyle: true,
          disable_test: true, make_dependents: false, save_data: true},
        ~w(-Dcheckstyle.skip=true -DskipTests=true install)
      }},
      {~w(-X module1), {
        %Opts{
          build: :selected, clean: false, deployment: :cache, disable_checkstyle: true,
          disable_test: true, make_dependents: false, modules: ["module1"], save_data: false},
        ~w(-Dcheckstyle.skip=true -DskipTests=true install)
      }},
      {~w(-X module1 -f), {
        %Opts{
          build: :selected, clean: false, deployment: :full, disable_checkstyle: true,
          disable_test: true, make_dependents: false, modules: ["module1"], save_data: true},
        ~w(-Dcheckstyle.skip=true -DskipTests=true install)
      }},
      {~w(-c -s -a --fast-dev), {
        %Opts{
          build: :all, clean: true, deployment: :implicit, disable_checkstyle: true,
          disable_test: true, save_data: true},
        ~w(-Dcheckstyle.skip=true -DskipTests=true clean install)
      }},
      {~w(--full-dev module1), {
        %Opts{
          build: :selected, deployment: :full,
          disable_test: true, disable_checkstyle: true, modules: ["module1"], save_data: true},
        ~w(-Dcheckstyle.skip=true -DskipTests=true install)
      }},
      {~w(-m), {
        %Opts{build: :modified, deployment: :cache},
        ~w(-Dcheckstyle.skip=false -DskipTests=false install)
      }},
      {~w(-m module1), {
        %Opts{build: :modified, deployment: :cache, modules: ["module1"]},
        ~w(-Dcheckstyle.skip=false -DskipTests=false install)
      }},
      {~w(-m -a), {
        %Opts{build: :all, deployment: :implicit},
        ~w(-Dcheckstyle.skip=false -DskipTests=false install)
      }}
    ]
    |> Enum.each(&check_parse_result/1)
  end

  defp check_parse_result({args, {expected_opts, expected_mvn_opts}}) do
    opts = parse_args(args)
    assert opts == expected_opts
    assert Enum.sort(Ocb.mk_maven_opts(opts)) == Enum.sort(expected_mvn_opts)
  end

  defp check_parse_result({args, expected_result}) do
    assert parse_args(args) == expected_result
  end

  defp parse_args(args) do
    IO.puts ~s(Checking args "#{Enum.join(args, " ")}")
    Ocb.Options.parse_args(args)
  end

  #
  #
  #

  test "build parser options" do
    a = Ocb.Options.build_parser_opts(
      [
        {:help, :h, :boolean},
        {:disable_test, :T, :boolean},
        {:bla, :string},
        {:blubb, :b, :integer}
      ]
    )
    assert a == [
      strict: [blubb: :integer, bla: :string, disable_test: :boolean, help: :boolean],
      aliases: [b: :blubb, T: :disable_test, h: :help]
    ]
  end
end
