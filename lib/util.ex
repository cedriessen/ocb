defmodule Util do
  use Timex

  @moduledoc """
  General utility function.
  """

  @doc """
  Split `text` into lines and strip each.
  """
  def lines_stripped(text, newline \\ "\n") do
    text
    |> String.split(newline)
    |> Enum.map(&(String.strip(&1)))
  end

  @doc """
  Print `a` to the console and return it.
  Useful for debugging. It can be put anywhere using the pipe operator.
  """
  def debug(a) do
    IO.inspect(a)
    a
  end

  @doc """
  The pipe operator can only use local or remote calls and anonymous functions.
  Code like the one below does not work.

      "write me to a file"
      |> &File.write("myfile.txt", &1) <== does not compile

  In order to omit intermediary variables use the pipe function like this:

      "write me to a file"
      |> pipe(&File.write("myfile.text", &1)) <== compiles
  """
  def pipe(a, fun) do
    fun.(a)
  end

  @doc """
  Find the file that has been modified latest and return that date.
  """
  def get_last_modified(files) do
    files
    |> Enum.map(fn file -> File.stat!(file).mtime |> Date.from end)
    |> Enum.reduce(:distant_past, fn a, b -> if Date.compare(a, b) >= 0, do: a, else: b end)
  end
end
