defmodule Grid.Cell do
  @moduledoc """
  A module for creating grid cells.
  """
  defstruct [
    :row,
    :column,
    :row_span,
    :column_span,
    :cell_height,
    :cell_width,
    :data,
    :empty,
    :x,
    :y
  ]

  @type t :: %__MODULE__{
          data: term(),
          row: T.index() | nil,
          column: T.index() | nil,
          row_span: T.size(),
          column_span: T.size(),
          cell_height: T.size(),
          cell_width: T.size(),
          x: T.index() | nil,
          y: T.index() | nil,
          empty: boolean
        }

  @doc ~S"""
  Creates a new cell.

  ## Arguments

    * `data` - The data to be stored in the cell.
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
  @spec new(term(), Keyword.t()) :: t
  def new(data, options \\ []) do
    options = default_options(options)

    %__MODULE__{
      data: data,
      row: options[:row],
      column: options[:column],
      row_span: options[:row_span],
      column_span: options[:column_span],
      cell_height: options[:cell_height],
      cell_width: options[:cell_width],
      x: options[:x],
      y: options[:y],
      empty: options[:empty]
    }
  end

  ##############################################################################
  #
  # default_options/1
  #
  @spec default_options(Keyword.t()) :: Keyword.t()
  defp default_options(options) do
    Keyword.merge(
      [
        row: nil,
        column: nil,
        row_span: 1,
        column_span: 1,
        cell_height: 1,
        cell_width: 1,
        x: nil,
        y: nil,
        empty: false
      ],
      options
    )
  end
end
