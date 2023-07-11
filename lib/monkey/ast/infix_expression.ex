defmodule Monkey.AST.InfixExpression do
  alias Monkey.AST.Node
  alias Monkey.Parser
  alias Monkey.Token

  @enforce_keys [:token, :operator, :left, :right]
  defstruct [:token, :operator, :left, :right]

  @type expression :: Parser.expression

  @type t() :: %__MODULE__{
          token: %Token{},
          operator: String.t(),
          left: expression(),
          right: expression()
        }

  @spec new(%Token{}, String.t(), expression(), expression()) :: t()
  def new(%Token{} = token, operator, left, right) do
    %__MODULE__{token: token, operator: operator, left: left, right: right}
  end

  defimpl Node, for: __MODULE__ do
    def token_literal(expression), do: expression.token.literal

    def to_string(exp) do
      left = Node.to_string(exp.left)
      operator = exp.operator
      right = Node.to_string(exp.right)

      "(#{left} #{operator} #{right})"
    end
  end
end
