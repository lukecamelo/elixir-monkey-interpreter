defmodule Monkey.Repl do
  @moduledoc """
  REPL for the Monkey programming language.
  """
  alias Monkey.Lexer

  @prompt ">>"

  def start(input \\ :stdio, output \\ :stdio) do
    input
    |> get_line()
    |> process_line(output)

    start(input, output)
  end

  def get_line(input) do
    IO.write(@prompt)
    IO.gets(input, "")
  end

  def process_line(line, output) do
    line
    |> Lexer.tokenize()
    |> Enum.take_while(&(&1.type != :eof))
    |> Enum.each(fn token ->
      IO.write(output, "#{inspect(token)}\n")
    end)
  end
end
