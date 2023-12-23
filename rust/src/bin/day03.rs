use adventofcode2023::AocSolution;

use std::{iter::Enumerate, ops::RangeInclusive, str::Chars};

use itertools::Itertools;

pub struct Solution;

impl AocSolution for Solution {
    const DAY: u8 = 3;

    fn new() -> Self {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        let lines = input.lines().collect::<Vec<_>>();
        let row_count = lines.len() as i32;
        let column_count = lines[0].len() as i32;

        let symbol_coords = lines.iter().enumerate().flat_map(|(row, line)| {
            line.chars()
                .enumerate()
                .filter_map(move |(col, sym)| match sym {
                    '0'..='9' | '.' => None,
                    _ => Some((row as i32, col as i32)),
                })
        });

        let neighborhoods = symbol_coords
            .flat_map(|(row, col)| {
                (-1..=1)
                    .cartesian_product(-1..=1)
                    .filter(|&(r, c)| r != 0 || c != 0)
                    .map(move |(r, c)| (row + r, col + c))
                    .filter(|&(row, col)| {
                        (0..row_count).contains(&row) && (0..column_count).contains(&col)
                    })
            })
            .collect::<Vec<_>>();

        let numbers = lines.iter().enumerate().flat_map(|(row, line)| {
            NumLocator(line.chars().enumerate(), line)
                .map(move |(range, num)| (row as i32, range, num))
        });

        numbers
            .filter_map(|(row, cols, num)| {
                if neighborhoods
                    .iter()
                    .any(|&(nrow, ncol)| nrow == row && cols.contains(&ncol))
                {
                    Some(num)
                } else {
                    None
                }
            })
            .sum::<i32>() as u64
    }

    fn part2(&self, input: &str) -> u64 {
        let lines = input.lines().collect::<Vec<_>>();
        let row_count = lines.len() as i32;
        let column_count = lines[0].len() as i32;

        let gear_coords = lines.iter().enumerate().flat_map(|(row, line)| {
            line.chars()
                .enumerate()
                .filter_map(move |(col, sym)| match sym {
                    '*' => Some((row as i32, col as i32)),
                    _ => None,
                })
        });

        let gear_neighborhoods = gear_coords.map(|(row, col)| {
            (-1..=1)
                .cartesian_product(-1..=1)
                .filter(|&(r, c)| r != 0 || c != 0)
                .map(move |(r, c)| (row + r, col + c))
                .filter(|&(row, col)| {
                    (0..row_count).contains(&row) && (0..column_count).contains(&col)
                })
                .collect::<Vec<_>>()
        });

        let numbers = lines
            .iter()
            .enumerate()
            .flat_map(|(row, line)| {
                NumLocator(line.chars().enumerate(), line)
                    .map(move |(range, num)| (row as i32, range, num))
            })
            .collect::<Vec<_>>();

        gear_neighborhoods
            .map(|neighborhood| {
                numbers
                    .iter()
                    .filter_map(|(row, range, num)| {
                        if neighborhood
                            .iter()
                            .any(|(nrow, ncol)| nrow == row && range.contains(ncol))
                        {
                            Some(num)
                        } else {
                            None
                        }
                    })
                    .collect::<Vec<_>>()
            })
            .filter_map(|nums| {
                if nums.len() == 2 {
                    Some(nums[0] * nums[1])
                } else {
                    None
                }
            })
            .sum::<i32>() as u64
    }
}

struct NumLocator<'a>(Enumerate<Chars<'a>>, &'a str);

impl Iterator for NumLocator<'_> {
    type Item = (RangeInclusive<i32>, i32);

    fn next(&mut self) -> Option<Self::Item> {
        let mut next_number_seq = self
            .0
            .by_ref()
            .skip_while(|(_, c)| !c.is_ascii_digit())
            .take_while(|(_, c)| c.is_ascii_digit())
            .map(|(idx, _)| idx);

        let start = next_number_seq.next()?;
        let end = next_number_seq.last().unwrap_or(start);
        let slice = &self.1[start..=end];

        Some(((start as i32..=end as i32), slice.parse::<i32>().unwrap()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use indoc::indoc;

    const TEST_INPUT: &str = indoc! {
        r#"
        467..114..
        ...*......
        ..35..633.
        ......#...
        617*......
        .....+.58.
        ..592.....
        ......755.
        ...$.*....
        .664.598..
        "#
    };

    #[test]
    fn test() {
        let sol = Solution::new();
        assert_eq!(sol.part1(TEST_INPUT), 4361);
        assert_eq!(sol.part2(TEST_INPUT), 467835);
    }
}

adventofcode2023::run!(Solution);
