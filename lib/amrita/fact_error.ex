defexception Amrita.FactError, message: "fact failed"

defexception Amrita.FactError,
                    expected: nil,
                    actual: nil,
                    predicate: "",
                    negation: false,
                    prelude: "Expected" do

  def message(exception) do
    "#{exception.prelude}:\n" <>
    "     #{exception.actual_result} |> #{exception.full_checker}"
  end

  def full_checker(exception) do
    Amrita.Checker.to_s exception.predicate, exception.expected
  end

  def actual_result(exception) do
    if is_bitstring(exception.actual) do
      exception.actual
    else
     inspect exception.actual
    end
  end

end