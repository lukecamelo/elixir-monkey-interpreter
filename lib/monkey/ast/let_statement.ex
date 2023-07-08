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

  # @spec new(%Token{}, %Identifier{}, %Expression{}) :: t()
  def new(%Token{} = token, %Identifier{} = ident) do
    %__MODULE__{token: token, name: ident}
  end

  defimpl Node, for: __MODULE__ do
    def token_literal(let_statement), do: let_statement.token.literal

    def to_string(let_statement) do
      out = [
        Node.token_literal(let_statement),
        " ",
        Node.to_string(let_statement.name),
        " = "
      ]

      out = if let_statement.value, do: out ++ [Node.to_string(let_statement.value)], else: out
      Enum.join(out)
    end
  end
end
