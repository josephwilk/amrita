defmodule Amrita.Mocks do
  @moduledoc """
  Add support for prerequisites or mocks to tests.

  ## Example:
      use Amrita.Mocks

  """

  defmacro __using__(_ // []) do
    quote do
      import Amrita.Mocks.Provided
    end
  end

  defmodule Provided do

    @doc """
    Adds prerequisites to a test.

    ## Example
        defmodule Polite do
          def swear?(word) do
            word == "bugger"
          end
        end

        provided [Polite.swear?("bugger") |> false] do
          Polite.swear?("bugger") |> falsey
        end

        #With a wildcard argument matcher
        provided [Polite.swear?(:_) |> false] do
          Polite.swear?("bugger") |> falsey
          Polite.swear?("pants")  |> falsey
        end

    """
    defmacro provided(forms, test) do
      prerequisites = Amrita.Mocks.ParsePrerequisites.prerequisites(forms)
      mock_modules = Dict.keys(prerequisites)
      prerequisite_list = Macro.escape Dict.to_list(prerequisites)

      quote do
        prerequisites = unquote(prerequisite_list)

        :meck.new(unquote(mock_modules), [:passthrough])

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
              message = case :meck.called(m, f, a) do
                false -> [Amrita.Checker.to_s(m, f, a) <> " called 0 times."]
                _     -> []
              end
              List.concat(message_list, message)
            end
            List.concat(all_errors, messages)
          end

          :meck.unload(unquote(mock_modules))

          if not(Enum.empty? errors), do: Amrita.Message.fail "#{errors}",
                                                              "Expected atleast once", {"called", ""}
        end
      end
    end

    def __add_expect__(mock_module, fn_name, args, value) do
      #FIXME: Dynamically create fn with right arrity
      case Enum.count args do
        0 -> :meck.expect(mock_module, fn_name, fn -> value end)
        1 -> :meck.expect(mock_module, fn_name, fn(_) -> value end)
        2 -> :meck.expect(mock_module, fn_name, fn(_,_) -> value end)
        3 -> :meck.expect(mock_module, fn_name, fn(_,_,_) -> value end)
        4 -> :meck.expect(mock_module, fn_name, fn(_,_,_,_) -> value end)
        5 -> :meck.expect(mock_module, fn_name, fn(_,_,_,_,_) -> value end)
        6 -> :meck.expect(mock_module, fn_name, fn(_,_,_,_,_,_) -> value end)
        _ -> raise "Error, too many args. Help fix me @: https://github.com/josephwilk/amrita/issues/21"
      end
    end

  end

  defmodule ParsePrerequisites do
    @moduledoc false

    def prerequisites(forms) do
      prerequisites = Enum.map(forms, fn form -> extract(form) end)
      Enum.reduce prerequisites, HashDict.new, fn {m,f,a,v}, acc ->
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
      throw "Amrita could not understand your `provided`. Make sure it uses this format: [Module.fun |> :return_value]"
    end

  end

end
