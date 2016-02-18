defmodule Ocb.Updater do
  @moduledoc """
  Update ocb from Github.
  """

  # cannot call git/1 from here
  @version System.cmd("git", ~w(log -1 --format=%h master))

  @home_dir File.cwd!

  @doc """
  Update ocb. Fetch new code from Github and compile it.

  Return either `:up_to_date` or the git hash of the new version.
  """
  def update do
    git(~w(fetch))
    case git(~w(log -1 --format=%h master..origin/master)) do
      "" ->
        :up_to_date

      git_hash ->
        git(~w(checkout master))
        git(~w(pull --prune))
        cmd("mix", ~w(escript.build))
        git_hash
    end
  end

  @doc "Get the current version."
  def version do
    {version, 0} = @version
    version |> String.strip
  end

  # Run git with the given arguments and return its output.
  defp git(args), do: cmd("git", args)

  # Run `cmd` in the fixed @home_dir, require the command to exit with 0.
  # Extract and return the command output.
  defp cmd(cmd, args) do
    {result, 0} = System.cmd(cmd, args, cd: @home_dir)
    result
  end
end
