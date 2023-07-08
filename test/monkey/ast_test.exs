defmodule Monkey.ASTTest do
  alias Monkey.AST.Identifier
  alias Monkey.AST.LetStatement
  alias Monkey.AST.Program
  alias Monkey.Token

  use ExUnit.Case

  test "test Node.to_string/1" do
    program = %Program{
      statements: [
        %LetStatement{
          token: %Token{type: :let, literal: "let"},
          name: %Identifier{
            token: %Token{type: :ident, literal: "myVar"},
            value: "myVar"
          },
          value: %Identifier{
            token: %Token{type: :ident, literal: "anotherVar"},
            value: "anotherVar"
          }
        }
      ]
    }

    assert "let myVar = anotherVar" == Program.to_string(program)
  end
end
