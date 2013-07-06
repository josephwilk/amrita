defmodule Amrita.Formatter.ProgressCreator do
  def elixir_version do
    elixir_version = String.split(System.version, %r"[\.-]")
    Enum.map elixir_version, fn x -> if x != "dev", do: binary_to_integer(x) end
  end

  @doc false
  defmacro define_progress_formatter do
    if Enum.fetch!(elixir_version, 0) <= 0 &&
       Enum.fetch!(elixir_version, 1) <= 9 &&
       Enum.fetch!(elixir_version, 2) <= 3 do
      quote do
       @behaviour ExUnit.Formatter
          @timeout 30_000
          use GenServer.Behaviour

          import Exception, only: [format_stacktrace_entry: 2]
          defrecord Config, counter: 0, test_failures: [], case_failures: [], pending_failures: []

          ## Behaviour

          def suite_started(_opts) do
            { :ok, pid } = :gen_server.start_link(__MODULE__, [], [])
            pid
          end

          def suite_finished(id, run_us, load_us) do
            :gen_server.call(id, { :suite_finished, run_us, load_us }, @timeout)
          end

          def case_started(_id, _test_case) do
            :ok
          end

          def case_finished(id, test_case) do
            :gen_server.cast(id, { :case_finished, test_case })
          end

          def test_started(_id, _test) do
            :ok
          end

          def test_finished(id, test) do
            :gen_server.cast(id, { :test_finished, test })
          end

          ## Callbacks

          def init(_args) do
            { :ok, Config.new }
          end

          def handle_call({ :suite_finished, run_us, load_us }, _from, config) do
            print_suite(config.counter, config.test_failures, config.case_failures, config.pending_failures, run_us, load_us)
            { :stop, :normal, length(config.test_failures), config }
          end

          def handle_call(state, from, config) do
            super(state, from, config)
          end

          def handle_cast({ :test_finished, test = ExUnit.Test[invalid: true] }, config) do
            IO.write invalid("?")
            { :noreply, config.update_counter(&1 + 1).
                update_test_failures([test|&1]) }
          end

          def handle_cast({ :test_finished, ExUnit.Test[failure: nil] }, config) do
            IO.write success(".")
            { :noreply, config.update_counter(&1 + 1) }
          end

          def handle_cast({ :test_finished, test }, config) do

            ExUnit.Test[case: test_casex, name: testx, failure: { kind, reason, stacktrace }] = test
             exception_type = reason.__record__(:name)

             if exception_type == Elixir.Amrita.FactPending do
               IO.write invalid("P")
               { :noreply, config.update_pending_failures([test|&1]) }
             else
               IO.write failure("F")
               { :noreply, config.update_counter(&1 + 1).update_test_failures([test|&1]) }
             end
          end

          def handle_cast({ :case_finished, test_case }, config) do
            if test_case.failure do
              { :noreply, config.update_case_failures([test_case|&1]) }
            else
              { :noreply, config }
            end
          end

          def handle_cast(state, config) do
            super(state, config)
          end

          defp print_suite(counter, [], [], pending_failures, run_us, load_us) do
            Enum.reduce Enum.reverse(pending_failures), 0, print_test_pending(&1, &2, File.cwd!)
            IO.write "\n\n"
            print_time(run_us, load_us)

            IO.write success("#{counter} facts, ")
            if !Enum.empty?(pending_failures) do
              IO.write success("#{Enum.count(pending_failures)} pending, ")
            end
            IO.write success "0 failures"
            IO.write "\n"
          end

          defp print_suite(counter, test_failures, case_failures, pending_failures, run_us, load_us) do
            IO.write "\n\n"

            if !Enum.empty?(pending_failures) do
              IO.write "Pending:\n\n"
              Enum.reduce Enum.reverse(pending_failures), 0, print_test_pending(&1, &2, File.cwd!)
            end

            IO.write "Failures:\n\n"

            num_fails = Enum.reduce Enum.reverse(test_failures), 1, print_test_failure(&1, &2, File.cwd!)
            Enum.reduce Enum.reverse(case_failures), num_fails, print_case_failure(&1, &2, File.cwd!)
            num_invalids = Enum.count test_failures, fn test -> test.invalid end
            num_pending  = Enum.count pending_failures

            print_time(run_us, load_us)

            num_fails = num_fails - 1
            message = "#{counter} facts, "

            if(num_pending > 0) do
              message = message <> "#{num_pending} pending, "
            end

            message = message <> "#{num_fails} failures"
            if num_invalids > 0, do: message = message <>  ", #{num_invalids} invalid"
            cond do
              num_fails > 0    -> IO.puts failure(message)
              num_invalids > 0 -> IO.puts invalid(message)
              true             -> IO.puts success(message)
            end
          end

          defp print_test_failure(ExUnit.Test[failure: nil], acc, _cwd) do
            acc
          end

          defp print_test_failure(ExUnit.Test[case: test_case, name: test, failure: { kind, reason, stacktrace }], acc, cwd) do

            test_string = "#{test}"
            if String.starts_with?(test_string, "test") do
              fact_string = "fact" <> String.slice(test_string, 4, String.length(test_string))
            else
              fact_string = test
            end

            IO.puts "  #{acc}) #{fact_string} (#{inspect test_case.name})"
            print_kind_reason(kind, reason)
            print_stacktrace(stacktrace, test_case.name, test, cwd)
            IO.write "\n"
            acc + 1
          end

          defp print_case_failure(ExUnit.TestCase[name: case_name, failure: { kind, reason, stacktrace }], acc, cwd) do
            IO.puts "  #{acc}) #{inspect case_name}: failure on setup_all/teardown_all callback, tests invalidated."
            print_kind_reason(kind, reason)
            print_stacktrace(stacktrace, case_name, nil, cwd)
            IO.write "\n"
            acc + 1
          end

          defp print_kind_reason(:error, ExUnit.ExpectationError[] = record) do
            prelude  = String.downcase record.prelude
            reason   = record.full_reason
            max      = max(size(prelude), size(reason))

            IO.puts error_info "** (ExUnit.ExpectationError)"

            if desc = record.description do
              IO.puts error_info "  #{pad(prelude, max)}: #{maybe_multiline(desc, max)}"
              IO.puts error_info "  #{pad(reason, max)}: #{maybe_multiline(record.expected, max)}"
              IO.puts error_info "  #{pad("instead got", max)}: #{maybe_multiline(record.actual, max)}"
            else
              IO.puts error_info "  #{pad(prelude, max)}: #{maybe_multiline(record.expected, max)}"
              IO.puts error_info "  #{pad(reason, max)}: #{maybe_multiline(record.actual, max)}"
            end
          end

          defp print_kind_reason(:error, exception) do
            IO.puts error_info "** (#{inspect exception.__record__(:name)}) #{exception.message}"
          end

          defp print_kind_reason(kind, reason) do
            IO.puts error_info "** (#{kind}) #{inspect(reason)}"
          end

          defp print_stacktrace([{ test_case, test, _, [ file: file, line: line ] }|_], test_case, test, cwd) do
            IO.puts location_info "at #{Path.relative_to(file, cwd)}:#{line}"
          end

          defp print_stacktrace(stacktrace, _case, _test, cwd) do
            IO.puts location_info "stacktrace:"
            Enum.each stacktrace, fn(s) -> IO.puts stacktrace_info format_stacktrace_entry(s, cwd) end
          end

          defp print_time(run_us, nil) do
            IO.puts "Finished in #{run_us |> normalize_us |> format_us} seconds."
          end

          defp print_time(run_us, load_us) do
            run_us  = run_us |> normalize_us
            load_us = load_us |> normalize_us

            ms = run_us + load_us
            IO.puts "Finished in #{format_us ms} seconds (#{format_us load_us}s on load, #{format_us run_us}s on tests)"
          end

          defp pad(binary, max) do
            remaining = max - size(binary)
            if remaining > 0 do
              String.duplicate(" ", remaining) <>  binary
            else
              binary
            end
          end

          defp normalize_us(us) do
            div(us, 10000)
          end

          defp format_us(us) do
            if us < 10 do
              "0.0#{us}"
            else
              us = div us, 10
              "#{div(us, 10)}.#{rem(us, 10)}"
            end
          end

          defp maybe_multiline(str, max) do
            unless multiline?(str) do
              String.strip(str)
            else
              "\n" <>
              Enum.join((lc line inlist String.split(str, %r/\n/), do: String.duplicate(" ", max) <> line ), "\n")
            end
          end

          defp multiline?(<<>>), do: false
          defp multiline?(<<?\n, _ :: binary>>) do
            true
          end
          defp multiline?(<<_, rest :: binary>>) do
            multiline?(rest)
          end

          # Print styles

          defp success(msg) do
            IO.ANSI.escape("%{green}" <>  msg)
          end

          defp invalid(msg) do
            IO.ANSI.escape("%{yellow}" <>  msg)
          end

          defp failure(msg) do
            IO.ANSI.escape("%{red}" <>  msg)
          end

          defp error_info(msg) do
            IO.ANSI.escape("%{red}     " <> msg)
          end

          defp location_info(msg) do
            IO.ANSI.escape("%{cyan}     " <> msg)
          end

          defp stacktrace_info(msg) do
            "       " <> msg
          end
      end
    else
      quote do
          @behaviour ExUnit.Formatter
          @timeout 30_000
          use GenServer.Behaviour

          import ExUnit.Formatter, only: [format_time: 2, format_test_failure: 4, format_test_case_failure: 4]

          defrecord Config, tests_counter: 0, invalid_counter: 0, pending_counter: 0,
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
            if config.trace, do: IO.write("  * #{trace_test_name test}")
            { :noreply, config }
          end

          def handle_cast({ :test_finished, ExUnit.Test[failure: nil] = test }, config) do
            if config.trace do
              IO.puts success("\r  * #{trace_test_name test}")
            else
              IO.write success(".")
            end
            { :noreply, config.update_tests_counter(&1 + 1) }
          end

          def handle_cast({ :test_finished, ExUnit.Test[failure: { :invalid, _ }] = test }, config) do
            if config.trace do
              IO.puts invalid("\r  * #{trace_test_name test}")
            else
              IO.write invalid("?")
            end
            { :noreply, config.update_tests_counter(&1 + 1).
                update_invalid_counter(&1 + 1) }
          end

          def handle_cast({ :test_finished, test }, config) do
            ExUnit.Test[case: test_casex, name: testx, failure: { kind, reason, stacktrace }] = test
            exception_type = reason.__record__(:name)

            if exception_type == Elixir.Amrita.FactPending do
              IO.write invalid("P")
              { :noreply, config.update_pending_counter(&1 + 1).
                update_pending_failures([test|&1]) }
            else
              if config.trace do
                IO.puts failure("\r  * #{trace_test_name test}")
              else
                IO.write failure("F")
              end
            { :noreply, config.update_tests_counter(&1 + 1).
                update_test_failures([test|&1]) }
            end
          end

          def handle_cast({ :case_started, ExUnit.TestCase[name: name] }, config) do
            if config.trace, do: IO.puts("\n#{name}")
            { :noreply, config }
          end

          def handle_cast({ :case_finished, test_case }, config) do
            if test_case.failure do
              { :noreply, config.update_case_failures([test_case|&1]) }
            else
              { :noreply, config }
            end
          end

          def handle_cast(request, config) do
            super(request, config)
          end

          defp trace_test_name(ExUnit.Test[name: name]) do
            case atom_to_binary(name) do
              "test_" <> rest -> rest
              "test " <> rest -> rest
            end
          end

          defp print_suite(counter, 0, num_pending, [], [], pending_failures, run_us, load_us) do
            IO.write "\n\nPending:\n\n"
            Enum.reduce Enum.reverse(pending_failures), 0, print_test_pending(&1, &2, File.cwd!)

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
              Enum.reduce Enum.reverse(pending_failures), 0, print_test_pending(&1, &2, File.cwd!)
            end

            IO.write "Failures:\n\n"
            num_fails = Enum.reduce Enum.reverse(test_failures), 0, print_test_failure(&1, &2, File.cwd!)
            Enum.reduce Enum.reverse(case_failures), num_fails, print_test_case_failure(&1, &2, File.cwd!)

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

          defp print_test_failure(test, acc, cwd) do
            IO.puts format_test_failure(test, acc + 1, cwd, function(formatter/2))
            acc + 1
          end

          defp print_test_case_failure(test_case, acc, cwd) do
            IO.puts format_test_case_failure(test_case, acc + 1, cwd, function(formatter/2))
            acc + 1
          end

      end
    end
  end
end

defmodule Amrita.Formatter.Progress do
  @moduledoc """
  Formatter responsible for printing test results
  """

  import Amrita.Formatter.ProgressCreator
  define_progress_formatter

  defp print_test_pending(test, acc, cwd) do
    IO.puts Amrita.Formatter.Formatter.format_test_pending(test, acc + 1, cwd, function(pending_formatter/2))
    acc + 1
  end

  defp colorize(escape, string) do
    IO.ANSI.escape_fragment("%{#{escape}}") <> string <> IO.ANSI.escape_fragment("%{reset}")
  end

  defp success(msg) do
    colorize("green", msg)
  end

  defp pending(msg) do
    invalid(msg)
  end

  defp invalid(msg) do
    colorize("yellow", msg)
  end

  defp failure(msg) do
    colorize("red", msg)
  end

  # Color styles

  defp formatter(:error_info, msg),    do: colorize("red", msg)
  defp formatter(:location_info, msg), do: colorize("cyan", msg)
  defp formatter(_,  msg),             do: msg

  defp pending_formatter(:error_info, msg),    do: colorize("yellow", msg)
  defp pending_formatter(:location_info, msg), do: colorize("cyan", msg)
  defp pending_formatter(_,  msg),             do: msg
end