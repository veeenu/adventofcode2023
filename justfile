r:
  zig run -O ReleaseFast zig/day$(date +%d).zig

t:
  zig run -O Debug zig/day$(date +%d).zig -- t
