defmodule FactEngine do
  @moduledoc """
  An Engine of Facts. Add facts and query them.
  """
  alias FactEngine.Util

  @doc """
  Reads the file specified at `read_file_path`, processes its contents and then writes the results to `write_file_path`.
  """
  def run(read_file_path, write_file_path) do
    with {:ok, file_contents} <- Util.get_file_contents(read_file_path) do
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
    search_values = Util.get_values_to_search_with(arguments)
    frequencies = Util.get_frequency_counts(arguments)

    results =
      engine_state
      |> Util.get_lists_that_contain_values(search_values)
      |> Util.filter_lists_that_matches_frequencies(frequencies, search_values)

    query_arguments = Util.get_query_arguments(arguments)

    Util.write(results, query_arguments, search_values, write_file_path)
  end
end
