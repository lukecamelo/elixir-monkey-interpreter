defmodule Monkey.AST.ReturnStatement do
  alias Monkey.AST.Node
  alias Monkey.AST.Expression
  alias Monkey.Token

  # enforce keys once expression parsing is implemented
  # @enforce_keys [:token, :return_value]
  defstruct [:token, :return_value]

  @type t() :: %__MODULE__{
          token: %Token{},
          # expression
          return_value: %Expression{}
        }

  # @spec new(%Token{}, %Expression{}) :: t()
  def new(%Token{} = token) do
    %__MODULE__{token: token}
  end

  defimpl Node, for: __MODULE__ do
    def token_literal(statement), do: statement.token.literal

    def to_string(statement) do
      literal_string = Node.token_literal(statement) <> " "

      return_value_string =
        if statement.return_value, do: Node.to_string(statement.return_value), else: ""

      literal_string <> return_value_string <> ";"
    end
  end
end
