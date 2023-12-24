use std::collections::VecDeque;

use adventofcode2023::AocSolution;
use hashbrown::{HashMap, HashSet};
use itertools::Itertools;

struct Solution;

impl AocSolution for Solution {
    const DAY: u8 = 23;

    fn new() -> Self
    where
        Self: Sized,
    {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        Grid::parse(input).traverse()
    }

    fn part2(&self, input: &str) -> u64 {
        Grid::parse(input).traverse2()
    }
}

struct Grid<'a> {
    data: &'a [u8],
    rows: usize,
    cols: usize,
}

impl<'a> Grid<'a> {
    fn parse(input: &'a str) -> Self {
        let input = input.trim();
        let cols = input.lines().next().unwrap().len();
        let rows = input.lines().count();

        Self {
            data: input.as_bytes(),
            cols,
            rows,
        }
    }

    fn get(&self, (x, y): (usize, usize)) -> u8 {
        self.data[y * (self.cols + 1) + x]
    }

    fn start(&self) -> (usize, usize) {
        let x = self.data[0..self.cols]
            .iter()
            .position(|&b| b == b'.')
            .unwrap();
        (x, 0)
    }

    fn end(&self) -> (usize, usize) {
        let y = self.rows - 1;
        let yp = y * (self.cols + 1);
        let x = self.data[yp..yp + self.cols]
            .iter()
            .position(|&b| b == b'.')
            .unwrap();
        (x, y)
    }

    fn edges(&self, (x, y): (usize, usize)) -> impl Iterator<Item = (usize, usize)> + '_ {
        [
            Direction::North,
            Direction::South,
            Direction::West,
            Direction::East,
        ]
        .into_iter()
        .filter_map(move |d| {
            let (x, y) = d.transform((x, y), self.cols, self.rows)?;
            match (self.get((x, y)), d) {
                (b'.', _)
                | (b'<', Direction::West)
                | (b'>', Direction::East)
                | (b'v', Direction::South)
                | (b'^', Direction::North) => Some((x, y)),
                _ => None,
            }
        })
    }

    fn edges2(&self, (x, y): (usize, usize)) -> impl Iterator<Item = (usize, usize)> + '_ {
        [
            Direction::North,
            Direction::South,
            Direction::West,
            Direction::East,
        ]
        .into_iter()
        .filter_map(move |d| {
            let (x, y) = d.transform((x, y), self.cols, self.rows)?;
            match self.get((x, y)) {
                b'.' | b'<' | b'>' | b'v' | b'^' => Some((x, y)),
                _ => None,
            }
        })
    }

    fn points(&self) -> impl Iterator<Item = (usize, usize)> + '_ {
        (0..self.rows)
            .flat_map(move |y| (0..self.cols).map(move |x| (x, y)))
            .filter(|&p| matches!(self.get(p), b'.' | b'<' | b'>' | b'v' | b'^'))
    }

    fn traverse(&self) -> u64 {
        let mut q = VecDeque::new();
        q.push_back((self.start(), Vec::<(usize, usize)>::new()));
        let mut paths = Vec::new();
        let end = self.end();

        while let Some((head, path)) = q.pop_front() {
            if head == end {
                paths.push(path);
                continue;
            }

            for edge in self.edges(head) {
                if !path.contains(&edge) {
                    let mut path = path.clone();
                    path.push(edge);
                    q.push_back((edge, path));
                }
            }
        }

        paths.into_iter().map(|p| p.len()).max().unwrap() as u64
    }

    fn distance(
        &self,
        a: (usize, usize),
        b: (usize, usize),
        branch_points: &HashSet<(usize, usize)>,
    ) -> Option<usize> {
        let mut q = VecDeque::new();
        q.push_back((a, 0usize));

        let mut visited = HashSet::new();

        while let Some((head, len)) = q.pop_front() {
            for edge in self.edges2(head) {
                if edge == b {
                    return Some(len + 1);
                }
                if !branch_points.contains(&edge) && !visited.contains(&edge) {
                    q.push_back((edge, len + 1));
                    visited.insert(edge);
                }
            }
        }

        None
    }

    fn branch_points(&self) -> HashSet<(usize, usize)> {
        let adj_lists = self
            .points()
            .map(|p| (p, self.edges2(p).collect::<Vec<_>>()))
            .collect::<HashMap<_, _>>();

        adj_lists
            .iter()
            .filter_map(|(k, v)| if v.len() != 2 { Some(*k) } else { None })
            .chain([self.start(), self.end()])
            .collect::<HashSet<_>>()
    }

    fn traverse2(&self) -> u64 {
        let branch_points = self.branch_points();

        let distances = branch_points
            .iter()
            .cartesian_product(branch_points.iter())
            .filter(|(a, b)| a != b)
            .filter_map(|(a, b)| self.distance(*a, *b, &branch_points).map(|d| ((*a, *b), d)))
            .collect::<HashMap<_, _>>();

        let edges = distances.keys().fold(
            HashMap::<(usize, usize), HashSet<(usize, usize)>>::new(),
            |mut o, (src, dst)| {
                o.entry(*src).or_default().insert(*dst);
                o
            },
        );

        let mut q = VecDeque::new();
        q.push_back((self.start(), vec![self.start()]));
        let mut paths = Vec::new();
        let end = self.end();

        while let Some((head, path)) = q.pop_front() {
            if head == end {
                paths.push(path);
                continue;
            }

            for &edge in edges.get(&head).unwrap() {
                if !path.contains(&edge) {
                    let mut path = path.clone();
                    path.push(edge);
                    q.push_back((edge, path));
                }
            }
        }

        paths
            .into_iter()
            .map(|path| {
                path.iter()
                    .tuple_windows()
                    .map(|(&src, &dst)| distances.get(&(src, dst)).unwrap())
                    .sum::<usize>()
            })
            .max()
            .unwrap() as _
    }
}

#[derive(Clone, Copy, Debug)]
enum Direction {
    North,
    South,
    East,
    West,
}

impl Direction {
    fn transform(self, (x, y): (usize, usize), w: usize, h: usize) -> Option<(usize, usize)> {
        match self {
            Direction::North if y > 0 => Some((x, y - 1)),
            Direction::South if y < h - 1 => Some((x, y + 1)),
            Direction::East if x < w - 1 => Some((x + 1, y)),
            Direction::West if x > 0 => Some((x - 1, y)),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
        #.#####################
        #.......#########...###
        #######.#########.#.###
        ###.....#.>.>.###.#.###
        ###v#####.#v#.###.#.###
        ###.>...#.#.#.....#...#
        ###v###.#.#.#########.#
        ###...#.#.#.......#...#
        #####.#.#.#######.#.###
        #.....#.#.#.......#...#
        #.#####.#.#.#########v#
        #.#...#...#...###...>.#
        #.#.#v#######v###.###v#
        #...#.>.#...>.>.#.###.#
        #####v#.#.###v#.#.###.#
        #.....#...#...#.#.#...#
        #.#########.###.#.#.###
        #...###...#...#...#.###
        ###.###.#.###v#####v###
        #...#...#.#.>.>.#.>.###
        #.###.###.#.###.#.#v###
        #.....###...###...#...#
        #####################.#
        "
    );

    #[test]
    #[ignore]
    fn test_part1() {
        let g = Grid::parse(TEST_CASE);
        println!("{:?} {:?}", g.start(), g.end());
        println!("{}", g.traverse());
    }

    #[test]
    fn test_part2() {
        let g = Grid::parse(TEST_CASE);
        println!("{:?} {:?}", g.start(), g.end());
        println!("{}", g.traverse2());
    }
}

adventofcode2023::run!(Solution);
