defmodule Amrita.Formatter.Documentation do
  @moduledoc """
  Provides a documentation focused formatter. Outputting the full test names indenting based on the fact groups.
  """

  @behaviour ExUnit.Formatter
  @timeout 30_000
  use GenServer.Behaviour

  import ExUnit.Formatter, only: [format_time: 2, format_test_failure: 5, format_test_case_failure: 4]

  defrecord Config, tests_counter: 0, invalid_counter: 0, pending_counter: 0, scope: HashDict.new,
            test_failures: [], case_failures: [], pending_failures: [], trace: false

  ## Behaviour

  def suite_started(opts) do
    { :ok, pid } = :gen_server.start_link(__MODULE__, opts[:trace], [])
    pid
  end

  def suite_finished(id, run_us, load_us) do
    :gen_server.call(id, { :suite_finished, run_us, load_us }, @timeout)
  end

  def case_started(id, test_case) do
    :gen_server.cast(id, { :case_started, test_case })
  end

  def case_finished(id, test_case) do
    :gen_server.cast(id, { :case_finished, test_case })
  end

  def test_started(id, test) do
    :gen_server.cast(id, { :test_started, test })
  end

  def test_finished(id, test) do
    :gen_server.cast(id, { :test_finished, test })
  end

  ## Callbacks

  def init(trace) do
    { :ok, Config[trace: trace] }
  end

  def handle_call({ :suite_finished, run_us, load_us }, _from, config) do
    print_suite(config.tests_counter, config.invalid_counter, config.pending_counter,
                config.test_failures, config.case_failures, config.pending_failures, run_us, load_us)
    { :stop, :normal, length(config.test_failures), config }
  end

  def handle_call(reqest, from, config) do
    super(reqest, from, config)
  end

  def handle_cast({ :test_started, ExUnit.Test[] = test }, config) do
    if(name_parts = scoped(test)) do
      if(scope = new_scope(config, name_parts)) do
        print_scopes(name_parts)
        config = config.update_scope fn s -> HashDict.put(s, scope, []) end
      end
    end

    { :noreply, config }
  end

  def handle_cast({ :test_finished, ExUnit.Test[state: :passed] = test }, config) do
    if(name_parts = scoped(test)) do
      print_indent(name_parts)
      IO.write success(String.lstrip "#{Enum.at(name_parts, Enum.count(name_parts)-1)}#{trace_test_time(test, config)}\n")

      { :noreply, config.update_tests_counter(&(&1 + 1)) }
    else
      IO.puts success("\r  #{format_test_name test}#{trace_test_time(test, config)}")
      { :noreply, config.update_tests_counter(&(&1 + 1)) }
    end
  end

  def handle_cast({ :test_finished, ExUnit.Test[state: { :invalid, _ }] = test }, config) do
    IO.puts invalid("\r  #{format_test_name test}")
    { :noreply, config.update_tests_counter(&(&1 + 1)).update_invalid_counter(&(&1 + 1)) }
  end

  def handle_cast({ :test_finished, test }, config) do
    ExUnit.Test[case: _test_case, name: _test, state: { :failed, { _kind, reason, _stacktrace }}] = test
    exception_type = reason.__record__(:name)

    name_parts = scoped(test)
    if(name_parts) do
      print_indent(name_parts)
    end

    if exception_type == Elixir.Amrita.FactPending do
      if(name_parts) do
        IO.write pending(String.lstrip "#{Enum.at(name_parts, Enum.count(name_parts)-1)}\n")
      else
        IO.puts  pending("  #{format_test_name test}")
      end
      { :noreply, config.update_pending_counter(&(&1 + 1)).
        update_pending_failures(&([test|&1])) }
    else
      if(name_parts) do
        IO.write failure(String.lstrip "#{Enum.at(name_parts, Enum.count(name_parts)-1)}#{trace_test_time(test, config)}\n")
      else
        IO.puts  failure("  #{format_test_name test}#{trace_test_time(test, config)}")
      end
      { :noreply, config.update_tests_counter(&(&1 + 1)).update_test_failures(&([test|&1])) }
    end
  end

  def handle_cast({ :case_started, ExUnit.TestCase[name: name] }, config) do
    IO.puts("\n#{name}")
    { :noreply, config }
  end

  def handle_cast({ :case_finished, test_case }, config) do
    if test_case.state && test_case.state != :passed do
      { :noreply, config.update_case_failures(&([test_case|&1])) }
    else
      { :noreply, config }
    end
  end

  def handle_cast(request, config) do
    super(request, config)
  end

  defp format_test_name(ExUnit.Test[] = test) do
    Amrita.Formatter.Format.format_test_name(test)
  end

  defp print_suite(counter, 0, num_pending, [], [], pending_failures, run_us, load_us) do
    IO.write "\n\nPending:\n\n"
    Enum.reduce Enum.reverse(pending_failures), 0, &print_test_pending(&1, &2)

    IO.puts format_time(run_us, load_us)
    IO.write success("#{counter} facts, ")
    if num_pending > 0 do
      IO.write success("#{num_pending} pending, ")
    end
    IO.write success "0 failures"
    IO.write "\n"
  end

  defp print_suite(counter, num_invalids, num_pending, test_failures, case_failures, pending_failures, run_us, load_us) do
    IO.write "\n\n"

    if num_pending > 0 do
      IO.write "Pending:\n\n"
      Enum.reduce Enum.reverse(pending_failures), 0, &print_test_pending(&1, &2)
    end

    IO.write "Failures:\n\n"
    num_fails = Enum.reduce Enum.reverse(test_failures), 0, &print_test_failure(&1, &2)
    Enum.reduce Enum.reverse(case_failures), num_fails, &print_test_case_failure(&1, &2)

    IO.puts format_time(run_us, load_us)
    message = "#{counter} facts"

    if num_invalids > 0 do
      message = message <>  ", #{num_invalids} invalid"
    end
    if num_pending > 0 do
      message = message <>  ", #{num_pending} pending"
    end

    message = message <> ", #{num_fails} failures"

    cond do
      num_fails > 0    -> IO.puts failure(message)
      num_invalids > 0 -> IO.puts invalid(message)
      true             -> IO.puts success(message)
    end
  end

  defp print_test_pending(test, acc) do
    IO.puts Amrita.Formatter.Format.format_test_pending(test, acc + 1, &pending_formatter/2)
    acc + 1
  end

  defp print_test_failure(ExUnit.Test[name: name, case: mod, state: { :failed, tuple }], acc) do
    IO.puts format_test_failure(mod, name, tuple, acc + 1, &formatter/2)
    acc + 1
  end

  defp print_test_case_failure(ExUnit.TestCase[name: name, state: { :failed, tuple }], acc) do
    IO.puts format_test_case_failure(name, tuple, acc + 1, &formatter/2)
    acc + 1
  end

  defp print_scopes(name_parts) do
    Enum.each 0..Enum.count(name_parts)-2, fn n ->
                                                Enum.each 0..n, fn _ -> IO.write("  ") end
                                                IO.write(Enum.at(name_parts, n))
                                                IO.write("\n")
                                           end
  end

  defp print_indent(name_parts) do
    Enum.each 0..Enum.count(name_parts)-1, fn _ -> IO.write "  " end
  end

  defp new_scope(config, name_parts) do
    scope = Enum.take(name_parts, Enum.count(name_parts)-1)
    scope = Enum.join(scope, ".")
    if !HashDict.has_key?(config.scope, scope) do
      scope
    end
  end

  defp scoped(test) do
    name = format_test_name(test)
    name_parts = String.split(name, "-")
    if Enum.count(name_parts) > 1 do
      name_parts
    end
  end

  # Color styles

  defp success(msg) do
    Amrita.Formatter.Format.colorize("green", msg)
  end

  defp invalid(msg) do
    Amrita.Formatter.Format.colorize("yellow", msg)
  end

  defp pending(msg) do
    Amrita.Formatter.Format.colorize("yellow", msg)
  end

  defp failure(msg) do
    Amrita.Formatter.Format.colorize("red", msg)
  end

  defp pending_formatter(:error_info, msg),    do: Amrita.Formatter.Format.colorize("yellow", msg)
  defp pending_formatter(:location_info, msg), do: Amrita.Formatter.Format.colorize("cyan", msg)
  defp pending_formatter(_,  msg),             do: msg

  defp formatter(:error_info, msg),    do: Amrita.Formatter.Format.colorize("red", msg)
  defp formatter(:location_info, msg), do: Amrita.Formatter.Format.colorize("cyan", msg)
  defp formatter(_,  msg),             do: msg

  defp trace_test_time(_test, Config[trace: false]), do: ""
  defp trace_test_time(test, _config) do
    " (#{format_us(test.time)}ms)"
  end

  defp format_us(us) do
    us = div(us, 10)
    if us < 10 do
      "0.0#{us}"
    else
      us = div us, 10
      "#{div(us, 10)}.#{rem(us, 10)}"
    end
  end
end
