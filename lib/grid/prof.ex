defmodule Grid.Prof do
  @doc ~S"""
  Run a profiler on Grid.layout/2 with random data.

  How to use:

  $ mix run -e 'Grid.Prof.layout(1000)'
  """
  def layout(n) do
    cells = cells(n)
    options = [row_gap: 2, column_gap: 2, column_count: Enum.random(1..10)]

    :eprof.start_profiling([self()])

    Grid.layout(cells, options)

    :eprof.stop_profiling()
    :eprof.analyze()
  end

  @doc ~S"""
  Run a profiler on Grid.place/2 with random data.

  How to use:

  $ mix run -e 'Grid.Prof.place(1000)'
  """
  def place(n) do
    cells = cells(n)
    options = [row_gap: 2, column_gap: 2, column_count: Enum.random(1..10)]

    :eprof.start_profiling([self()])

    Grid.place(cells, options)

    :eprof.stop_profiling()
    :eprof.analyze()
  end

  def cells(n) do
    for _ <- 1..n, do: make_cell()
  end

  def make_cell() do
    data = for _ <- 1..3, into: "", do: <<Enum.random('abcdefghijklmnopqrstuvwxyz')>>
    row_span = Enum.random([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 5, 6])
    column_span = Enum.random([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 5, 6])
    cell_height = ceil(100 * abs(:rand.normal()))
    cell_width = ceil(100 * abs(:rand.normal()))

    Grid.cell(data,
      row_span: row_span,
      column_span: column_span,
      cell_height: cell_height,
      cell_width: cell_width
    )
  end
end
