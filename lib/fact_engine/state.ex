defmodule FactEngine.State do
  @moduledoc """
  Persistent state used to store INPUT arguments.

  The state is a map. A key in the map is a `statement` and the value is a `MapSet containing arguments.

  Example:
  %{
    "is_a_cat" => #MapSet<[["bowler_cat"], ["garfield"], ["lucy"]]>,
    "loves" => #MapSet<[["garfield", "lasagna"]]>
  }
  """
  use Agent

  @doc """
  Starts the persistent state process.
  """
  def start() do
    case Agent.start_link(fn -> %{} end,
           name: {:global, :state}
         ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  @doc """
  Resets the persistent state process.
  """
  def reset() do
    case stop() do
      {:error, :no_state_to_stop} ->
        start()

      _ ->
        start()
    end
  end

  @doc """
  Stops the persistent state process.
  """
  def stop() do
    case :global.whereis_name(:state) do
      :undefined ->
        {:error, :no_state_to_stop}

      pid when is_pid(pid) ->
        Agent.stop(pid)
    end
  end

  @doc """
  Gets all the state in the process.
  """
  def get() do
    Agent.get(pid(), fn state ->
      state
    end)
  end

  @doc """
  Gets the state in the process corresponding to a specific `statement`.
  """
  def get(statement) do
    Agent.get(pid(), fn state ->
      Map.get(state, statement, [])
    end)
  end

  @doc """
  Updates the state in the process by adding the `arguments` to the specified `statement`.
  """
  def update(statement, arguments) do
    Agent.update(pid(), fn state ->
      Map.update(state, statement, MapSet.new([arguments]), fn existing_value ->
        MapSet.put(existing_value, arguments)
      end)
    end)
  end

  defp pid() do
    case :global.whereis_name(:state) do
      pid when is_pid(pid) ->
        pid
    end
  end
end
