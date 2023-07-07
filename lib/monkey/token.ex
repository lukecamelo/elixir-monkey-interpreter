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
    fn: "FUNCTION",
    let: "LET"
  }

  @keywords %{
    fn: "FUNCTION",
    let: "LET"
  }

  def new([type: type, literal: literal], remaining_chars)
      when is_atom(type) and is_binary(literal) do
    if Map.has_key?(@types, type) do
      {%__MODULE__{type: type, literal: literal}, remaining_chars}
    else
      {{:error, :invalid_token}, remaining_chars}
    end
  end

  def lookup_ident(identifier) do
    ident_as_key = String.to_atom(identifier)

    type = Map.get(@keywords, ident_as_key, :ident)

    literal =
      if type == :ident do
        String.upcase(identifier)
      else
        @keywords[ident_as_key]
      end

    [type: type, literal: literal]
  end
end
