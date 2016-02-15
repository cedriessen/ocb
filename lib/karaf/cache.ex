defmodule Karaf.Cache do
  @moduledoc """
  Operations on the Karaf bundle cache.

  Karaf's bundle cache on disk is called _bundle cache_.
  The cache that is maintained by this service is referred to as _cache_.

  Start the service with `start_link/0` and fill the cache
  with `find_artifacts/1` or `find_artifacts/2`.
  """

  @type artifacts :: %{String.t => String.t}


  @doc """
  Start the Karaf cache service for a deployment in `base_dir`.
  """
  def start_link(base_dir) do
    Agent.start_link(fn -> {Karaf.Files.cache_directory(base_dir), %{}} end, name: __MODULE__)
  end

  defp update_artifacts(artifacts) do
    Agent.update(__MODULE__, fn {cache_dir, _} -> {cache_dir, artifacts} end)
  end

  @doc """
  Return the JAR's path or `nil`.
  """
  def get_jar(artifact_name) do
    Agent.get(__MODULE__, fn {_, artifacts} -> Map.get(artifacts, artifact_name) end)
  end

  @doc """
  Get the artifacts contained in the bundle cache and
  return them as a map form the artifact's name to the jar file.

  Use `find_artifacts/0` to read the artifacts first.
  """
  @spec get_artifacts :: artifacts
  def get_artifacts do
    Agent.get(__MODULE__, &(elem(&1, 1)))
  end

  @doc """
  Get the cache directory or `:notfound` if it does not exist.
  """
  @spec get_cache_directory :: Path.t | :notfound
  def get_cache_directory do
    Agent.get(__MODULE__, &(elem(&1, 0)))
    |> Karaf.Files.exists_dir?
  end

  @doc """
  Check if the bundle cache exists.
  """
  def exists? do
    get_cache_directory != :notfound
  end

  @doc """
  Get the last modified time stamp of an artifact or `:distant_future` if it does not exit.

  See `Timex.Date.compare/2` for details about `:distant_future`.
  """
  def get_last_modified(artifact) do
    case artifact |> get_jar do
      nil ->
        :distant_future
      jar ->
        jar
        |> File.stat!
        |> Map.get(:mtime)
        |> Timex.Date.from
    end
  end

  @doc """
  Find all artifacts in the given Karaf deployment and make them
  accessible via the `get_jar/1` function.

  Return either `:ok` or `:notfound`, depending on whether the cache directory
  exists or not.
  """
  @spec find_artifacts :: {:ok, String.t} | :notfound
  def find_artifacts do
    case get_cache_directory do
      :notfound ->
        update_artifacts(%{})
        :notfound
      cache_dir ->
        artifacts = cache_dir
          |> DirWalker.stream
          |> Stream.filter(&(String.ends_with?(&1, ".info")))
          |> Stream.map(&read_artifact/1)
          |> Map.new
        update_artifacts(artifacts)
        {:ok, artifacts}
    end
  end

  @doc """
  Find all artifacts only if the cache is empty.

  See `find_artifacts/0` for further details.
  """
  @spec find_artifacts(:only_if_empts) :: {:ok, String.t} | :notfound
  def find_artifacts(:only_if_empty) do
    case get_artifacts do
      artifacts when map_size(artifacts) > 0 -> {:ok, get_artifacts}
      _ -> find_artifacts
    end
  end

  # Read the artifact's name from Karaf `bundle.info` file.
  #
  # Return a tuple `{artifact_name, jar}` or `{artifact_name, :none}`
  # for those bundles in the cache that do not have a jar.
  @spec read_artifact(String.t) :: {String.t, String.t} | {String.t, :none}
  defp read_artifact(info_file) do
    jar = info_file
      |> Path.dirname
      |> prepend(["version0.0", "bundle.jar"])
      |> Path.join
    artifact_name = info_file
      |> File.read!
      |> String.split("\n")
      |> Enum.at(1)
      |> extract_artifact_name()
    cond do
      File.exists?(jar) -> {artifact_name, jar}
      true -> {artifact_name, :none}
    end
  end

  # Except a string from Karaf's bundle info file
  # mvn:org.opencastproject/matterhorn-serviceregistry/2.1-SNAPSHOT
  defp extract_artifact_name(bundle_info_line) do
    bundle_info_line
    |> String.split("/")
    |> Enum.at(1)
  end

  @doc """
  Replace artifact `artifact_name` with the given jar.
  """
  @spec replace_artifact(String.t, Path.t) :: :ok | :notfound
  def replace_artifact(artifact_name, replacement_jar) do
    case get_jar(artifact_name) do
      nil ->
        :notfound
      jar ->
        File.rm!(jar)
        File.cp!(replacement_jar, jar)
    end
  end

  defp prepend(a, as), do: [a | as]
end
