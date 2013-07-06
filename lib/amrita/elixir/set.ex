defmodule Amrita.Set do
  @moduledoc """
  Until Sets are added to Elixir (pending this pullrequest: https://github.com/elixir-lang/elixir/pull/1241/files)
  Our own Set implementation.

  Use to indicate we don't care about order when using checkers.

  """

  defrecordp :ordered,
    size: 0,
    bucket: []

  def new(members) do
    Enum.reduce members, ordered(), fn member, set ->
      put(set, member)
    end
  end

  def member?(set, member) when is_record(set, Amrita.Set) do
    case set_get(set, member) do
      ^member -> true
      _       -> false
    end
  end

  def size(set) do
    elem(set, 1)
  end

  def put(set, member) do
    { set, _ } = set_put(set, { :put, member })
    set
  end

  def to_list(ordered(bucket: bucket)) do
    bucket
  end

  defp set_get(ordered(bucket: bucket), member) do
    bucket_get(bucket, member)
  end

  defp set_put(ordered(size: size, bucket: bucket) = set, member) do
    { new, count } = bucket_put(bucket, member)
    { ordered(set, size: size + count, bucket: new), count }
  end

  def reduce(ordered(bucket: bucket), acc, fun) do
    :lists.foldl(fun, acc, bucket)
  end

  defp bucket_get([member|_], member) do
    member
  end

  defp bucket_get([member|bucket], candidate) when candidate > member do
    bucket_get(bucket, candidate)
  end

  defp bucket_get(_, _member) do
    nil
  end

  defp bucket_put([m|_]=bucket, { :put, member }) when m > member do
    { [member|bucket], 1 }
  end

  defp bucket_put([member|bucket], { :put, member }) do
    { [member|bucket], 0 }
  end

  defp bucket_put([e|bucket], member) do
    { rest, count } = bucket_put(bucket, member)
    { [e|rest], count }
  end

  defp bucket_put([], { :put, member }) do
    { [member], 1 }
  end

end

defimpl Enumerable, for: Amrita.Set do
  def reduce(set, acc, fun), do: Amrita.Set.reduce(set, acc, fun)
  def member?(set, v),       do: Amrita.Set.member?(set, v)
  def count(set),            do: Amrita.Set.size(set)
end
