defexception Amrita.FactError, message: "fact failed"

defexception Amrita.FactError,
                    expected: nil,
                    actual: nil,
                    predicate: "",
                    negation: false,
                    prelude: "Expected" do

  def message(exception) do
    "#{exception.prelude}:\n" <>
    "     #{exception.actual_result} => #{exception.full_matcher}"
  end

  def full_matcher(exception) do
    "#{exception.predicate}#{exception.arguments}"
  end

  def actual_result(exception) do
    if is_bitstring(exception.actual) do
      exception.actual
    else
     inspect exception.actual
    end
  end

  def arguments(exception) do
    if exception.expected do
      "(#{exception.expected})"
    else
      ""
    end
  end

end