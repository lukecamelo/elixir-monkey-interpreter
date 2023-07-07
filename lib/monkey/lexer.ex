defmodule Monkey.Lexer do
  @moduledoc """
  Lexer module for the Monkey interpreter  
  """

  alias Monkey.Token

  @doc """
  Given a string as `input`, return list of `Token` structs representing the input as tokens.
  """
  @spec tokenize(String.t()) :: [%Token{}]
  def tokenize(input) do
    chars = String.graphemes(input)
    do_tokenize(chars, [])
  end

  defp do_tokenize([], tokens), do: Enum.reverse([%Token{type: :eof, literal: "EOF"} | tokens])

  defp do_tokenize([ch | _] = chars, tokens) do
    {token, remaining_chars} =
      ch
      |> parse_char(chars)
      |> Token.new()

    do_tokenize(remaining_chars, [token | tokens])
  end

  @spec parse_char(String.t(), [String.t()]) :: [type: atom(), literal: String.t()]
  defp parse_char(char, remaining_chars) do
    token =
      case char do
        "+" ->
          [type: :plus, literal: char]

        "=" ->
          [type: :assign, literal: char]

        "(" ->
          [type: :lparen, literal: char]

        ")" ->
          [type: :rparen, literal: char]

        "{" ->
          [type: :lbrace, literal: char]

        "}" ->
          [type: :rbrace, literal: char]

        "," ->
          [type: :comma, literal: char]

        ";" ->
          [type: :semicolon, literal: char]

        _ ->
          case letter?(char) do
            true ->
              parse_identifier(remaining_chars)

            false ->
              [type: :illegal, literal: "ILLEGAL"]
          end
      end

    {token, tl(remaining_chars)}
  end

  defp parse_identifier(chars) do
    chars
    |> Enum.take_while(&letter?/1)
    |> Enum.join("")
    |> Token.lookup_ident()
  end

  @spec letter?(String.t()) :: boolean()
  defp letter?(char) do
    Regex.match?(~r/^[a-zA-Z_]$/, char)
  end
end
