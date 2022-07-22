defmodule FactEngine.Util do
  @moduledoc """
  Provides a wide range of utility support functions.
  """

  @doc """
  Writes false for query when the results list is empty.
  """
  def write([], _query_arguments, _search_values, write_file_path) do
    write_file(write_file_path, "---\nfalse\n")
  end

  @doc """
  Writes true for query when the results list contains at least one item and the query arguments list is empty.
  """
  def write(results, [], _search_values, write_file_path) when length(results) >= 1 do
    write_file(write_file_path, "---\ntrue\n")
  end

  @doc """
  Writes query results is desired format.
  """
  def write(results, query_arguments, search_values, write_file_path) do
    results = remove_search_values(results, search_values)

    {results, query_arguments} = maybe_dedup(results, query_arguments)

    to_write =
      Enum.reduce(results, "---\n", fn result, top_acc ->
        joined_result =
          result
          |> Enum.zip(query_arguments)
          |> Enum.reduce("", fn {r, q}, bottom_acc ->
            bottom_acc <> "#{q}: #{r}, "
          end)
          |> String.slice(0..-3)

        top_acc <> joined_result <> "\n"
      end)

    write_file(write_file_path, to_write)
  end

  @doc """
  Gets the query arguments from the arguments list.
  """
  def get_query_arguments(arguments) do
    Enum.filter(arguments, &has_an_uppercase_letter(&1))
  end

  @doc """
  Gets the frequency counts for each argument in the arguments list.
  """
  def get_frequency_counts(arguments) do
    arguments
    |> Enum.filter(&has_an_uppercase_letter(&1))
    |> Enum.frequencies()
  end

  @doc """
  Gets lists that contain the search values specified. In this case none were provided so it returns the whole list.
  """
  def get_lists_that_contain_values(list_of_lists, []) do
    list_of_lists
  end

  @doc """
   Gets lists that contain the search values specified.
  """
  def get_lists_that_contain_values(list_of_lists, search_values) do
    Enum.filter(list_of_lists, fn list ->
      Enum.any?(list, fn item -> item in search_values end)
    end)
  end

  @doc """
  Filters list by checking its frequencies against the arguments frequencies.
  """
  def filter_lists_that_matches_frequencies(list_of_lists, frequencies, search_values) do
    Enum.filter(list_of_lists, fn list ->
      list = list -- search_values
      list_frequencies = Enum.frequencies(list)

      list_keys_count = Map.keys(list_frequencies) |> Enum.count()
      list_values = Map.values(list_frequencies) |> Enum.sort()

      frequencies_keys_count = Map.keys(frequencies) |> Enum.count()
      frequencies_values = Map.values(frequencies) |> Enum.sort()

      list_keys_count == frequencies_keys_count and list_values == frequencies_values
    end)
  end

  @doc """
  Gets search values by selecting arguments that do not have a capital letter in it.
  """
  def get_values_to_search_with(arguments) do
    Enum.filter(arguments, fn arg ->
      !has_an_uppercase_letter(arg)
    end)
  end

  @doc """
  Gets the content of the file at the specified file path.
  """
  def get_file_contents(file_path) do
    with {:ok, file_lines} <- get_file_lines(file_path),
         {:ok, parsed_file_lines} <- parse_file_lines(file_lines) do
      {:ok, parsed_file_lines}
    end
  end

  defp maybe_dedup(results, query_arguments) do
    result_dedup_count =
      results
      |> List.first()
      |> Enum.dedup()
      |> Enum.count()

    case result_dedup_count do
      1 ->
        {Enum.map(results, &Enum.dedup(&1)), Enum.dedup(query_arguments)}

      _ ->
        {results, query_arguments}
    end
  end

  defp remove_search_values(results, search_values) do
    Enum.map(results, fn x ->
      x -- search_values
    end)
  end

  defp read_file(file_path) do
    File.read(file_path)
  end

  defp write_file(file_path, content) do
    File.write!(file_path, content, [:append])
  end

  defp get_file_lines(file_path) do
    with {:ok, result} <- read_file(file_path) do
      file_lines = String.split(result, "\n", trim: true)

      case Enum.count(file_lines) do
        0 ->
          {:error, "File at #{file_path} is empty."}

        _ ->
          {:ok, file_lines}
      end
    end
  end

  defp parse_file_lines(file_lines) do
    file_lines
    |> Enum.reduce({[], []}, fn file_line, {parsed_file_lines, errors} ->
      with {:ok, parsed_file_line} <- parse_file_line(file_line) do
        {parsed_file_lines ++ [parsed_file_line], errors}
      else
        {:error, error} ->
          {parsed_file_lines, errors ++ [error]}
      end
    end)
    |> handle_parsed_file_lines()
  end

  defp handle_parsed_file_lines({parsed_file_lines, []}) do
    {:ok, parsed_file_lines}
  end

  defp handle_parsed_file_lines({_parsed_file_lines, errors}) do
    {:error, errors}
  end

  defp parse_file_line(file_line) do
    split_and_trimmed =
      file_line
      |> String.split(" ", parts: 3, trim: true)
      |> Enum.map(&String.trim(&1))

    with :ok <- check_field_count(split_and_trimmed),
         :ok <- check_action(split_and_trimmed),
         :ok <- check_statement(split_and_trimmed),
         {:ok, formatted_arguments} <-
           check_arguments(split_and_trimmed) do
      {_, file_line_no_arguments} = List.pop_at(split_and_trimmed, -1)
      {:ok, file_line_no_arguments ++ [formatted_arguments]}
    end
  end

  defp check_field_count(split_and_trimmed) do
    case Enum.count(split_and_trimmed) do
      3 ->
        :ok

      _ ->
        {:error, "#{Enum.join(split_and_trimmed, " ")} is malformed."}
    end
  end

  defp check_statement([_, statement, _]) do
    if Regex.match?(~r/^[a-z_]+$/, statement) do
      :ok
    else
      {:error, "#{statement} should only contain lowercase alphabetic letters and underscores"}
    end
  end

  defp check_action(["INPUT", _, _]) do
    :ok
  end

  defp check_action(["QUERY", _, _]) do
    :ok
  end

  defp check_action([action, _, _]) do
    {:error, "#{action} is an invalid action"}
  end

  defp check_arguments([_, _, arguments]) do
    with :ok <- check_parentheses(arguments),
         :ok <- check_if_not_empty(arguments),
         :ok <- check_commas(arguments),
         :ok <- check_for_empty_strings(arguments),
         formatted_arguments <- format_arguments(arguments),
         :ok <- check_if_alphanumeric(formatted_arguments) do
      {:ok, formatted_arguments}
    end
  end

  defp check_if_not_empty(arguments) do
    if String.slice(arguments, 1..-2) == "" do
      {:error, "#{arguments} is empty."}
    else
      :ok
    end
  end

  defp check_parentheses(arguments) do
    arguments_graphemes = arguments |> String.graphemes()

    left_parens_count_is_one = arguments_graphemes |> Enum.count(&(&1 == "(")) == 1
    right_parens_count_is_one = arguments_graphemes |> Enum.count(&(&1 == ")")) == 1

    left_paren = arguments_graphemes |> List.first()
    right_paren = arguments_graphemes |> List.last()

    if left_parens_count_is_one and
         right_parens_count_is_one and
         left_paren == "(" and
         right_paren == ")" do
      :ok
    else
      {:error, "#{arguments} has parentheses issues."}
    end
  end

  defp check_commas(arguments) do
    no_parens = String.slice(arguments, 1..-2)

    comma_count = no_parens |> String.graphemes() |> Enum.count(&(&1 == ","))

    args_count = no_parens |> String.split(",", trim: true) |> Enum.count()

    if args_count - 1 == comma_count do
      :ok
    else
      {:error, "#{arguments} has too many commas."}
    end
  end

  defp check_for_empty_strings(arguments) do
    result =
      arguments
      |> String.slice(1..-2)
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim(&1))

    empty_string_count =
      Enum.filter(result, fn x -> x == "" end)
      |> Enum.count()

    if empty_string_count == 0 do
      :ok
    else
      {:error, "#{arguments} contains a field that is an empty string."}
    end
  end

  defp format_arguments(arguments) do
    arguments
    |> String.slice(1..-2)
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim(&1))
    |> Enum.sort()
  end

  defp check_if_alphanumeric(content) do
    joined_content = Enum.join(content, ",")

    if Regex.match?(~r/^[a-zA-Z0-9,_]+$/, joined_content) do
      :ok
    else
      {:error, "#{joined_content} should only contain alphanumeric and commas"}
    end
  end

  defp has_an_uppercase_letter(content) when is_binary(content),
    do: String.downcase(content) != content

  defp has_an_uppercase_letter(_content), do: false
end
