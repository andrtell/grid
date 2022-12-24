defmodule Grid.Placement do
  @moduledoc """
  A module for placing cells in a grid by row and column.
  """

  alias Grid.T
  alias Grid.Cell

  @doc ~s"""
  Places the given cells in a grid of the given column count by row and column.

  ## Arguments

    * `cells` - A list of cells to place in a grid.
    * `options` - The options for placing the cells.

  ## Options

    * `column_count` - The number of columns in the grid (default: 1).
    * `empty` - A default cell to insert in place of empty cells (default: `Grid.Cell.new(nil)`).

  ## Returns

    A list of cells with their `row` and `column` set to a new 
    value.

  ## Not yet implemented

  Support for laying out cells along column-axis.

  Support for absolute positioning

  * by row and column
  * by row (fixed row, placed in column)
  * by column (fixed column, placed in row)

  ## How it works

  The cell are placed in the grid in the order they are given. 

      ╭───┬───╮
      │ 1 │ 2 │
      ╰───┴───╯
      └───┴───┘
      column_count=2

  Cells can span multiple rows and columns.

      row_span=2
        ↑
      ╭───┬───────╮
      │ 1 │ 2   2 │ <- column_span=2
      │   ├───────┤
      │ 1 │ 3   3 │
      ╰───┴───────╯
      └───┴───┴───┘
      column_count=3

  Gaps are filled with empty cells.

      ╭───┬───╮
      │ 1 │ 2 │
      ├───┼───┤
      │ 3 │ E │
      ╰───┴───╯
      └───┴───┘
      column_count=2. 

  Empty cells will have the greatest row and column span possible.

      ╭───┬───┬───╮
      │ 1 │ 2 │ 3 │
      ├───┼───┴───┤
      │ 4 │ E   E │ 
      │   │       │ <- row_span=2, column span=2
      │ 4 │ E   E │
      ╰───┴───────╯
      └───┴───┴───┘
      column count=3.

  If an cell has a column span greater than the column count, the column 
  count will be increased.
    
      ┌───┬───┐     <- column_count=2
      ╭───────────╮
      │ 1   1   1 │ <- column_span=3
      ╰───────────╯
      └───┴───┴───┘ <- column_count=3 (new)

  If an empty list of cells is given, the grid will have a single empty cell
  that spans a single row.

      ╭───────────╮
      │ E   E   E │ <- column_span=3
      ╰───────────╯
      └───┴───┴───┘ <- column_count=3

  ## Examples

      iex> Grid.Placement.place_cells([Grid.cell("data")])
      {[
        %Grid.Cell{
          row: 0,
          column: 0,
          row_span: 1,
          column_span: 1,
          cell_height: 1,
          cell_width: 1,
          data: "data",
          empty: false,
          x: nil,
          y: nil
        }  
      ], 1, 1}
  """
  @spec place_cells([Cell.t()], Keyword.t()) :: {[Cell.t()], T.size(), T.size()}
  def place_cells(cells, options \\ []) do
    options = default_options(options)

    #
    # ┌───┬───┐     <- column_count=2 (arg)
    # ╭───────────╮
    # │ 1   1   1 │ <- column_span=3
    # ╰───────────╯
    # └───┴───┴───┘ <- column_count=3 (new)
    #
    column_count =
      case cells do
        [] -> options[:column_count]
        _ -> max(options[:column_count], cells |> Enum.map(& &1.column_span) |> Enum.max())
      end

    {cells, row_count} = place_cells(cells, [], 0, 0, [], column_count, options[:empty])

    cells = merge_empty_cells(cells)

    # Done.
    {Enum.reverse(cells), row_count, column_count}
  end

  ##############################################################################
  #
  # default_options/1
  #
  @spec default_options(Keyword.t()) :: Keyword.t()
  defp default_options(options) do
    options =
      Keyword.merge(
        [
          empty: Cell.new(nil),
          column_count: 1
        ],
        options
      )

    Keyword.update!(options, :empty, &%Cell{&1 | empty: true})
  end

  ##############################################################################
  #
  # place_cells/7
  #
  # Places cells by row and column in the grid. 
  # 
  # Returns a list of cells in reverse order.
  #
  # This clause matches:
  #
  #   * Any slot that is occupied.
  #
  #     ╭───┬───╮
  #     │ 1 │ 2 │
  #     ├───┤   │
  #     │ 3 │ 2 │ <- Occupied
  #     ╰───┴───╯
  #           ^
  # Action:
  #
  #   * Skip the slot, discard the occupied cell.
  #
  @spec place_cells(
          [Cell.t()],
          [Cell.t()],
          T.index(),
          T.index(),
          [{T.index(), T.index()}],
          T.size(),
          Cell.t()
        ) ::
          {[Cell.t()], T.count()}
  defp place_cells(
         cells,
         placed,
         row,
         column,
         [{row, column} | occupied],
         column_count,
         empty_cell_template
       ) do
    place_cells(
      cells,
      placed,
      row,
      column + 1,
      occupied,
      column_count,
      empty_cell_template
    )
  end

  #
  # This clause matches: 
  #
  #   * A free slot. 
  #   * No more cells to place.
  #   * Occupied slots to the right.
  #
  #     ╭───┬───┬───╮
  #     │ 1 │ 2 │ 3 │
  #     │   ├───┤   │
  #     │ 1 │ _ │ 3 │
  #     ╰───┴───┴───╯
  #           ^
  # Action: 
  #
  #   * Place an empty cell to fill the gap.
  #
  #     ╭───┬───┬───╮
  #     │ 1 │ 2 │ 3 │
  #     │   ├───┤   │    ╭───╮
  #     │ 1 │ _ │ 3 │ <- │ E │
  #     ╰───┴───┴───╯    ╰───╯
  #           ^
  #
  defp place_cells(
         [],
         placed,
         row,
         column,
         [{row, occupied_column} | _] = occupied,
         column_count,
         empty_cell_template
       )
       when column < column_count do
    empty_cell = %{
      empty_cell_template
      | row: row,
        column: column,
        column_span: occupied_column - column
    }

    place_cells(
      [],
      [empty_cell | placed],
      row,
      column + empty_cell.column_span,
      occupied,
      column_count,
      empty_cell_template
    )
  end

  #
  # This clause matches: 
  #
  #   * A free slot. 
  #   * No more cells to place.
  #   * All slots remaining on the row is free.
  #
  #     ╭───┬───┬───╮
  #     │ 1 │ 2 │ 3 │
  #     │   ├───┼───┤
  #     │ 1 │ _ │ _ │
  #     ╰───┴───┴───╯
  #           ^
  # Action: 
  #
  #   * Place an empty cell to fill the row.
  #
  #     ╭───┬───┬───╮
  #     │ 1 │ 2 │ 3 │
  #     │   ├───┼───┤    ╭───────╮
  #     │ 1 │ _ │ _ │ <- │ E   E │
  #     ╰───┴───┴───╯    ╰───────╯
  #           ^
  #
  defp place_cells(
         [],
         placed,
         row,
         column,
         occupied,
         column_count,
         empty_cell_template
       )
       when column < column_count do
    empty_cell = %{
      empty_cell_template
      | row: row,
        column: column,
        column_span: column_count - column
    }

    place_cells(
      [],
      [empty_cell | placed],
      row,
      column_count,
      occupied,
      column_count,
      empty_cell_template
    )
  end

  #
  # This clause matches: 
  #
  #   * A free slot. 
  #   * Occupied slots to the right.
  #   * The current cell would not fit the gap.
  #
  #     ╭───┬───────┬───╮
  #     │ 1 │ 2   2 │ 3 │
  #     │   ├───┬───┤   │    ╭───────────╮
  #     │ 1 │ _ │ _ │ 3 │ <- │ 4   4   4 │ (would not fit)
  #     ╰───┴───┴───┴───╯    ╰───────────╯
  #           ^
  # Action:
  #
  #   * Place an empty cell to fill the gap.
  # 
  #     ╭───┬───────┬───╮
  #     │ 1 │ 2   2 │ 3 │
  #     │   ├───┬───┤   │    ╭───────╮
  #     │ 1 │ _ │ _ │ 3 │ <- │ E   E │
  #     ╰───┴───┴───┴───╯    ╰───────╯
  #
  defp place_cells(
         [cell | _] = cells,
         placed,
         row,
         column,
         [{row, occupied_column} | _] = occupied,
         column_count,
         empty_cell_template
       )
       when column < column_count and occupied_column - column < cell.column_span do
    empty_cell = %{
      empty_cell_template
      | row: row,
        column: column,
        column_span: occupied_column - column
    }

    place_cells(
      cells,
      [empty_cell | placed],
      row,
      column + empty_cell.column_span,
      occupied,
      column_count,
      empty_cell_template
    )
  end

  #
  # This clause matches: 
  #
  #   * A free slot. 
  #   * All slots remaining on the row is free.
  #   * The current cell would not fit the row.
  #
  #     ╭───┬───╮
  #     │ 1 │ 2 │
  #     ├───┼───┤    ╭───────╮
  #     │ 3 │ _ │ <- │ 4   4 │ (would not fit)
  #     ╰───┴───╯    ╰───────╯
  #           ^
  # Action:
  #
  #   * Place an empty cell to fill the row.
  # 
  #     ╭───┬───╮
  #     │ 1 │ 2 │
  #     ├───┼───┤    ╭───╮
  #     │ 3 │ _ │ <- │ E │
  #     ╰───┴───╯    ╰───╯
  #           ^
  #
  defp place_cells(
         [cell | _] = cells,
         placed,
         row,
         column,
         occupied,
         column_count,
         empty_cell_template
       )
       when column < column_count and column + cell.column_span > column_count do
    empty_cell = %{
      empty_cell_template
      | row: row,
        column: column,
        column_span: column_count - column
    }

    place_cells(
      cells,
      [empty_cell | placed],
      row,
      column_count,
      occupied,
      column_count,
      empty_cell_template
    )
  end

  #
  # This clause matches: 
  #
  #   * A free slot. 
  #   * Occupied slots to the right.
  #   * The current cell fits in the gap.
  #
  #     ╭───┬───────┬───╮
  #     │ 1 │ 2   2 │ 3 │
  #     │   ├───┬───┤   │
  #     │ 1 │ _ │ _ │ 3 │
  #     ╰───┴───┴───┴───╯
  #           ^
  # Action:
  #
  #   * Place the cell
  #
  #     ╭───┬───────┬───╮
  #     │ 1 │ 2   2 │ 3 │
  #     │   ├───┬───┤   │    ╭───────╮
  #     │ 1 │ _ │ _ │ 3 │ <- │ 4   4 │ (fits)
  #     ╰───┴───┴───┴───╯    ╰───────╯
  #           ^
  #
  defp place_cells(
         [cell | cells],
         placed,
         row,
         column,
         [{row, occupied_column} | _] = occupied,
         column_count,
         empty_cell_template
       )
       when column < column_count and occupied_column - column >= cell.column_span do
    cell = %{cell | row: row, column: column}

    place_cells(
      cells,
      [cell | placed],
      row,
      column + cell.column_span,
      occupied |> update_occupied_from_placed_cell(cell),
      column_count,
      empty_cell_template
    )
  end

  # This clause matches: 
  #
  #   * A free slot. 
  #   * All slots remaining on the row is free.
  #   * The current cell fits the row
  #
  #     ╭───┬───────╮
  #     │ 1 │ 2   2 │
  #     │   ├───┬───┤
  #     │ 1 │ _ │ _ │
  #     ╰───┴───┴───╯
  #           ^
  # Action:
  #
  #   * Place the cell
  #
  #     ╭───┬───────╮
  #     │ 1 │ 2   2 │
  #     │   ├───┬───┤    ╭───────╮
  #     │ 1 │ _ │ _ │ <- │ 4   4 │ (fits)
  #     ╰───┴───┴───╯    ╰───────╯
  #           ^
  #
  defp place_cells(
         [cell | cells],
         placed,
         row,
         column,
         occupied,
         column_count,
         empty_cell_template
       )
       when column < column_count and column + cell.column_span <= column_count do
    cell = %{cell | row: row, column: column}

    place_cells(
      cells,
      [cell | placed],
      row,
      column + cell.column_span,
      occupied |> update_occupied_from_placed_cell(cell),
      column_count,
      empty_cell_template
    )
  end

  # This clause matches: 
  #
  #   * The end of a row. 
  #   * No more cells to place.
  #
  #   ╭───┬───┬───╮
  #   │ 1 │ 2 │ 3 │
  #   ╰───┴───┴───╯
  #             ^
  # Action:
  # 
  #   Check if there are more (implicit) rows.
  #
  #   ╭───┬───┬───╮
  #   │ 1 │ 2 │ 3 │
  #   │   ├───┼───┤
  #   │ 1 │ ? │ ? │ <- More rows!
  #   ╰───┴───┴───╯
  #
  #   If there are NO more rows, return the placed cells.
  #
  defp place_cells(
         [],
         placed,
         row,
         column,
         occupied,
         column_count,
         empty_cell_template
       )
       when column >= column_count do
    extra_rows? = Enum.any?(occupied, fn {r, _} -> r == row + 1 end)

    if extra_rows? do
      place_cells(
        [],
        placed,
        row + 1,
        0,
        occupied,
        column_count,
        empty_cell_template
      )
    else
      {placed, row + 1}
    end
  end

  # 
  # This clause matches: 
  #   
  #   * The end of a row, 
  #   * More cells to place
  #
  #     ╭───┬───┬───╮
  #     │ 1 │ 2 │ 3 │
  #     ╰───┴───┴───╯
  #               ^  
  # Action:
  # 
  #  * Continue with the next row.
  #
  #     ╭───┬───┬───╮
  #     │ 1 │ 2 │ 3 │ ┐
  #     ╰───┴───┴───╯ ┊
  #               ^   ┊
  #   ┌───────────────┘
  #   ┊ ╭───┬─
  #   └>│ _ │  
  #     ╰───┴─
  #
  defp place_cells(
         cells,
         placed,
         row,
         column,
         occupied,
         column_count,
         empty_cell_template
       )
       when column >= column_count do
    place_cells(
      cells,
      placed,
      row + 1,
      0,
      occupied,
      column_count,
      empty_cell_template
    )
  end

  ##############################################################################
  #
  # update_occupied_from_placed_cell/2
  #
  defp update_occupied_from_placed_cell(occupied, %Cell{row_span: row_span}) when row_span < 2 do
    occupied
  end

  defp update_occupied_from_placed_cell(occupied, cell) do
    to_insert =
      for r <- 1..(cell.row_span - 1),
          c <- 0..(cell.column_span - 1),
          do: {cell.row + r, cell.column + c}

    update_occupied([], occupied, to_insert)
  end

  ##############################################################################
  #
  # update_occupied/3
  #
  defp update_occupied(
         new_occupied,
         [],
         to_insert
       ) do
    Enum.reverse(new_occupied, to_insert)
  end

  defp update_occupied(
         new_occupied,
         occupied,
         []
       ) do
    Enum.reverse(new_occupied, occupied)
  end

  defp update_occupied(
         new_occupied,
         [old | occupied],
         [new | _] = to_insert
       )
       when old < new do
    update_occupied([old | new_occupied], occupied, to_insert)
  end

  defp update_occupied(
         new_occupied,
         [old | _] = occupied,
         [new | to_insert]
       )
       when old > new do
    update_occupied([new | new_occupied], occupied, to_insert)
  end

  ##############################################################################
  #
  # merge_empty_cells/1
  #
  # Merges empty cells with the same column and column_span that follow each 
  # other on consecutive rows.
  #
  # Before:
  #
  #   ╭───┬──────╮
  #   │ 1 │ E  E │
  #   ├───┼──────┤
  #   │ 3 │ E  E │
  #   ╰───┴──────╯
  # 
  # After:
  #
  #   ╭───┬──────╮
  #   │ 1 │ E  E │
  #   ├───┤      │
  #   │ 3 │ E  E │
  #   ╰───┴──────╯
  #
  # Arguments:
  #
  #   * `cells` - A list of cells in reverse order.
  #
  @spec merge_empty_cells([Cell.t()]) :: [Cell.t()]
  def merge_empty_cells(cells_r) do
    {cells, keep_list} = find_empty_to_keep_and_update([], cells_r, [])
    update_empty_cells([], cells, keep_list)
  end

  ##############################################################################
  #
  # find_empty_to_keep_and_update/1
  #
  # Wrapper around `find_empty_to_keep_and_update/3`.
  #
  def find_empty_to_keep_and_update(cells_r) do
    find_empty_to_keep_and_update([], cells_r, [])
  end

  ##############################################################################
  #
  # find_empty_to_keep_and_update/3
  #
  # Finds empty cells that should be kept and record their row, column and 
  # column_span. Also records the new row_span for the empty cells to keep.
  #
  # Returns:
  #
  #   * `cells` - A list of cells in normal order.
  #   * `keep_list` - A list of empty cells to keep with their new row_span.
  #
  # This clause matches:
  #
  #   * No more cells
  #
  # Action:
  #
  #   * Return the result.
  #
  def find_empty_to_keep_and_update(cells, [], keep_list) do
    {cells, keep_list}
  end

  #
  # This clause matches:
  #
  #   * Cell is non-empty.
  #
  # Action:
  #
  #   * Skip the cell.
  # 
  def find_empty_to_keep_and_update(cells, [cell | cells_r], keep_list)
      when not cell.empty do
    find_empty_to_keep_and_update([cell | cells], cells_r, keep_list)
  end

  #
  # This clause matches:
  #
  #  * Cell is empty.
  #
  # Action:
  #
  # * Update the `keep_list` and continue.
  #
  def find_empty_to_keep_and_update(cells, [cell | cells_r], keep_list) do
    keep_list = update_keep_list(cell, keep_list)
    find_empty_to_keep_and_update([cell | cells], cells_r, keep_list)
  end

  ##############################################################################
  #
  # update_keep_list/2
  #
  # Wrapper around `update_keep_list/3`.
  #
  @spec update_empty_cells(
          Cell.t(),
          [{T.index(), T.index(), T.size(), T.size()}]
        ) :: [{T.index(), T.index(), T.size(), T.size()}]
  def update_keep_list(cell, keep_list) do
    update_keep_list(cell, [], keep_list)
  end

  ##############################################################################
  #
  # update_keep_list/3
  #
  # update the `keep_list` given a cell and the old `keep_list`.
  #
  # This clause matches:
  #
  #  * Reached the end of the `keep_list`
  #  * No match for given cell found in the `keep_list`.
  #
  # Action:
  #
  #  * Update the `keep_list` with a fresh entry.
  #
  @spec update_empty_cells(
          Cell.t(),
          [{T.index(), T.index(), T.size(), T.size()}],
          [{T.index(), T.index(), T.size(), T.size()}]
        ) :: [{T.index(), T.index(), T.size(), T.size()}]
  def update_keep_list(cell, l, []) do
    [{cell.row, cell.column, cell.row_span, cell.column_span} | Enum.reverse(l)]
  end

  #
  # This clause matches:
  #
  #  * Given cell matches entry from cell on previous row.
  #
  # Action:
  #
  #  * Update the `keep_list` with information from the cell.
  #
  def update_keep_list(cell, l, [{row, column, row_span, column_span} | r])
      when cell.row + 1 == row and cell.column == column and cell.column_span == column_span do
    [{row - 1, column, row_span + 1, column_span} | Enum.reverse(l) ++ r]
  end

  #
  # This clause matches:
  #
  #  * No match for the given cell found in the `keep_list`.
  #  * Row is past the previous row.
  #
  # Action:
  #
  #  * Update the `keep_list` with information from the cell.
  #
  def update_keep_list(cell, l, [{row, _, _, _} | _] = r)
      when cell.row + 1 < row do
    [{cell.row, cell.column, cell.row_span, cell.column_span} | Enum.reverse(l) ++ r]
  end

  #
  # This clause matches:
  #
  #  * So far no match for the given cell found in the `keep_list`.
  #
  # Action:
  #
  #  * Continue to the next entry.
  #
  def update_keep_list(cell, l, [h | t]) do
    update_keep_list(cell, [h | l], t)
  end

  ##############################################################################
  #
  # update_empty_cells/2
  # 
  # Wrapper around `update_empty_cells/3`.
  #
  @spec update_empty_cells(
          [Cell.t()],
          [{T.index(), T.index(), T.size(), T.size()}]
        ) :: [Cell.t()]
  def update_empty_cells(cells, keep_list) do
    update_empty_cells([], cells, keep_list)
  end

  ##############################################################################
  #
  # update_empty_cells/3
  #
  # Given a list of cells and a keep list, update the row_spans of the empty
  # cells in the list, and removes cells that are not in the keep list.
  #
  # This clause matches:
  #
  #   * No more cells.
  #
  # Action:
  #
  #   * Return the result.
  #
  @spec update_empty_cells(
          [Cell.t()],
          [Cell.t()],
          [{T.index(), T.index(), T.size(), T.size()}]
        ) :: [Cell.t()]
  def update_empty_cells(cells_r, [], []) do
    cells_r
  end

  #
  # This clause matches:
  #
  #   * Cell is non-empty.
  #
  # Action:
  #   
  #   * Skip the cell.
  #
  def update_empty_cells(cells_r, [cell | cells], keep_list) when not cell.empty do
    update_empty_cells([cell | cells_r], cells, keep_list)
  end

  #
  # This clause matches:
  #
  #   * Cell is empty
  #   * In the `keep_list`.
  #
  # Action:
  #
  #   * Update cell `row_span`.
  #
  def update_empty_cells(cells_r, [cell | cells], [
        {row, column, row_span, column_span} | keep_list
      ])
      when cell.row == row and cell.column == column and cell.column_span == column_span do
    update_empty_cells([%Cell{cell | row_span: row_span} | cells_r], cells, keep_list)
  end

  #
  # This clause matches:
  #
  #   * Cell is empty
  #   * Not in the `keep_list`.
  #
  # Action:
  #
  #   * Discard the cell.
  #
  def update_empty_cells(cells_r, [_ | cells], keep_list) do
    update_empty_cells(cells_r, cells, keep_list)
  end
end
