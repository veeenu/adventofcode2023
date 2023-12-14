import std/strutils

type
  Grid* = seq[GridRow]
  GridRow* = string
  GridCell* = (int, int, char)

proc intoGrid*(self: string): Grid =
  self.splitLines()

proc rowCount*(self: Grid): int = self.len
proc colCount*(self: Grid): int = self[0].len

proc rowRange*(self: Grid): Slice[int] = 0..<self.rowCount
proc colRange*(self: Grid): Slice[int] = 0..<self.colCount

proc cell*(self: Grid, x, y: int): char =
  self[y][x]

proc setCell*(self: var Grid, x, y: int, c: char) =
  self[y][x] = c

iterator cells*(self: Grid): GridCell =
  for y in self.rowRange:
    for x in self.colRange:
      yield (x, y, self[y][x])

iterator rows*(self: Grid): (int, GridRow) =
  for y in 0..<self.len():
    yield (y, self[y])

iterator row*(self: Grid, row: int): GridCell =
  for x in self.colRange:
    yield (x, row, self[row][x])

iterator column*(self: Grid, column: int): GridCell =
  for y in self.rowRange:
    yield (column, y, self[y][column])

proc print*(self: Grid) =
  for (y, row) in self.rows:
    echo row, " ", y
  echo ""

