defmodule FactEngineTest do
  use ExUnit.Case, async: false

  describe "test file content parsing" do
    test "bad action" do
      assert FactEngine.run("test/test_files/action.txt", "") ==
               {:error, ["WRONG is an invalid action"]}
    end

    test "bad commas" do
      assert FactEngine.run("test/test_files/commas.txt", "") ==
               {:error, ["(lucy,) has too many commas."]}
    end

    test "empty arguments" do
      assert FactEngine.run("test/test_files/empty_arguments.txt", "") ==
               {:error, ["() is empty."]}
    end

    test "missing fields" do
      assert FactEngine.run("test/test_files/missing_fields.txt", "") ==
               {:error, ["INPUT (lucy) is malformed."]}
    end

    test "empty argument field" do
      assert FactEngine.run("test/test_files/empty_argument_string.txt", "") ==
               {:error, ["(tom, ,grant) contains a field that is an empty string."]}
    end

    test "bad statement" do
      assert FactEngine.run("test/test_files/statement.txt", "") ==
               {:error,
                ["h3ros should only contain lowercase alphabetic letters and underscores"]}
    end

    test "argument contains non alphanumeric" do
      assert FactEngine.run("test/test_files/alphanumeric_arguments.txt", "") ==
               {:error, ["$pat,cat should only contain alphanumeric and commas"]}
    end
  end

  describe "test processing files" do
    test "file #1" do
      read_file_path = "examples/1/in.txt"
      existing_out_file_path = "examples/1/out.txt"
      test_write_file_path = "examples/1/test_out.txt"

      :ok = FactEngine.State.start()
      FactEngine.run(read_file_path, test_write_file_path)

      assert File.read!(existing_out_file_path) == File.read!(test_write_file_path)

      File.rm!(test_write_file_path)
      :ok = FactEngine.State.stop()
    end

    test "file #2" do
      read_file_path = "examples/2/in.txt"
      existing_out_file_path = "examples/2/out.txt"
      test_write_file_path = "examples/2/test_out.txt"

      :ok = FactEngine.State.start()
      FactEngine.run(read_file_path, test_write_file_path)

      assert File.read!(existing_out_file_path) == File.read!(test_write_file_path)

      File.rm!(test_write_file_path)
      :ok = FactEngine.State.stop()
    end

    test "file #3" do
      read_file_path = "examples/3/in.txt"
      existing_out_file_path = "examples/3/out.txt"
      test_write_file_path = "examples/3/test_out.txt"

      :ok = FactEngine.State.start()
      FactEngine.run(read_file_path, test_write_file_path)

      assert File.read!(existing_out_file_path) == File.read!(test_write_file_path)

      File.rm!(test_write_file_path)
      :ok = FactEngine.State.stop()
    end

    test "file #4" do
      read_file_path = "examples/4/in.txt"
      existing_out_file_path = "examples/4/out.txt"
      test_write_file_path = "examples/4/test_out.txt"

      :ok = FactEngine.State.start()
      FactEngine.run(read_file_path, test_write_file_path)

      assert File.read!(existing_out_file_path) == File.read!(test_write_file_path)

      File.rm!(test_write_file_path)
      :ok = FactEngine.State.stop()
    end
  end
end
