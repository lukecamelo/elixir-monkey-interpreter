defmodule Monkey.Parser do
  @moduledoc """
  Module containing the logic for creating an Abstract Syntax Tree from a list of `Token`.
  """

  alias Monkey.Token

  alias Monkey.AST.{
    Boolean,
    ExpressionStatement,
    Identifier,
    InfixExpression,
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

  @type statement :: %ExpressionStatement{} | %LetStatement{} | %ReturnStatement{} | nil

  @type expression :: %IntegerLiteral{} | %PrefixExpression{} | %InfixExpression{} | %Identifier{} | %Boolean{}

  @precedences %{
    lowest: 0,
    # ==
    equals: 1,
    # > or <
    less_greater: 2,
    # + or -
    sum: 3,
    # *
    product: 4,
    # -X or !X
    prefix: 5,
    # myFunction(X)
    call: 6
  }

  @precedence_table %{
    eq: @precedences.equals,
    not_eq: @precedences.equals,
    lt: @precedences.less_greater,
    gt: @precedences.less_greater,
    plus: @precedences.sum,
    minus: @precedences.sum,
    slash: @precedences.product,
    asterisk: @precedences.product
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

  @spec parse_statement(t()) :: {t(), %LetStatement{} | %ReturnStatement{} | nil}
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

  @spec parse_return_statement(t()) :: {t(), %ReturnStatement{}} | {t(), nil}
  defp parse_return_statement(p) do
    return_token = p.cur_token

    with p <- __loop_until_semicolon__(p),
         p <- next_token(p) do
      statement = ReturnStatement.new(return_token)

      {p, statement}
    else
      # I'm not so sure this branch is even possible. vestigial?
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

  @spec parse_expression(t(), non_neg_integer()) :: {:ok, t(), expression} | {:error, t(), nil}
  defp parse_expression(p, precedence) do
    case prefix_parse_fn(p.cur_token.type, p) do
      {p, nil} ->
        p = no_prefix_parse_error(p)
        {:error, p, nil}

      {p, left_expression} ->
        {p, expression} = handle_infix(p, left_expression, precedence)
        {:ok, p, expression}
    end
  end

  @spec handle_infix(t(), expression, non_neg_integer()) :: {t(), expression}
  defp handle_infix(p, left, precedence) do
    continue = not token_is_semicolon?(p.next_token) and precedence < next_precedence(p)

    with true <- continue,
         infix_fn <- infix_parse_fn(p.next_token.type),
         true <- infix_fn != nil do
      p = next_token(p)
      {p, infix_expression} = infix_fn.(p, left)
      handle_infix(p, infix_expression, precedence)
    else
      _ -> {p, left}
    end
  end

  @spec prefix_parse_fn(atom(), t()) :: {t(), expression} | {t(), nil}
  defp prefix_parse_fn(:ident, p), do: parse_identifier(p)
  defp prefix_parse_fn(:int, p), do: parse_integer_literal(p)
  defp prefix_parse_fn(:bang, p), do: parse_prefix_expression(p)
  defp prefix_parse_fn(:minus, p), do: parse_prefix_expression(p)
  defp prefix_parse_fn(:lparen, p), do: parse_grouped_expression(p)
  defp prefix_parse_fn(true, p), do: parse_boolean_expression(p)
  defp prefix_parse_fn(false, p), do: parse_boolean_expression(p)

  @spec parse_identifier(t()) :: {t(), %Identifier{}}
  defp parse_identifier(p) do
    identifier = Identifier.new(p.cur_token, p.cur_token.literal)
    {p, identifier}
  end

  @spec parse_integer_literal(t()) :: {t(), %IntegerLiteral{}} | {t(), nil}
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

  @spec parse_prefix_expression(t()) :: {t(), %PrefixExpression{}}
  defp parse_prefix_expression(%__MODULE__{cur_token: cur_token} = p) do
    {_, p, right} =
      p
      |> next_token()
      |> parse_expression(@precedences.prefix)

    prefix_expression = PrefixExpression.new(cur_token, cur_token.literal, right)

    {p, prefix_expression}
  end

  @spec parse_grouped_expression(t()) :: {t(), expression} | {t(), nil}
  defp parse_grouped_expression(p) do
    {_, p, expression} =
      p
      |> next_token()
      |> parse_expression(@precedences.lowest)

    case expect_peek(p, :rparen) do
      {:ok, p, _} -> {p, expression}
      {:error, p, nil} -> {p, nil}
    end
  end

  @spec parse_boolean_expression(t()) :: {t(), %Boolean{}}
  defp parse_boolean_expression(%__MODULE__{cur_token: cur_token} = p) do
    boolean_expression = Boolean.new(cur_token, cur_token.type == true)

    {p, boolean_expression}
  end

  @spec no_prefix_parse_error(t()) :: t()
  defp no_prefix_parse_error(%__MODULE__{cur_token: %Token{type: type}} = p) do
    error = "No prefix parse function for :#{type} found"
    add_error(p, error)
  end

  @spec infix_parse_fn(atom()) :: (t(), expression -> {t(), %InfixExpression{}}) | nil
  defp infix_parse_fn(:plus), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(:minus), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(:slash), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(:asterisk), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(:eq), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(:not_eq), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(:lt), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(:gt), do: &parse_infix_expression(&1, &2)
  defp infix_parse_fn(_), do: nil

  @spec parse_infix_expression(t(), expression) :: {t(), %InfixExpression{}} | {t(), nil}
  defp parse_infix_expression(p, left) do
    cur_token = p.cur_token
    operator = cur_token.literal

    precedence = cur_precedence(p)

    with p <- next_token(p),
         {:ok, p, right} <- parse_expression(p, precedence) do
      infix_expression = InfixExpression.new(cur_token, operator, left, right)

      {p, infix_expression}
    else
      {:error, p, nil} ->
        {p, nil}
    end
  end

  # temp until we parse expressions in let/return statements
  @spec __loop_until_semicolon__(t()) :: t()
  defp __loop_until_semicolon__(parser) do
    case parser.cur_token do
      %{type: :semicolon} ->
        parser

      _ ->
        next_parser = next_token(parser)
        __loop_until_semicolon__(next_parser)
    end
  end

  @spec skip_semicolon(t()) :: t()
  defp skip_semicolon(%__MODULE__{cur_token: %Token{type: :semicolon}} = p) do
    next_token(p)
  end

  defp skip_semicolon(p), do: p

  @spec token_is_semicolon?(%Token{}) :: boolean()
  defp token_is_semicolon?(%Token{type: :semicolon}), do: true
  defp token_is_semicolon?(_), do: false

  @spec next_precedence(t()) :: non_neg_integer()
  defp next_precedence(%__MODULE__{next_token: next_token}) do
    Map.get(@precedence_table, next_token.type, @precedences.lowest)
  end

  @spec cur_precedence(t()) :: non_neg_integer()
  defp cur_precedence(%__MODULE__{cur_token: cur_token}) do
    Map.get(@precedence_table, cur_token.type, @precedences.lowest)
  end

  @spec expect_peek(t(), :let | :ident | :assign | :rparen) :: {:ok, t(), %Token{}} | {:error, t(), nil}
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
