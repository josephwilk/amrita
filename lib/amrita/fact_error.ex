defexception Amrita.FactError, message: "fact failed"

defexception Amrita.FactError,
                    expected: nil,
                    actual: nil,
                    predicate: "",
                    negation: false,
                    prelude: "Expected" do

  def message(exception) do
    "#{exception.prelude}:\n" <>
    "     #{exception.actual} => #{exception.full_matcher}"
  end

  def full_matcher(exception) do
    "#{exception.predicate}#{exception.arguments}"
  end

  def arguments(exception) do
    if exception.expected do
      "(#{exception.expected})"
    else
      ""
    end
  end

end