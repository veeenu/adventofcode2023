use std::collections::VecDeque;

use hashbrown::{HashMap, HashSet};
use itertools::Itertools;

use super::AocSolution;

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Point(usize, usize, usize);

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct BrickId(usize);

#[derive(Clone, Copy, Debug)]
struct Brick {
    start: Point,
    end: Point,
    id: BrickId,
}

impl Brick {
    fn range(&self) -> impl Iterator<Item = Point> + '_ {
        (self.start.0..=self.end.0).flat_map(move |x| {
            (self.start.1..=self.end.1)
                .flat_map(move |y| (self.start.2..=self.end.2).map(move |z| Point(x, y, z)))
        })
    }

    fn lower(&self) -> Self {
        Brick {
            start: Point(self.start.0, self.start.1, self.start.2 - 1),
            end: Point(self.end.0, self.end.1, self.end.2 - 1),
            id: self.id,
        }
    }
}

fn parse(input: &str) -> Vec<Brick> {
    let mut v: Vec<_> = input
        .trim()
        .lines()
        .map(|line| {
            let (start, end) = line.split('~').next_tuple().unwrap();

            let (x, y, z) = start
                .split(',')
                .map(|s| s.parse::<usize>().unwrap())
                .next_tuple()
                .unwrap();
            let start = Point(x, y, z);

            let (x, y, z) = end
                .split(',')
                .map(|s| s.parse::<usize>().unwrap())
                .next_tuple()
                .unwrap();
            let end = Point(x, y, z);

            Brick {
                start,
                end,
                id: BrickId(0),
            }
        })
        .collect();

    // From the input, looks like x and y inside a brick are ordered,
    // but z between bricks is not ordered.
    v.sort_by(|a, b| a.start.2.cmp(&(b.start.2)));

    for (id, brick) in v.iter_mut().enumerate() {
        brick.id = BrickId(id);
    }

    v
}

#[derive(Clone, Debug)]
struct Field {
    field: HashMap<Point, BrickId>,
    bricks: Vec<Brick>,
}

impl From<Vec<Brick>> for Field {
    fn from(bricks: Vec<Brick>) -> Self {
        let mut field = HashMap::new();

        for brick in &bricks {
            for point in brick.range() {
                field.insert(point, brick.id);
            }
        }

        Field { field, bricks }
    }
}

impl Field {
    fn add_brick(&mut self, brick: &Brick) {
        for p in brick.range() {
            self.field.insert(p, brick.id);
        }
    }

    fn remove_brick(&mut self, brick: &Brick) {
        for p in brick.range() {
            self.field.remove(&p);
        }
    }

    fn replace_brick(&mut self, old: Brick, new: Brick) {
        *self.bricks.iter_mut().find(|b| b.id == old.id).unwrap() = new;
    }

    fn support_map(&self) -> HashMap<BrickId, HashSet<BrickId>> {
        let mut support_map: HashMap<BrickId, HashSet<BrickId>> = HashMap::new();

        // Generate support map
        for (a, b) in self.find_supports() {
            support_map.entry(b).or_default().insert(a);
        }

        // Add empty sets for bricks not supporting anything
        for b in &self.bricks {
            support_map.entry(b.id).or_default();
        }

        support_map
    }

    // Returns (a, b) if a is supported by b
    fn find_supports(&self) -> impl Iterator<Item = (BrickId, BrickId)> + '_ {
        self.bricks
            .iter()
            .copied()
            .flat_map(move |brick| {
                brick
                    .lower()
                    .range()
                    .filter_map(move |p| self.field.get(&p).map(|&id| (brick.id, id)))
                    .collect::<Vec<_>>()
            })
            .filter(|(a, b)| a != b)
    }

    fn find_chain(&self, id: BrickId) -> HashSet<BrickId> {
        let mut q = VecDeque::new();
        q.push_back(id);

        let mut support_map = self.support_map();

        let mut falling = HashSet::new();

        while !q.is_empty() {
            let head = q.pop_front().unwrap();
            let s = support_map.remove(&head).unwrap();
            for supported_by_head in &s {
                // If no other brick (k) supports this brick (supported_by head)...
                if support_map
                    .iter()
                    .all(|(&k, v)| k == head || !v.contains(supported_by_head))
                {
                    q.push_back(*supported_by_head);
                    falling.insert(*supported_by_head);
                }
            }
        }

        falling
    }

    fn lower_bricks(&mut self) {
        loop {
            let bricks_to_lower = self
                .bricks
                .iter()
                .filter_map(|brick| {
                    let lowered_brick = brick.lower();
                    if lowered_brick
                        .range()
                        .all(|p| !self.field.get(&p).is_some_and(|&id| id != brick.id))
                        && lowered_brick.start.2 > 0
                        && lowered_brick.end.2 > 0
                    {
                        Some((*brick, lowered_brick))
                    } else {
                        None
                    }
                })
                .collect::<Vec<_>>();

            let mut any_lowered = false;
            for (brick, lowered_brick) in bricks_to_lower {
                self.remove_brick(&brick);
                self.add_brick(&lowered_brick);
                self.replace_brick(brick, lowered_brick);
                any_lowered = true;
            }
            if !any_lowered {
                break;
            }
        }
    }

    fn get_redundants(self: &Field) -> Vec<BrickId> {
        let support_map = self.support_map();
        support_map
            .iter()
            .filter(|(&a, supported)| {
                supported
                    .iter()
                    .all(|b| support_map.iter().any(|(&k, v)| k != a && v.contains(b)))
            })
            .map(|(id, _)| *id)
            .collect()
    }
}

pub struct Solution;

impl AocSolution for Solution {
    fn new() -> Self {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        let bricks = parse(input);
        let mut field = Field::from(bricks);
        field.lower_bricks();
        field.get_redundants().len() as u64
    }

    fn part2(&self, input: &str) -> u64 {
        let bricks = parse(input);
        let mut field = Field::from(bricks);
        field.lower_bricks();

        field
            .bricks
            .iter()
            .map(|b| field.find_chain(b.id).len() as u64)
            .sum::<u64>()
    }
}

#[cfg(test)]
mod tests {
    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
        1,0,1~1,2,1
        0,0,2~2,0,2
        0,2,3~2,2,3
        0,0,4~0,2,4
        2,0,5~2,2,5
        0,1,6~2,1,6
        1,1,8~1,1,9
        "
    );

    use super::*;

    #[test]
    fn test_part1() {
        println!("{}", Solution.part1(TEST_CASE));
    }

    #[test]
    fn test_part2() {
        let bricks = parse(TEST_CASE);
        let mut field = Field::from(bricks);
        field.lower_bricks();

        println!("{:?}", field.find_chain(BrickId(0)));
        println!("{:?}", field.find_chain(BrickId(5)));
    }
}
