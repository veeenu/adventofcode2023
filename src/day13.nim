import std/sequtils
import std/strutils

const TEST_CASE = """
#.##..##.
..#.##.#.
##......#
##......#
..#.##.#.
..##..##.
#.#.##.#.

#...##..#
#....#..#
..##..###
#####.##.
#####.##.
..##..###
#....#..#
""".strip()

type
  Field = seq[string]

proc rowMatch(field: Field, i, j: int): bool =
  field[i] == field[j]

proc columnMatch(field: Field, i, j: int): bool =
  for row in field:
    if row[i] != row[j]:
      return false
  true

proc rowMatchSmudge(field: Field, i, j: int): bool =
  var smudges = 1
  for (c1, c2) in zip(field[i], field[j]):
    if c1 != c2:
      if smudges > 0:
        smudges -= 1
      else:
        return false
  smudges == 0

proc columnMatchSmudge(field: Field, i, j: int): bool =
  var smudges = 1
  for row in field:
    if row[i] != row[j]:
      if smudges > 0:
        smudges -= 1
      else:
        return false
  smudges == 0

proc checkParity(
  field: Field,
  c: int,
  max: int,
  pred: proc(field: Field, i, j: int): bool
): bool =
  var i = 0
  while true:
    var c1 = c - i
    var c2 = c + i + 1
    if (c1 < 0) or (c2 >= max):
      return true
    if not pred(field, c1, c2):
      return false
    i += 1

proc checkParitySmudge(
  field: Field,
  c: int,
  max: int,
  pred: proc(field: Field, i, j: int): bool,
  predSmudge: proc(field: Field, i, j: int): bool
): bool =
  var smudge_checks = 0
  var i = 0
  while true:
    var c1 = c - i
    var c2 = c + i + 1
    if (c1 < 0) or (c2 >= max):
      break
    if smudge_checks == 0 and predSmudge(field, c1, c2):
      smudge_checks += 1
    elif not pred(field, c1, c2):
      return false
    i += 1
  smudge_checks == 1

proc findMirrorColumn(field: Field): int64 =
  for x in 0..<field[0].len() - 1:
    if field.columnMatch(x, x + 1) and field.checkParity(x, field[0].len, columnMatch):
      return x + 1

proc findMirrorRow(field: Field): int64 =
  for y in 0..<field.len() - 1:
    if field.rowMatch(y, y + 1) and field.checkParity(y, field.len, rowMatch):
      return y + 1

proc findMirrorColumnSmudge(field: Field): int64 =
  for x in 0..<field[0].len() - 1:
    if field.columnMatchSmudge(x, x + 1) or field.columnMatch(x, x + 1):
      if field.checkParitySmudge(
        x, field[0].len, columnMatch, columnMatchSmudge
      ):
        return x + 1

proc findMirrorRowSmudge(field: Field): int64 =
  for y in 0..<field.len() - 1:
    if field.rowMatchSmudge(y, y + 1) or field.rowMatch(y, y + 1):
      if field.checkParitySmudge(
        y, field.len, rowMatch, rowMatchSmudge
      ):
        return y + 1

proc findCount(field: Field): int64 =
  let mirror_col = field.findMirrorColumn
  let mirror_row = field.findMirrorRow

  mirror_col + 100 * mirror_row

proc findCountAll(fields: seq[Field]): int64 =
  for field in fields:
    result += field.findCount

proc findCountSmudge(field: Field): int64 =
  let mirror_col = field.findMirrorColumnSmudge
  let mirror_row = field.findMirrorRowSmudge

  mirror_col + 100 * mirror_row

proc findCountAllSmudge(fields: seq[Field]): int64 =
  for field in fields:
    result += field.findCountSmudge

proc parse(input: string): seq[Field] =
  let patterns = input.split("\n\n")
  for p in patterns:
    result.add p.splitLines()

proc run1*(input: string): int64 = parse(input).findCountAll
proc run2*(input: string): int64 = parse(input).findCountAllSmudge

proc test1*(input: string): int64 = run1(TEST_CASE)
proc test2*(input: string): int64 = run2(TEST_CASE)
