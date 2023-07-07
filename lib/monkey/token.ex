defmodule Monkey.Token do
  @enforce_keys [:type, :literal]
  defstruct [:type, :literal]

  @types %{
    illegal: "ILLEGAL",
    eof: "EOF",
    # identifiers + literals
    ident: "IDENT",
    int: "INT",
    # operators
    assign: "=",
    plus: "+",
    # delimiters
    comma: ",",
    semicolon: ";",
    lparen: "(",
    rparen: ")",
    lbrace: "{",
    rbrace: "}",
    # keywords
    function: "FUNCTION",
    let: "LET"
  }

  @keywords %{
    "fn" => :function,
    "let" => :let
  }

  def new(type: type, literal: literal)
      when is_atom(type) and is_binary(literal) do
    if Map.has_key?(@types, type) do
      %__MODULE__{type: type, literal: literal}
    else
      raise "Invalid Token type: #{inspect(type)}"
    end
  end

  def lookup_ident(ident) do
    Map.get(@keywords, ident, :ident)
  end
end
