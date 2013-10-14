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
    @moduledoc """
    The Mocking DSL.
    """

    defrecord Error, module: nil, fun: nil, args: nil, raw_args: nil, history: []

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
      mock_modules = Provided.Prerequisites.all_modules(prerequisites)
      prerequisite_list = Macro.escape(Provided.Prerequisites.to_list(prerequisites))

      quote do
        prerequisites = Provided.Prerequisites.to_prerequisites(unquote(prerequisite_list))

        :meck.new(unquote(mock_modules), [:passthrough, :non_strict])

        prerequisites = unquote(__MODULE__).__resolve_args__(prerequisites, __MODULE__, __ENV__)

        Provided.Prerequisites.each_mock_list prerequisites, fn mocks ->
          unquote(__MODULE__).__add_expect__(mocks, __MODULE__, __ENV__)
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
      Provided.Prerequisites.map prerequisites, fn { module, fun, args, _, value } ->
        new_args = Enum.map args, fn arg -> __resolve_arg__(arg, target_module, env) end
        { module, fun, new_args, args, value }
      end
    end

    def __resolve_arg__(arg, target_module, env) do
      case arg do
        { :_, _, _ }          -> anything
        { :fn, _meta, args }   -> { evaled_arg, _ } = Code.eval_quoted(arg, [], env)
                                 :meck.is(evaled_arg)
        { name, _meta, args } ->
          args = args || []
          if __in_scope__(name, args, target_module) do
            apply(target_module, name, args)
          else
            { evaled_arg, _ } = Code.eval_quoted(arg, [], env)
            evaled_arg
          end
        _ -> arg
      end
    end

    def __in_scope__(name, args, target_module) do
      Enum.any? target_module.__info__(:functions),
                              fn { method, arity } -> method == name && arity == Enum.count(args) end
    end


    def __add_expect__(mocks, target_module, env) do
      args_specs = Enum.map mocks, fn { _, _, args, _, value } ->
        value = __resolve_arg__(value, target_module, env)
        { args, value }
      end
      { mock_module, fn_name, _, _, _ } = Enum.at(mocks, 0)

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
      Provided.Prerequisites.reduce prerequisites, [], fn mock -> called?(mock) end
    end

    defp called?({module, fun, args, raw_args, _}) do
      case :meck.called(module, fun, args) do
        false -> [Provided.Error.new(module: module,
                                     fun: fun,
                                     args: args,
                                     raw_args: raw_args,
                                     history: Amrita.Mocks.History.matches(module, fun))]
        _     -> []
      end
    end
  end

  defmodule Provided.Prerequisites do
    @moduledoc false

    defrecordp :prereqs, bucket: [HashDict.new(HashDict.new)]

    def new(prerequisites) do
       bucket = Enum.reduce prerequisites, HashDict.new, fn {module, fun, args, value}, acc ->
        mocks_by_module = HashDict.get(acc, module, HashDict.new)
        mocks_by_fun    = HashDict.get(mocks_by_module, fun, [])
        mocks = Enum.concat(mocks_by_fun, [{module, fun, args, nil ,value}])

        Dict.put(acc, module, Dict.put(mocks_by_module, fun, mocks))
      end

       prereqs(bucket: bucket)
    end

    def all_modules(prereqs(bucket: bucket)) do
      Dict.keys(bucket)
    end

    def each_mock_list(prereqs(bucket: bucket), fun) do
      Enum.each bucket, fn { _, mocks_by_module } ->
        Enum.each mocks_by_module, fn { _, mocks } ->
          fun.(mocks)
        end
      end
    end

    def map(prereqs(bucket: bucket), fun) do
      new_bucket = Enum.map bucket, fn { module_key, mocks_by_module } ->
        new_mocks_by_module = Enum.map mocks_by_module, fn {fun_key, mocks} ->
          new_mocks_by_fun = Enum.map mocks, fun
          { fun_key, new_mocks_by_fun }
        end
        { module_key, new_mocks_by_module }
      end
      prereqs(bucket: new_bucket)
    end

    def reduce(prereqs(bucket: bucket), start, fun) do
      Enum.reduce bucket, start, fn { _, mocks_by_module }, all_acc ->
        results = Enum.reduce mocks_by_module, [], fn { _, mocks }, fn_acc ->
          results = Enum.reduce mocks, [],  fn mock, acc ->
            result = fun.(mock)
            Enum.concat(acc, result)
          end
          Enum.concat(fn_acc, results)
        end
        Enum.concat(all_acc, results)
      end
    end

    def to_list(prereqs(bucket: bucket)) do
      Dict.to_list(bucket)
    end

    def to_prerequisites(list) do
      prereqs(bucket: list)
    end

    def by_module_and_fun(prereqs(bucket: bucket), module, fun) do
      mocks = by_fun(by_module(bucket, module), fun)
      Enum.map mocks, fn {m,f,a,_,v} -> {m,f,a,v} end
    end

    defp by_fun(bucket, fun) do
      Dict.get(bucket, fun)
    end

    defp by_module(bucket, module) do
      Dict.get(bucket, module)
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
      prerequisites = Enum.map(forms, &extract(&1))
      Provided.Prerequisites.new(prerequisites)
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
