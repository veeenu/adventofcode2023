import std/deques
import std/strutils

const TEST_CASE = """
???.### 1,1,3
.??..??...?##. 1,1,3
?#?#?#?#?#?#?#? 1,3,1,6
????.#...#... 4,1,1
????.######..#####. 1,6,5
?###???????? 3,2,1
""".strip()

type
  State = enum
    Ok, Broken, Unknown
  Row = object
    states: seq[State]
    check: seq[int]

proc countUnknowns(self: seq[State]): int =
  for x in self:
    if x == State.Unknown:
      result += 1

proc countBroken(self: seq[State]): int =
  for x in self:
    if x == State.Broken:
      result += 1

proc expand(self: seq[State]): (seq[State], seq[State]) =
  var replaced = false
  for x in self:
    if x == State.Unknown and not replaced:
      result[0].add State.Ok
      result[1].add State.Broken
      replaced = true
    else:
      result[0].add x
      result[1].add x

proc intoCheck(self: seq[State]): seq[int] =
  var streak = 0
  for x in self:
    if x == State.Broken:
      streak += 1
    elif x == State.Unknown:
      break
    elif streak > 0:
      result.add streak
      streak = 0
  if streak > 0:
    result.add streak

proc isPrefix(a, b: seq[int]): bool =
  if a.len > b.len:
    return false
  for i in 0..<a.len:
    if a[i] > b[i]:
      return false
  true

proc countValidStates(self: Row): int64 =
  var q = @[self.states].toDeque

  while q.len() > 0:
    let states = q.popFirst
    let count_unk = states.countUnknowns
    let states_check = states.intoCheck

    if count_unk == 0 and states_check == self.check:
      result += 1
    elif count_unk > 0 and states_check.isPrefix(self.check):
      let (a, b) = states.expand
      q.addLast a
      q.addLast b

proc countAllValidStates(self: seq[Row]): int64 =
  for x in self:
    result += x.countValidStates

proc parse(input: string): seq[Row] =
  proc parseStates(states: string): seq[State] =
    for c in states:
      result.add case c
        of '?': State.Unknown
        of '#': State.Broken
        of '.': State.Ok
        else: raise

  proc parseChecks(checks: string): seq[int] =
    for c in checks.split(','):
      result.add parseInt(c)

  for line in input.splitLines():
    let segments = line.splitWhitespace()
    let states = parseStates(segments[0])
    let check = parseChecks(segments[1])
    result.add Row(states: states, check: check)

proc run1*(input: string): int64 = parse(input).countAllValidStates
proc run2*(input: string): int64 = 0

proc test1*(input: string): int64 =
  let rows = parse(TEST_CASE)
  for row in rows:
    echo row.countValidStates

proc test2*(input: string): int64 = 0
