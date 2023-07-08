defmodule Monkey.AST.Statement do
  alias Monkey.AST.Node
  alias Monkey.Token

  @enforce_keys [:token]
  defstruct [:token]

  @type t() :: %__MODULE__{
          token: %Token{}
        }

  defimpl Node, for: __MODULE__ do
    def token_literal(statement), do: statement.token.literal
  end
end
