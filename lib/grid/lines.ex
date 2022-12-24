defmodule Grid.Lines do
  @moduledoc """
  A module for generating lines for a grid.
  """

  alias Grid.Cell

  @doc ~S"""
  Given a list of `cells`, returns a list of lines and intersections that can be 
  used to draw a grid.

  ## Arguments

    * `cells` - A list of cells to draw a grid for.
    * `options` - The options for drawing the grid.

  These invariants must hold:

    * The `cells` are sorted by row and column.
    * There are no gaps between the `cells`.
    * Every `cell` in the same row has the same `cell_height`.
    * Every `cell` in the same column has the same `cell_width`.
    * Every `cell` has a `x` and `y` value that gives the `cell`'s position in a grid.

  See also:

    * `Grid.Placement.place_cells/2`
    * `Grid.Sizing.size_cells/2`
    * `Grid.Positioning.position_cells/2`

  ## Options

    * `row_gap` - The gap between rows (default: 0).
    * `column_gap` - The gap between columns (default: 0).

  ## Returns

  A map representing the grid lines and intersections.

  ## How it works

  Example:

          0 1 2 3 4
        0 ╭───┬───╮ (row_gap=1, column_gap=1)
        1 │ A │ B │  
        2 ├───┼───┤
        3 │ C │ D │  
        4 ╰───┴───╯ (spaces added for clarity)

  This example corresponds to:

       %{
        horizontal_lines: [
          [{0, 0}, {4, 0}], 
          [{0, 2}, {4, 2}], 
          [{0, 4}, {4, 4}]
        ],
        vertical_lines: [
          [{0, 0}, {0, 4}], 
          [{2, 0}, {2, 4}], 
          [{4, 0}, {4, 4}]
        ],
        intersections: %{
          {0, 0} => %{up: 0, down: 1, left: 0, right: 1},
          {2, 0} => %{up: 0, down: 1, left: 1, right: 1},
          {4, 0} => %{up: 0, down: 1, left: 1, right: 0},
          {0, 2} => %{up: 1, down: 1, left: 0, right: 1},
          {2, 2} => %{up: 1, down: 1, left: 1, right: 1},
          {4, 2} => %{up: 1, down: 1, left: 1, right: 0},
          {0, 4} => %{up: 1, down: 0, left: 0, right: 1},
          {2, 4} => %{up: 1, down: 0, left: 1, right: 1},
          {4, 4} => %{up: 1, down: 0, left: 1, right: 0}
       }
  """
  @spec create_lines(cells :: Cell.t(), options :: Keyword.t()) :: map
  def create_lines(cells, options \\ []) do
    options = default_options(options)

    row_gap = options[:row_gap]
    column_gap = options[:column_gap]
    row_gap_bottom = div(row_gap, 2)
    row_gap_top = row_gap - row_gap_bottom
    column_gap_right = div(column_gap, 2)
    column_gap_left = column_gap - column_gap_right

    create_lines(
      cells,
      [],
      [],
      %{},
      row_gap_top,
      row_gap_bottom,
      column_gap_left,
      column_gap_right
    )
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
        column_gap: 1
      ],
      options
    )
  end

  ##############################################################################
  #
  # create_lines/8
  #
  defp create_lines(
         [],
         hs,
         vs,
         is,
         _row_gap_top,
         _row_gap_bottom,
         _column_gap_left,
         _column_gap_right
       ) do
    hs = merge_segments(hs) |> Enum.map(fn [y, x1, x2] -> [{x1, y}, {x2, y}] end)
    vs = merge_segments(vs) |> Enum.map(fn [x, y1, y2] -> [{x, y1}, {x, y2}] end)

    %{horizontal_lines: hs, vertical_lines: vs, intersections: is}
  end

  defp create_lines(
         [cell | cells],
         hs,
         vs,
         is,
         row_gap_top,
         row_gap_bottom,
         column_gap_left,
         column_gap_right
       ) do
    x_l = cell.x - column_gap_left
    x_r = cell.x + cell.cell_width + column_gap_right
    y_t = cell.y - row_gap_top
    y_b = cell.y + cell.cell_height + row_gap_bottom

    hs = [[y_t, x_l, x_r], [y_b, x_l, x_r] | hs]
    vs = [[x_l, y_t, y_b], [x_r, y_t, y_b] | vs]

    is =
      Map.merge(
        is,
        %{
          {x_l, y_t} => %{right: 1, down: 1},
          {x_r, y_t} => %{left: 1, down: 1},
          {x_l, y_b} => %{right: 1, up: 1},
          {x_r, y_b} => %{left: 1, up: 1}
        },
        fn _, m1, m2 -> Map.merge(m1, m2) end
      )

    create_lines(
      cells,
      hs,
      vs,
      is,
      row_gap_top,
      row_gap_bottom,
      column_gap_left,
      column_gap_right
    )
  end

  ##############################################################################
  #
  # merge_segments/1
  #
  @spec merge_segments([[integer()]]) :: [[integer()]]
  defp merge_segments(ls) do
    ls
    |> Enum.sort()
    |> Enum.reduce([], fn [y, curr_start, curr_end] = curr, lines ->
      case lines do
        [] ->
          # No previous line, so add the current line.
          [curr]

        [[^y, prev_start, prev_end] | lines_rest] = lines ->
          cond do
            #
            # ├───────┤          <- prev
            #
            #         ├───────┤  <- curr
            #
            # ├───────────────┤  <- result
            #
            curr_start == prev_end ->
              [[y, prev_start, curr_end] | lines_rest]

            #
            # ├───────┤      <- prev
            #
            #     ├───────┤  <- curr
            #
            # ├───────────┤  <- result
            #
            curr_start >= prev_start and curr_end >= prev_end ->
              [[y, prev_start, curr_end] | lines_rest]

            #
            #     ├───────┤  <- prev
            #
            # ├───────┤      <- curr
            #
            # ├───────────┤  <- result
            #
            curr_start <= prev_start and curr_end <= prev_end ->
              [[y, curr_start, prev_end] | lines_rest]

            #
            #     ├───────┤      <- prev
            #
            # ├───────────────┤  <- curr
            #
            # ├───────────────┤  <- result
            #
            curr_start <= prev_start and curr_end >= prev_end ->
              [[y, curr_start, curr_end] | lines_rest]

            #
            # ├───────────────┤  <- prev
            #
            #    ├────────┤      <- curr
            #
            # ├───────────────┤  <- result
            #
            curr_start >= prev_start and curr_end <= prev_end ->
              lines

            #
            # ├───────┤              <- prev
            #
            #             ├───────┤  <- curr
            #
            # ├───────┤   ├───────┤  <- result
            #
            true ->
              [curr | lines]
          end

        _ ->
          # Previous line is on another row/column, so add the current line.
          [curr | lines]
      end
    end)
    |> Enum.reverse()
  end
end
