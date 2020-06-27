defmodule Homework do
  def task_1() do
    # Return "hello world" changing only right hand side of line 4
    {word_1, word_2} = {"elxir", "school"}

    word_1 <> " " <> word_2
  end

  def task_2() do
    # Return "hello world" by changing only order in the right clause
    {word_1, _, _, _, word_2} = {"hello", "world", "elixir", "is", "cool"}

    word_1 <> " " <> word_2
  end

  def task_3() do
    # Return "hello world" by changing the right hand side in the line 20
    list = ["hello", "world", "elixir", "is", "cool"]
    [word_1 | tail] = list
    [word_2 | _tail] = list  # here is the bug

    word_1 <> " " <> word_2
  end

  def task_4() do
    # Return "hello world" by adding the pin operator in the correct place
    word_1 = "hello"
    word_2 = "elixir"
    {word_2, word_2} = {"world", "elixir"}

    word_1 <> " " <> word_2
  end
end

ExUnit.start()

defmodule HomeworkTests do
  use ExUnit.Case

  test "Task 1" do
    assert Homework.task_1() == "hello world"
  end

  test "Task 2" do
    assert Homework.task_2() == "hello world"
  end

  test "Task 3" do
    assert Homework.task_3() == "hello world"
  end

  test "Task 4" do
    assert Homework.task_4() == "hello world"
  end
end
