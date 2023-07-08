defmodule Monkey.AST.Identifier do
  alias Monkey.AST.Node
  alias Monkey.Token

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  @type t() :: %__MODULE__{
          token: %Token{},
          # name of identifier, like, a variable name
          value: String.t()
        }

  defimpl Node, for: __MODULE__ do
    def token_literal(identifier), do: identifier.token.literal
  end
end