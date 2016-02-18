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
        {_, 0} = cmd("mix", ~w(escript.build))
        git_hash
    end
  end

  @doc "Get the current version."
  def version do
    {version, 0} = @version
    version |> String.strip
  end

  # run git with the given arguments
  defp git(args), do: cmd("git", args)

  # run `cmd` in the fixed @home_dir
  defp cmd(cmd, args) do
    {result, 0} = System.cmd(cmd, args, cd: @home_dir)
    result
  end
end
