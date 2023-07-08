defmodule Monkey.AST.Program do
  alias Monkey.AST.Node
  alias Monkey.AST.Statement

  @enforce_keys [:statements]
  defstruct [:statements]

  @type t() :: %__MODULE__{
          statements: [%Statement{}]
        }

  def new(statements) do
    %__MODULE__{statements: statements}
  end

  def token_literal(program) when length(program.statements) > 0 do
    program.statements
    |> List.first()
    |> Node.token_literal()
  end

  def token_literal(%__MODULE__{statements: []}), do: ""
end
