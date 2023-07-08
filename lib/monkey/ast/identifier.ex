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

  @spec new(%Token{}, String.t()) :: t()
  def new(%Token{} = token, value) do
    %__MODULE__{token: token, value: value}
  end

  defimpl Node, for: __MODULE__ do
    def token_literal(identifier), do: identifier.token.literal
  end
end
