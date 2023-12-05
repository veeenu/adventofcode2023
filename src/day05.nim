import std/algorithm
import std/sequtils
import std/strutils

#
# Range types
#

type
  Range = tuple[start: int, stop: int]
  RangeMap = tuple[dst: Range, src: Range]

proc isEmpty(self: Range): bool = self.start >= self.stop

proc contains(self: Range, val: int): bool = val in (self.start .. self.stop)

proc size(self: Range): int = self.stop - self.start

# Map a value from the source to a value into the destination range.
proc mapValue(self: RangeMap, val: int): int =
  assert self.src.size() == self.dst.size()
  val - self.src.start + self.dst.start

# Apply the range map to the input range.
# Returns the mapped range and the fixed points ranges, if not empty.
proc apply(self: RangeMap, seed: Range): (Range, seq[Range]) =
  let fixed_left: Range = (
    min(seed.start, self.src.start),
    min(seed.stop, self.src.start)
  )

  let fixed_right: Range = (
    max(seed.start, self.src.stop),
    max(seed.stop, self.src.stop)
  )

  let mapped: Range = (
    self.mapValue(max(seed.start, self.src.start)),
    self.mapValue(min(seed.stop, self.src.stop))
  )

  var fixed: seq[Range] = @[]

  if not fixed_left.isEmpty():
    fixed.add(fixed_left)

  if not fixed_right.isEmpty():
    fixed.add(fixed_right)

  (mapped, fixed)

#
# Map types
#

type
  Map = object
    name: string
    ranges: seq[RangeMap]

proc mapIndex(self: Map, input: int): int =
  for (dst_range, src_range) in self.ranges:
    if src_range.contains(input):
      return (dst_range, src_range).mapValue(input)
  return input

proc mapRange(self: Map, input: Range): seq[Range] =
  var unmapped_ranges: seq[Range] = @[input]

  for range in self.ranges:
    var next_unmapped_ranges: seq[Range] = @[]
    for unmapped_range in unmapped_ranges:
      let (mapped, fixed) = range.apply(unmapped_range)
      if not mapped.isEmpty():
        result.add mapped
      next_unmapped_ranges.add fixed
    unmapped_ranges = next_unmapped_ranges

  result.add unmapped_ranges

proc mapRanges(self: Map, input: seq[Range]): seq[Range] =
  for input_range in input:
    result.add self.mapRange(input_range)

type
  Maps = seq[Map]

proc mapPath(self: Maps, seed: int): int =
  result = seed
  for map in self:
    result = map.mapIndex(result)

proc minPath(self: Maps, seeds: seq[int]): int =
  var locs: seq[int] = @[]
  for seed in seeds:
    locs.add self.mapPath(seed)
  locs.min()

proc mapRanges(self: Maps, input: seq[Range]): seq[Range] =
  result = input
  for map in self:
    result = map.mapRanges(result)

proc findMin(self: Maps, input: seq[Range]): int =
  result = high(int)
  for range in self.mapRanges(input):
    result = min(result, range.start)

#
# Parsing procs
#

proc parseSeeds(line: string): seq[int] =
  let tok = line.split(" ")
  tok[1..^1].map(parseInt)

proc parseMap(name: string, lines: openArray[string]): Map =
  var m = Map(name: name, ranges: @[])

  for line in lines:
    let parts = line.split(" ")
    let (dst, src, len) = (parseInt(parts[0]), parseInt(parts[1]), parseInt(
        parts[2]))
    m.ranges.add(((dst, dst + len), (src, src + len)))
  m.ranges.sort(proc (a, b: (Range, Range)): int = a[1].start - b[1].start)

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
    maps.add(parseMap(lines[s-1].split(" ")[0], lines[s..e]))

  (maps, seeds)

proc parseInput2(input: string): (Maps, seq[Range]) =
  let (maps, seeds) = parseInput(input)

  var seeds_ranges: seq[Range] = @[]
  var idx = 0
  while idx < seeds.len():
    let range = (seeds[idx], seeds[idx] + seeds[idx + 1])
    seeds_ranges.add(range)
    idx += 2

  (maps, seeds_ranges)

#
# Entry points
#

proc run1*(input: string): int =
  let (maps, seeds) = parseInput(input)
  maps.minPath(seeds)

proc run2*(input: string): int =
  let (maps, seeds) = parseInput2(input)
  maps.findMin(seeds)
