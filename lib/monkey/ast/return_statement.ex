defmodule Monkey.AST.ReturnStatement do
  alias Monkey.AST.Node
  alias Monkey.AST.Expression
  alias Monkey.Token

  # @enforce_keys [:token, :return_value]
  defstruct [:token, :return_value]

  @type t() :: %__MODULE__{
          token: %Token{},
          # expression
          return_value: %Expression{}
        }

  defimpl Node, for: __MODULE__ do
    def token_literal(return_statement), do: return_statement.token.literal
  end
end
