defmodule Ocb.Updater do
  @moduledoc """
  Update ocb from Github.
  """

  @home_dir File.cwd!

  @doc """
  Update ocb. Fetch new code from Github and compile it.
  """
  def update do
    git(~w(fetch))
    case git(~w(log -1 --format=%h master..origin/master)) do
      "" ->
        {:ok, :up_to_date}
      git_hash ->
        git(~w(checkout master))
        git(~w(pull --prune))
        {_, 0} = cmd("mix", ~w(escript.build))
        {:ok, git_hash}
    end
  end

  # run git with the given arguments
  defp git(args), do: cmd("git", args)

  # run `cmd` in the fixed @home_dir
  defp cmd(cmd, args) do
    {result, 0} = System.cmd(cmd, args, cd: @home_dir)
    result
  end
end
