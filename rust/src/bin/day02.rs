use adventofcode2023::AocSolution;

use nom::{
    branch::alt, bytes::complete::tag, character::complete, combinator::map, error::VerboseError,
    multi::separated_list0, sequence::tuple,
};

pub struct Solution;

impl AocSolution for Solution {
    const DAY: u8 = 2;

    fn new() -> Self {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        input
            .trim()
            .lines()
            .map(Game::parse)
            .map(|g| {
                if g.is_possible(12, 13, 14) {
                    g.index
                } else {
                    0
                }
            })
            .sum::<u64>()
    }

    fn part2(&self, input: &str) -> u64 {
        input
            .trim()
            .lines()
            .map(Game::parse)
            .map(|g| g.min_cubes())
            .map(|(r, g, b)| r * g * b)
            .sum::<u64>()
    }
}

#[derive(Debug)]
struct Game {
    index: u64,
    sets: Vec<CubeSet>,
}

impl Game {
    fn is_possible(&self, red: u64, green: u64, blue: u64) -> bool {
        self.sets.iter().all(|c| c.is_possible(red, green, blue))
    }

    fn min_cubes(&self) -> (u64, u64, u64) {
        self.sets.iter().fold((0, 0, 0), |(r, g, b), cube_set| {
            let (rs, gs, bs) = cube_set.as_tuple();
            (u64::max(r, rs), u64::max(g, gs), u64::max(b, bs))
        })
    }

    fn parse(line: &str) -> Self {
        let parse_cube = map(
            tuple((
                complete::u64::<&str, VerboseError<_>>,
                alt((tag(" red"), tag(" green"), tag(" blue"))),
            )),
            |(count, color)| match color {
                " red" => Cube::Red(count),
                " green" => Cube::Green(count),
                " blue" => Cube::Blue(count),
                _ => panic!(),
            },
        );

        let parse_cubes = map(separated_list0(tag(", "), parse_cube), CubeSet);
        let parse_set = separated_list0(tag("; "), parse_cubes);

        let mut parse_game = map(
            tuple((tag("Game "), complete::u64, tag(": "), parse_set)),
            |(_, index, _, sets)| Game { index, sets },
        );

        parse_game(line).unwrap().1
    }
}

#[derive(Debug)]
struct CubeSet(Vec<Cube>);

#[derive(Debug)]
enum Cube {
    Red(u64),
    Green(u64),
    Blue(u64),
}

impl CubeSet {
    fn is_possible(&self, red: u64, green: u64, blue: u64) -> bool {
        let (set_red, set_green, set_blue) =
            self.0.iter().fold((0, 0, 0), |(r, g, b), cube| match cube {
                Cube::Red(i) => (r + i, g, b),
                Cube::Green(i) => (r, g + i, b),
                Cube::Blue(i) => (r, g, b + i),
            });

        set_red <= red && set_green <= green && set_blue <= blue
    }

    fn as_tuple(&self) -> (u64, u64, u64) {
        self.0.iter().fold((0, 0, 0), |(r, g, b), cube| match cube {
            Cube::Red(i) => (r + i, g, b),
            Cube::Green(i) => (r, g + i, b),
            Cube::Blue(i) => (r, g, b + i),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use indoc::indoc;

    const TEST_INPUT: &str = indoc!(
        r#"
        Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
        "#
    );

    #[test]
    fn test_parser() {
        let mut it = TEST_INPUT
            .trim()
            .lines()
            .map(Game::parse)
            .map(|g| g.is_possible(12, 13, 14));

        assert!(it.next().unwrap());
        assert!(it.next().unwrap());
        assert!(!it.next().unwrap());
        assert!(!it.next().unwrap());
        assert!(it.next().unwrap());
    }
}

adventofcode2023::run!(Solution);
