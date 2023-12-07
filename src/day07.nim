import std/algorithm
import std/sequtils
import std/strutils

const TEST_CASE = """
32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483
""".strip()

type
  Card = range[2..14]
  Hand = array[0..4, Card]
  HandBid = tuple[hand: Hand, bid: int]
  HandKind = enum
    FiveOaK, FourOaK, FullHouse, ThreeOaK, TwoPair, OnePair, HighCard

proc getKind(self: Hand): HandKind =
  var tbl = default(array[2..15, int])

  for i in self:
    tbl[i] += 1

  let ones = foldl(tbl, a + (if b == 1: 1 else: 0), 0)
  let twos = foldl(tbl, a + (if b == 2: 1 else: 0), 0)
  let threes = foldl(tbl, a + (if b == 3: 1 else: 0), 0)
  let fours = foldl(tbl, a + (if b == 4: 1 else: 0), 0)
  let fives = foldl(tbl, a + (if b == 5: 1 else: 0), 0)

  let counts = (ones, twos, threes, fours, fives)
  if counts == (5, 0, 0, 0, 0):
    HighCard
  elif counts == (3, 1, 0, 0, 0):
    OnePair
  elif counts == (1, 2, 0, 0, 0):
    TwoPair
  elif counts == (2, 0, 1, 0, 0):
    ThreeOaK
  elif counts == (0, 1, 1, 0, 0):
    FullHouse
  elif counts == (1, 0, 0, 1, 0):
    FourOaK
  elif counts == (0, 0, 0, 0, 1):
    FiveOaK
  else:
    raise

proc getKindAugmented(self: Hand): HandKind =
  var tbl = default(array[2..15, int])

  for i in self:
    tbl[i] += 1

  tbl[11] = 0

  let max_count = max(tbl)
  var jsub = -1

  if max_count > 0:
    for i in countdown(15, 2):
      if tbl[i] == max_count and i != 11:
        jsub = i
        break
  else:
    jsub = 11

  var augHand = default(Hand)

  for i in 0..4:
    augHand[i] =
      if self[i] == 11: jsub
      else: self[i]

  augHand.getKind

proc icmp(ai, bi: int): int =
  if ai < bi:
    1
  elif ai > bi:
    -1
  else: 0

proc cmp(a, b: Hand): int =
  let (ka, kb) = (a.getKind, b.getKind)

  if ka == kb:
    for i in 0..4:
      let r = icmp(a[i], b[i])
      if r != 0:
        return r
    return 0
  elif ka > kb:
    1
  else:
    -1

proc cmpAugmented(a, b: Hand): int =
  let (ka, kb) = (a.getKindAugmented, b.getKindAugmented)

  if ka == kb:
    for i in 0..4:
      let av = if a[i] == 11: 1 else: a[i]
      let bv = if b[i] == 11: 1 else: b[i]
      let r = icmp(av, bv)
      if r != 0:
        return r
    return 0
  elif ka > kb:
    1
  else:
    -1

#
# Parsing
#

proc parseCard(card: char): Card =
  case card
  of 'A': 14
  of 'K': 13
  of 'Q': 12
  of 'J': 11
  of 'T': 10
  of '2'..'9': int(card) - int('0')
  else:
    raise

proc parseHand(hand: string): Hand =
  for i in 0..4:
    result[i] = parseCard(hand[i])

proc parseHandBid(line: string): HandBid =
  let toks = line.splitWhitespace()
  let hand = parseHand(toks[0])
  let bid = parseInt(toks[1])

  (hand, bid)

proc parseGame(input: string): seq[HandBid] =
  map(input.strip().splitLines(), parseHandBid)

#
# Entry points
#

proc run1*(input: string): int =
  let game = parseGame(input)

  var sorted_hands = game
  sorted_hands.sort(proc (a, b: HandBid): int = -cmp(a.hand, b.hand))
  for idx, hand in sorted_hands.pairs():
    result += (idx + 1) * hand.bid

proc run2*(input: string): int =
  let game = parseGame(input)

  var sorted_hands = game
  sorted_hands.sort(proc (a, b: HandBid): int = -cmpAugmented(a.hand, b.hand))
  for idx, hand in sorted_hands.pairs():
    result += (idx + 1) * hand.bid

when isMainModule:
  let game = parseGame(TEST_CASE)
  for hand in game:
    echo hand.hand.getKind, hand.hand

  echo "Must be 1: ", cmp(game[0].hand, game[1].hand), game[0].hand, game[1].hand
  echo "Must be -1: ", cmp(game[2].hand, game[3].hand), game[2].hand, game[3].hand
  echo "Must be 0: ", cmp(game[2].hand, game[2].hand), game[2].hand

  for hand in game:
    echo hand.hand.getKindAugmented, hand.hand

  echo run1(TEST_CASE)
  echo run2(TEST_CASE)
