defmodule Util do
  def read_file(file_path) do
    File.read(file_path)
  end

  def write_file(file_path, content) do
    File.write(file_path, content)
  end

  def get_file_lines(file_path) do
    with {:ok, result} <- read_file(file_path) do
      file_lines = String.split(result, "\n", trim: true)

      case Enum.count(file_lines) do
        0 ->
          {:error, :file_is_empty}

        _ ->
          {:ok, file_lines}
      end
    end
  end

  def parse_file_lines(file_lines) do
    Enum.reduce(file_lines, {[], []}, fn file_line, {parsed_file_lines, errors} ->
      nil
    end)
  end

  def parse_file_line(file_line) do
    split_and_trimmed =
      file_line
      |> String.split(" ", parts: 3, trim: true)
      |> Enum.map(&String.trim(&1))

    with {:ok, split_and_trimmed} <- check_field_count(split_and_trimmed),
         :ok <- check_action(split_and_trimmed),
         :ok <- check_arguments(split_and_trimmed) do
      {:ok, split_and_trimmed}
    end
  end

  def check_field_count(split_and_trimmed) do
    case Enum.count(split_and_trimmed) do
      3 ->
        {:ok, split_and_trimmed}

      _ ->
        {:error, :invalid_line_format}
    end
  end

  def check_action(["INPUT", _, _]) do
    :ok
  end

  def check_action(["QUERY", _, _]) do
    :ok
  end

  def check_action([_, _, _]) do
    {:error, :invalid_action}
  end

  def check_arguments([_, _, arguments]) do
  end

  def check_parentheses(arguments) do
    left_parens_count = arguments |> String.graphemes() |> Enum.count(&(&1 == "("))
    right_parens_count = arguments |> String.graphemes() |> Enum.count(&(&1 == ")"))

    if left_parens_count == right_parens_count do
      :ok
    else
      {:error, :parentheses_mismatch}
    end
  end

  def check_commas(arguments) do
    no_parens = String.slice(arguments, 1..-2)

    comma_count = no_parens |> String.graphemes() |> Enum.count(&(&1 == ","))

    args_count = no_parens |> String.split(",", trim: true) |> Enum.count()

    if args_count == comma_count - 1 do
      :ok
    else
      {:error, :comma_to_args_mismatch}
    end
  end
end
