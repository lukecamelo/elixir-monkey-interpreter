defprotocol Monkey.AST.Node do
  @doc "Returns the token literal of the `Node`."
  def token_literal(node)
end
