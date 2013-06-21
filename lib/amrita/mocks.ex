defmodule Amrita.Mocks do

  defmacro __using__(_ // []) do
    quote do
      import Amrita.Mocks.Provided
    end
  end

  defmodule Provided do
    defmacro provided(form, test) do
      { mock_module, fn_name, value } =  module_fn(Enum.at(form, 0))

      quote do
        :meck.new(unquote(mock_module), [:passthrough])
        unquote(__MODULE__).__add_expect__(unquote(mock_module), unquote(fn_name), unquote(value))
        try do
          unquote(test)
          :meck.validate(unquote(mock_module)) |> truthy
        after
          r = :meck.called(unquote(mock_module), unquote(fn_name), :_)
          :meck.unload(unquote(mock_module))

          if not(r), do: Amrita.Message.fail "#{unquote(fn_name)} called 0 times",
                                             "expected at least once", {"called", ""}
        end
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
      Module.concat(ns)
    end

    def __add_expect__(mock_module, fn_name, value) do
      :meck.expect(mock_module, fn_name, fn -> value end)
    end

  end
end
