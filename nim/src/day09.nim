import std/strutils
import std/sequtils

const TEST_CASE = """
0 3 6 9 12 15
1 3 6 10 15 21
10 13 16 21 30 45
""".strip()

proc getNextValue(s: seq[int64]): int64 =
  var last_values = @[s[ ^ 1]]
  var cur_seq = s
  while true:
    var next_seq = default(seq[int64])
    for i in 0..<cur_seq.len() - 1:
      next_seq.add(cur_seq[i + 1] - cur_seq[i])

    if next_seq.all(proc (i: int64): bool = i == 0):
      break

    last_values.add next_seq[ ^ 1]
    cur_seq = next_seq

  last_values.foldl(a + b, 0)

proc getPrediction(s: seq[seq[int64]]): int64 =
  for line in s:
    result += getNextValue(line)

proc reverse(s: seq[int64]): seq[int64] =
  for i in 0..<s.len():
    result.add s[s.len() - 1 - i]

proc getPredictionBackwards(s: seq[seq[int64]]): int64 =
  for line in s:
    let line_rev = reverse(line)
    result += getNextValue(line_rev)

proc parse(lines: string): seq[seq[int64]] =
  for line in lines.splitLines():
    var s = default(seq[int64])
    for i in line.splitWhitespace():
      s.add parseInt i
    result.add s

proc run1*(input: string): int64 =
  let data = parse(input.strip())
  getPrediction(data)

proc run2*(input: string): int64 =
  let data = parse(input.strip())
  getPredictionBackwards(data)

proc test1*(input: string): int64 =
  let data = parse(TEST_CASE.strip())
  echo getPrediction(data)

proc test2*(input: string): int64 =
  let data = parse(TEST_CASE.strip())
  echo getPredictionBackwards(data)
