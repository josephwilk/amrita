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
      prerequisite_list = Macro.escape Dict.to_list(prerequisites)

      quote do
        prerequisites = unquote(prerequisite_list)

        Enum.map unquote(mock_modules), fn mock_module ->
          :meck.new(mock_module, [:passthrough])
        end

        Enum.map prerequisites, fn {m, mocks} ->
          Enum.map mocks, fn {m, f, a, v} ->
            unquote(__MODULE__).__add_expect__(m, f, a, v)
          end
        end

        try do
          unquote(test)

          Enum.map unquote(mock_modules), fn mock_module ->
            :meck.validate(mock_module) |> truthy
          end
        after
          errors = Enum.reduce prerequisites, [], fn {m, mocks}, all_errors ->
            messages = Enum.reduce mocks, [], fn {m, f, a, v}, message_list ->
              message = case :meck.called(m, f, :_) do
                false -> ["#{m}.#{f} called 0 times."]
                _     -> []
              end
              List.concat(message_list, message)
            end
            List.concat(all_errors, messages)
          end

          Enum.map unquote(mock_modules), fn mock_module ->
            :meck.unload(mock_module)
          end

          if not(Enum.empty? errors), do: Amrita.Message.fail "#{errors}",
                                                              "Expected atleast once", {"called", ""}
        end
      end
    end

    def __add_expect__(mock_module, fn_name, args, value) do
      :meck.expect(mock_module, fn_name, fn -> value end)
    end

  end

  defmodule ParsePrerequisites do
    def prerequisites(forms) do
      prerequisites = Enum.map(forms, fn form -> extract(form) end)
      prerequisites = Enum.reduce prerequisites, HashDict.new, fn {m,f,a,v}, acc ->
        mocks = HashDict.get(acc, m, [])
        mocks = List.concat(mocks, [{m,f,a,v}])
        HashDict.put(acc,m,mocks)
      end
    end

    defp extract({:|>, _, [{fun, _, args}, value]}) do
      { module_name, function_name } = extract(fun)
      { module_name, function_name,  args, value }
    end

    defp extract({:., _, [ns, method_name]}) do
      { extract(ns), method_name }
    end

    defp extract({:__aliases__, _, ns}) do
      Module.concat ns
    end

    defp extract(_) do
      throw "Amrita could not understand your provided"
    end

  end

end
