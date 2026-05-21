defmodule TopDeckTutor.Decks.ValidationResult do
  @moduledoc """
  Derived deck validation result for display and tests.
  """

  defstruct valid?: true, errors: [], warnings: []
end
