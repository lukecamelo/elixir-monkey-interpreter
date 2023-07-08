defmodule Monkey.ParserTest do
  alias Monkey.AST.ReturnStatement
  alias Monkey.AST.LetStatement
  alias Monkey.AST.Node
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

  def test_let_statement(%LetStatement{} = let_statement, name) do
    assert Node.token_literal(let_statement) == "let"
    assert Node.token_literal(let_statement.name) == name
    assert let_statement.name.value == name
  end

  def test_return_statement(%ReturnStatement{} = return_statement) do
    assert Node.token_literal(return_statement) == "return"
  end

  def check_parser_errors(%Parser{errors: []}), do: IO.puts("No errors!")

  def check_parser_errors(%Parser{errors: errors} = parser) do
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
end
