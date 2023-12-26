// I have been writing this language since 2018 and it's the first time I noticed this:
// https://doc.rust-lang.org/std/collections/binary_heap/index.html
use std::{cmp::Ordering, collections::binary_heap::*};

use adventofcode2023::AocSolution;
use hashbrown::{HashMap, HashSet};
use itertools::Itertools;

struct Solution;

impl AocSolution for Solution {
    const DAY: u8 = 17;

    fn new() -> Self
    where
        Self: Sized,
    {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        let (edges, size) = parse(input);
        let v = shortest_path(&edges, size).unwrap();

        let s = input.trim().as_bytes();

        let p = v.steps.into_iter().collect::<HashSet<_>>();

        for y in 0..size {
            for x in 0..size {
                let c = s[y * (size + 1) + x] as char;
                if p.contains(&(x, y)) {
                    print!("\x1b[31m{}\x1b[0m", c);
                } else {
                    print!("{}", c);
                }
            }
            println!();
        }

        v.cost
    }

    fn part2(&self, input: &str) -> u64 {
        0
    }
}

#[derive(Clone, Eq, PartialEq, Debug)]
struct State {
    cost: u64,
    position: (usize, usize),
    steps: Vec<(usize, usize)>,
    dir: Direction,
}

impl Ord for State {
    fn cmp(&self, other: &Self) -> Ordering {
        other.cost.cmp(&self.cost)
    }
}

impl PartialOrd for State {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Edge {
    node: (usize, usize),
    cost: u64,
}

#[derive(Copy, Clone, PartialEq, Eq, Debug, Hash)]
enum Direction {
    North(usize),
    South(usize),
    West(usize),
    East(usize),
}

impl Direction {
    fn forward(self) -> Self {
        match self {
            Direction::North(i) => Direction::North(i + 1),
            Direction::South(i) => Direction::South(i + 1),
            Direction::West(i) => Direction::West(i + 1),
            Direction::East(i) => Direction::East(i + 1),
        }
    }

    fn cw(self) -> Self {
        match self {
            Direction::North(_) => Direction::East(1),
            Direction::South(_) => Direction::West(1),
            Direction::West(_) => Direction::North(1),
            Direction::East(_) => Direction::South(1),
        }
    }

    fn ccw(self) -> Self {
        match self {
            Direction::North(_) => Direction::West(1),
            Direction::South(_) => Direction::East(1),
            Direction::West(_) => Direction::South(1),
            Direction::East(_) => Direction::North(1),
        }
    }

    fn dirs(&self) -> (isize, isize) {
        match self {
            Direction::North(_) => (0, -1),
            Direction::South(_) => (0, 1),
            Direction::West(_) => (-1, 0),
            Direction::East(_) => (1, 0),
        }
    }

    fn check(&self) -> bool {
        match self {
            Direction::North(i) | Direction::South(i) | Direction::West(i) | Direction::East(i) => {
                *i <= 3
            }
        }
    }

    fn advance(
        &self,
        position: (usize, usize),
        size: usize,
    ) -> impl Iterator<Item = ((usize, usize), Self)> {
        [self.forward(), self.cw(), self.ccw()]
            .into_iter()
            .filter_map(move |dir| {
                let (x, y) = position;
                let (dx, dy) = dir.dirs();
                Some((
                    (
                        x.checked_add_signed(dx).filter(move |x| x < &size)?,
                        y.checked_add_signed(dy).filter(move |y| y < &size)?,
                    ),
                    dir,
                ))
            })
    }
}

fn shortest_path(costs: &HashMap<(usize, usize), u64>, size: usize) -> Option<State> {
    let mut heap = BinaryHeap::new();
    let mut visited = HashSet::new();

    heap.push(State {
        cost: 0,
        position: (0, 0),
        steps: vec![],
        dir: Direction::East(0),
    });

    while let Some(State {
        cost,
        position,
        steps,
        dir,
    }) = heap.pop()
    {
        if position == (size - 1, size - 1) {
            return Some(State {
                cost,
                position,
                steps: steps.clone(),
                dir,
            });
        }

        if !visited.insert((position, dir)) {
            continue;
        }

        for (edge, dir) in dir.advance(position, size) {
            if !dir.check() {
                continue;
            }

            let mut next_steps = steps.clone();
            next_steps.push(edge);

            let next_cost = costs.get(&edge).unwrap();

            let next = State {
                cost: cost + next_cost,
                position: edge,
                steps: next_steps,
                dir,
            };

            heap.push(next);
        }
    }

    None
}

fn neighborhood((x, y): (usize, usize), size: usize) -> impl Iterator<Item = (usize, usize)> {
    [(-1isize, 0isize), (1, 0), (0, -1), (0, 1)]
        .into_iter()
        .filter_map(move |(dx, dy)| {
            Some((
                x.checked_add_signed(dx).filter(move |x| x < &size)?,
                y.checked_add_signed(dy).filter(move |y| y < &size)?,
            ))
        })
}

fn parse(input: &str) -> (HashMap<(usize, usize), u64>, usize) {
    let size = input.trim().lines().count(); // assume equal
    let input = input.trim().as_bytes();

    let mut edges = HashMap::<(usize, usize), u64>::new();

    for y in 0..size {
        for x in 0..size {
            edges.insert((x, y), (input[y * (size + 1) + x] - b'0') as u64);
        }
    }

    (edges, size)
}

#[cfg(test)]
mod tests {
    use hashbrown::HashSet;

    use super::*;

    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
        2413432311323
        3215453535623
        3255245654254
        3446585845452
        4546657867536
        1438598798454
        4457876987766
        3637877979653
        4654967986887
        4564679986453
        1224686865563
        2546548887735
        4322674655533
        "
    );

    #[test]
    fn test() {
        let (edges, size) = parse(TEST_CASE);
        let v = shortest_path(&edges, size).unwrap();
        let s = TEST_CASE.trim().as_bytes();

        println!("Cost {}", v.cost);
        for point in &v.steps {
            println!("{point:?} {}", edges.get(point).unwrap());
        }

        let p = v.steps.into_iter().collect::<HashSet<_>>();

        for y in 0..size {
            for x in 0..size {
                let c = s[y * (size + 1) + x] as char;
                if p.contains(&(x, y)) {
                    print!("\x1b[31m{}\x1b[0m", c);
                } else {
                    print!("{}", c);
                }
            }
            println!();
        }
    }
}

adventofcode2023::run!(Solution);
