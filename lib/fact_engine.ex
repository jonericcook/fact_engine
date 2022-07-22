defmodule FactEngine do
  def run(read_file_path, write_file_path) do
    with {:ok, file_contents} <- get_file_contents(read_file_path) do
      process_file_contents(file_contents, write_file_path)
    end
  end

  defp process_file_contents(file_contents, write_file_path) do
    for operation <- file_contents do
      process(operation, write_file_path)
    end
  end

  defp process(["INPUT", statement, arguments], _write_file_path) do
    State.update(statement, arguments)
  end

  defp process(["QUERY", statement, arguments], write_file_path) do
    engine_state = State.get(statement)
    search_values = get_values_to_search_with(arguments)
    frequencies = get_frequency_counts(arguments)

    results =
      engine_state
      |> get_lists_that_contain_values(search_values)
      |> filter_lists_that_matches_frequencies(frequencies, search_values)

    query_arguments = get_query_arguments(arguments)

    write(results, query_arguments, search_values, write_file_path)
  end

  defp write([], _query_arguments, _search_values, write_file_path) do
    write_file(write_file_path, "\n---\nfalse")
  end

  defp write(results, [], _search_values, write_file_path) when length(results) >= 1 do
    write_file(write_file_path, "\n---\ntrue")
  end

  defp write(results, query_arguments, search_values, write_file_path) do
    results = remove_search_values(results, search_values)

    to_write =
      Enum.reduce(results, "\n---\n", fn result, acc ->
        result =
          result
          |> Enum.zip(query_arguments)
          |> Enum.reduce("", fn {r, q}, acc ->
            acc <> "#{q}: #{r}, "
          end)
          |> String.slice(0..-3)

        IO.puts(result)

        acc <> result
      end)

    write_file(write_file_path, to_write)
  end

  def remove_search_values(results, search_values) do
    Enum.map(results, fn x ->
      x -- search_values
    end)
  end

  defp get_file_contents(file_path) do
    with {:ok, file_lines} <- get_file_lines(file_path),
         {:ok, parsed_file_lines} <- parse_file_lines(file_lines) do
      {:ok, parsed_file_lines}
    end
  end

  defp read_file(file_path) do
    File.read(file_path)
  end

  defp write_file(file_path, content) do
    File.write(file_path, content, [:append])
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

  defp get_lists_that_contain_values(list_of_lists, []) do
    list_of_lists
  end

  defp get_lists_that_contain_values(list_of_lists, search_values) do
    Enum.filter(list_of_lists, fn list ->
      Enum.any?(list, fn item -> item in search_values end)
    end)
  end

  defp filter_lists_that_matches_frequencies(list_of_lists, frequencies, search_values) do
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

  defp get_values_to_search_with(arguments) do
    Enum.filter(arguments, fn arg ->
      !has_an_uppercase_letter(arg)
    end)
  end

  defp get_query_arguments(arguments) do
    Enum.filter(arguments, &has_an_uppercase_letter(&1))
  end

  defp get_frequency_counts(arguments) do
    arguments
    |> Enum.filter(&has_an_uppercase_letter(&1))
    |> Enum.frequencies()
  end
end
