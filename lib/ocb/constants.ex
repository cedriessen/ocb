defmodule Ocb.Constants do
  @moduledoc """
  Constants.
  """
  # The paths based on the current working directory cannot be
  # a module attribute since it yields
  # the directory where the executable is located rather than
  # the current work dir
  #
  # In order to be consistent, all paths etc. are gathered here.

  def work_dir, do: File.cwd!
  def build_target, do: Path.join(work_dir, "build")
  def save_data_directory, do: Path.join(System.tmp_dir!, "mh-build-tmp")
  def provision_script, do: "mh_build.provision"

  def karaf_executable, do: Karaf.Files.karaf_executable(build_target)
#  def karaf_data_directory, do: Karaf.Files.data_directory(build_target)
end
