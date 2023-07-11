defprotocol Monkey.AST.Node do
  @moduledoc """
  Protocol defining contract for AST `Node`s.  
  """

  @doc """
  Returns the token literal of the `Node`. 

  ## Examples
   iex> token_literal(%Monkey.AST.InfixExpression{token: %Monkey.Token{type: :plus, literal: "+"}}
      "+"
  """
  def token_literal(node)
  @doc "Returns the `Node` as string for ease of debugging, I guess."
  def to_string(node)
end
