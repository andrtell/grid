# Grid

Tiny library for laying data out in a grid. 

Inspired by [CSS Grid Layout Module Level 1](https://www.w3.org/TR/css-grid-1/)

Status: Work In Progress.

Look out for: Bugs, poor test coverage, minimal feature set, wierd behaviour, breaking changes, forced pushes.

Purpose: I am exploring the non-OTP parts of Elixir.

Should you use this "library"? - No.

Installation
------------

```elixir
defp deps do
    [
        {:grid, git: "https://github.com/andrtell/grid.git"}
    ]
end
```

Intro
-----

To start we need some `cells`:

```elixir
cells = [
   Grid.cell("orange", row_span: 2, cell_width: 8, cell_height: 3),
   Grid.cell("melon", column_span: 2, cell_width: 7, cell_height: 3),
   Grid.cell("banana", row_span: 2, column_span: 2, cell_width: 8, cell_height: 3)
]
```

We also need to set some grid `options`:

```elixir
 options = [
  column_count: 3,
  row_gap: 3,
  column_gap: 3,
  min_row_height: 3,
  empty: Grid.cell("apple", cell_height: 3, cell_width: 7)
]
```
Finally we can place the `cells` in a grid.

```elixir
Grid.layout(cells, options)

[
  %Grid.Cell{
    row: 0,
    column: 0,
    row_span: 2,
    column_span: 1,
    cell_height: 9,
    cell_width: 8,
    data: "orange",
    empty: false,
    x: 0,
    y: 0
  },
  %Grid.Cell{
    row: 0,
    column: 1,
    row_span: 1,
    column_span: 2,
    cell_height: 3,
    cell_width: 11,
    data: "melon",
    empty: false,
    x: 11,
    y: 0
  },
  %Grid.Cell{
    row: 1,
    column: 1,
    row_span: 2,
    column_span: 2,
    cell_height: 9,
    cell_width: 11,
    data: "banana",
    empty: false,
    x: 11,
    y: 6
  },
  %Grid.Cell{
    row: 2,
    column: 0,
    row_span: 1,
    column_span: 1,
    cell_height: 3,
    cell_width: 8,
    data: "apple",
    empty: true,
    x: 0,
    y: 12
  }
]
```

If you squint real hard, you might see this:

```
   (cell outlines added for clearity)

        0      7   11       21 
        |      |   |         |
    0 ─ ╭──────╮   ╭─────────╮ 
        │orange│   │melon    │
        │      │   ╰─────────╯
        │      │               ┐ 
        │      │               ┊ row_gap=3
        │      │               ┘
    6 ─ │      │   ╭─────────╮
        │      │   │banana   │
    8 ─ ╰──────╯   │         │                      
                   │         │ ┐
                   │         │ ┊ 
                   │         │ ┘
   12 ─ ╭──────╮   │         │
        │apple │   │         │
   14 ─ ╰──────╯   ╰─────────╯ 
                └┄┘    └┄┘
            column_gap=3 
```

Finally we can create some grid lines:

```elixir
cells |> Grid.create_lines(options)

%{
  horizontal_lines: [
    [{-2, -2}, {23, -2}],
    [{9, 4}, {23, 4}],
    [{-2, 10}, {9, 10}],
    [{-2, 16}, {23, 16}]
  ],
  intersections: %{
    {-2, -2} => %{down: 1, right: 1},
    {-2, 10} => %{down: 1, right: 1, up: 1},
    {-2, 16} => %{right: 1, up: 1},
    {9, -2} => %{down: 1, left: 1, right: 1},
    {9, 4} => %{down: 1, right: 1, up: 1},
    {9, 10} => %{down: 1, left: 1, up: 1},
    {9, 16} => %{left: 1, right: 1, up: 1},
    {23, -2} => %{down: 1, left: 1},
    {23, 4} => %{down: 1, left: 1, up: 1},
    {23, 16} => %{left: 1, up: 1}
  },
  vertical_lines: [
    [{-2, -2}, {-2, 16}],
    [{9, -2}, {9, 16}],
    [{23, -2}, {23, 16}]
  ]
}
```

If you squint real hard again:

```
    -2 0        9            23
     | |        |             |  
-2 ─ ╭──────────┬─────────────╮
     │          │             │  
 0 ─ │          │             │ 
     │          │             │  
     │          │             │  
     │          │             │     
 4 ─ │          ├─────────────┤            
     │          │             │     
     │          │             │  
     │          │             │   
     │          │             │   
     │          │             │   
10 ─ ├──────────┤             │     
     │          │             │                           
     │          │             │
     │          │             │
     │          │             │
     │          │             │
16 ─ ╰──────────┴─────────────╯
```

To avoid negative coordinates for the grid lines:

```
options = [
    x_start: 2,
    y_start: 2,
    ... 
]
```
