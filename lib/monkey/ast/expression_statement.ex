defmodule Monkey.AST.ExpressionStatement do
  alias Monkey.AST.Node
  alias Monkey.Token

  @enforce_keys [:token, :expression]
  defstruct [:token, :expression]

  def new(%Token{} = token, expression) do
    %__MODULE__{token: token, expression: expression}
  end

  defimpl Node, for: __MODULE__ do
    def token_literal(statement), do: statement.token.literal

    def to_string(%{expression: nil}), do: ""
    def to_string(statement), do: Node.to_string(statement)
  end
end
