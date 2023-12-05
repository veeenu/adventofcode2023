import std/cmdline
import std/strformat
import std/strutils
import std/macros
import std/os
import input

proc getDay(): int =
  try:
    let cli = commandLineParams()
    if cli.len() > 0:
      cli[0].parseInt()
    else:
      raise
  except:
    input.today()

macro genCase(): untyped =
  let importStmts = newStmtList()
  let dayIdent = newIdentNode("day")
  let caseStmt = nnkCaseStmt.newTree(dayIdent)

  for day in 1..25:
    let daySource = fmt"src/day{day:02}.nim"
    let dayModuleName = newIdentNode(fmt"day{day:02}")
    let dayLit = newIntLitNode(day)
    if fileExists(daySource):
      echo fmt"Importing {dayModuleName}"

      let caseDay = quote do:
        let input = getInput(`dayLit`)

        let result1 = `dayModuleName`.run1(input)
        echo "Part \x1b[32m1\x1b[0m: \x1b[33m" & repr(result1) & "\x1b[0m"

        let result2 = `dayModuleName`.run2(input)
        echo "Part \x1b[32m2\x1b[0m: \x1b[33m" & repr(result2) & "\x1b[0m"

      let ofBranch = nnkOfBranch.newTree(dayLit)
      ofBranch.add caseDay
      caseStmt.add ofBranch

      let importStmt = quote do:
        import `dayModuleName`

      importStmts.add importStmt

  caseStmt.add nnkElse.newTree().add quote do:
    echo fmt"Day {day} unimplemented"

  quote do:
    `importStmts`

    proc runDay(`dayIdent`: int) =
      `caseStmt`

when isMainModule:
  genCase()
  runDay(getDay())
