defmodule Karaf.Files do
  @moduledoc """
  Knowledge about the directory structure of a Karaf deployment and its files.
  """

  def data_directory(base_dir), do: Path.join(base_dir, "data")

  @spec data_directory(Path.t) :: Path.t | :notfound
  def data_directory?(base_dir) do
    base_dir |> data_directory |> exists_dir?
  end

  def cache_directory(base_dir), do: Path.join([base_dir, "data", "cache"])

  @spec cache_directory(Path.t) :: Path.t | :notfound
  def cache_directory?(base_dir) do
    base_dir |> cache_directory |> exists_dir?
  end

  def karaf_executable(base_dir), do: Path.join([base_dir, "bin", "karaf"])

  def exists_dir?(dir) do
    if File.dir?(dir), do: dir, else: :notfound
  end
end
