defmodule Grid.Sizing do
  @moduledoc """
  A module for giving cells a height and width based on their row, column and spans.
  """

  alias Grid.T
  alias Grid.Cell

  @doc ~S"""
  Calulcates the height of each row and the width of each column in a grid.

  Then sets the `cell_height` and `cell_width` fields of each cell in the grid
  to the height and width of the row and column it occupies.

  ## Arguments

    * `cells` - A list of cells.
    * `row_count` - The number of rows in the grid.
    * `column_count` - The number of columns in the grid.
    * `options` - The options for expand the cells.

  These invariants must hold:

    * The `cells` are sorted by row and column.
    * There are no gaps between cells.

  See also:

    * `Grid.Placement.place_cells/2`

  ## Options

    * `min_row_height` - The minimum height of a row (default: 1).
    * `min_column_width` - The minimum width of a column (default: 1).

  ## Returns

    A list of cells with their `cell_height` and `cell_width` set to a new 
    value (if needed).

  ## How it works

  Each cell initially has a `cell_height` and `cell_width` set.

                   cell_width=1
                      ┌╌╌╌┐
                    ┌ ╭───┬───╮ ┐
      cell_height=1 ┊ │   │   │ ┊
                    └ │   │   │ ┊ cell_height=3
                      │   │   │ ┊
                      ├───┴───┤ ┘
                      │       │
                      ╰───────╯
                      └╌╌╌╌╌╌╌┘
                     cell_width=4

  After expand_cells has been applied:

                   cell_width=2
                      ┌╌╌╌┐
                    ┌ ╭───┬───╮ ┐
                    ┊ │   │   │ ┊
      cell_height=3 ┊ │   │   │ ┊ cell_height=3
                    ┊ │   │   │ ┊
                    └ ├───┴───┤ ┘
                      │       │
                      ╰───────╯
                      └╌╌╌╌╌╌╌┘
                     cell_width=4

  ## Examples

      iex> [
      ...>  Grid.cell("red", cell_width: 3, row: 0, column: 0), 
      ...>  Grid.cell("orange", cell_width: 5, row: 1, column: 0)
      ...> ]
      ...> |> Grid.Sizing.expand_cells(2, 1)
      [
        %Grid.Cell{
          row: 0,
          column: 0,
          row_span: 1,
          column_span: 1,
          cell_height: 1,
          cell_width: 5, # <- no longer 3
          data: "red",
          empty: false,
          x: nil,
          y: nil
        },
        %Grid.Cell{
          row: 1,
          column: 0,
          row_span: 1,
          column_span: 1,
          cell_height: 1,
          cell_width: 5, # <- widest cell in the column
          data: "orange",
          empty: false,
          x: nil,
          y: nil
        }
      ]
  """
  @spec expand_cells([Cell.t()], T.size(), T.size(), Keyword.t()) :: [Cell.t()]
  def expand_cells(cells, row_count, column_count, options \\ []) do
    options = default_options(options)
    row_heights = row_heights(cells, row_count, options)
    column_widths = column_widths(cells, column_count, options)
    set_dimensions(cells, row_heights, column_widths)
  end

  ##############################################################################
  #
  # default_options/1
  #
  @spec default_options(Keyword.t()) :: Keyword.t()
  defp default_options(options) do
    Keyword.merge(
      [
        min_row_height: 1,
        min_column_width: 1
      ],
      options
    )
  end

  ##############################################################################
  #
  # set_dimensions/3
  #
  # Wrapper around set_dimensions/6.
  #
  @spec set_dimensions([Cell.t()], [T.size()], [{T.index(), T.size()}]) :: [Cell.t()]
  defp set_dimensions(cells, row_heights, column_widths) do
    set_dimensions([], cells, 0, row_heights, [], column_widths)
  end

  ##############################################################################
  #
  # set_dimensions/6
  #
  # Sets the cell_height and cell_width of each cell in the grid.
  #
  # This clause matches:
  #
  #   * No more cells.
  #
  # Action:
  #
  #   * Return the result.
  #
  @spec set_dimensions(
          [Cell.t()],
          [Cell.t()],
          T.size(),
          [T.size()],
          [{T.index(), T.size()}],
          [{T.index(), T.size()}]
        ) :: [Cell.t()]
  defp set_dimensions(cells_out, [], _row, _rhs, _cws1, _cws2) do
    Enum.reverse(cells_out)
  end

  #
  # This clause matches:
  #
  #   * Cell is ahead of the current row height.
  #
  # Action:
  #
  #   * Increment the row counter.
  #   * Pop row_heights.
  #
  defp set_dimensions(cells_out, [cell | _] = cells_in, row, [_ | rs], c1, c2)
       when cell.row > row do
    set_dimensions(cells_out, cells_in, row + 1, rs, c1, c2)
  end

  #
  # This clause matches:
  #
  #   * Cell is behind current column width.
  # 
  #     c1 = [{2, 10}, {1, 17}, {0, 21}] ; c2 = [{3, 31}]
  #            ┊                                  ┊ 
  #          ╭───╮                             current
  #          │   │ cell.column=2
  #          ╰───╯
  #
  # Action:
  #
  #   * Shift column width and try again.
  #
  defp set_dimensions(
         cells_out,
         [cell | _] = cells_in,
         row,
         rs,
         [prev | c1],
         [{column, _} | _] = c2
       )
       when cell.column < column do
    set_dimensions(cells_out, cells_in, row, rs, c1, [prev | c2])
  end

  #
  # This clause matches:
  #
  #   * Cell is ahead of current column width.
  # 
  #     c1 = [{0, 10}] ; c2 = [{1, 31}, {2, 17}]
  #                             ┊        ┊
  #                           current  ╭───╮
  #                                    │   │ cell.column=2
  #                                    ╰───╯
  #
  # Action:
  #
  #   * Shift column and try again.
  #
  defp set_dimensions(cells_out, [cell | _] = cells_in, row, rs, c1, [{column, _} = curr | c2])
       when cell.column > column do
    set_dimensions(cells_out, cells_in, row, rs, [curr | c1], c2)
  end

  #
  # This clause matches:
  #
  #   * No more column widths.
  # 
  #     c1 = [{1, 12}, {0, 10}] ; c2 = [ ]
  #                                     ┊ 
  #                                  current
  #
  #   * Cell is ahead of the current column width.
  #
  # Action:
  #
  #   * Raise an error.
  #
  defp set_dimensions(_cells_out, [cell | _], _row, _rs, [{column, _} | _], [])
       when cell.column > column do
    raise ArgumentError, message: "The given `column_count` to low."
  end

  #
  # This clause matches:
  #
  #   * No more column widths.
  # 
  #     c1 = [{1, 12}, {0, 10}] ; c2 = [ ]
  #                                     ┊ 
  #                                  current
  # Action:
  #
  #   * Shift column and try again.
  #
  defp set_dimensions(cells_out, cells_in, row, rs, [cw | c1], []) do
    set_dimensions(cells_out, cells_in, row, rs, c1, [cw])
  end

  #
  # This clause matches:
  #
  #   * Cell is on the current row and column.
  #
  # Action:
  #
  #   * Set cell dimensions.
  #
  defp set_dimensions(cells_out, [cell | cells_in], row, [h | _] = rs, c1, [{_, w} | _] = c2) do
    cell_height =
      if cell.row_span == 1 do
        h
      else
        Enum.take(rs, cell.row_span) |> Enum.sum()
      end

    cell_width =
      if cell.column_span == 1 do
        w
      else
        c2
        |> Enum.take(cell.column_span)
        |> Enum.map(&elem(&1, 1))
        |> Enum.sum()
      end

    cell = %{cell | cell_width: cell_width, cell_height: cell_height}

    set_dimensions([cell | cells_out], cells_in, row, rs, c1, c2)
  end

  ##############################################################################
  #
  # row_heights/3
  #
  # Calculates the row heights given a list of cells.
  #
  # Arguments:
  #
  #  * cells - A list of cells.
  #  * options - A keyword list of options.
  #
  # How it works:
  #
  #   Each cell has a `row_span` and `cell_height` set.
  #   
  #                  row_span=1
  #                      ↑
  #                    ╭───┬───╮
  #                    │   │   │ 
  #                    ├───┤   │
  #                    │   │   │ <- row_span=3
  #      row_span=2 -> │   │   │
  #                    │   │   │
  #                    ╰───┴───╯
  #  
  #                 cell_height=10
  #                      ↑
  #                    ╭───┬───╮
  #                    │   │   │ 
  #                    ├───┤   │
  #                    │   │   │ <- cell_height=36
  #   cell_height=20-> │   │   │
  #                    │   │   │
  #                    ╰───┴───╯
  #  
  #   There is also a `min_row_height` option.
  #  
  #   This function passes over the list of cells twice.
  #  
  #   In the first pass the row_heights are calculated based on
  #   any cell with a `row_span` of 1 and the `min_row_height` option.
  #  
  #    ╭───┬───╮
  #    │ x │   │ 
  #    ├───┤   │
  #    │   │   │ (with a `min_row_height` of 5)
  #    │   │   │
  #    │   │   │
  #    ╰───┴───╯
  #
  #    [10, 5, 5] 
  #  
  #   In the second pass the row_heights are adjusted such that any cell
  #   with a `row_span` > 1 will have its excess height distributed evenly
  #   across the rows it spans.
  #
  #   Like so:
  #
  #    ╭───┬───╮      ╭───┬───╮
  #    │   │   │      │   │   │  
  #    ├───┤   │      ├───┤   │
  #    │   │   │      │   │ x │
  #    │ x │   │      │   │   │
  #    │   │   │      │   │   │
  #    ╰───┴───╯      ╰───┴───╯
  #                               
  #   [10, 10, 10]   [12, 12, 12] 
  #
  @spec row_heights([Cell.t()], T.size(), keyword()) :: [integer()]
  defp row_heights(cells, row_count, options) do
    r =
      row_heights_1(
        cells,
        0,
        [],
        0..(row_count - 1) |> Enum.map(fn _ -> options[:min_row_height] end)
      )

    row_heights_2(
      cells,
      0,
      [],
      r
    )
  end

  ##############################################################################
  #
  # row_heights_1/4
  #
  # Calculates the row heights given a list of cells only taking cells with
  # row_span=1 into account.
  #
  # This clause matches:
  #
  #   * No more cells.
  #
  # Action:
  #
  #   * Return the result.
  #
  @spec row_heights_1([Cell.t()], T.index(), [T.size()], [T.size()]) :: [T.size()]
  defp row_heights_1([], _row, r1, r2) do
    Enum.reverse(r1, r2)
  end

  #
  # This clause matches:
  #
  #   * Cells left, but no more rows.
  #
  # Action:
  #
  #   * Raise an error.
  #
  defp row_heights_1(_cells, _row, _r1, []) do
    raise ArgumentError, message: "The given `row_count` too small"
  end

  #
  # This clause matches:
  #
  #   * Cell has a `row_span` of 2 or more.
  #
  #    ╭───╮
  #    │   │  
  #    │   │ row_span > 1
  #    │   │ 
  #    ╰───╯    
  #
  # Action:
  #
  #   * Skip the cell.
  #
  defp row_heights_1([cell | cells], row, r1, r2) when cell.row_span > 1 do
    row_heights_1(cells, row, r1, r2)
  end

  #
  # This clause matches:
  #
  #   * Cell that is not on the current row.
  #
  # Action:
  #
  #   * Increment the row counter.
  #   * Shift row_heights.
  #
  defp row_heights_1([cell | _] = cells, row, r1, [curr_rh | r2]) when cell.row > row do
    row_heights_1(cells, row + 1, [curr_rh | r1], r2)
  end

  #
  # This clause matches:
  #
  #   * Cell is on current row.
  #
  # Action:
  #
  #   * Calculate a new row height.
  #
  defp row_heights_1([cell | cells], row, r1, [curr_rh | r2]) do
    row_heights_1(cells, row, r1, [max(curr_rh, cell.cell_height) | r2])
  end

  ##############################################################################
  #
  # row_heights_2/4
  #
  # This function is called after `row_heights_1/4` and adjusts the row heights
  # such that any cell with a `row_span` > 1 will have its excess height 
  # distributed evenly across the rows it spans.
  #
  # This clause matches:
  #
  #   * No more cells.
  #
  # Action:
  #
  #   * Return the result.
  #
  @spec row_heights_2([Cell.t()], T.index(), [T.size()], [T.size()]) :: [T.size()]
  defp row_heights_2([], _row, r1, r2) do
    Enum.reverse(r1, r2)
  end

  #
  # This clause matches:
  #
  #   * Cell has a `row_span` of 1.
  #
  # Action:
  #
  #   * Skip cell.
  #
  defp row_heights_2([cell | cells], row, r1, r2) when cell.row_span < 2 do
    row_heights_2(cells, row, r1, r2)
  end

  #
  # This clause matches:
  #
  #   * Cell is not on the current row.
  #
  # Action:
  #
  #   * Increment the row counter
  #   * Shift row_heights.
  #
  defp row_heights_2([cell | _] = cells, row, r1, [curr_rh | r2]) when cell.row > row do
    row_heights_2(cells, row + 1, [curr_rh | r1], r2)
  end

  #
  # This clause matches:
  #
  #   * Cell is on the current row.
  #
  # Action:
  #
  #   * Calculate a new max heights for all the rows this cell spans.
  #   * Shift row heights.
  #
  defp row_heights_2([cell | cells], row, r1, r2) do
    {span, r2_rest} = Enum.split(r2, cell.row_span)

    span_height = span |> Enum.sum()

    diff = cell.cell_height - span_height

    if diff > 0 do
      plus = div(diff, cell.row_span)
      r = rem(diff, cell.row_span)

      span = Enum.with_index(span, fn h, i -> h + plus + if(i < r, do: 1, else: 0) end)

      row_heights_2(cells, row, r1, span ++ r2_rest)
    else
      row_heights_2(cells, row, r1, r2)
    end
  end

  ##############################################################################
  #
  # column_widths/3
  #
  # Calculates the column widths given a list of cells.
  #
  # Arguments:
  #
  #  * cells - A list of cells.
  #  * column_count - The number of columns in the grid.
  #  * options - A keyword list of options.
  #
  # How it works:
  #
  #   Each cell has a `column_span` and `cell_width` set.
  #   
  #      column_span=1
  #        ↑
  #      ╭───┬───────╮
  #      │   │       │ <- column_span=2
  #      ├───┴───────┤
  #      │           │ <- column_span=2
  #      ╰───────────╯
  #  
  #      cell_width=10
  #        ↑
  #      ╭───┬───────╮
  #      │   │       │ <- cell_width=20
  #      ├───┴───────┤
  #      │           │ <- cell_width=36
  #      ╰───────────╯
  #  
  #   There is also a `min_column_width` option.
  #  
  #   This function passes over the list of cells twice.
  #  
  #   In the first pass the column_widths are calculated based on cells with a 
  #   `column_span` of 1 and the `min_column_width` option.
  #  
  #      ╭───┬───────╮
  #      │ x │       │
  #      ├───┴───────┤ (with a `min_column_width` of 5)
  #      │           │
  #      ╰───────────╯
  #
  #   => [{0, 10}, {1, 5}, {2, 5}] 
  #  
  #   In the second pass the column_widths are adjusted such that any cell
  #   with a `column_span` > 1 will have its excess width distributed evenly
  #   across the columns it spans.
  #
  #   Like so:
  #
  #      ╭───┬───────╮
  #      │   │   x   │
  #      ├───┴───────┤
  #      │           │
  #      ╰───────────╯
  #
  #   => [{0, 10}, {1, 10}, {2, 10}] 
  #  
  #      ╭───┬───────╮
  #      │   │       │
  #      ├───┴───────┤
  #      │     x     │
  #      ╰───────────╯
  #  
  #   => [{0, 12}, {1, 12}, {2, 12}] 
  #
  @spec column_widths([Cell.t()], T.size(), Keyword.t()) :: [{T.index(), T.size()}]
  defp column_widths(cells, column_count, options) do
    cw1 =
      column_widths_1(
        cells,
        [],
        0..(column_count - 1) |> Enum.map(&{&1, options[:min_column_width]})
      )

    column_widths_2(
      cells,
      [],
      cw1
    )
  end

  ##############################################################################
  #
  # column_widths_1/3
  #
  # Calculates the column widths given a list of cells only taking into account
  # cells with a `column_span` of 1.
  #
  # This clause matches:
  #
  #   * No more cells.
  #
  # Action:
  #
  #   * Return the results.
  #
  @spec column_widths_1(
          [Cell.t()],
          [{T.size(), T.size()}],
          [{T.size(), T.size()}]
        ) :: [
          {T.size(), T.size()}
        ]
  defp column_widths_1([], c1, c2) do
    Enum.reverse(c1, c2)
  end

  #
  # This clause matches:
  #
  #   * Cell has a `column_span` of 2 or more.
  #
  #    ╭──────╮    
  #    │      │ column_span > 1
  #    ╰──────╯    
  #
  # Action:
  #
  #   * Skip cell.
  #
  defp column_widths_1([cell | cells], c1, c2) when cell.column_span >= 2 do
    column_widths_1(cells, c1, c2)
  end

  #
  # This clause matches:
  #
  #   * Column is behind the current column width.
  # 
  #     c1 = [{2, 10}, {1, 17}, {0, 21}] ; c2 = [{3, 31}]
  #            ┊                                  ┊ 
  #          ╭───╮                             current
  #          │   │ cell.column=2
  #          ╰───╯
  #
  # Action:
  #
  #   * Shift column widths and try again.
  #
  defp column_widths_1([cell | _] = cells, [prev | c1], [{column, _} | _] = c2)
       when cell.column < column do
    column_widths_1(cells, c1, [prev | c2])
  end

  #
  # This clause matches:
  #
  #   * Cell is ahead of the current column width.
  # 
  #     c1 = [{0, 10}] ; c2 = [{1, 31}, {2, 17}]
  #                             ┊        ┊
  #                          current     ┊
  #                                    ╭───╮
  #                                    │   │ cell.column=2
  #                                    ╰───╯
  #
  # Action:
  #
  #   * Shift column widths and try again.
  #
  defp column_widths_1([cell | _] = cells, c1, [{column, _} = curr | c2])
       when cell.column > column do
    column_widths_1(cells, [curr | c1], c2)
  end

  #
  # This clause matches:
  #
  #   * No more column widths.
  # 
  #     c1 = [{1, 12}, {0, 10}] ; c2 = [ ]
  #                                     ┊ 
  #                                  current
  #
  #   * Cell is ahead of the current column width.
  #
  # Action:
  #
  #   * Raise an error.
  #
  defp column_widths_1([cell | _], [{column, _} | _], []) when cell.column > column do
    raise ArgumentError, message: "The given `column_count` to low."
  end

  #
  # This clause matches:
  #
  #   * No more column widths.
  # 
  #     c1 = [{1, 12}, {0, 10}] ; c2 = [ ]
  #                                     ┊ 
  #                                  current
  #
  # Action:
  #
  #   * Shift column widths and try again.
  #
  defp column_widths_1(cells, [cw | c1], []) do
    column_widths_1(cells, c1, [cw])
  end

  #
  # This clause matches:
  #
  #   * Cell is at the current column.
  # 
  #     c1 = [{0, 10}] ; c2 = [{1, 31}, {2, 17}]
  #                             ┊        
  #                          current 
  #                             ┊
  #                           ╭───╮ 
  #                           │   │ cell.column=1
  #                           ╰───╯
  #
  # Action:
  #
  #   * Calculate a new column width.
  #   * Shift column.
  #
  defp column_widths_1([cell | cells], c1, [{column, w} | c2])
       when cell.column == column do
    column_widths_1(cells, [{column, max(cell.cell_width, w)} | c1], c2)
  end

  ##############################################################################
  #
  # column_widths_2/3
  #
  #
  # This function is called after `column_widths_1/3` and adjusts the column
  # widths such that any cell with a `column_span` > 1 will have its excess
  # width distributed evenly across the columns it spans.
  #
  # This clause matches:
  #
  #   * No more cells.
  #
  # Action:
  #
  #   * Return the result.
  #
  @spec column_widths_2(
          [Cell.t()],
          [{T.size(), T.size()}],
          [{T.size(), T.size()}]
        ) :: [
          {T.size(), T.size()}
        ]
  defp column_widths_2([], c1, c2) do
    Enum.reverse(c1, c2)
  end

  #
  # This clause matches:
  #
  #   * Cell has column_span == 1.
  #
  #    ╭───╮    
  #    │   │ column_span == 1
  #    ╰───╯    
  #
  # Action:
  #
  #   * Skip cell.
  #
  defp column_widths_2([cell | cells], c1, c2) when cell.column_span < 2 do
    column_widths_2(cells, c1, c2)
  end

  #
  # This clause matches:
  #
  #   * Cell is behind the current column width.
  # 
  #     [{2, 10}, {1, 17}, {0, 21}] ; [{3, 31}]
  #       ┊                             ┊
  #       ┊                          current
  #     ╭─────╮
  #     │     │ cell.column=2
  #     ╰─────╯
  #
  # Action:
  #
  #   * Shift column widths and try again.
  #
  defp column_widths_2([cell | _] = cells, [prev | c1], [{column, _} | _] = c2)
       when cell.column < column do
    column_widths_2(cells, c1, [prev | c2])
  end

  #
  # cell_widths_2/3
  #
  # This clause matches:
  #
  #   * Cell is ahead of the current column width.
  # 
  #     [{0, 10}] ; [{1, 31}, {2, 17}]
  #                   ┊        ┊
  #                current     ┊
  #                          ╭─────╮
  #                          │     │ cell.column=2
  #                          ╰─────╯
  # Action:
  #
  #   * Shift column widths and try again.
  #
  defp column_widths_2([cell | _] = cells, c1, [{column, _} = curr | c2])
       when cell.column > column do
    column_widths_2(cells, [curr | c1], c2)
  end

  #
  # This clause matches:
  #
  #   * No more column widths.
  # 
  #     c1 = [{1, 12}, {0, 10}] ; c2 = [ ]
  #                                     ┊ 
  #                                  current
  #
  #   * Cell is ahead of the current column width.
  #
  # Action:
  #
  #   * Raise an error.
  #
  defp column_widths_2([cell | _], [{column, _} | _], []) when cell.column > column do
    raise ArgumentError, message: "The given `column_count` to low."
  end

  #
  # This clause matches:
  #
  #   * No more column widths.
  # 
  #     [{1, 12}, {0, 10}] ; [ ]
  #                           ┊ 
  #                         current
  # Action:
  #
  #   * Shift column widths and try again.
  #
  defp column_widths_2(cells, [cw | c1], []) do
    column_widths_2(cells, c1, [cw])
  end

  #
  # This clause matches:
  #
  #   * Cell is at current column.
  # 
  #     [{0, 10}] ; [{1, 5}, {2, 5}]
  #                   ┊        
  #                current
  #                   ┊
  #                ╭─────╮
  #                │     │ cell.column=1
  #                ╰─────╯
  # Action:
  #
  #   * Calculate a new column width.
  #   * Shift column.
  #
  defp column_widths_2([cell | cells], c1, [{column, _} | _] = c2)
       when cell.column == column do
    {span, c2_rest} = Enum.split(c2, cell.column_span)

    span_width = span |> Enum.map(fn {_, w} -> w end) |> Enum.sum()

    diff = cell.cell_width - span_width

    if diff > 0 do
      plus = div(diff, cell.column_span)
      r = rem(diff, cell.column_span)

      span =
        Enum.map(span, fn {c, w} -> {c, w + plus + if(c < cell.column + r, do: 1, else: 0)} end)

      column_widths_2(cells, Enum.reverse(span) ++ c1, c2_rest)
    else
      column_widths_2(cells, c1, c2)
    end
  end
end
