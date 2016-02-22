defmodule Ocb.Options do
  @moduledoc """
  Handle command line options.
  """

  defmodule Opts do
    defstruct [
      modules: [],
      # :all | :modified | :selected
      build: nil,
      # :full | :cache | :implicit
      deployment: nil,
      disable_test: false,
      disable_checkstyle: false,
      make_dependents: false,
      clean: false,
      save_data: false,
      resume: false
    ]

    @type t :: %__MODULE__{}
  end

  @options [
    {:help, :h, :boolean},
    {:build_all, :a, :boolean},
    {:build_modified, :m, :boolean},
    {:full_deployment, :f, :boolean},
    {:disable_test, :T, :boolean},
    {:disable_checkstyle, :C, :boolean},
    {:make_dependents, :d, :boolean},
    {:clean, :c, :boolean},
    {:save_data, :s, :boolean},
    {:fast_dev, :X, :boolean},
    {:full_dev, :F, :boolean},
    {:fast_rebuild, :R, :boolean},
    {:resume, :r, :boolean},
    {:update, :boolean},
    {:bash_complete, :boolean}
  ]

  @combined_options [
    fast_dev: [disable_test: true, disable_checkstyle: true, build_modified: true, save_data: true],
    full_dev: [disable_test: true, disable_checkstyle: true, save_data: true, full_deployment: true],
    fast_rebuild: [disable_test: true, disable_checkstyle: true, full_build: true, clean: true]
  ]

  @doc """
  Parse the commandline args into a `Ocb.Options.Opts` struct.
  """
  @spec parse_args(list(String.t)) :: Ocb.Options.Opts.t
  def parse_args(args) do
    Agent.start_link(fn -> %Opts{} end, name: __MODULE__)
    Agent.update(__MODULE__, fn _ -> %Opts{} end)
    parser_opts = build_parser_opts(@options)
    case OptionParser.parse(args, parser_opts) do
      {[update: true], _, _} -> :update
      {[], [], _} -> :help
      {[help: true], _, _} -> :help
      {[bash_complete: true], _, _} -> :bash_complete
      {options, modules, _} ->
        opts = process_options(options, modules)
        Agent.update(__MODULE__, fn _ -> opts end)
        opts
    end
  end

  @doc """
  Return a list of available options for bash complete.
  """
  def bash_complete do
    @options
    |> Enum.flat_map(
         fn {:bash_complete, _} -> []
            opt -> ["--#{elem(opt, 0)}"]
         end)
    |> Enum.join(" ")
  end

  defp process_options(options, modules) do
    # process combined options
    options = process_combined_options(options)
    dep_mod_match = {
      Keyword.get(options, :full_deployment, false),
      Keyword.get(options, :build_all, false),
      Keyword.get(options, :build_modified, false),
      modules
    }
    {deployment, build, modules} = case dep_mod_match do
      {_, true, _, _} -> {:implicit, :all, []}
      {_, false, false, []} -> {:implicit, :all, []}
      {_, _, true, []} -> {:cache, :modified, []}
      {true, _, true, m} -> {:full, :modified, m}
      {_, _, true, m} -> {:cache, :modified, m}
      {true, false, _, m} -> {:full, :selected, m}
      {_, false, _, m} -> {:cache, :selected, m}
    end
    save_data =
      case {Keyword.get(options, :save_data, false), deployment} do
        {s, :full} -> s
        {s, :implicit} -> s
        {_, :cache} -> false
      end
    %Opts{
      modules: modules,
      build: build,
      deployment: deployment,
      disable_test: Keyword.get(options, :disable_test, false),
      disable_checkstyle: Keyword.get(options, :disable_checkstyle, false),
      make_dependents: Keyword.get(options, :make_dependents, false),
      clean: Keyword.get(options, :clean, false),
      save_data: save_data,
      resume: Keyword.get(options, :resume, false)
    }
  end

  defp process_combined_options(options) do
    @combined_options
    |> Enum.reduce(options, fn {opt, overrides}, acc ->
         cond do
           options[opt] -> Keyword.merge(acc, overrides)
           true -> acc
         end
       end)
  end

  @doc """
  Get the current options. Make sure to call `parse_args/1` first.
  """
  def get_opts do
    Agent.get(__MODULE__, &(&1))
  end

  @doc """
  A definition looks like this

      {long_name, short_name, type}
      {long_name, type}

  Returns a tuple containg the parse options for `OptionParser.parse/2`.
  """
  def build_parser_opts(definitions) do
    definitions
    |> Enum.reduce([], &do_build_parser_opts/2)
  end

  defp do_build_parser_opts(definition, parser_opts) do
    case definition do
      {long_opt, short_opt, type} ->
        parser_opts
          |> update_parser_opts(:strict, long_opt, type)
          |> update_parser_opts(:aliases, short_opt, long_opt)

      {long_opt, type} ->
        parser_opts
          |> update_parser_opts(:strict, long_opt, type)
    end
  end

  defp update_parser_opts(parser_opts, opt, key, value) do
    parser_opts |> Keyword.update(opt, [{key, value}], &Keyword.put(&1, key, value))
  end
end
