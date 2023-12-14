import std/tables
import std/strutils

import grid

const TEST_CASE = """
O....#....
O.OO#....#
.....##...
OO.#O....O
.O.....O#.
O.#..O.#.#
..O..#O..O
.......O..
#....###..
#OO..#....
""".strip()

proc tiltUp(grid: Grid): Grid =
  result = grid
  for sy in countdown(result.rowCount, 1):
    for y in 1..<sy:
      for (x, _, c) in result.row(y):
        if c == 'O' and result.cell(x, y - 1) == '.':
          result.setCell(x, y - 1, 'O')
          result.setCell(x, y, '.')

proc tiltDown(grid: Grid): Grid =
  result = grid
  for sy in countdown(result.rowCount - 1, 0):
    for y in 0..<sy:
      for (x, _, c) in result.row(y):
        if c == 'O' and result.cell(x, y + 1) == '.':
          result.setCell(x, y + 1, 'O')
          result.setCell(x, y, '.')

proc tiltLeft(grid: Grid): Grid =
  result = grid
  for sx in countdown(result.colCount, 1):
    for x in 1..<sx:
      for (_, y, c) in result.column(x):
        if c == 'O' and result.cell(x - 1, y) == '.':
          result.setCell(x - 1, y, 'O')
          result.setCell(x, y, '.')

proc tiltRight(grid: Grid): Grid =
  result = grid
  for sx in countdown(result.colCount - 1, 0):
    for x in 0..<sx:
      for (_, y, c) in result.column(x):
        if c == 'O' and result.cell(x + 1, y) == '.':
          result.setCell(x + 1, y, 'O')
          result.setCell(x, y, '.')

proc spin_cycle(grid: Grid): Grid = grid.tiltUp.tiltLeft.tiltDown.tiltRight

proc countLoad(grid: Grid): int64 =
  for (x, y, c) in grid.cells:
    if c == 'O':
      result += grid.rowCount - y

proc parse(input: string): Grid = input.intoGrid

proc run1*(input: string): int64 = parse(input).tiltUp.countLoad

proc run2*(input: string): int64 =
  # A state will always have the same successor state.
  #
  # If we find a state at step n that was already computed at step m < n, we found
  # a cycle of length n - m starting at m, which will repeat at every

  var n = 0
  let startGrid = parse(input)
  var indices = @[(startGrid, 0)].toTable
  var grid = startGrid

  while true:
    n += 1
    grid = grid.spin_cycle
    if indices.contains grid:
      break
    indices[grid] = n
    if n mod 10 == 0:
      echo "Checking cycle ", n, "..."

  # Equation: max = m + l * r + c
  # Where:
  #   max = 1000000000
  #   m = indices[grid]
  #   l = n - m
  #   c < cycle_len
  #   c = max - a - l * r = (max - m) mod l

  let m = indices[grid]
  let l = n - m
  const maxx = 1000000000
  let c = (maxx - m) mod l

  for i in 0..<c:
    grid = grid.spin_cycle
  grid.countLoad

proc test1*(input: string): int64 = run1(TEST_CASE)
proc test2*(input: string): int64 = run2(TEST_CASE)
