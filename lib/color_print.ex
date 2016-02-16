defmodule ColorPrint do
  import IO.ANSI

  @moduledoc """
  Colorful console output
  """

  def join(strings, opts \\ []) when is_list(strings) do
    strings |> Enum.join(Keyword.get(opts, :sep, " "))
  end

  def info(string, opts \\ []) do
    IO.puts(format([:blue, :bright, "==> ", :reset, :bright, string], true))
    with block = [_ | _] <- opts[:block] do
      block
      |> Enum.each(&infob/1)
    end
  end

  def infob(strings) when is_list(strings) do
    strings |> Enum.each(&infob/1)
  end

  def infob(string) do
    IO.puts("  " <> string)
  end

  def warn(string) do
    IO.puts(format([:yellow, :bright, "Warning: ", :reset, :bright, string], true))
  end

  def error(string) do
    IO.puts(format([:red, :bright, "Error: ", :reset, :bright, string], true))
  end
end
