defexception Amrita.FactPending, message: "Pending" do
  def message(exception) do
    exception.message
  end
end