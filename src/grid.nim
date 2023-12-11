import std/strutils

type
  Grid* = seq[GridRow]
  GridRow* = string
  GridCell* = (int, int, char)

proc intoGrid*(self: string): Grid =
  self.splitLines()

proc rowRange*(self: Grid): Slice[int] = 0..<self.len()
proc colRange*(self: Grid): Slice[int] = 0..<self[0].len()

iterator cells*(self: Grid): GridCell =
  for y in 0..<self.len():
    for x in 0..<self[y].len():
      yield (x, y, self[y][x])

iterator rows*(self: Grid, row: int): (int, GridRow) =
  for y in 0..<self.len():
    yield (row, self[row])

iterator row*(self: Grid, row: int): GridCell =
  for x in self.colRange:
    yield (x, row, self[row][x])

iterator column*(self: Grid, column: int): GridCell =
  for y in self.rowRange:
    yield (column, y, self[y][column])


