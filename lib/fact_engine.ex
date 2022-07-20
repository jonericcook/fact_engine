defmodule FactEngine do
  def run(file_path) do
    with {:ok, file_contents} <- Util.get_file_contents(file_path) do
      process_file_contents(file_contents)
    end
  end

  def process_file_contents(file_contents) do
    for operation <- file_contents do
      process(operation)
    end
  end

  def process(["INPUT", statement, arguments]) do
  end

  def process(["QUERY", statement, arguments]) do
  end
end
