import std/strutils

iterator zip[T1, T2](a: iterator(): T1, b: iterator(): T2): (T1, T2) =
  while true:
    let na = a()
    let nb = b()
    if finished(a) or finished(b):
      break
    yield (na, nb)

proc raceDistance(hold_time: int, total_time: int): int =
  hold_time * (total_time - hold_time)

type
  Race = tuple[time: int, distance: int]

proc score(self: Race, hold_time: int): int =
  raceDistance(hold_time, self.time) - self.distance

proc isWin(self: Race, hold_time: int): bool =
  self.score(hold_time) > 0

proc countWins(self: Race): int =
  for i in 0..self.time:
    if self.isWin(i):
      result += 1

proc findZeros(self: Race): (int, int) =
  # Function is a parabola; first find the top, then split 0-distance in two
  # ranges, and bisect each to find the zero.
  #
  # score(x) = x * (b - x) - c = -x^2 + bx - c  (b = time, c = distance)
  #
  # So the top is always x = -b / 2a = -b / -2 = b / 2 = self.time / 2.

  proc findZero(min, max: int, val: proc(v: int): int): int =
    let mid = int((max - min) / 2) + min
    let v = val(mid)
    echo min, " -> ", max, ": ", mid, " (", v, ")"
    if v == 0:
      v
    elif v > 0:
      if max-min < 2 and val(mid - 1) < 0:
        return mid
      findZero(min, mid, val)
    else:
      if max-min < 2 and val(mid + 1) > 0:
        return mid
      findZero(mid, max, val)

  echo "Zero 1:"
  let zero1 = findZero(
    0, int(self.time / 2), proc(x: int): int = self.score(x)
  )

  echo "Zero 2:"
  let zero2 = findZero(
    int(self.time / 2), self.time, proc(x: int): int = -self.score(x)
  )

  (zero1, zero2)


proc parseInput1(input: string): seq[Race] =
  let lines = input.splitLines()

  proc parseRow(line: string): iterator(): int =
    return iterator(): int =
      let t = line.splitWhitespace()
      for i in t[1..^1]:
        yield parseInt(i)

  let parseTime = parseRow(lines[0])
  let parseDistance = parseRow(lines[1])

  for (time, distance) in zip(parseTime, parseDistance):
    result.add((time, distance))

proc parseInput2(input: string): Race =
  let lines = input.splitLines()

  proc joinLine(line: string): string =
    for i in line.splitWhitespace()[1..^1]:
      result &= i

  let time = parseInt(joinLine(lines[0]))
  let distance = parseInt(joinLine(lines[1]))
  (time, distance)

proc run1*(input: string): int =
  result = 1
  let races = parseInput1(input)
  echo races
  for r in races:
    let w = r.countWins()
    echo w
    result *= w

proc run2*(input: string): int =
  let race = parseInput2(input)
  let (z1, z2) = race.findZeros()
  z2 - z1

proc test1*(input: string): int64 = 0
proc test2*(input: string): int64 = 0
