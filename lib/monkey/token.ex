defmodule Monkey.Token do
  @enforce_keys [:type, :literal]
  defstruct [:type, :literal]

  @type t() :: %__MODULE__{
          type: atom(),
          literal: String.t()
        }

  @types %{
    illegal: "ILLEGAL",
    eof: "EOF",
    # identifiers + literals
    ident: "IDENT",
    int: "INT",
    # operators
    assign: "=",
    plus: "+",
    minus: "-",
    bang: "!",
    asterisk: "*",
    slash: "/",
    lt: "<",
    gt: ">",
    eq: "==",
    not_eq: "!=",
    # delimiters
    comma: ",",
    semicolon: ";",
    lparen: "(",
    rparen: ")",
    lbrace: "{",
    rbrace: "}",
    # keywords
    function: "FUNCTION",
    let: "LET",
    if: "IF",
    else: "else",
    return: "RETURN",
    true: "TRUE",
    false: "FALSE"
  }

  @keywords %{
    "fn" => :function,
    "let" => :let,
    "if" => :if,
    "else" => :else,
    "return" => :return,
    "true" => true,
    "false" => false
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
