defmodule Grid.Positioning do
  @moduledoc """
  A module for giving cells an absolute position based on their size and placement in a grid.
  """

  alias Grid.T
  alias Grid.Cell

  @doc """
  Positions the given cells in a grid by setting their `x` and `y` fields.

  Also sets the `cell_height` and `cell_width` each cell to account for the
  `row_gap` and `column_gap` if the cells span multiple rows or columns.

  ## Arguments

    * `cells` - A list of cells to position.
    * `options` - The options for positioning the cells.

  These invariants must hold:

    * The `cells` are sorted by row and column.
    * There are no gaps between cells.
    * Every cell in the same row has the same height.
    * Every cell in the same column has the same width.

  See also:

    * `Grid.Placement.place_cells/2`
    * `Grid.Sizing.size_cells/2`

  ## Options

    * `row_gap` - The gap between rows (default: 1).
    * `column_gap` - The gap between columns (default: 1).
    * `x_start` - The starting x position (default: 0).
    * `y_start` - The starting y position (default: 0).

  ## Returns

    A list of cells with their `x`, `y`, `cell_height` and `cell_widht` fields 
    set to a new value.

  ## How it works

  A visual representation of some positioned cells:

        (x_start, y_start) = (0, 0)

           x=0  1   2   3   4   5
            |   |   |   |   |   |
      y=0 ─ ╭───╮   ╭───╮   ╭───╮ 
            │ A │   │ B │   │ C │
        1 ─ ╰───╯   ╰───╯   ╰───╯ ┐
                                  ┊ row_gap=1
        2 ─ ╭───╮   ╭───────────╮ ┘
            │ D │   │ E       E │
        3 ─ ╰───╯   ╰───────────╯ ┐    
                                  ┊
        4 ─ ╭───╮   ╭───────────╮ ┘
            │ F │   │ G       G │
        5 ─ ╰───╯   │           │ ┐
                    │           │ ┊
        6 ─ ╭───╮   │           │ ┘
            │ I │   │ G       G │
        7 ─ ╰───╯   ╰───────────╯
                └─┄─┘   └─┄─┘
             column_gap=1                   

  That corresponds to:

    * A is positioned at `x=0` and `y=0`.
    * B is positioned at `x=2` and `y=0`.
    * C is positioned at `x=4` and `y=0`.
    * D is positioned at `x=0` and `y=2`.
    * E is positioned at `x=2` and `y=2`.
    * F is positioned at `x=0` and `y=4`.
    * G is positioned at `x=2` and `y=4`.
    * I is positioned at `x=0` and `y=6`.

  The `cell_height` and `cell_width` of of G and E are increased to account for
  the `row_gap` and `column_gap` respectively.

    * E's `cell_width` is increased by 1 to account for the `column_gap`
    * G's `cell_width` is increased by 1 to account for the `column_gap`
    * G's `cell_height` is increased by 1 to account for the `row_gap`

  ## Examples

      iex> [
      ...>  Grid.cell(
      ...>    "A", row: 0, column: 0, 
      ...>    row_span: 1, column_span: 1, 
      ...>    cell_height: 1, cell_width: 1
      ...>  )
      ...> ]
      ...> |> Grid.Positioning.position_cells()
      [
        %Grid.Cell{
          row: 0,
          column: 0,
          row_span: 1,
          column_span: 1,
          cell_height: 1, # <- unchanged (only 1 cell with a span of 1)
          cell_width: 1, # <- unchanged (only 1 cell with a span of 1)
          data: "A",
          empty: false,
          x: 0, # <- set to 0
          y: 0  # <- set to 0
        }
      ]
  """
  @spec position_cells([Cell.t()], Keyword.t()) :: [Cell.t()]
  def position_cells(cells, options \\ []) do
    options = default_options(options)

    cells =
      position_cells(
        cells,
        [],
        options[:row_gap],
        options[:column_gap],
        %{},
        %{},
        options[:x_start],
        options[:y_start]
      )

    Enum.reverse(cells)
  end

  ##############################################################################
  #
  # default_options/1
  #
  @spec default_options(Keyword.t()) :: Keyword.t()
  defp default_options(options) do
    Keyword.merge(
      [
        row_gap: 1,
        column_gap: 1,
        x_start: 0,
        y_start: 0
      ],
      options
    )
  end

  ##############################################################################
  #
  # position_cells/8
  #
  @spec position_cells(
          [Cell.t()],
          [Cell.t()],
          T.size(),
          T.size(),
          %{T.index() => T.index()},
          %{T.index() => T.index()},
          T.index(),
          T.index()
        ) :: [Cell.t()]
  defp position_cells(
         [],
         positioned,
         _row_gap,
         _column_gap,
         _row_map,
         _column_map,
         _x_start,
         _y_start
       ) do
    positioned
  end

  defp position_cells(
         [cell | cells_rest],
         positioned,
         row_gap,
         column_gap,
         y_offset_by_row,
         x_offset_by_column,
         x_start,
         y_start
       ) do
    y_offset = Map.get(y_offset_by_row, cell.row, y_start)
    x_offset = Map.get(x_offset_by_column, cell.column, x_start)

    cell = %Cell{
      cell
      | x: x_offset,
        y: y_offset,
        cell_height: cell.cell_height + (cell.row_span - 1) * row_gap,
        cell_width: cell.cell_width + (cell.column_span - 1) * column_gap
    }

    y_offset_by_row =
      Map.put_new_lazy(
        y_offset_by_row,
        cell.row + cell.row_span,
        fn ->
          y_offset + cell.cell_height + row_gap
        end
      )

    x_offset_by_column =
      Map.put_new_lazy(
        x_offset_by_column,
        cell.column + cell.column_span,
        fn ->
          x_offset + cell.cell_width + column_gap
        end
      )

    position_cells(
      cells_rest,
      [cell | positioned],
      row_gap,
      column_gap,
      y_offset_by_row,
      x_offset_by_column,
      x_start,
      y_start
    )
  end
end
