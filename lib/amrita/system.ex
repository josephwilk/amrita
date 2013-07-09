defmodule Amrita.System do

  def version do
    String.strip(File.read!("VERSION"))
  end

end
