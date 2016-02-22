defmodule Ocb.OptionsTest do
  use ExUnit.Case
  alias Ocb.Options.Opts

  doctest Ocb.Options

  @moduledoc false

  test "test get bash completion" do
    assert Ocb.Options.bash_complete == "--help --build_all --build_modified --full_deployment --disable_test --disable_checkstyle --make_dependents --clean --save_data --fast_dev --full_dev --fast_rebuild --resume --update"
  end
end
