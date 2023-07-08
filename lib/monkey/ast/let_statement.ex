defmodule Monkey.AST.LetStatement do
  alias Monkey.AST.Node
  alias Monkey.AST.Expression
  alias Monkey.AST.Identifier
  alias Monkey.Token

  # enforce keys once expression parsing is implemented
  # @enforce_keys [:token, :name, :value]
  defstruct [:token, :name, :value]

  @type t() :: %__MODULE__{
          token: %Token{},
          # identifier
          name: %Identifier{},
          # expression
          value: %Expression{}
        }

  defimpl Node, for: __MODULE__ do
    def token_literal(let_statement), do: let_statement.token.literal
  end
end
