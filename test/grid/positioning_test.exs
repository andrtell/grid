defmodule PositioningTest do
  use ExUnit.Case
  doctest Grid.Positioning

  alias Grid.Positioning
  alias Grid.Cell

  test "No cells given" do
    assert Positioning.position_cells([]) == []
  end

  test "1 cell given" do
    assert Positioning.position_cells(
             [
               Cell.new(nil, row: 0, column: 0)
             ],
             row_gap: 0,
             column_gap: 0
           ) == [
             Cell.new(nil, row: 0, column: 0, x: 0, y: 0)
           ]
  end

  test "2 cells given. Grid has 1 row with row_gap=1" do
    assert Positioning.position_cells(
             [
               Cell.new(nil, row: 0, column: 0),
               Cell.new(nil, row: 0, column: 1)
             ],
             row_gap: 0,
             column_gap: 1
           ) == [
             Cell.new(nil, row: 0, column: 0, x: 0, y: 0),
             Cell.new(nil, row: 0, column: 1, x: 2, y: 0)
           ]
  end

  test "2 cells given. Grid has 1 column with column_gap=1" do
    assert Positioning.position_cells(
             [
               Cell.new(nil, row: 0, column: 0),
               Cell.new(nil, row: 1, column: 0)
             ],
             row_gap: 1,
             column_gap: 0
           ) == [
             Cell.new(nil, row: 0, column: 0, x: 0, y: 0),
             Cell.new(nil, row: 1, column: 0, x: 0, y: 2)
           ]
  end

  test "4 cells given. Grid has 2 rows and 2 columns with row_gap=1 and column_gap=1" do
    assert Positioning.position_cells(
             [
               Cell.new(nil, row: 0, column: 0),
               Cell.new(nil, row: 0, column: 1),
               Cell.new(nil, row: 1, column: 0),
               Cell.new(nil, row: 1, column: 1)
             ],
             row_gap: 1,
             column_gap: 1
           ) ==
             [
               Cell.new(nil, row: 0, column: 0, x: 0, y: 0),
               Cell.new(nil, row: 0, column: 1, x: 2, y: 0),
               Cell.new(nil, row: 1, column: 0, x: 0, y: 2),
               Cell.new(nil, row: 1, column: 1, x: 2, y: 2)
             ]
  end

  test "3 cells given. The second cell has row_span=2. Grid has 2 rows and 2 columns with row_gap=1 and column_gap=1" do
    assert Positioning.position_cells(
             [
               Cell.new(nil, row: 0, column: 0),
               Cell.new(nil, row: 0, column: 1, row_span: 2, cell_height: 2),
               Cell.new(nil, row: 1, column: 0)
             ],
             row_gap: 1,
             column_gap: 1
           ) == [
             Cell.new(nil, row: 0, column: 0, x: 0, y: 0),
             Cell.new(nil, row: 0, column: 1, row_span: 2, cell_height: 3, x: 2, y: 0),
             Cell.new(nil, row: 1, column: 0, x: 0, y: 2)
           ]
  end

  test "3 cells given, the first cell has col_span=2. Grid has 2 rows and 2 columns with row_gap=0 and column_gap=1" do
    assert Positioning.position_cells(
             [
               Cell.new(nil, row: 0, column: 0, column_span: 2, cell_width: 2),
               Cell.new(nil, row: 1, column: 0),
               Cell.new(nil, row: 1, column: 1)
             ],
             row_gap: 0,
             column_gap: 1
           ) == [
             Cell.new(nil, row: 0, column: 0, column_span: 2, cell_width: 3, x: 0, y: 0),
             Cell.new(nil, row: 1, column: 0, x: 0, y: 1),
             Cell.new(nil, row: 1, column: 1, x: 2, y: 1)
           ]
  end

  test "2 cells given with col_span=2. Grid has 2 rows and 2 columns with row_gap=0 and column_gap=1" do
    assert Positioning.position_cells(
             [
               Cell.new(nil, row: 0, column: 0, column_span: 2, cell_width: 2),
               Cell.new(nil, row: 1, column: 0, column_span: 2, cell_width: 2)
             ],
             row_gap: 0,
             column_gap: 1
           ) == [
             Cell.new(nil, row: 0, column: 0, column_span: 2, cell_width: 3, x: 0, y: 0),
             Cell.new(nil, row: 1, column: 0, column_span: 2, cell_width: 3, x: 0, y: 1)
           ]
  end
end
