defmodule Maven do
  alias Porcelain.Process, as: Proc

  @moduledoc """
  Run Maven.
  """

  defmodule Result do
    @moduledoc """
    Result of running Maven.
    """

    defstruct [:status, :exit, :filtered]

    @type t :: %__MODULE__{}
  end

  @mvn "mvn"

  @doc """
  Run maven with the given options `mvn_opts` and an optional filter function `filter`.
  """
  @spec mvn(list(String.t), (String.t -> list)) :: Maven.Result.t
  def mvn(mvn_opts, filter \\ &([&1])) do
    # it is important to :keep the result, otherwise
    # you cannot wait for it
    proc = Porcelain.spawn(@mvn, mvn_opts, out: :stream, result: :keep)
    filtered = proc.out
      |> Stream.map(&String.strip(&1))
      |> Stream.each(&IO.puts(&1))
      |> Stream.flat_map(&filter.(&1))
      |> Enum.into([])
    # await Maven to finish and transform the return code
    case Proc.await(proc) do
      {:ok, %Porcelain.Result{status: 0}} ->
        %Result{status: :ok, exit: nil, filtered: filtered}
      {:ok, %Porcelain.Result{status: exit}} ->
        %Result{status: :error, exit: exit, filtered: filtered}
      # crash otherwise
    end
  end

  ###
  # Filters & extractors
  ###

  def combine_filters(funs) do
    fn line -> funs |> Enum.flat_map(&(&1.(line))) end
  end

  @doc """
  Predefined filter function for `mvn/2` to extract messages about installed jars.
  Use the extractor function `extract_find_install_jar/1` to access findings.
  """
  def filter_find_install_jar(line) do
    line |> filter_generic(:installed, ~r/^\[INFO\] Installing (.*?\.jar) to .*?\.jar$/)
  end

  @doc """
  Extract all findings of the `filter_find_install_jar/1` filter from the `Maven.Result`.
  """
  def extract_find_install_jar(r = %Result{}) do
    r |> extract_generic(:installed)
  end

  def filter_resume_build(line) do
    line |> filter_generic(:resume, ~r/\[ERROR\]\s+mvn <goals> -rf :(.*)/)
  end

  def extract_resume_build(r = %Result{}) do
    r |> extract_generic(:resume)
  end

  ## Generic filter and extractor functions

  defp extract_generic(%Result{filtered: f}, key) do
    f |> Enum.flat_map(&(do_extract_generic(&1, key)))
  end

  defp do_extract_generic(filtered, key) do
    case filtered do
      {^key, found} -> [found]
      _ -> []
    end
  end

  # Regex shall contain one matching group
  defp filter_generic(line, key, regex) when is_atom(key) do
    match = Regex.run(regex, line)
    case match do
      nil -> []
      [_, found] -> [{key, found}]
    end
  end
end
