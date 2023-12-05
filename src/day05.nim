import std/algorithm
import std/options
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

#
# Range types
#

type
  Range = object
    r_start: int
    r_end: int

proc intersect(a, b: Range): bool =
  return not (b.r_start > a.r_end or a.r_start > b.r_end)

proc union(a, b: Range): Range =
  if not a.intersect(b):
    raise newException(ValueError, "Ranges do not overlap")
  return Range(r_start: min(a.r_start, b.r_start), r_end: max(a.r_end, b.r_end))

proc intersection(a, b: Range): Option[Range] =
  if a.intersect(b):
    return some(Range(r_start: max(a.r_start, b.r_start), r_end: min(a.r_end, b.r_end)))

proc subtraction(a, b: Range): seq[Range] =
  if not a.intersect(b):
    return @[a]

  var ranges: seq[Range] = @[]

  if a.r_start < b.r_start:
    ranges.add(Range(r_start: a.r_start, r_end: b.r_start))
  if a.r_end > b.r_end:
    ranges.add(Range(r_start: b.r_end, r_end: a.r_end))

  ranges

proc contains(self: Range, val: int): bool =
  val in (self.r_start .. self.r_end)

proc size(self: Range): int =
  self.r_end - self.r_start

proc mapValue(self: Range, dst: Range, val: int): int =
  assert self.size() == dst.size()
  val - self.r_start + dst.r_start

type
  RangeSet = object
    ranges: seq[Range]

proc sort(self: var RangeSet) =
  self.ranges.sort(proc (a, b: Range): int = a.r_start - b.r_start)

proc add(self: var RangeSet, in_range: Range) =
  var in_range = in_range
  var new_ranges: seq[Range] = @[]

  for range in self.ranges:
    if in_range.intersect(range):
      in_range = in_range.union(range)
    else:
      new_ranges.add(range)

  new_ranges.add(in_range)

  self.ranges = new_ranges
  self.sort()

#
# Domain structs
#

type
  Map = object
    ranges: seq[(Range, Range)]

proc mapIndex(self: Map, input: int): int =
  for (dst_range, src_range) in self.ranges:
    if src_range.contains(input):
      return src_range.mapValue(dst_range, input)
  return input

proc findFirstIntersecting(self: Map, input_range: Range): Option[int] =
  var i = 0
  for i in 0..self.ranges.len():
    if self.ranges[i][1].r_start > input_range.r_start:
      return some(i)

proc findLastIntersecting(self: Map, input_range: Range): Option[int] =
  var i = 0
  for i in 0..self.ranges.len():
    if self.ranges[i][1].r_start > input_range.r_end:
      return some(i)

proc mapRange(self: Map, input_range: Range): RangeSet =
  var r: seq[Range] = @[]

  # Find first map after start of input range.
  let first_map = self.findFirstIntersecting(input_range)
  let last_map = self.findLastIntersecting(input_range)

  for (dst, src) in self.ranges[first_map.get()..last_map.get()]:
    r.add(src.intersection(input_range))
    r.add()
  
  # Find last map before end of input range.

  # for (dst_range, src_range) in self.ranges:
  #   let intersection = input_range.intersection(src_range)
  #   if intersection.isSome:
  #     let intersection = intersection.get()
  #     let s = src_range.mapValue(dst_range, intersection.r_start)
  #     let e = src_range.mapValue(dst_range, intersection.r_end)
  #     let mapped_range = Range(r_start: s, r_end: e)
  #     echo mapped_range
  #     r.add(mapped_range)
  #     for diff in input_range.subtraction(src_range):
  #       echo diff
  #       r.add(diff)
  #   else:
  #     r.add(input_range)
  #
  # echo r
  # RangeSet(ranges: r)

proc mapRanges(self: Map, input_ranges: RangeSet): RangeSet =
  var r = RangeSet()

  for range in input_ranges.ranges:
    for mapped_range in self.mapRange(range).ranges:
      r.add(mapped_range)
  
  echo "All ranges: ", r
  r

type
  Maps = object
    maps: seq[Map]

proc mapPath(self: Maps, seed: int): int =
  var index = seed

  for map in self.maps:
    index = map.mapIndex(index)

  index

proc minPath(self: Maps, seeds: seq[int]): int =
  var locs: seq[int] = @[]

  for seed in seeds:
    locs.add(self.mapPath(seed))

  locs.min()

proc mapRanges(self: Maps, seeds: RangeSet): RangeSet =
  var r = seeds

  for map in self.maps:
    r = map.mapRanges(r)

  r

#
# Parsing procs
#

proc parseSeeds(line: string): seq[int] =
  let tok = line.split(" ")
  tok[1..^1].map(parseInt)

proc parseMap(lines: openArray[string]): Map =
  var m = Map(ranges: @[])

  for line in lines:
    let parts = line.split(" ")
    let (dst, src, len) = (parseInt(parts[0]), parseInt(parts[1]), parseInt(parts[2]))
    m.ranges.add((Range(r_start: dst, r_end: dst + len), Range(r_start: src, r_end: src + len)))
  m.ranges.sort(proc (a, b: (Range, Range)): int = a[1].r_start - b[1].r_start)

  m

proc parseInput(input: string): (Maps, seq[int]) = 
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

  (Maps(maps: maps), seeds)

#
# Entry points
#

proc run1*(input: string): int =
  let (maps, seeds) = parseInput(input)
  maps.minPath(seeds)

proc run2*(input: string): int =
  let (maps, seeds) = parseInput(TEST_CASE)

  var seeds_ranges = RangeSet()
  var idx = 0
  while idx < seeds.len():
    let range = Range(r_start: seeds[idx], r_end: seeds[idx] + seeds[idx + 1])
    seeds_ranges.add(range)
    idx += 2

  let mapped_range = maps.mapRanges(seeds_ranges)
  echo mapped_range

  # maps.minPath(seedsRanges)
  0

when isMainModule:
  echo run1(TEST_CASE)
  echo run2(TEST_CASE)
