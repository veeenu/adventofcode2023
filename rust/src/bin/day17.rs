// I have been writing this language since 2018 and it's the first time I noticed this:
// https://doc.rust-lang.org/std/collections/binary_heap/index.html
use std::{cmp::Ordering, collections::binary_heap::*};

use adventofcode2023::AocSolution;
use hashbrown::HashMap;
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
        0
    }

    fn part2(&self, input: &str) -> u64 {
        0
    }
}

#[derive(Clone, Eq, PartialEq)]
struct State {
    cost: u64,
    position: (usize, usize),
    steps: Vec<(usize, usize)>,
}

impl Ord for State {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .cmp(&self.cost)
            .then_with(|| self.steps.cmp(&other.steps))
            .then_with(|| self.position.cmp(&other.position))
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

// #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
// enum Step {
//     North(usize),
//     South(usize),
//     East(usize),
//     West(usize),
// }
//
// impl Step {
//     fn next(&self, (ax, ay): (usize, usize), (bx, by): (usize, usize)) -> Option<Self> {
//         let dx = bx as isize - ax as isize;
//         let dy = by as isize - ay as isize;
//
//         match (dx, dy, self) {
//             (-1, 0, Step::West(i)) => Some(Step::West(i + 1)),
//             (-1, 0, Step::East(_)) => None,
//             (-1, 0, _) => Some(Step::West(1)),
//             (1, 0, Step::East(i)) => Some(Step::East(i + 1)),
//             (1, 0, Step::West(_)) => None,
//             (1, 0, _) => Some(Step::East(1)),
//             (0, -1, Step::North(i)) => Some(Step::North(i + 1)),
//             (0, -1, Step::South(_)) => None,
//             (0, -1, _) => Some(Step::North(1)),
//             (0, 1, Step::South(i)) => Some(Step::South(i + 1)),
//             (0, 1, Step::North(_)) => None,
//             (0, 1, _) => Some(Step::South(1)),
//             _ => None,
//         }
//     }
//
//     fn valid(&self) -> bool {
//         let i = match *self {
//             Step::North(i) => i,
//             Step::South(i) => i,
//             Step::East(i) => i,
//             Step::West(i) => i,
//         };
//
//         i < 3
//     }
// }

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
enum Step {
    North,
    South,
    West,
    East,
}

impl Step {
    fn from_points((x1, y1): (usize, usize), (x2, y2): (usize, usize)) -> Self {
        let dx = x2 as isize - x1 as isize;
        let dy = y2 as isize - y1 as isize;

        match (dx, dy) {
            (-1, 0) => Step::West,
            (1, 0) => Step::East,
            (0, -1) => Step::North,
            (0, 1) => Step::South,
            _ => unreachable!(),
        }
    }

    fn goes_back(&self, rhs: Self) -> bool {
        matches!(
            (self, rhs),
            (Step::North, Step::South)
                | (Step::South, Step::North)
                | (Step::West, Step::East)
                | (Step::East, Step::West)
        )
    }

    fn check(steps: &[(usize, usize)]) -> bool {
        if steps.len() < 5 {
            return true;
        }

        let last_five = &steps[(steps.len() - 5)..];

        let Some((a, b, c, d)) = last_five
            .iter()
            .tuple_windows()
            .map(|(a, b)| Self::from_points(*a, *b))
            .next_tuple()
        else {
            return true;
        };

        !(a == b && b == c && c == d && !c.goes_back(d))
    }
}

fn shortest_path(costs: HashMap<(usize, usize), u64>, size: usize) -> Option<State> {
    let mut dist = (0..size)
        .cartesian_product(0..size)
        .map(|(x, y)| ((x, y), std::u64::MAX))
        .collect::<HashMap<_, _>>();
    let mut heap = BinaryHeap::new();

    *dist.get_mut(&(0, 0)).unwrap() = 0;
    heap.push(State {
        cost: 0,
        position: (0, 0),
        steps: vec![],
    });

    while let Some(State {
        cost,
        position,
        steps,
    }) = heap.pop()
    {
        if position == (size - 1, size - 1) {
            return Some(State {
                cost,
                position,
                steps,
            });
        }

        if cost > *dist.get(&position).unwrap() {
            continue;
        }

        for edge in neighborhood(position, size) {
            let mut next_steps = steps.clone();
            next_steps.push(edge);

            if !Step::check(&next_steps) {
                continue;
            }

            let next_cost = costs.get(&edge).unwrap();

            let next = State {
                cost: cost + next_cost,
                position: edge,
                steps: next_steps,
            };

            if next.cost < *dist.get(&next.position).unwrap() {
                *dist.get_mut(&next.position).unwrap() = next.cost;
                heap.push(next);
            }
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
            // edges
            //     .entry((x, y))
            //     .or_default()
            // .extend(neighborhood(x, y, size).map(|(x, y)| Edge {
            //     node: (x, y),
            //     cost: (input[y * (size + 1) + x] - b'0') as u64,
            // }));
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
        for (k, vs) in &edges {
            println!("{k:?}: ");
            for Edge { node, cost } in vs {
                print!("  {node:?} {cost}, ");
            }
            println!();
        }
        let v = shortest_path(edges, size).unwrap();
        let p = v.steps.into_iter().collect::<HashSet<_>>();
        println!("{}", v.cost);

        let s = TEST_CASE.trim().as_bytes();

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
