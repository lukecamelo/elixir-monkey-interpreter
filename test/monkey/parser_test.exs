defmodule Monkey.ParserTest do
  alias Monkey.AST.{
    Boolean,
    ExpressionStatement,
    Identifier,
    InfixExpression,
    IntegerLiteral,
    LetStatement,
    Node,
    PrefixExpression,
    ReturnStatement
  }

  alias Monkey.Parser
  alias Monkey.Lexer

  use ExUnit.Case

  test "parses input; let statements" do
    input = """
    let x = 5;
    let y = 10;
    let foobar = 838383;
    """

    identifiers = ["x", "y", "foobar"]

    {parser, program} = parse_input(input)

    check_parser_errors(parser)

    program.statements
    |> Enum.zip(identifiers)
    |> Enum.each(fn {statement, ident} ->
      test_let_statement(statement, ident)
    end)

    assert 3 == length(program.statements)
  end

  test "parses input; return statements" do
    input = """
    return 5;
    return 10;
    return 993322;
    """

    {parser, program} = parse_input(input)

    check_parser_errors(parser)

    assert 3 == length(program.statements)

    Enum.each(program.statements, &test_return_statement/1)
  end

  test "parses input; identifier expression" do
    input = "foobar;"

    statement = parse_one_expression_statement(input)

    identifier = statement.expression

    test_identifier(identifier, "foobar")
  end

  test "parses input; integer literal expression" do
    input = "5;"

    statement = parse_one_expression_statement(input)

    integer_literal = statement.expression

    test_integer_literal(integer_literal, 5, "5")
  end

  test "parses input; prefix expression" do
    input = [{"!5;", "!", 5, "5"}, {"-15;", "-", 15, "15"}]

    Enum.each(input, fn {input, operator, value, literal} ->
      statement = parse_one_expression_statement(input)
      prefix = statement.expression

      test_prefix_expression(prefix, operator)
      test_integer_literal(prefix.right, value, literal)
    end)
  end

  test "parses input; infix expression" do
    input = [
      {"5 + 5;", 5, "+", 5},
      {"5 - 5;", 5, "-", 5},
      {"5 * 5;", 5, "*", 5},
      {"5 / 5;", 5, "/", 5},
      {"5 > 5;", 5, ">", 5},
      {"5 < 5;", 5, "<", 5},
      {"5 == 5;", 5, "==", 5},
      {"5 != 5;", 5, "!=", 5}
    ]

    Enum.each(input, fn {input_string, left_value, operator, right_value} ->
      statement = parse_one_expression_statement(input_string)
      infix = statement.expression

      test_infix_expression(infix, operator)
      test_integer_literal(infix.left, left_value, Integer.to_string(left_value))
      test_integer_literal(infix.right, right_value, Integer.to_string(right_value))
    end)
  end

  test "parses input; more complicated infix expressions" do
    input = [
      {"-a * b", "((-a) * b)"},
      {"!-a", "(!(-a))"},
      {"a + b + c", "((a + b) + c)"},
      {"a + b - c", "((a + b) - c)"},
      {"a * b * c", "((a * b) * c)"},
      {"a * b / c", "((a * b) / c)"},
      {"a + b / c", "(a + (b / c))"},
      {"a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"},
      {"5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"},
      {"5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"},
      {"3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"}
    ]

    test_multiple_expressions(input, &test_expression_to_string/2)
  end

  test "parses input; boolean expression" do
    input = [{"true;", true}, {"false;", false}]

    test_multiple_expressions(input, &test_boolean_expression/2)
  end

  ####################
  # Test Helpers
  ####################

  defp test_multiple_expressions(input, test_fn) do
    Enum.each(input, fn {input_string, value} ->
      statement = parse_one_expression_statement(input_string)

      expression = statement.expression

      test_fn.(expression, value)
    end)
  end

  defp test_let_statement(%LetStatement{} = let_statement, name) do
    assert Node.token_literal(let_statement) == "let"
    assert Node.token_literal(let_statement.name) == name
    assert let_statement.name.value == name
  end

  defp test_return_statement(%ReturnStatement{} = return_statement) do
    assert Node.token_literal(return_statement) == "return"
  end

  defp test_identifier(expression, value) do
    assert %Identifier{} = expression
    assert expression.value == value
    assert Node.token_literal(expression) == value
  end

  defp test_integer_literal(integer_literal, value, token_literal_value) do
    assert %IntegerLiteral{} = integer_literal
    assert integer_literal.value == value
    assert Node.token_literal(integer_literal) == token_literal_value
  end

  defp test_prefix_expression(prefix, operator) do
    assert %PrefixExpression{} = prefix
    assert prefix.operator == operator
  end

  defp test_infix_expression(infix, operator) do
    assert %InfixExpression{} = infix
    assert infix.operator == operator
  end

  defp test_boolean_expression(expression, value) do
    assert %Boolean{} = expression

    assert expression.value == value
    assert Node.token_literal(expression) == Atom.to_string(value)
  end

  defp test_expression_to_string(expression, string_value) do
    assert Node.to_string(expression) == string_value 
  end

  ####################
  # Parsing Helpers
  ####################

  def check_parser_errors(%Parser{errors: errors}) do
    Enum.each(errors, &IO.puts("Disaster! Error: #{&1}"))
  end

  def parse_input(input) do
    tokens = Lexer.tokenize(input)
    parser = Parser.new(tokens)

    {parser, program} = Parser.parse_program(parser)

    if length(parser.errors) > 0, do: IO.inspect(parser.errors)
    assert length(parser.errors) == 0

    {parser, program}
  end

  def parse_one_expression_statement(input) do
    {_, program} = parse_input(input)
    assert length(program.statements) == 1

    statement = List.first(program.statements)
    assert %ExpressionStatement{} = statement
    statement
  end
end
