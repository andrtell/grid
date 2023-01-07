defmodule Grid do
  @doc ~S"""
  Creates a new grid cell.

  ## Arguments

    * `data` - The data to be stored in the cell. Can be used to associate
      the thing being layed out with the cell (or just store it all together).
    * `options` - A keyword list of options.

  ## Options

    * `:row` - The row index of the cell.
    * `:column` - The column index of the cell.
    * `:row_span` - The number of rows the cell spans.
    * `:column_span` - The number of columns the cell spans.
    * `:cell_height` - The height of a cell in the grid.
    * `:cell_width` - The width of a cell in the grid.
    * `:empty` - Whether the cell is empty.
    * `:x` - The x position of the cell.
    * `:y` - The y position of the cell.
  """
  @spec cell(term(), Keyword.t()) :: Grid.Cell.t()
  def cell(data, options \\ []) do
    Grid.Cell.new(data, options)
  end

  @doc ~S"""
  Places the given cells in a grid.

  Updates the `row`, `column`, `cell_height`, `cell_width`, `x`, and `y` fields 
  of each cell.

  ## Arguments

    * `cells` - A list of cells to be placed in the grid.
    * `options` - A keyword list of options.

  ## Options

    * `:column_count` - The number of columns in the grid (default: 1).
    * `:row_gap` - The number of rows between cells (default: 1).
    * `:column_gap` - The number of columns between cells (default: 1).
    * `:x_start` - The x position of the first cell (default: 0).
    * `:y_start` - The y position of the first cell (default: 0).
    * `:min_row_height` - The minimum height of a row (default: 1).
    * `:min_column_width` - The minimum width of a column (default: 1).
    * `:empty` - Empty cell template (a Grid.Cell).
  """
  @spec layout([Grid.Cell.t()], Keyword.t()) :: [Grid.Cell.t()]
  def layout(cells, options \\ []) do
    {cells, row_count, column_count} = Grid.Placement.place_cells(cells, options)

    cells
    |> Grid.Sizing.expand_cells(row_count, column_count, options)
    |> Grid.Positioning.position_cells(options)
  end

  @doc ~S"""
  Only places cells in the grid by row and column. 

  DOES NOT set the `cell_height`, `cell_width` or `x` and `y` positions of the 
  cells.

  ## Arguments

    * `cells` - A list of cells to be placed in the grid.
    * `options` - A keyword list of options.

  ## Options

    * `:column_count` - The number of columns in the grid (default: 1).
    * `:empty` - Empty cell template (a Grid.Cell).
  """
  @spec place([Grid.Cell.t()], column_count: integer) :: {[Grid.Cell.t()], map}
  def place(cells, options \\ []) do
    cells |> Grid.Placement.place_cells(options)
  end

  @doc ~S"""
  Creates grid lines for a list of cells returned from `Grid.layout/2`.

  See also:

    * `Grid.layout/2`
    * `Grid.Lines.create_lines/2`
  """
  def create_lines(cells, row_count, column_count, options \\ []) do
    cells |> Grid.Lines.create_lines(row_count, column_count, options)
  end
end
