defmodule Monkey.AST.Program do
  alias Monkey.AST.Node

  @enforce_keys [:statements]
  defstruct [:statements]

  @type t() :: %__MODULE__{
          statements: [any()]
        }

  def new(statements) do
    %__MODULE__{statements: statements}
  end

  # defimpl not working for some reason? ast_test:9 fails, saying Node.to_string/1 is not defined or somet shit
  # defimpl Node, for: __MODULE__ do
  def token_literal(program) when length(program.statements) > 0 do
    program.statements
    |> List.first()
    |> Node.token_literal()
  end

  def token_literal(%{statements: []}), do: ""

  @spec to_string(t()) :: String.t()
  def to_string(program) do
    program.statements
    |> IO.inspect()
    |> Enum.map(&Node.to_string/1)
    |> Enum.join()
  end

  # end
end
