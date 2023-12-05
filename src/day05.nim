import std/sequtils
import std/strutils

const TEST_CASE: string = """
seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4
""".strip()

type
  Map = object
    ranges: seq[(int, int, int)]
  
  Maps = object
    maps: seq[Map]
    seeds: seq[int]

proc mapIndex(self: Map, input: int): int =
  for (dst, src, len) in self.ranges:
    if input in (src..src + len):
      return input - src + dst
  return input

proc mapPath(self: Maps, input: int): int =
  var index = input

  for map in self.maps:
    index = map.mapIndex(index)

  index

proc minPath(self: Maps): int =
  var ranges: seq[int] = @[]

  for seed in self.seeds:
    ranges.add(self.mapPath(seed))

  ranges.min()

proc parseMap(lines: openArray[string]): Map =
  var m = Map(ranges: @[])

  for line in lines:
    let parts = line.split(" ")
    let range = (parseInt(parts[0]), parseInt(parts[1]), parseInt(parts[2]))
    m.ranges.add(range)

  m

proc parseSeeds(line: string): seq[int] =
  let tok = line.split(" ")
  tok[1..^1].map(parseInt)

proc parseInput(input: string): Maps = 
  let lines = input.splitLines()
  var line_ranges: seq[(int, int)] = @[]

  let seeds = parseSeeds(lines[0])

  var cursor = 2
  while cursor < lines.len():
    if lines[cursor].endsWith("map:"):
      cursor += 1
      let start_range = cursor
      while cursor < lines.len() and lines[cursor] != "":
        cursor += 1
      let end_range = cursor - 1
      line_ranges.add((start_range, end_range))
    cursor += 1

  var maps: seq[Map] = @[]
  for (s, e) in line_ranges:
    maps.add(parseMap(lines[s..e]))

  Maps(maps: maps, seeds: seeds)


proc run1*(input: string): int =
  let maps = parseInput(input)
  maps.minPath()

proc run2*(input: string): int =
  0

when isMainModule:
  echo run1(TEST_CASE)
  echo run2(TEST_CASE)
