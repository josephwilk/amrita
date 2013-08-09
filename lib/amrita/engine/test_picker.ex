defmodule Amrita.Engine.TestPicker do
  @moduledoc false

  def run?(case_name, function, selectors) do
    if Enum.empty?(selectors) do
      true
    else
      meta = meta_for(case_name, function)
      if meta do
        relevant_selectors = Enum.filter selectors, fn selector -> String.contains?(meta[:file], selector[:file]) end
        if Enum.empty?(relevant_selectors) do
          true
        else
          Enum.any? relevant_selectors, fn selector ->
            case selector[:line] do
              nil -> true
              _   -> selector[:line] == meta[:line] 
            end 
          end
        end
      end
    end
  end

  defp meta_for(case_name, function) do
    try do  
      apply(case_name, :"__#{function}__", [])
    rescue
      #If its not an Amrita test it will not have metadata.
      _ -> nil
    end
  end

end