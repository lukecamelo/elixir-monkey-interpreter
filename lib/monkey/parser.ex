defmodule Monkey.Parser do
  alias Monkey.Token

  alias Monkey.AST.{
    ExpressionStatement,
    Identifier,
    IntegerLiteral,
    LetStatement,
    PrefixExpression,
    Program,
    ReturnStatement
  }

  @enforce_keys [:cur_token, :next_token, :tokens, :errors]
  defstruct [:cur_token, :next_token, :tokens, :errors]

  @type t() :: %__MODULE__{
          cur_token: %Token{},
          next_token: %Token{},
          tokens: [%Token{}],
          errors: [String.t()]
        }

  @type statement :: %ExpressionStatement{} | %LetStatement{} | %ReturnStatement{}

  @precedences %{
    lowest: 0,
    # ==
    equals: 1,
    # > or <
    less_greater: 2,
    # +
    sum: 3,
    # *
    product: 4,
    # -X or !X
    prefix: 5,
    # myFunction(X)
    call: 6
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

  @spec parse_program(t(), [statement]) :: {t(), %Program{}}
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

      _ ->
        parse_expression_statement(parser)
    end
  end

  @spec parse_let_statement(t()) :: {t(), %LetStatement{} | nil}
  defp parse_let_statement(p) do
    let_token = p.cur_token

    # TODO: i feel like this loop til semicolon -> next_token() business should only be written once
    with {:ok, p, ident_token} <- expect_peek(p, :ident),
         {:ok, p, _assign_token} <- expect_peek(p, :assign),
         p <- __loop_until_semicolon__(p),
         p <- next_token(p) do
      identifier = Identifier.new(ident_token, ident_token.literal)
      # , value: %Expression{}}
      statement = LetStatement.new(let_token, identifier)

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

  @spec parse_expression_statement(t()) :: {t(), %ExpressionStatement{} | nil}
  def parse_expression_statement(p) do
    token = p.cur_token

    {_, p, expression} = parse_expression(p, @precedences.lowest)

    p =
      p
      |> next_token()
      |> skip_semicolon()

    expression_statement = ExpressionStatement.new(token, expression)

    {p, expression_statement}
  end

  def parse_expression(p, _precedence) do
    case prefix_parse_fn(p.cur_token.type, p) do
      {p, nil} ->
        p = no_prefix_parse_error(p)
        {:ok, p, nil}

      {p, expression} ->
        {:ok, p, expression}
    end
  end

  defp prefix_parse_fn(:ident, p), do: parse_identifier(p)
  defp prefix_parse_fn(:int, p), do: parse_integer_literal(p)
  defp prefix_parse_fn(:bang, p), do: parse_prefix(p)
  defp prefix_parse_fn(:minus, p), do: parse_prefix(p)

  defp parse_identifier(p) do
    identifier = Identifier.new(p.cur_token, p.cur_token.literal)
    {p, identifier}
  end

  defp parse_integer_literal(p) do
    int = Integer.parse(p.cur_token.literal)

    case int do
      :error ->
        error = "could not parse #{p.cur_token.literal} to integer"
        p = add_error(p, error)
        {p, nil}

      {int, _} ->
        integer_literal = IntegerLiteral.new(p.cur_token, int)
        {p, integer_literal}
    end
  end

  defp parse_prefix(p) do
    cur_token = p.cur_token

    {_, p, right} =
      p
      |> next_token()
      |> parse_expression(@precedences.lowest)

    prefix_expression = PrefixExpression.new(cur_token, cur_token.literal, right)

    {p, prefix_expression}
  end

  defp no_prefix_parse_error(p) do
    error = "No prefix parse function for :#{p.cur_token.type} found"
    add_error(p, error)
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

  defp skip_semicolon(%__MODULE__{cur_token: %Token{type: :semicolon}} = p) do
    next_token(p)
  end

  defp skip_semicolon(p), do: p

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
