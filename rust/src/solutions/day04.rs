use std::collections::{HashSet, VecDeque};

use nom::{
    bytes::complete::tag,
    character::complete,
    combinator::map,
    error::VerboseError,
    multi::{many1, separated_list1},
    sequence::tuple,
};

use super::AocSolution;

pub struct Solution;

impl AocSolution for Solution {
    fn new() -> Self {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        win_count(input)
            .filter_map(|(_, win_count)| {
                if win_count == 0 {
                    None
                } else {
                    Some(2u64.pow(win_count - 1))
                }
            })
            .sum::<u64>()
    }

    fn part2(&self, input: &str) -> u64 {
        let win_counts = win_count(input).collect::<Vec<_>>();

        let mut queue = VecDeque::new();
        for (card, win_count) in &win_counts {
            queue.push_back((card.clone(), win_count));
        }

        let mut count = 0;

        while let Some((current_card, &win_count)) = queue.pop_front() {
            win_counts
                .iter()
                .skip_while(|(card, _)| card.index != current_card.index)
                .skip(1)
                .take(win_count as usize)
                .for_each(|(card, win_count)| queue.push_back((card.clone(), win_count)));

            count += 1;
        }

        count as u64
    }
}

fn win_count(input: &str) -> impl Iterator<Item = (Card, u32)> + '_ {
    input.lines().map(Card::parse).map(|card| {
        let winners = card
            .winners
            .iter()
            .copied()
            .collect::<HashSet<_>>()
            .intersection(&card.numbers.iter().copied().collect::<HashSet<_>>())
            .count() as u32;

        (card, winners)
    })
}

#[derive(Debug, Clone)]
struct Card {
    index: u32,
    winners: Vec<u32>,
    numbers: Vec<u32>,
}

impl Card {
    fn parse(line: &str) -> Self {
        let mut parser = map(
            tuple((
                tag("Card"),
                many1(tag(" ")),
                complete::u32::<_, VerboseError<_>>,
                tag(":"),
                many1(tag(" ")),
                separated_list1(many1(tag(" ")), complete::u32),
                tuple((many1(tag(" ")), tag("|"), many1(tag(" ")))),
                separated_list1(many1(tag(" ")), complete::u32),
            )),
            |(_, _, index, _, _, winners, _, numbers)| Card {
                index,
                winners,
                numbers,
            },
        );

        parser(line).unwrap().1
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {
        r#"
        Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
        "#
    };

    #[test]
    fn test() {
        let sol = Solution::new();
        println!("{:?}", Card::parse(TEST_INPUT));
        assert_eq!(sol.part1(TEST_INPUT), 13);
        assert_eq!(sol.part2(TEST_INPUT), 30);
    }
}
