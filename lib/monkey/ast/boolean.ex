defmodule Monkey.AST.Boolean do
  alias Monkey.AST.Node
  alias Monkey.Token

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  @type t() :: %__MODULE__{
    token: %Token{},
    value: boolean()
  }

  @spec new(%Token{}, boolean()) :: t()
  def new(%Token{} = token, value) do
    %__MODULE__{token: token, value: value} 
  end
 
  defimpl Node, for: __MODULE__ do
    def token_literal(bool), do: bool.token.literal 
    def to_string(bool), do: bool.token.literal 
  end
end
