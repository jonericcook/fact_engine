defmodule State do
  use Agent

  def init() do
    case Agent.start_link(fn -> %{} end,
           name: {:global, :state}
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  def get() do
    {:ok, state} = pid()

    Agent.get(state, fn state ->
      state
    end)
  end

  def pid() do
    case :global.whereis_name(:state) do
      pid when is_pid(pid) ->
        {:ok, pid}
    end
  end
end
