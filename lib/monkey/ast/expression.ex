defmodule Monkey.AST.Expression do
  alias Monkey.AST.Node
  alias Monkey.Token

  @enforce_keys [:token]
  defstruct [:token]

  @type t() :: %__MODULE__{
          token: %Token{}
        }

  defimpl Node, for: __MODULE__ do
    def token_literal(expression), do: expression.token.literal
  end
end
