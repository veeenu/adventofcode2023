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
  for _ in 0..result.rowCount:
    for y in 1..<result.rowCount:
      for (x, _, c) in result.row(y):
        if c == 'O' and result.cell(x, y - 1) == '.':
          result.setCell(x, y - 1, 'O')
          result.setCell(x, y, '.')

proc tiltDown(grid: Grid): Grid =
  result = grid
  for _ in 0..result.rowCount:
    for y in 0..<result.rowCount - 1:
      for (x, _, c) in result.row(y):
        if c == 'O' and result.cell(x, y + 1) == '.':
          result.setCell(x, y + 1, 'O')
          result.setCell(x, y, '.')

proc tiltLeft(grid: Grid): Grid =
  result = grid
  for r in 0..result.colCount:
    for x in 1..<result.colCount:
      for (_, y, c) in result.column(x):
        if c == 'O' and result.cell(x - 1, y) == '.':
          result.setCell(x - 1, y, 'O')
          result.setCell(x, y, '.')

proc tiltRight(grid: Grid): Grid =
  result = grid
  for _ in 0..result.colCount:
    for x in 0..<result.colCount - 1:
      for (_, y, c) in result.column(x):
        if c == 'O' and result.cell(x + 1, y) == '.':
          result.setCell(x + 1, y, 'O')
          result.setCell(x, y, '.')

proc cycle(grid: Grid): Grid =
  grid.tiltUp.tiltLeft.tiltDown.tiltRight

proc countLoad(grid: Grid): int64 =
  for (x, y, c) in grid.cells:
    if c == 'O':
      result += grid.rowCount - y

proc parse(input: string): Grid = input.intoGrid

proc run1*(input: string): int64 = parse(input).tiltUp.countLoad

proc run2*(input: string): int64 =
  var cycles = 0
  let startGrid = parse(input)
  var indices = @[(startGrid, 0)].toTable
  var grid = startGrid

  while true:
    cycles += 1
    grid = grid.cycle
    if indices.contains grid:
      break
    indices[grid] = cycles
    if cycles mod 10 == 0:
      echo cycles

  echo "Found cycle ", cycles, " was at ", indices[grid]


proc test1*(input: string): int64 = run1(TEST_CASE)
proc test2*(input: string): int64 = run2(TEST_CASE)
