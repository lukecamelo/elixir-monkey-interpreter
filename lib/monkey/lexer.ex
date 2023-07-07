defmodule Monkey.Lexer do
  @moduledoc """
  Lexer module for the Monkey interpreter
  """

  alias Monkey.Token

  @char_to_token_type %{
    "+" => :plus,
    "=" => :assign,
    "(" => :lparen,
    ")" => :rparen,
    "{" => :lbrace,
    "}" => :rbrace,
    "," => :comma,
    ";" => :semicolon,
    "-" => :minus,
    "!" => :bang,
    "*" => :asterisk,
    "/" => :slash,
    "<" => :lt,
    ">" => :gt
  }

  @doc """
  Given a string as `input`, return list of `Token` structs representing the input as tokens.
  """
  @spec tokenize(String.t()) :: [String.t()]
  def tokenize(input) do
    input
    |> String.graphemes()
    |> tokenize([])
  end

  @spec(tokenize([String.t()], [%Token{}]) :: [String.t()], [%Token{}])
  defp tokenize([], tokens), do: Enum.reverse([Token.new(type: :eof, literal: "EOF") | tokens])

  defp tokenize([ch | tail] = chars, tokens) do
    cond do
      whitespace?(ch) -> tokenize(tail, tokens)
      letter?(ch) -> read_identifier(chars, tokens)
      number?(ch) -> read_number(chars, tokens)
      true -> read_char(ch, tail, tokens)
    end
  end

  @spec read_char(String.t(), [String.t()], [%Token{}]) :: [String.t()]
  defp read_char(char, remaining_chars, tokens) do
    token_type = Map.get(@char_to_token_type, char, :illegal)
    token = Token.new(type: token_type, literal: char)

    tokenize(remaining_chars, [token | tokens])
  end

  # defp read_char(char, remaining_chars, tokens) do
  #   token =
  #     case char do
  #       "+" ->
  #         Token.new(type: :plus, literal: char)

  #       "=" ->
  #         Token.new(type: :assign, literal: char)

  #       "(" ->
  #         Token.new(type: :lparen, literal: char)

  #       ")" ->
  #         Token.new(type: :rparen, literal: char)

  #       "{" ->
  #         Token.new(type: :lbrace, literal: char)

  #       "}" ->
  #         Token.new(type: :rbrace, literal: char)

  #       "," ->
  #         Token.new(type: :comma, literal: char)

  #       ";" ->
  #         Token.new(type: :semicolon, literal: char)

  #       _ ->
  #         Token.new(type: :illegal, literal: "ILLEGAL")
  #     end

  #   tokenize(remaining_chars, [token | tokens])
  # end

  @spec read_number([String.t()], [%Token{}]) :: [String.t()]
  defp read_number(chars, tokens) do
    number =
      chars
      |> Enum.take_while(&number?/1)
      |> Enum.join("")

    token = Token.new(type: :int, literal: number)

    tokenize(delete_chars(chars, number), [token | tokens])
  end

  @spec read_identifier([String.t()], [%Token{}]) :: [String.t()]
  defp read_identifier(chars, tokens) do
    identifier =
      chars
      |> Enum.take_while(&letter?/1)
      |> Enum.join("")

    ident_key = Token.lookup_ident(identifier)

    token = Token.new(type: ident_key, literal: identifier)

    tokenize(delete_chars(chars, identifier), [token | tokens])
  end

  defp delete_chars(list, string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.reduce(list, fn char, acc ->
      List.delete(acc, char)
    end)
  end

  @spec whitespace?(String.t()) :: boolean()
  defp whitespace?(char) do
    char in [" ", "\n", "\r", "\t"]
  end

  @spec letter?(String.t()) :: boolean()
  defp letter?(char) do
    Regex.match?(~r/^[a-zA-Z_]$/, char)
  end

  @spec number?(String.t()) :: boolean()
  defp number?(char) do
    Regex.match?(~r/^[0-9]$/, char)
  end
end
