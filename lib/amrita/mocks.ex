defmodule Amrita.Mocks do
  @moduledoc """
  Add support for prerequisites or mocks to tests.
  Automatically imported with `use Amrita.Sweet`

  ## Example:
      use Amrita.Mocks

  """

  defmacro __using__(_ // []) do
    quote do
      import Amrita.Mocks.ProvidedDsl
    end
  end

  defmodule ProvidedDsl do

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
        provided [Polite.swear?(anything) |> false] do
          Polite.swear?("bugger") |> falsey
          Polite.swear?("pants")  |> falsey
        end

    """
    defmacro provided(forms, test) do
      prerequisites = Amrita.Mocks.Provided.Parse.prerequisites(forms)
      mock_modules = Dict.keys(prerequisites)
      prerequisite_list = Macro.escape Dict.to_list(prerequisites)

      quote do
        prerequisites = unquote(prerequisite_list)

        :meck.new(unquote(mock_modules), [:passthrough])

        Enum.map prerequisites, fn {_, mocks} ->
          Enum.map mocks, fn {module, fun, args, value} ->
            unquote(__MODULE__).__add_expect__(module, fun, args, value)
          end
        end

        try do
          unquote(test)

          Enum.map unquote(mock_modules), fn mock_module ->
            :meck.validate(mock_module) |> truthy
          end

        after
          fails = Amrita.Mocks.Provided.fails(prerequisites)
          :meck.unload(unquote(mock_modules))

          if not(Enum.empty?(fails)) do
            Amrita.Message.mock_fail(fails)
          end

        end
      end
    end

    def __add_expect__(mock_module, fn_name, args, value) do
      args  = Enum.map args, fn _arg -> {anything, [], nil} end
      #TODO: replace this with a macro
      Code.eval_quoted(quote do
        :meck.expect(unquote(mock_module), unquote(fn_name), fn unquote_splicing(args) -> unquote(value) end)
      end)
    end

    @doc """
    alias for :_ the wild card checker for arguments
    """
    def anything do
      :_
    end
  end

  defmodule Provided do
    defrecord Error, module: nil, fun: nil, args: nil, history: []

    def fails(prerequisites) do
      Enum.reduce prerequisites, [], fn {_, mocks}, all_errors ->
        messages = Enum.reduce mocks, [],  fn mock, message_list ->
          List.concat(message_list, called?(mock))
        end
        List.concat(all_errors, messages)
      end
    end

    defp called?({module, fun, args, _}) do
      args = Enum.map args, function(resolve_arg/1)

      case :meck.called(module, fun, args) do
        false -> [Error.new(module: module,
                            fun: fun,
                            args: args,
                            history: Amrita.Mocks.History.matches(module, fun))]
        _     -> []
      end
    end

    defp resolve_arg(arg) do
      case arg do
        { :anything, _, _ } -> Amrita.Mocks.ProvidedDsl.anything
        _ when is_tuple(arg) -> { evaled_arg, _ } = Code.eval_quoted(arg)
                                evaled_arg
        _ -> arg
      end
    end
  end

  defmodule Provided.Parse do
    @moduledoc false

    def prerequisites(forms) do
      prerequisites = Enum.map(forms, fn form -> extract(form) end)
      Enum.reduce prerequisites, HashDict.new, fn {module, fun, args, value}, acc ->
        mocks = HashDict.get(acc, module, [])
        mocks = List.concat(mocks, [{module, fun, args, value}])
        HashDict.put(acc, module, mocks)
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
