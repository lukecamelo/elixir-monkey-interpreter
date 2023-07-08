defmodule Monkey.AST.IntegerLiteral do
  alias Monkey.Token
  alias Monkey.AST.Node

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  @type t() :: %__MODULE__{
          token: %Token{},
          value: integer()
        }

  def new(%Token{} = token, value) do
    %__MODULE__{token: token, value: value}
  end

  defimpl Node, for: __MODULE__ do
    def token_literal(expression), do: expression.token.literal
    def to_string(expression), do: expression.token.literal
  end
end
