defmodule Amrita.Mocks do
  @moduledoc """
  Add support for prerequisites or mocks to tests.
  Automatically imported with `use Amrita.Sweet`

  ## Example:
      use Amrita.Mocks

  """

  defmacro __using__(_ // []) do
    quote do
      import Amrita.Mocks.Provided
    end
  end

  defmodule Provided do
    defrecord Error, module: nil, fun: nil, args: nil, history: []

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

        :meck.new(unquote(mock_modules), [:passthrough, :non_strict])

        prerequisites = unquote(__MODULE__).__resolve_args__(prerequisites, __MODULE__, __ENV__)

        Enum.map prerequisites, fn { _, mocks } ->
          Enum.map mocks, fn { module, fun, args, value } ->
            mock = Enum.filter(mocks, fn { m, f, _, _ } ->  m == module && f == fun end)
            unquote(__MODULE__).__add_expect__(mock, __MODULE__, __ENV__)
          end
        end

        try do
          unquote(test)

          Enum.map unquote(mock_modules), fn mock_module ->
            :meck.validate(mock_module) |> truthy
          end

        after
          fails = Provided.Check.fails(prerequisites)
          :meck.unload(unquote(mock_modules))

          if not(Enum.empty?(fails)) do
            Amrita.Message.mock_fail(fails)
          end

        end
      end
    end

    def __resolve_args__(prerequisites, target_module, env) do
      Enum.map prerequisites, fn {meta, mocks} ->
        new_mocks = Enum.map mocks, fn { module, fun, args, value } ->
          new_args = Enum.map args, fn arg ->
            case arg do
              { :_, _, _ }         -> anything
              {name, _meta, args}  ->
                args = args || []
                if Enum.any? target_module.__info__(:functions), fn {method, arity} -> method == name && arity == Enum.count(args) end do
                  apply(target_module, name, args)
                else
                  { evaled_arg, _ } = Code.eval_quoted(arg, [], env)
                  evaled_arg
                end
              _ -> arg
            end
          end
          { module, fun, new_args, value }
        end
        { meta, new_mocks }
      end
    end

    def __add_expect__(mocks, target_module, env) do
      args_specs = Enum.map mocks, fn { _, _, args, value } ->
        value = if is_tuple(value) do
          { fun_name, _m, fun_args } = value
          fun_args = fun_args || []
          if Enum.any? target_module.__info__(:functions), fn { method, arity } -> method == fun_name && arity == Enum.count(fun_args) end do
            apply(target_module, fun_name, fun_args)
          else
            { new_value, _ } = Code.eval_quoted(value, [], env)
            new_value
          end
        else
          value
        end

        { args, value }
      end
      { mock_module, fn_name, _, _ } = Enum.at(mocks, 0)

      :meck.expect(mock_module, fn_name, args_specs)
    end

    @doc """
    alias for :_ the wild card checker for arguments
    """
    def anything do
      :_
    end
  end

  defmodule Provided.Check do
  @moduledoc false

    def fails(prerequisites) do
      Enum.reduce prerequisites, [], fn {_, mocks}, all_errors ->
        messages = Enum.reduce mocks, [],  fn mock, message_list ->
          List.concat(message_list, called?(mock))
        end
        List.concat(all_errors, messages)
      end
    end

    defp called?({module, fun, args, _}) do
      case :meck.called(module, fun, args) do
        false -> [Provided.Error.new(module: module,
                                     fun: fun,
                                     args: args,
                                     history: Amrita.Mocks.History.matches(module, fun))]
        _     -> []
      end
    end
  end

  defmodule Provided.Parse do
    @moduledoc false

    defexception Error, form: []  do
      def message(exception) do
        "Amrita could not understand your `provided`:\n" <>
        "     " <> Macro.to_string(exception.form) <> "\n" <>
        "     Make sure it uses this format: [Module.fun |> :return_value]"
      end
    end

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

    defp extract(form) do
      raise Error.new(form: form)
    end

  end

end
