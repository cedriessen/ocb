defmodule Ocb.Modules do
  use Timex

  @moduledoc """
  Functions dealing with Opencast modules.
  """

  @module_name_regex ~r"^(?<module>modules/(\w|-|_)+)"

  @doc """
  Find the last modified file within a module.
  Return a list of tuples `{module_name, last_modified}`.
  """
  def get_last_modified(work_dir) do
    {result, 0} = System.cmd("git", ~w(ls-files), cd: work_dir)
    # group modified files by module
    result
    |> Util.lines_stripped
    |> Stream.flat_map(fn file ->
         case Regex.named_captures(@module_name_regex, file) do
           %{"module" => module} ->
             [{module, Path.join(work_dir, file)}]
           _ ->
             []
         end
       end)
    |> Enum.group_by(&(elem(&1, 0)))
    |> Enum.map(fn {module, files} ->
         lm = files
           |> Enum.map(&(elem(&1, 1)))
           |> Util.get_last_modified
         {module, lm}
       end)
  end

  @doc """
  Use the current work dir. See `get_last_modified/1` for details.
  """
  def get_last_modified do
    get_last_modified(Ocb.Constants.work_dir)
  end

  @doc """
  Get a module's artifact name.
  Example: `modules/matterhorn-common` -> `matterhorn-common`
  """
  def get_artifact_name("modules/" <> artifact) do
    # make sure the artifact name does not contain any path separators
    case Path.split(artifact) do
      [artifact] -> artifact
    end
  end

  @doc """
  Find all modules that have been modified in the work directory and need a redeployment
  to the Karaf cache. Make sure to initialize `Karaf.Cache` prior to calling this method.

  Return a list of modules or `:nocache` if there is no Karaf bundle cache.
  This may happen if there has been no initial deployment.

  This function is based on `get_last_modified/0`.
  """
  @spec find_modules_to_update :: list(String.t) | :nocache
  def find_modules_to_update do
    case Karaf.Cache.find_artifacts(:only_if_empty) do
      {:ok, _} ->
        get_last_modified
        |> Enum.flat_map(&do_find_modules_to_update/1)

      :notfound ->
        :nocache
    end
  end

  defp do_find_modules_to_update({module, last_modified}) do
    modified_in_cache = module
      |> get_artifact_name
      |> Karaf.Cache.get_last_modified
    case Date.compare(last_modified, modified_in_cache) do
      1 -> [module]
      _ -> []
    end
  end
end
