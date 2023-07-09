defmodule Monkey.AST.PrefixExpression do
  alias Monkey.AST.Node
  alias Monkey.Token

  @enforce_keys [:token, :operator, :right]
  defstruct [:token, :operator, :right]

  @type t() :: %__MODULE__{
          token: %Token{},
          operator: String.t(),
          right: any()
        }

  @spec new(%Token{}, String.t(), any()) :: t()
  def new(%Token{} = token, operator, right) do
    %__MODULE__{token: token, operator: operator, right: right}
  end

  defimpl Node, for: __MODULE__ do
    def token_literal(expression), do: expression.token.literal

    def to_string(expression) do
      "(" <> expression.operator <> Node.to_string(expression.right) <> ")"
    end
  end
end
