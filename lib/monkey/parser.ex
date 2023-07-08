defmodule Monkey.Parser do
  alias Monkey.AST.ReturnStatement
  alias Monkey.AST.Program
  # alias Monkey.AST.Expression
  alias Monkey.AST.Identifier
  alias Monkey.AST.LetStatement
  alias Monkey.AST.Statement
  alias Monkey.Token

  @enforce_keys [:cur_token, :next_token, :tokens, :errors]
  defstruct [:cur_token, :next_token, :tokens, :errors]

  @type t() :: %__MODULE__{
          cur_token: %Token{},
          next_token: %Token{},
          tokens: [%Token{}],
          errors: [String.t()]
        }

  @doc """
  Initializes `%Parser{}` from list of `%Token{}`.
  """
  @spec new([%Token{}]) :: t()
  def new([cur | [next | rest]]) do
    %__MODULE__{cur_token: cur, next_token: next, tokens: rest, errors: []}
  end

  @doc """
  Returns a new `%Parser{}`, advancing the tokens (of type `%Token{}`) by one.
  """
  @spec next_token(t()) :: t()
  def next_token(%__MODULE__{tokens: []} = p) do
    %{p | cur_token: p.next_token, next_token: nil}
  end

  def next_token(%__MODULE__{tokens: [next_peek | rest]} = p) do
    %{p | cur_token: p.next_token, next_token: next_peek, tokens: rest}
  end

  @spec parse_program(t(), [%Statement{}]) :: {t(), %Program{}}
  def parse_program(%__MODULE__{} = parser, statements \\ []) do
    do_parse_program(parser, statements)
  end

  defp do_parse_program(%__MODULE__{cur_token: %Token{type: :eof}} = parser, statements) do
    program =
      statements
      |> Enum.reverse()
      |> Program.new()

    {parser, program}
  end

  defp do_parse_program(%__MODULE__{} = parser, statements) do
    {p, statement} = parse_statement(parser)

    statements =
      case statement do
        nil -> statements
        statement -> [statement | statements]
      end

    # p = next_token(p)

    do_parse_program(p, statements)
  end

  @spec parse_statement(t()) :: {t(), %LetStatement{} | nil}
  defp parse_statement(parser) do
    case parser.cur_token.type do
      :let ->
        parse_let_statement(parser)

      :return ->
        parse_return_statement(parser)
        # _ -> {parser, nil}
    end
  end

  @spec parse_let_statement(t()) :: {t(), %LetStatement{} | nil}
  defp parse_let_statement(p) do
    let_token = p.cur_token

    with {:ok, p, ident_token} <- expect_peek(p, :ident),
         {:ok, p, _assign_token} <- expect_peek(p, :assign),
         p <- __loop_until_semicolon__(p),
         p <- next_token(p) do
      identifier = Identifier.new(ident_token, ident_token.literal)
      # , value: %Expression{}}
      statement = %LetStatement{token: let_token, name: identifier}

      {p, statement}
    else
      {:error, err_p, _} ->
        err_p =
          err_p
          |> __loop_until_semicolon__()
          |> next_token()

        {err_p, nil}
    end
  end

  @spec parse_return_statement(t()) :: {t(), %ReturnStatement{} | nil}
  defp parse_return_statement(p) do
    return_token = p.cur_token

    with p <- __loop_until_semicolon__(p),
         p <- next_token(p) do
      statement = ReturnStatement.new(return_token)

      {p, statement}
    else
      {:error, err_p, _} ->
        err_p =
          err_p
          |> __loop_until_semicolon__()
          |> next_token()

        {err_p, nil}
    end
  end

  # temp until we parse expressions
  def __loop_until_semicolon__(parser) do
    case parser.cur_token do
      %{type: :semicolon} ->
        parser

      _ ->
        next_parser = next_token(parser)
        __loop_until_semicolon__(next_parser)
    end
  end

  @spec expect_peek(t(), :let | :ident | :assign) :: {:ok, t(), %Token{}} | {:error, t(), nil}
  defp expect_peek(%__MODULE__{next_token: %Token{type: type} = next} = parser, type) do
    p = next_token(parser)
    {:ok, p, next}
  end

  defp expect_peek(%__MODULE__{next_token: next} = parser, expected_type) do
    error = "expected type #{expected_type} but got #{next.type}"
    p = add_error(parser, error)
    {:error, p, nil}
  end

  @spec add_error(t(), String.t()) :: t()
  defp add_error(%__MODULE__{errors: errors} = parser, error) do
    %{parser | errors: [error | errors]}
  end
end
