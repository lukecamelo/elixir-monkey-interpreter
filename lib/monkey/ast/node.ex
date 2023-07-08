defprotocol Monkey.AST.Node do
  @doc "Returns the token literal of the `Node`."
  def token_literal(node)
  @doc "Returns the `Node` as string for ease of debugging, I guess."
  def to_string(node)
end
