defmodule Amrita do
  defmodule Sweet do
    import :all, ExUnit.Case
    use ExUnit.Case

    defmacro fact(description, var // quote(do: _), contents) do
      quote do
        test unquote(description) do
          unquote(contents)
        end
      end
    end

  end
end