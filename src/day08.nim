import std/re
import std/strutils
import std/tables

const TEST_CASE = """
RL

AAA = (BBB, CCC)
BBB = (DDD, EEE)
CCC = (ZZZ, GGG)
DDD = (DDD, DDD)
EEE = (EEE, EEE)
GGG = (GGG, GGG)
ZZZ = (ZZZ, ZZZ)
""".strip()

const TEST_CASE2 = """
LR

11A = (11B, XXX)
11B = (XXX, 11Z)
11Z = (11B, XXX)
22A = (22B, XXX)
22B = (22C, 22C)
22C = (22Z, 22Z)
22Z = (22B, 22B)
XXX = (XXX, XXX)
"""

type
  Graph = Table[string, tuple[l: string, r: string]]
  Step = enum
    Left = 'L'
    Right = 'R'
  Steps = seq[Step]

proc parseSteps(input: string): Steps =
  for c in input:
    if c == 'R':
      result.add Step.Right
    elif c == 'L':
      result.add Step.Left

proc parseGraph(input: string): Graph =
  var matches: array[3, string]
  var line_re = re"^(\w+) = \((\w+), (\w+)\)$"

  for line in input.splitLines():
    if match(line, line_re, matches):
      result[matches[0]] = (matches[1], matches[2])

proc parseInput(input: string): (Steps, Graph) =
  let first_nl = input.find('\n')
  let second_nl = input.find('\n', first_nl + 1)

  (parseSteps(input[0..first_nl]), parseGraph(input[second_nl..^1]))

#
# Logic
#

# Iteratively traverse the graph via the edges
proc traversal(
  graph: Graph,
  steps: Steps,
  src: string,
  dest: proc(s: string): bool
): int64 =
  var current = src
  while true:
    if dest(current):
      break
    let (l, r) = graph[current]
    let step = steps[result mod steps.len()]
    current =
      case step
      of Left: l
      of Right: r
    result += 1

# LCM of the lengths
proc parTraversal(graph: Graph, steps: Steps): int64 =
  var stepCounts: seq[int64]
  let pred = proc(s: string): bool = s.endsWith("Z")

  # Compute the lengths to the first ending node for each starting node
  for k in graph.keys:
    if k.endsWith('A'):
      stepCounts.add traversal(graph, steps, k, pred)

  proc gcd(a, b: int64): int64 =
    var aa = a
    var bb = b
    while true:
      (aa, bb) = (bb, aa mod bb)
      if bb == 0:
        return aa

  proc lcm(a, b: int64): int64 =
    (a * b) div gcd(a, b)

  # Compute the LCM for all the path lengths
  result = stepCounts[0]
  for i in 1..<stepCounts.len:
    echo result, " ", stepCounts[i]
    result = lcm(result, stepCounts[i])

#
# Entry points
#

proc run1*(input: string): int64 =
  let (steps, graph) = parseInput(input)
  traversal(graph, steps, "AAA", proc(s: string): bool = s == "ZZZ")

proc run2*(input: string): int64 =
  let (steps, graph) = parseInput(input)
  parTraversal(graph, steps)

proc test1*(input: string): int64 = 0
proc test2*(input: string): int64 = 0

when isMainModule:
  echo run1(TEST_CASE)
  echo run2(TEST_CASE2)
