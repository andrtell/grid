defmodule Grid.PlacementTest do
  use ExUnit.Case
  doctest Grid.Placement

  alias Grid.Placement
  alias Grid.Cell

  test "No cells given (empty list). Grid has column_count=1" do
    assert Placement.place_cells([], column_count: 1) ==
             {[
                Cell.empty(row: 0, column: 0)
              ], 1, 1}
  end

  test "No cells given (empty list). Grid has column_count=2" do
    assert Placement.place_cells(
             [],
             column_count: 2
           ) ==
             {[
                Cell.empty(row: 0, column: 0, column_span: 2)
              ], 1, 2}
  end

  test "No cells given (empty list). Grid column_count=3" do
    assert Placement.place_cells(
             [],
             column_count: 3
           ) ==
             {[
                Cell.empty(row: 0, column: 0, column_span: 3)
              ], 1, 3}
  end

  test "1 cell given. Grid has column_count=1" do
    assert Placement.place_cells(
             [Cell.new(nil)],
             column_count: 1
           ) == {
             [Cell.new(nil, row: 0, column: 0)],
             1,
             1
           }
  end

  test "1 cell given with column_span=2. Grid has column_count=1" do
    assert Placement.place_cells(
             [Cell.new(nil, column_span: 2)],
             column_count: 1
           ) ==
             {[
                Cell.new(nil, column_span: 2, row: 0, column: 0)
              ], 1, 2}
  end

  test "2 cells given both with column_span=1. Grid has column_count=1" do
    assert Placement.place_cells(
             [Cell.new(nil), Cell.new(nil)],
             column_count: 1
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0),
                 Cell.new(nil, row: 1, column: 0)
               ],
               2,
               1
             }
  end

  test "2 cells given both with column_span=1. Grid has column_count=2" do
    assert Placement.place_cells(
             [Cell.new(nil), Cell.new(nil)],
             column_count: 2
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0),
                 Cell.new(nil, row: 0, column: 1)
               ],
               1,
               2
             }
  end

  test "2 cells given both with column_span=1. Grid has column_count=3" do
    assert Placement.place_cells(
             [Cell.new(nil), Cell.new(nil)],
             column_count: 3
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0),
                 Cell.new(nil, row: 0, column: 1),
                 Cell.empty(row: 0, column: 2)
               ],
               1,
               3
             }
  end

  test "2 cells given with column_span=1 and column_span=2. Grid has column_count=3" do
    assert Placement.place_cells(
             [
               Cell.new(nil),
               Cell.new(nil, column_span: 2)
             ],
             column_count: 3
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0),
                 Cell.new(nil, row: 0, column: 1, column_span: 2)
               ],
               1,
               3
             }

    assert Placement.place_cells(
             [
               Cell.new(nil),
               Cell.new(nil, column_span: 2)
             ],
             column_count: 3
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0),
                 Cell.new(nil, row: 0, column: 1, column_span: 2)
               ],
               1,
               3
             }
  end

  test "2 cells given with row_span=1 and row_span=2. Grid has column_count=2" do
    assert Placement.place_cells(
             [
               Cell.new(nil),
               Cell.new(nil, row_span: 2)
             ],
             column_count: 2
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0),
                 Cell.new(nil, row: 0, column: 1, row_span: 2),
                 Cell.empty(row: 1, column: 0)
               ],
               2,
               2
             }
  end

  test "1 cell with row_span=2 and 2 cells gwith column_span=2 given. Grid has column_count=3" do
    assert Placement.place_cells(
             [
               Cell.new(nil, row_span: 2),
               Cell.new(nil, column_span: 2),
               Cell.new(nil, column_span: 2)
             ],
             column_count: 3
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0, row_span: 2),
                 Cell.new(nil, row: 0, column: 1, column_span: 2),
                 Cell.new(nil, row: 1, column: 1, column_span: 2)
               ],
               2,
               3
             }
  end

  test "3 cells given all with row_span=2. Grid has column_count=3" do
    assert Placement.place_cells(
             [
               Cell.new(nil, row_span: 2),
               Cell.new(nil, row_span: 2),
               Cell.new(nil, row_span: 2)
             ],
             column_count: 3
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0, row_span: 2),
                 Cell.new(nil, row: 0, column: 1, row_span: 2),
                 Cell.new(nil, row: 0, column: 2, row_span: 2)
               ],
               2,
               3
             }
  end

  test "3 cells given all with col_span=2. Grid has column_count=2" do
    assert Placement.place_cells(
             [
               Cell.new(nil, column_span: 2),
               Cell.new(nil, column_span: 2),
               Cell.new(nil, column_span: 2)
             ],
             column_count: 2
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0, column_span: 2),
                 Cell.new(nil, row: 1, column: 0, column_span: 2),
                 Cell.new(nil, row: 2, column: 0, column_span: 2)
               ],
               3,
               2
             }
  end

  test "3 cells given all with col_span=2. Grid has column_count=3" do
    assert Placement.place_cells(
             [
               Cell.new(nil, column_span: 2),
               Cell.new(nil, column_span: 2),
               Cell.new(nil, column_span: 2)
             ],
             column_count: 3
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0, column_span: 2),
                 Cell.empty(row: 0, column: 2, row_span: 3),
                 Cell.new(nil, row: 1, column: 0, column_span: 2),
                 Cell.new(nil, row: 2, column: 0, column_span: 2)
               ],
               3,
               3
             }
  end

  test "Empty cell spans columns and rows I" do
    assert Placement.place_cells(
             [
               Cell.new(nil, column_span: 4, row_span: 4),
               Cell.new(nil, row_span: 3, column_span: 3)
             ],
             column_count: 5
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0, column_span: 4, row_span: 4),
                 Cell.empty(row: 0, column: 4, row_span: 4),
                 Cell.new(nil, row: 4, column: 0, column_span: 3, row_span: 3),
                 Cell.empty(row: 4, column: 3, column_span: 2, row_span: 3)
               ],
               7,
               5
             }
  end

  test "Empty cell spans columns and rows II" do
    assert Placement.place_cells(
             [
               Cell.new(nil, row_span: 2, column_span: 2),
               Cell.new(nil, column_span: 3, row_span: 3)
             ],
             column_count: 4
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0, column_span: 2, row_span: 2),
                 Cell.empty(row: 0, column: 2, column_span: 2, row_span: 2),
                 Cell.new(nil, row: 2, column: 0, column_span: 3, row_span: 3),
                 Cell.empty(row: 2, column: 3, column_span: 1, row_span: 3)
               ],
               5,
               4
             }
  end

  test "Empty cell spans columns and rows III" do
    assert Placement.place_cells(
             [
               Cell.new(nil, row_span: 3, column_span: 3),
               Cell.new(nil, row_span: 1, column_span: 1)
             ],
             column_count: 4
           ) ==
             {
               [
                 Cell.new(nil, row: 0, column: 0, row_span: 3, column_span: 3),
                 Cell.new(nil, row: 0, column: 3, row_span: 1, column_span: 1),
                 Cell.empty(row: 1, column: 3, row_span: 2, column_span: 1)
               ],
               3,
               4
             }
  end
end
