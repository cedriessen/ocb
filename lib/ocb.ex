defmodule Ocb do
  import ColorPrint
  alias Ocb.Constants, as: Const
  alias Ocb.Options, as: Opt

  @build_error %Maven.Result{exit: 1, status: :error}

  @moduledoc """
  `ocb` does a local, Karaf based deployment of Opencast Matterhorn.

  ## Usage

  Always run `ocb` from the root of you work directory.

      ocb                             - print this help
      ocb module1 module2 ...         - build and deploy only the given modules

  ## Single Options

      -h, --help                      - print this help
      -a, --build-all                 - build all modules including
                                        a full deployment
      -m, --build-modified            - build all modified modules
                                        (based on git status)
      -f, --full-deployment           - do a full deployment (see below)
      -C, --disable-checkstyle        - disable checkstyle
      -T, --disable-test              - disable testing
      -d, --make-dependents           - make dependents of the given modules
      -c, --clean                     - do a clean install
      -r, --resume                    - resume the last build
      -s, --save-data                 - keep Karaf's data/ directory
                                        between deployments

  ## Combined Options

  Please note that combined options take precedence over single ones.

      -X, --fast-dev                  - fast development mode
                                        Equal to -C -T -s -m
      -F, --full-dev                  - full development mode
                                        Equal to -C -T -s -m -f
      -R, --fast-rebuild              - do a fast rebuild
                                        Equal to -C -T -c -a

  ## Provisioning

  To automatically provision a deployment, place an executable file called
  `#{Const.provision_script}` into the directory where you run `ocb` from.
  It will then run after a successful deployment.

  ## Full Deployment vs Cache Deployment

  A full deployment is done by a maven build of the assemblies.
  It creates a whole new deployment erasing any previous data.
  In order to save existing data use the `-s` flag.
  A cache deployment on the other hand, only updates the respective bundles
  in Karaf's bundle cache.

  ## Resuming a Build

  In case the last build crashed, a build can be resumed by passing
  the `-r` option.
  Where to resume from is stored in the file `#{Const.ocb_state_file}`.

  ## Examples

  After an initial `ocb -a` it will most often be enough to issue
  a `ocb -X` to only update modified bundles.

  To force the rebuild of a particular module, e.g. matterhorn-common
  use `ocb modules/matterhorn-common`.
  """

  # main function is required for escript to create a standalone executable
  def main(args) do
    {time, exit} = :timer.tc(&do_main/1, [args])
    info "Build took #{:io_lib.format("~.2f", [time / 1_000_000])} sec."
    System.halt(exit)
  end

  defp do_main(args) do
    args |> Opt.parse_args |> process
  end

  ###
  # First stage of argument handling
  ###

  @doc """
  Return an exit code.
  """
  @spec process(:help | Opt.Opts.t) :: non_neg_integer
  def process(args)

  def process(:help) do
    IO.ANSI.Docs.print_heading "OCB"
    IO.ANSI.Docs.print @moduledoc
    0
  end

  def process(opts) do
    info "Build opts", block: show_opts(opts)
    Karaf.Cache.start_link(Const.build_target)
    opts.save_data && save_data
    # run the build
    result = build(opts)
    # handle the result
    exit = case result do
      %Maven.Result{status: :ok} ->
        case opts.deployment do
          :cache ->
            result
            |> Maven.extract_find_install_jar
            |> deployment_cache
          :full -> deployment_full
          :implicit -> nil
        end
        post_deployment
        remove_resume_build_info
        0

      r = %Maven.Result{exit: exit} when is_integer(exit) ->
        case Maven.extract_resume_build(r) do
          [resume] ->
            info "The build may be resumed from #{resume}"
            save_resume_build_info(resume)
          _ ->
            nil
        end
        exit
    end
    opts.save_data && restore_data
    exit
  end

  @doc """
  Run some post deployment tasks.
  """
  def post_deployment do
    info "Make Karaf start script executable."
    :ok = File.chmod(Const.karaf_executable, 0o755)
    #
    case File.stat(Const.provision_script) do
      {:ok, %File.Stat{type: :regular}} ->
        info "Provising deployment with #{Const.provision_script}"
        {_, 0} = System.cmd(Const.provision_script, [])
      _ -> nil
    end
  end

  defp save_resume_build_info(artifact) do
    File.write!(Const.ocb_state_file, artifact)
  end

  defp remove_resume_build_info do
    File.rm(Const.ocb_state_file)
  end

  ###
  # Build
  ###

  @doc """
  Returns either `:ok` or `{:error, exit_code}`.
  """
  @spec build(Opt.Opts.t) :: Maven.Result.t
  def build(opts)

  @doc """
  Run a full build.
  """
  def build(opts = %Opt.Opts{build: :all}) do
    info "Run a full build."
    build_all(opts)
  end

  @doc """
  Build only modified modules and modules that have been given on the commandline.
  """
  @module_regex ~r"(?<module>modules/(\w|-|_)*).*"
  @file_regex ~r"M\s(?<file>modules/.*)"
  def build(opts = %Opt.Opts{build: :modified}) do
    info "Build modified modules."
    case Ocb.Modules.find_modules_to_update do
      :nocache ->
        warn """
        Cannot find a bundle cache directory.
        It seems that either no deployment happened or Karaf has not been started yet to fill the bundle cache.
        You may
        - run a full build
        - start Karaf
        """
        @build_error

      modified_modules ->
        case modified_modules ++ opts.modules do
          [] ->
            warn "No modified modules."
            @build_error
          modules ->
            infob modules
            build_modules(Map.put(opts, :modules, modules))
        end
    end
  end

  @doc """
  Build only modules that have been selected on the commandline.
  """
  def build(opts) do
    info "Build modules #{join opts.modules, sep: ", "}#{if opts.make_dependents, do: " and all dependent ones"}."
    build_modules(opts)
  end

  def build_modules(opts) do
    build_with_maven(opts, ~w(--projects #{join opts.modules, sep: ","}))
  end

  def build_all(opts) do
    build_with_maven(opts, ~w(-DdeployTo=#{Const.build_target} -Pmodules,entwine))
  end

  # Run a maven build. Transform opts into maven options and add them to the list of mvn_opts.
  @spec build_with_maven(Ocb.Options.Opts.t, list(String.t)) :: Maven.Result.t
  defp build_with_maven(opts, mvn_opts) do
    opts
    |> mk_maven_opts
    |> Enum.concat(mvn_opts)
    |> mvn
  end

  ###
  # Deployment
  ###

  def deployment_full do
    ~w(clean install -rf :opencast-karaf-features -DdeployTo=#{Const.build_target} -Pmodules,entwine)
    |> mvn
  end

  @doc """
  Deploy the list of jars to Karaf's bundle cache located
  in the given data directory.
  """
  @spec deployment_cache(list(Path.t)) :: any
  def deployment_cache(jars) do
    info "Direct deployment to Karaf cache directory in #{Karaf.Cache.get_cache_directory}"
    case Karaf.Cache.find_artifacts(:only_if_empty) do
      {:ok, _} ->
        for jar <- jars do
          artifact_name = extract_artifact_name_from_jar_path(jar)
          infob artifact_name
          Karaf.Cache.replace_artifact(artifact_name, jar)
        end

      :notfound ->
        warn "The bundle cache directory does not exist"
    end
  end

  # Extract the artifact's name from a path to an artifact jar.
  @spec extract_artifact_name_from_jar_path(Path.t) :: String.t
  defp extract_artifact_name_from_jar_path(path) do
    [artifact] = Path.split(path)
      |> Stream.drop_while(&(&1 != "modules"))
      |> Stream.drop(1)
      |> Enum.take(1)
    artifact
  end

  ###
  # Save and restore the data directory
  ###

  def save_data do
    data_directory = Karaf.Files.data_directory(Const.build_target)
    info ~s(Stash data "#{data_directory}" in "#{Const.save_data_directory}")
    case {File.dir?(Const.save_data_directory), File.dir?(data_directory)} do
      {_, true} ->
        # regular operation
        File.rm_rf(Const.save_data_directory)
        :ok = File.rename(data_directory, Const.save_data_directory)
        # remove the cache dir since we do not want to keep it between deployments!
        File.rm_rf(Const.save_data_directory <> "cache")
      {true, false} ->
        warn "It seems that the last build crashed. A stashed data directory alread exists."
      {false, false} ->
        warn "There is neither a data directory in the Karaf deployment nor in the stash."
    end
  end

  def restore_data do
    info "Restore stashed data."
    if File.dir?(Const.save_data_directory) do
      data_directory = Karaf.Files.data_directory(Const.build_target)
      File.rm_rf(data_directory)
      :ok = File.rename(Const.save_data_directory, data_directory)
    else
      warn "No data has been stashed."
    end
  end

  @spec mvn(list) :: Maven.Result.t
  defp mvn(mvn_opts) do
    info "Run mvn #{join mvn_opts}"
    filter =
      [&Maven.filter_find_install_jar/1,
       &Maven.filter_resume_build/1]
      |> Maven.combine_filters
    case Maven.mvn(mvn_opts, filter) do
      r = %Maven.Result{status: :error, exit: exit} ->
        error "Maven exited with #{exit}."
        r
      ok ->
        ok
    end
  end

  ###
  # Create Maven options
  ###

  def mk_maven_opts(opts) do
    opts
    |> Map.to_list
    |> Enum.flat_map(&to_mvn_opt/1)
  end

  defp to_mvn_opt({:disable_test, bool}), do: ~w(-DskipTests=#{bool})
  defp to_mvn_opt({:disable_checkstyle, bool}), do: ~w(-Dcheckstyle.skip=#{bool})
  defp to_mvn_opt({:clean, true}), do: ~w(clean install)
  defp to_mvn_opt({:clean, false}), do: ~w(install)
  defp to_mvn_opt({:make_dependents, true}), do: ~w(--also-make-dependents)
  defp to_mvn_opt({:resume, true}) do
    case File.read(".ocb") do
      {:ok, resume} ->
        info "Resuming build from #{resume}"
        ~w(-rf :#{resume})
      _ ->
        warn "Cannot resume"
        []
    end
  end
  defp to_mvn_opt(_), do: []

  #
  #
  #

  defp show_opts(opts) do
    opts
    |> Map.delete(:__struct__)
    |> Map.to_list
    |> Enum.map(fn
         {k, []} -> "#{k}: -"
         {k, v} -> "#{k}: #{v}"
       end)
  end
end
