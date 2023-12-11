import std/strutils
import std/sugar

import grid

const TEST_CASE = """
...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....
""".strip()

type
  Galaxy = tuple[x: int, y: int]

proc distance(self, other: Galaxy): int =
  abs(self.y - other.y) + abs(self.x - other.x)

type
  Image = object
    grid: Grid
    exp_rows: seq[int]
    exp_columns: seq[int]
  Galaxies = seq[Galaxy]

iterator pairs(self: Galaxies): (Galaxy, Galaxy) =
  for g1 in 0..<self.len():
    for g2 in (g1 + 1)..<self.len():
      yield (self[g1], self[g2])

proc allDistances(self: Galaxies): int =
  for (g1, g2) in self.pairs:
    result += g1.distance(g2)

proc intoGalaxies(self: Image, exp_rate: int): Galaxies = collect:
  for (x, y, c) in self.grid.cells:
    var ex = x
    var ey = y
    for v in self.exp_rows:
      if v < y:
        ey += exp_rate
    for v in self.exp_columns:
      if v < x:
        ex += exp_rate
    if c == '#':
      (ex, ey)

proc parse(input: string): Image =
  let grid = input.intoGrid

  let exp_rows = collect:
    for y in grid.rowRange:
      var all_empty = true
      for (_, _, c) in grid.row(y):
        all_empty = all_empty and c == '.'
      if all_empty:
        y

  let exp_columns = collect:
    for x in grid.colRange:
      var all_empty = true
      for (_, _, c) in grid.column(x):
        all_empty = all_empty and c == '.'
      if all_empty:
        x

  Image(
    grid: grid,
    exp_rows: exp_rows,
    exp_columns: exp_columns
  )

proc run1*(input: string): int64 =
  parse(input).intoGalaxies(1).allDistances
proc run2*(input: string): int64 =
  parse(input).intoGalaxies(1000000 - 1).allDistances

proc test1*(input: string): int64 =
  parse(TEST_CASE).intoGalaxies(1).allDistances
proc test2*(input: string): int64 =
  echo parse(TEST_CASE).intoGalaxies(9).allDistances
  echo parse(TEST_CASE).intoGalaxies(99).allDistances
  0
