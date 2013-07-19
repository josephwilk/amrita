defmodule Amrita.System do

  @doc """
  Returns Amritas current version
  """
  def version do
    String.strip(File.read!("VERSION"))
  end

end
