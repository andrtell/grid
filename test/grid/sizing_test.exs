defmodule Grid.SizingTest do
  use ExUnit.Case
  doctest Grid.Sizing

  alias Grid.Sizing
  alias Grid.Cell

  test "No cells given (empty list)" do
    assert Sizing.expand_cells([], 0, 0) == []
  end

  test "1 cell given" do
    assert Sizing.expand_cells([Cell.new(nil, row: 0, column: 0)], 1, 1) == [
             Cell.new(nil, row: 0, column: 0)
           ]
  end

  test "2 cells given. Grid has 2 columns" do
    assert Sizing.expand_cells(
             [
               Cell.new(nil, row: 0, column: 0),
               Cell.new(nil, row: 0, column: 1)
             ],
             1,
             2
           ) == [
             Cell.new(nil, row: 0, column: 0),
             Cell.new(nil, row: 0, column: 1)
           ]
  end

  test "2 cells given. Grid has 2 columns. Different cell_heights" do
    assert Sizing.expand_cells(
             [
               Cell.new(nil, row: 0, column: 0, cell_height: 2),
               Cell.new(nil, row: 0, column: 1, cell_height: 1)
             ],
             1,
             2
           ) == [
             Cell.new(nil, row: 0, column: 0, cell_height: 2),
             Cell.new(nil, row: 0, column: 1, cell_height: 2)
           ]
  end

  test "2 cells given. Grid has 2 rows. Different cell_widths" do
    assert Sizing.expand_cells(
             [
               Cell.new(nil, row: 0, column: 0, cell_width: 2),
               Cell.new(nil, row: 1, column: 0, cell_width: 1)
             ],
             2,
             1
           ) == [
             Cell.new(nil, row: 0, column: 0, cell_width: 2),
             Cell.new(nil, row: 1, column: 0, cell_width: 2)
           ]
  end

  test "4 cells given. Grid has 2 rows and 2 columns. Different cell_widths. Different row_heights." do
    assert Sizing.expand_cells(
             [
               Cell.new(nil, row: 0, column: 0, cell_width: 2, cell_height: 1),
               Cell.new(nil, row: 0, column: 1, cell_width: 1, cell_height: 2),
               Cell.new(nil, row: 1, column: 0, cell_width: 1, cell_height: 1),
               Cell.new(nil, row: 1, column: 1, cell_width: 2, cell_height: 1)
             ],
             2,
             2
           ) ==
             [
               Cell.new(nil, row: 0, column: 0, cell_width: 2, cell_height: 2),
               Cell.new(nil, row: 0, column: 1, cell_width: 2, cell_height: 2),
               Cell.new(nil, row: 1, column: 0, cell_width: 2),
               Cell.new(nil, row: 1, column: 1, cell_width: 2)
             ]
  end

  test "3 cells given. 1 cell has row_span=2. 2 cells has row_span=1. Grid has 2 columns." do
    assert Sizing.expand_cells(
             [
               Cell.new(nil, row: 0, column: 0, row_span: 2, cell_height: 4),
               Cell.new(nil, row: 0, column: 1),
               Cell.new(nil, row: 1, column: 1)
             ],
             2,
             2
           ) ==
             [
               Cell.new(nil, row: 0, column: 0, row_span: 2, cell_height: 4),
               Cell.new(nil, row: 0, column: 1, cell_height: 2),
               Cell.new(nil, row: 1, column: 1, cell_height: 2)
             ]
  end

  test "3 cells given. 1 cell has column_span=2, 2 cells have column_span=1, Grid has 2 rows." do
    assert Sizing.expand_cells(
             [
               Cell.new(nil, row: 0, column: 0, column_span: 2, cell_width: 4),
               Cell.new(nil, row: 1, column: 0),
               Cell.new(nil, row: 1, column: 1)
             ],
             2,
             2
           ) ==
             [
               Cell.new(nil, row: 0, column: 0, column_span: 2, cell_width: 4),
               Cell.new(nil, row: 1, column: 0, cell_width: 2),
               Cell.new(nil, row: 1, column: 1, cell_width: 2)
             ]
  end

  test "4 cells given. each cell has different row_span, column_span, cell_height and cell_width." do
    assert Sizing.expand_cells(
             [
               Cell.new(nil,
                 row: 0,
                 column: 0,
                 column_span: 2,
                 row_span: 2,
                 cell_width: 9,
                 cell_height: 11
               ),
               Cell.new(nil,
                 row: 0,
                 column: 2,
                 row_span: 3,
                 column_span: 2,
                 cell_width: 13,
                 cell_height: 17
               ),
               Cell.new(nil,
                 row: 2,
                 column: 0,
                 row_span: 1,
                 column_span: 2,
                 cell_width: 7,
                 cell_height: 7
               ),
               Cell.new(nil,
                 row: 3,
                 column: 0,
                 row_span: 1,
                 column_span: 4,
                 cell_width: 21,
                 cell_height: 1
               )
             ],
             4,
             5
           ) ==
             [
               Cell.new(nil,
                 row: 0,
                 column: 0,
                 column_span: 2,
                 row_span: 2,
                 cell_width: 9,
                 cell_height: 11
               ),
               Cell.new(nil,
                 row: 0,
                 column: 2,
                 row_span: 3,
                 column_span: 2,
                 cell_width: 13,
                 cell_height: 18
               ),
               Cell.new(nil,
                 row: 2,
                 column: 0,
                 row_span: 1,
                 column_span: 2,
                 cell_width: 9,
                 cell_height: 7
               ),
               Cell.new(nil,
                 row: 3,
                 column: 0,
                 row_span: 1,
                 column_span: 4,
                 cell_width: 22,
                 cell_height: 1
               )
             ]
  end
end
