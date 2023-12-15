import std/math
import std/sets
import std/tables
import std/strutils

const TEST_CASE = """
-L|F7
7S-7|
L|7||
-L-J|
L|-JF
""".strip()

const TEST_CASE2 = """
..F7.
.FJ|.
SJ.L7
|F--J
LJ...
""".strip()

const TEST_CASE3 = """
...........
.S-------7.
.|F-----7|.
.||.....||.
.||.....||.
.|L-7.F-J|.
.|..|.|..|.
.L--J.L--J.
...........
""".strip()

const TEST_CASE4 = """
.F----7F7F7F7F-7....
.|F--7||||||||FJ....
.||.FJ||||||||L7....
FJL7L7LJLJ||LJ.L-7..
L--J.L7...LJS7F-7L7.
....F-J..F7FJ|L7L7L7
....L7.F7||L7|.L7L7|
.....|FJLJ|FJ|F7|.LJ
....FJL-7.||.||||...
....L---J.LJ.LJLJ...
"""

type
  Node = tuple[x: int, y: int]
  Path = seq[Node]
  Graph = object
    start: Node
    adj: Table[Node, (Node, Node)]

proc parse(input: string): Graph =
  let lines = input.splitLines()
  for y in 0..<lines.len():
    for x in 0..<lines[y].len():
      case lines[y][x]
      of '|': result.adj[(x, y)] = ((x, y - 1), (x, y + 1))
      of '-': result.adj[(x, y)] = ((x - 1, y), (x + 1, y))
      of '7': result.adj[(x, y)] = ((x - 1, y), (x, y + 1))
      of 'J': result.adj[(x, y)] = ((x, y - 1), (x - 1, y))
      of 'F': result.adj[(x, y)] = ((x + 1, y), (x, y + 1))
      of 'L': result.adj[(x, y)] = ((x + 1, y), (x, y - 1))
      of 'S': result.start = (x, y)
      of '.': discard
      else: raise

proc startAdj(self: Graph): Path =
  for (adj, v) in self.adj.pairs():
    let (n1, n2) = v
    if n1 == self.start or n2 == self.start:
      result.add adj

proc traverse(self: Graph): Path =
  let start_adj = self.startAdj
  let start_node = start_adj[0]
  var (current_node, prev_node) = (start_node, self.start)

  result.add self.start

  while true:
    result.add current_node
    let (n1, n2) = self.adj[current_node]
    if n1 == prev_node:
      (current_node, prev_node) = (n2, current_node)
    elif n2 == prev_node:
      (current_node, prev_node) = (n1, current_node)
    if current_node == self.start:
      break

proc enclosed(path: Path, input: string): HashSet[Node] =
  let lines = input.splitLines()
  let path_set = path.toHashSet

  for y in 0..<lines.len():
    var is_inside = false
    var is_upwards = false
    for x in 0..<lines[y].len():
      if (x, y) in path_set:
        let ch = lines[y][x]
        if ch == '|' or ch == 'S':
          is_inside = not is_inside
        elif ch == 'F':
          is_upwards = true
        elif ch == 'L':
          is_upwards = false
        elif ch == '7' and not is_upwards:
          is_inside = not is_inside
        elif ch == 'J' and is_upwards:
          is_inside = not is_inside

      if is_inside and not ((x, y) in path_set):
        result.incl (x, y)

proc mapChar(c: char): string =
  case c
  of 'S': "S"
  of '|': "|"
  of '-': "-"
  of '7': "┒"
  of 'F': "┎"
  of 'J': "┚"
  of 'L': "┖"
  of '.': "."
  else: raise

proc highlight(
  input: string,
  path: Path,
  not_enclosed_set: HashSet[Node] = default(HashSet[Node])
) =
  let path_set = path.toHashSet
  let lines = input.splitLines()
  for y in 0..<lines.len():
    for x in 0..<lines[y].len():
      if (x, y) in not_enclosed_set:
        stdout.write "\x1b[32m"
        stdout.write mapChar lines[y][x]
        stdout.write "\x1b[0m"
      elif (x, y) in path_set:
        stdout.write "\x1b[31m"
        stdout.write mapChar lines[y][x]
        stdout.write "\x1b[0m"
      else:
        stdout.write mapChar lines[y][x]
    stdout.write("\n")

proc run1*(input: string): int64 =
  let graph = parse(input)
  let path = graph.traverse

  highlight(input, path)
  echo path.len()

  let l = float64(path.len())
  int64(ceil(l / 2))

proc run2*(input: string): int64 =
  let graph = parse(input)
  let path = graph.traverse
  let enclosed = path.enclosed(input)

  highlight(input, path, enclosed)
  enclosed.len()

proc test1*(input: string): int64 =
  block:
    let graph = parse(TEST_CASE)
    let path = graph.traverse

    highlight(TEST_CASE, path)
    echo path.len() div 2

  block:
    let graph = parse(TEST_CASE2)
    let path = graph.traverse

    highlight(TEST_CASE2, path)
    echo path.len() div 2
  0

proc test2*(input: string): int64 =
  block:
    let graph = parse(TEST_CASE3)
    let path = graph.traverse
    let encl = path.enclosed(TEST_CASE3)
    highlight(TEST_CASE3, path, encl)
    echo encl.len()

  block:
    let graph = parse(TEST_CASE4)
    let path = graph.traverse
    let encl = path.enclosed(TEST_CASE4)
    highlight(TEST_CASE4, path, encl)
    echo encl.len()
