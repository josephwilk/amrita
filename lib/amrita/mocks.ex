defmodule Amrita.Mocks do

  defmacro __using__(_ // []) do
    quote do
      import Amrita.Mocks.Provided
    end
  end

  defmodule Provided do
    defmacro provided(forms, test) do
      prerequisites = Amrita.Mocks.ParsePrerequisites.prerequisites(forms)
      mock_modules = Dict.keys(prerequisites)

      { :ok, [{ _, fn_name, value } | _] } = Dict.fetch(prerequisites, Enum.at(mock_modules,0))

      quote do
        Enum.map unquote(mock_modules), fn mock_module ->
          :meck.new(mock_module, [:passthrough])
          unquote(__MODULE__).__add_expect__(mock_module, unquote(fn_name), unquote(value))
        end

        try do
          unquote(test)

          Enum.map unquote(mock_modules), fn mock_module ->
            :meck.validate(mock_module) |> truthy
          end
        after
          Enum.map unquote(mock_modules), fn mock_module ->
            r = :meck.called(mock_module, unquote(fn_name), :_)
            :meck.unload(mock_module)

            if not(r), do: Amrita.Message.fail "#{unquote(fn_name)} called 0 times",
                                               "expected at least once", {"called", ""}
          end
        end
      end
    end

    def __add_expect__(mock_module, fn_name, value) do
      :meck.expect(mock_module, fn_name, fn -> value end)
    end

  end

  defmodule ParsePrerequisites do
    def prerequisites(forms) do
      prerequisites = Enum.map(forms, fn form -> module_fn(form) end)
      prerequisites = Enum.reduce prerequisites, HashDict.new, fn {m,f,v}, acc ->
        mocks = HashDict.get(acc, m, [])
        mocks = List.concat(mocks, [{m,f,v}])
        HashDict.put(acc,m,mocks)
      end
    end

    defp module_fn({:|>, _, [{l, _, _}, v]}) do
      { module_name, function_name } = module_fn(l)
      { module_name, function_name,  v }
    end

    defp module_fn({:., _, [ns, method_name]}) do
      { module_fn(ns), method_name }
    end

    defp module_fn({:__aliases__, _, ns}) do
      Module.concat ns
    end
  end

end
