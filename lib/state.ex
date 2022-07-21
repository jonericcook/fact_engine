defmodule State do
  use Agent

  def start() do
    case Agent.start_link(fn -> %{} end,
           name: {:global, :state}
         ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  def reset() do
    case stop() do
      {:error, :no_state_to_stop} ->
        start()

      _ ->
        start()
    end
  end

  def stop() do
    case :global.whereis_name(:state) do
      :undefined ->
        {:error, :no_state_to_stop}

      pid when is_pid(pid) ->
        Agent.stop(pid)
    end
  end

  defp pid() do
    case :global.whereis_name(:state) do
      pid when is_pid(pid) ->
        pid
    end
  end

  def get() do
    Agent.get(pid(), fn state ->
      state
    end)
  end

  def get(statement) do
    Agent.get(pid(), fn state ->
      Map.get(state, statement, [])
    end)
  end

  def update(statement, arguments) do
    Agent.update(pid(), fn state ->
      Map.update(state, statement, MapSet.new([arguments]), fn existing_value ->
        MapSet.put(existing_value, arguments)
      end)
    end)
  end
end
