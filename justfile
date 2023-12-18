DAY := `date +%d`

alias r := run
alias t := test

run DAY=(DAY):
  zig run zig/day{{DAY}}.zig

test DAY=(DAY):
  zig test zig/day{{DAY}}.zig
