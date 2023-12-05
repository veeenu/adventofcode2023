import std/httpclient
import std/syncio
import std/strformat
import std/times

proc cookie(): string =
  syncio.open(".cookie").readAll()

proc saveInput(day: int, input: string): string =
  syncio.open(fmt"input/day{day:02}.txt", fmWrite).write(input)
  input

proc today*(): int =
  times.getTime().local.monthday

proc downloadInput(day: int = today()): string =
  let headers = newHttpHeaders([("Cookie", cookie())])
  let client = newHttpClient(headers = headers)
  let input = client.getContent(fmt"https://adventofcode.com/2023/day/{day}/input")

  saveInput(day, input)

proc getInput*(day: int = today()): string =
  try:
    syncio.open(fmt"input/day{day:02}.txt", fmRead).readAll()
  except:
    downloadInput(day)
