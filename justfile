DAY := `date +%d`

alias r := run
alias t := test

run DAY=(DAY):
  cd rust && cargo run --release --bin day`printf "%02d" {{DAY}}`

test DAY=(DAY):
  cd rust && cargo test --release --bin day`printf "%02d" {{DAY}}`
