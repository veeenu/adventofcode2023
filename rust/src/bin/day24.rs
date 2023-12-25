use std::ops::RangeInclusive;

use adventofcode2023::AocSolution;

use itertools::Itertools;

struct Solution;

impl AocSolution for Solution {
    const DAY: u8 = 24;

    fn new() -> Self
    where
        Self: Sized,
    {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        check_intersections2d(input, 200000000000000f64..=400000000000000f64) as u64
    }

    fn part2(&self, input: &str) -> u64 {
        0
    }
}

fn check_intersections2d(input: &str, range: RangeInclusive<f64>) -> usize {
    let hailstones = input
        .trim()
        .lines()
        .map(Hailstone::parse)
        .collect::<Vec<_>>();

    hailstones
        .iter()
        .enumerate()
        .flat_map(|(idx, a)| hailstones[idx + 1..].iter().map(|b| (a.clone(), b.clone())))
        .filter(|(a, b)| a.intersection2d(b, &range).is_some())
        .count()
}

#[derive(Debug, Clone, PartialEq)]
struct Hailstone {
    x: f64,
    y: f64,
    z: f64,
    vx: f64,
    vy: f64,
    vz: f64,
}

impl Hailstone {
    fn parse(line: &str) -> Self {
        let (pos, vel) = line.split(" @ ").next_tuple().unwrap();
        let (x, y, z) = pos
            .split(", ")
            .map(str::trim)
            .map(str::parse)
            .map(Result::unwrap)
            .next_tuple()
            .unwrap();
        let (vx, vy, vz) = vel
            .split(", ")
            .map(str::trim)
            .map(str::parse)
            .map(Result::unwrap)
            .next_tuple()
            .unwrap();

        Self {
            x,
            y,
            z,
            vx,
            vy,
            vz,
        }
    }

    fn plug(&self, t: f64) -> (f64, f64, f64) {
        (
            self.x + t * self.vx,
            self.y + t * self.vy,
            self.z + t * self.vz,
        )
    }

    fn intersection2d(&self, rhs: &Self, range: &RangeInclusive<f64>) -> Option<(f64, f64, f64)> {
        // A.x + t A.vx = B.x + s B.vx, repeat for y and z, solve
        // t = (B.x - A.x + s B.vx) / A.vx
        // t = (B.y - A.y + s B.vy) / A.vy
        // Derive s
        // A.vy (B.x - A.x + s B.vx) = A.vx (B.y - A.y + s B.vy)
        // s = (A.vy (B.x - A.x) - A.vx (B.y - A.y)) / (A.vx * B.vy - A.vy * B.vx)

        let s = (self.vy * (rhs.x - self.x) - self.vx * (rhs.y - self.y))
            / (self.vx * rhs.vy - self.vy * rhs.vx);
        let t = (rhs.x - self.x + s * rhs.vx) / self.vx;

        let pt = self.plug(t);
        let ps = rhs.plug(s);

        if range.contains(&pt.0)
            && range.contains(&pt.1)
            && range.contains(&ps.0)
            && range.contains(&ps.1)
            && t > 0.
            && s > 0.
        {
            Some(pt)
        } else {
            None
        }
    }
}

adventofcode2023::run!(Solution);

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
        19, 13, 30 @ -2,  1, -2
        18, 19, 22 @ -1, -1, -2
        20, 25, 34 @ -2, -2, -4
        12, 31, 28 @ -1, -2, -1
        20, 19, 15 @  1, -5, -3
        "
    );

    #[test]
    fn test_part1() {
        println!("{:?}", check_intersections2d(TEST_CASE, 7f64..=27f64));
    }
}
