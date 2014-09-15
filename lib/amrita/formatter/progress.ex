defmodule Amrita.Formatter.Progress do
  @moduledoc """
  Provides a documentation focused formatter. Outputting the full test names indenting based on the fact groups.
  """
  require Record
  use GenServer

  import ExUnit.Formatter, only: [format_time: 2, format_filters: 2, format_test_failure: 5, format_test_case_failure: 5]

  defmodule Config do
    defstruct tests_counter: 0, invalid_counter: 0, pending_counter: 0, scope: HashDict.new,
              test_failures: [], case_failures: [], pending_failures: [], trace: false
    
  end

  ## Callbacks

  def init(opts) do
      print_filters(Keyword.take(opts, [:include, :exclude]))
      config = %{
        seed: opts[:seed],
        trace: opts[:trace],
        colors: Keyword.put_new(opts[:colors], :enabled, IO.ANSI.enabled?),
        width: get_terminal_width(),
        tests_counter: 0,
        failures_counter: 0,
        invalids_counter: 0,
        pending_counter: 0
      }
      {:ok, config}
  end

  def handle_event({:suite_finished, run_us, load_us}, config) do
    print_suite(config, run_us, load_us)
    :remove_handler
  end
   
  def handle_event({:test_started, %ExUnit.Test{} = test}, config) do
    if config.trace, do: IO.write "  * #{trace_test_name test}"
    {:ok, config}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: nil} = test}, config) do
    if config.trace do
      IO.puts success(trace_test_result(test), config)
    else
      IO.write success(".", config)
    end
    {:ok, %{config | tests_counter: config.tests_counter + 1}}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:skip, _}} = test}, config) do
    if config.trace, do: IO.puts trace_test_skip(test)
    {:ok, config}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:invalid, _}} = test}, config) do
    if config.trace do
      IO.puts invalid(trace_test_result(test), config)
    else
      IO.write invalid("?", config)
    end

    {:ok, %{config | tests_counter: config.tests_counter + 1,
                     invalids_counter: config.invalids_counter + 1}}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:failed, failed}} = test}, config) do
    if config.trace do
      IO.puts failure(trace_test_result(test), config)
    end

    formatted = format_test_failure(test, failed, config.failures_counter + 1,
                                    config.width, &formatter(&1, &2, config))
    print_failure(formatted, config)

    {:ok, %{config | tests_counter: config.tests_counter + 1,
                     failures_counter: config.failures_counter + 1}}
  end

  def handle_event({:case_started, %ExUnit.TestCase{name: name}}, config) do
    if config.trace do
      IO.puts("\n#{inspect name}")
    end

    {:ok, config}
  end

  def handle_event({:case_finished, %ExUnit.TestCase{state: nil}}, config) do
    {:ok, config}
  end

  def handle_event({:case_finished, %ExUnit.TestCase{state: {:failed, failed}} = test_case}, config) do
    formatted = format_test_case_failure(test_case, failed, config.failures_counter + 1,
                                         config.width, &formatter(&1, &2, config))
    print_failure(formatted, config)
    {:ok, %{config | failures_counter: config.failures_counter + 1}}
  end

  def handle_event(_, config) do
    {:ok, config}
  end

  ## Callbacks

  # def init(trace) do
  #   { :ok, Config[trace: trace] }
  # end
  #
  # def handle_call({ :suite_finished, run_us, load_us }, _from, config) do
  #   print_suite(config.tests_counter, config.invalid_counter, config.pending_counter,
  #               config.test_failures, config.case_failures, config.pending_failures, run_us, load_us)
  #   { :stop, :normal, length(config.test_failures), config }
  # end
  #
  # def handle_call(reqest, from, config) do
  #   super(reqest, from, config)
  # end
  #
  # def handle_cast({ :test_started, %ExUnit.Test{} = test }, config) do
  #   if(name_parts = scoped(test)) do
  #     if(scope = new_scope(config, name_parts)) do
  #       print_scopes(name_parts)
  #       config = config.update_scope fn s -> HashDict.put(s, scope, []) end
  #     end
  #   end
  #
  #   { :noreply, config }
  # end
  #
  # def handle_cast({ :test_finished, %ExUnit.Test{state: :passed} = test }, config) do
  #   if(name_parts = scoped(test)) do
  #     print_indent(name_parts)
  #     IO.write success(String.lstrip "#{Enum.at(name_parts, Enum.count(name_parts)-1)}#{trace_test_time(test, config)}\n")
  #
  #     { :noreply, config.update_tests_counter(&(&1 + 1)) }
  #   else
  #     IO.puts success("\r  #{format_test_name test}#{trace_test_time(test, config)}")
  #     { :noreply, config.update_tests_counter(&(&1 + 1)) }
  #   end
  # end
  #
  # def handle_cast({ :test_finished, %ExUnit.Test{state: { :invalid, _ }} = test }, config) do
  #   IO.puts invalid("\r  #{format_test_name test}")
  #   { :noreply, config.update_tests_counter(&(&1 + 1)).update_invalid_counter(&(&1 + 1)) }
  # end
  #
  # def handle_cast({ :test_finished, test }, config) do
  #   %ExUnit.Test{case: _test_case, name: _test, state: { :failed, { _kind, reason, _stacktrace }}} = test
  #   exception_type = reason.__record__(:name)
  #
  #   name_parts = scoped(test)
  #   if(name_parts) do
  #     print_indent(name_parts)
  #   end
  #
  #   if exception_type == Elixir.Amrita.FactPending do
  #     if(name_parts) do
  #       IO.write pending(String.lstrip "#{Enum.at(name_parts, Enum.count(name_parts)-1)}\n")
  #     else
  #       IO.puts  pending("  #{format_test_name test}")
  #     end
  #     { :noreply, config.update_pending_counter(&(&1 + 1)).
  #       update_pending_failures(&([test|&1])) }
  #   else
  #     if(name_parts) do
  #       IO.write failure(String.lstrip "#{Enum.at(name_parts, Enum.count(name_parts)-1)}#{trace_test_time(test, config)}\n")
  #     else
  #       IO.puts  failure("  #{format_test_name test}#{trace_test_time(test, config)}")
  #     end
  #     { :noreply, config.update_tests_counter(&(&1 + 1)).update_test_failures(&([test|&1])) }
  #   end
  # end
  #
  # def handle_cast({ :case_started, %ExUnit.TestCase{name: name}}, config) do
  #   IO.puts("\n#{name}")
  #   { :noreply, config }
  # end
  #
  # def handle_cast({ :case_finished, test_case }, config) do
  #   if test_case.state && test_case.state != :passed do
  #     { :noreply, config.update_case_failures(&([test_case|&1])) }
  #   else
  #     { :noreply, config }
  #   end
  # end
  #
  # def handle_cast(request, config) do
  #   super(request, config)
  # end

  ## Tracing

    defp trace_test_name(%ExUnit.Test{name: name}) do
      case Atom.to_string(name) do
        "test " <> rest -> rest
        rest -> rest
      end
    end

    defp trace_test_time(%ExUnit.Test{time: time}) do
      "#{format_us(time)}ms"
    end

    defp trace_test_result(test) do
      "\r  * #{trace_test_name test} (#{trace_test_time(test)})"
    end

    defp trace_test_skip(test) do
      "\r  * #{trace_test_name test} (skipped)"
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


    ## Printing

    defp print_filters([include: include, exclude: exclude]) do
      if include != [], do: IO.puts format_filters(include, :include)
      if exclude != [], do: IO.puts format_filters(exclude, :exclude)
      IO.puts("")
      :ok
    end

    defp print_failure(formatted, config) do
      cond do
        config.trace -> IO.puts ""
        true -> IO.puts "\n"
      end
      IO.puts formatted
    end

  defp format_test_name(%ExUnit.Test{} = test) do
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

  defp print_test_failure(%ExUnit.Test{name: name, case: mod, state: { :failed, tuple }}, acc) do
    IO.puts format_test_failure(mod, name, tuple, acc + 1, :infinity, &formatter/2)
    acc + 1
  end

  defp print_test_case_failure(%ExUnit.TestCase{name: name, state: { :failed, tuple }}, acc) do
    IO.puts format_test_case_failure(name, tuple, acc + 1, :infinity, &formatter/2)
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

  defp print_filters([include: [], exclude: []]) do
     :ok
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

  defp trace_test_time(_test, %Config{trace: false}) do
    ""
  end
  defp trace_test_time(test, _config) do
    " (#{format_us(test.time)}ms)"
  end

  defp print_suite(config, run_us, load_us) do
      IO.write "\n\n"
      IO.puts format_time(run_us, load_us)

      message = "#{config.tests_counter} tests, #{config.failures_counter} failures"

      if config.invalids_counter > 0 do
        message = message <>  ", #{config.invalids_counter} invalid"
      end

      cond do
        config.failures_counter > 0 -> IO.puts failure(message, config)
        config.invalids_counter > 0 -> IO.puts invalid(message, config)
        true                        -> IO.puts success(message, config)
      end

      IO.puts "\nRandomized with seed #{config.seed}"
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
  
  defp get_terminal_width do
      case :io.columns do
        {:ok, width} -> max(40, width)
        _ -> 80
      end
  end
  
  defp colorize(escape, string, %{colors: colors}) do
      enabled = colors[:enabled]
      [IO.ANSI.format_fragment(escape, enabled),
       string,
       IO.ANSI.format_fragment(:reset, enabled)] |> IO.iodata_to_binary
    end

    defp success(msg, config) do
      colorize([:green], msg, config)
    end

    defp invalid(msg, config) do
      colorize([:yellow], msg, config)
    end

    defp failure(msg, config) do
      colorize([:red], msg, config)
    end

    defp formatter(:error_info, msg, config),    do: colorize([:red], msg, config)
    defp formatter(:extra_info, msg, config),    do: colorize([:cyan], msg, config)
    defp formatter(:location_info, msg, config), do: colorize([:bright, :black], msg, config)
    defp formatter(_,  msg, _config),            do: msg

    defp get_terminal_width do
      case :io.columns do
        {:ok, width} -> max(40, width)
        _ -> 80
      end
    end
  
end
