defmodule Amrita.Checkers.Collections do
  alias Amrita.Message, as: Message
  alias Amrita.Checker, as: Checker
  
  @moduledoc """
  Checkers which are designed to work with collections (lists, tuples, keyword lists, strings).
  """

  @doc """
  Checks that the collection contains element.

  ## Examples
      [1, 2, 3] |> contains 3
      {1, 2, 3} |> contains 2

      "elixir of life" |> contains "of"

      "elixir of life" |> contains %r/"of"/

  """
  def contains(collection,element) do
    r = case collection do
          c when is_tuple(c)           -> element in tuple_to_list(c)
          c when is_list(c)            -> element in c
          c when is_regex(element)     -> Regex.match?(element, c)
          c when is_bitstring(element) -> String.contains?(c, element)
        end

    if (not r), do: Message.fail(collection, element, __ENV__.function)
  end

  @doc false
  def contains(element) do
    fn collection ->
         collection |> contains element
         Checker.to_s(__ENV__.function, element)
    end
  end

  @doc """
  Checks that the actual result starts with the expected result.

  ## Examples
      [1 2 3] |> has_prefix  [1 2]   ; true
      [1 2 3] |> has_prefix  [2 1]   ; false

      {1, 2, 3} |> has_prefix {1, 2} ; true

      "I cannot explain myself for I am not myself" |> has_prefix "I"

  """
  def has_prefix(collection, prefix) when is_list(collection) and is_record(prefix, HashSet) do
    collection_prefix = Enum.take(collection, Enum.count(prefix))

    r = fail_fast_contains?(collection_prefix, prefix)

    if not(r), do: Message.fail(prefix, collection, __ENV__.function)
  end

  def has_prefix(collection, prefix) do
    r = case collection do
          c when is_tuple(c) ->
            collection_prefix = Enum.take(tuple_to_list(collection), tuple_size(prefix))
            collection_prefix = list_to_tuple(collection_prefix)
            collection_prefix == prefix
          c when is_list(c)  ->
            Enum.take(collection, Enum.count(prefix)) == prefix
          _ when is_bitstring(prefix) ->
            String.starts_with?(collection, prefix)
        end

    if not(r), do: Message.fail(prefix, collection, __ENV__.function)
  end

  @doc false
  def has_prefix(element) do
    fn collection ->
         collection |> has_prefix element
         Checker.to_s(__ENV__.function, element)
    end
  end

  @doc """
  Checks that the actual result ends with the expected result.

  ## Examples:
      [1 2 3] |> has_suffix [2 3]  ; true
      [1 2 3] |> has_suffix [3 2]  ; false

      {1, 2, 3} |> has_suffix [3] ; true

      "I cannot explain myself for I am not myself" |> has_suffix "myself"

  """
  def has_suffix(collection, suffix) when is_list(collection) and is_record(suffix, HashSet) do
    collection_suffix = Enum.drop(collection, Enum.count(collection) - Enum.count(suffix))

    r = fail_fast_contains?(collection_suffix, suffix)

    if not(r), do: Message.fail(suffix, collection, __ENV__.function)
  end

  def has_suffix(collection, suffix) do
    r = case collection do
          c when is_tuple(c) ->
            collection_suffix = Enum.drop(tuple_to_list(collection), tuple_size(collection) - tuple_size(suffix))
            collection_suffix = list_to_tuple(collection_suffix)
            collection_suffix == suffix
          c when is_list(c) ->
            collection_suffix = Enum.drop(collection, Enum.count(collection) - Enum.count(suffix))
            collection_suffix == suffix
          _ when is_bitstring(suffix) ->
            String.ends_with?(collection, suffix)
        end

    if not(r), do: Message.fail(suffix, collection, __ENV__.function)
  end

  @doc false
  def has_suffix(element) do
    fn collection ->
         collection |> has_suffix element
         Checker.to_s(__ENV__.function, element)
    end
  end

  @doc """
  Checks whether a predicate holds for all elements in a collection.

  ## Examples:
      [1, 3, 5, 7] |> for_all odd(&1)  ; true
      [2, 3, 5, 7] |> for_all odd(&1)  ; false
  """
  def for_all(collection, fun) do
    Enum.each(collection, fun)
  end

  @doc """
  Checks whether a predicate holds for at least one element in a collection.

  ## Examples:
      [2, 4, 7, 8] |> for_some odd(&1) ; true
      [2, 4, 6, 8] |> for_some odd(&1) ; false
  """
  def for_some(collection, fun) do
   r = Enum.any?(Enum.map(collection, (fn value ->
      try do
        fun.(value)
        true
      rescue
        [Amrita.FactError, Amrita.MockError, ExUnit.AssertionError] -> false
      end
    end)))

    if not(r), do: Message.fail(fun, collection, __ENV__.function)
  end

  defp fail_fast_contains?(collection1, collection2) do
    try do
      Enum.reduce(collection1, true, fn(value, acc) ->
        case value in collection2 do
          true -> acc
          _    -> throw(:error)
        end
      end)
    catch
      :error -> false
    end
  end
end