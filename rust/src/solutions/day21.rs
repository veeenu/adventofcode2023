use std::{
    collections::BTreeSet,
    ops::{Div, Rem},
};

use hashbrown::HashMap;

use super::AocSolution;

pub struct Solution;

#[derive(Clone, Copy, Debug)]
enum Direction {
    North,
    South,
    West,
    East,
}

impl From<Direction> for (isize, isize) {
    fn from(value: Direction) -> Self {
        match value {
            Direction::North => (0, -1),
            Direction::South => (0, 1),
            Direction::West => (-1, 0),
            Direction::East => (1, 0),
        }
    }
}

#[derive(Clone, Copy, Debug)]
enum Wrap {
    Inside(Point),
    North(Point),
    South(Point),
    West(Point),
    East(Point),
}

impl Wrap {
    fn inside(self) -> Option<Point> {
        match self {
            Wrap::Inside(p) => Some(p),
            _ => None,
        }
    }
}

#[derive(Default, Clone, Copy, Hash, PartialEq, Eq, PartialOrd, Ord, Debug)]
struct Point(isize, isize);

impl Point {
    fn add(self, direction: Direction, width: isize, height: isize) -> Wrap {
        let (x, y) = direction.into();
        let x = self.0 + x;
        let y = self.1 + y;

        if (0..width).contains(&x) && (0..height).contains(&y) {
            Wrap::Inside(Point(x, y))
        } else {
            let p = Point(x % width, y % height);
            match direction {
                Direction::North => Wrap::North(p),
                Direction::South => Wrap::South(p),
                Direction::West => Wrap::West(p),
                Direction::East => Wrap::East(p),
            }
        }
    }
}

#[derive(Default, Debug)]
struct Field {
    points: BTreeSet<Point>,
    width: isize,
    height: isize,
}

impl Field {
    fn parse(input: &str) -> (Field, Point) {
        input
            .lines()
            .enumerate()
            .flat_map(move |(y, line)| {
                line.chars()
                    .enumerate()
                    .map(move |(x, c)| (x as isize, y as isize, c))
            })
            .fold(
                (Field::default(), Point::default()),
                |(mut field, point), (x, y, c)| {
                    if c == '.' || c == 'S' {
                        field.points.insert(Point(x, y));
                    }
                    field.width = (x + 1).max(field.width);
                    field.height = (y + 1).max(field.height);

                    (field, if c == 'S' { Point(x, y) } else { point })
                },
            )
    }
}

#[derive(Default, Clone, Debug, PartialEq, Eq, Hash)]
struct Config(BTreeSet<Point>);

impl Config {
    fn neighborhood(&self, field: &Field) -> Self {
        let (w, h) = (field.width, field.height);
        Self(
            self.0
                .iter()
                .copied()
                .flat_map(|p| {
                    [
                        p.add(Direction::North, w, h).inside(),
                        p.add(Direction::South, w, h).inside(),
                        p.add(Direction::West, w, h).inside(),
                        p.add(Direction::East, w, h).inside(),
                    ]
                    .into_iter()
                })
                .flatten()
                .filter(|p| field.points.contains(p))
                .collect(),
        )
    }

    fn count(&self) -> usize {
        self.0.len()
    }
}

struct ConfigMap {
    field: Field,
    current: Config,
    map: HashMap<Config, Config>,
}

impl ConfigMap {
    fn new(field: Field, start: Point) -> Self {
        let mut current = Config::default();
        current.0.insert(start);
        Self {
            field,
            current,
            map: Default::default(),
        }
    }

    fn reinit(&mut self, start: Point) {
        self.current = Config::default();
        self.current.0.insert(start);
    }

    fn step(&mut self) -> bool {
        if let Some(next) = self.map.get(&self.current) {
            self.current = next.clone();
            true
        } else {
            let next = self.current.neighborhood(&self.field);
            self.map.insert(self.current.clone(), next.clone());
            self.current = next;
            false
        }
    }

    fn count(&self) -> usize {
        self.current.0.len()
    }
}

impl AocSolution for Solution {
    fn new() -> Self {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        let (field, start) = Field::parse(input);
        let mut config_map = ConfigMap::new(field, start);

        for _ in 0..64 {
            config_map.step();
        }

        config_map.count() as u64
    }

    fn part2(&self, input: &str) -> u64 {
        const STEPS: usize = 26501365;

        let (field, start) = Field::parse(input);
        let mut config_map = ConfigMap::new(field, start);

        // For the input, the states repeat first at i = field.width and then repeat at every
        // single step. No point in calculating statuses farther.
        let wraps = config_map.field.width as usize;

        let div = STEPS.div(wraps);
        let rem = STEPS.rem(wraps);
        println!("Div {div} Rem {rem} wraps {wraps}");

        // Reinitialize to count the steps in a full cycle.
        config_map.reinit(start);
        (0..wraps).for_each(|_| {
            config_map.step();
        });
        let cycle_steps = config_map.count();

        // Proof that there is a cycle:
        for _ in 0..10 {
            (0..wraps).for_each(|_| {
                config_map.step();
            });
            assert_eq!(cycle_steps, config_map.count());
        }

        // Reinitialize to count the steps in a full cycle.
        config_map.reinit(start);
        (0..rem).for_each(|_| {
            config_map.step();
        });
        let rem_steps = config_map.count();

        // Complete guesswork under the assumption that wrapping doesn't matter.
        // It doesn't work.
        (cycle_steps * div + rem_steps * div) as u64
    }
}

#[cfg(test)]
mod tests {
    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
    ...........
    .....###.#.
    .###.##..#.
    ..#.#...#..
    ....#.#....
    .##..S####.
    .##..#...#.
    .......##..
    .##.#.####.
    .##..##.##.
    ...........
    "
    );

    use super::*;

    #[test]
    fn test_parse() {
        let (field, start) = Field::parse(TEST_CASE);
        let mut config_map = ConfigMap::new(field, start);

        for _ in 0..6 {
            config_map.step();
            println!("{}", config_map.current.0.len());
        }

        assert_eq!(config_map.count(), 16);
    }
}
