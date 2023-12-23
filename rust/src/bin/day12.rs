use adventofcode2023::AocSolution;

use std::cmp::Ordering;

use hashbrown::HashMap;
use itertools::Itertools;

pub struct Solution;

#[derive(Clone, Copy, Debug)]
enum State {
    Ok,
    Broken,
    Unk,
}

fn parse(input: &str) -> Cached {
    let (states, groups) = input.split_whitespace().next_tuple().unwrap();

    let states = states
        .chars()
        .map(|c| match c {
            '#' => State::Broken,
            '.' => State::Ok,
            '?' => State::Unk,
            _ => unreachable!(),
        })
        .chain([State::Unk].iter().copied())
        .cycle()
        .take((states.len() + 1) * 5 - 1)
        .collect::<Vec<_>>();

    let groups_len = groups.chars().filter(|&c| c == ',').count() + 1;
    let groups = groups
        .split(',')
        .map(|i| i.parse::<u64>().unwrap())
        .cycle()
        .take(groups_len * 5)
        .collect::<Vec<_>>();

    Cached {
        states,
        groups,
        cache: Default::default(),
    }
}

struct Cached {
    cache: HashMap<(usize, usize), u64>,
    states: Vec<State>,
    groups: Vec<u64>,
}

impl Cached {
    fn algorithm(&mut self, state_idx: usize, group_idx: usize) -> u64 {
        if let Some(&memo) = self.cache.get(&(state_idx, group_idx)) {
            return memo;
        }

        // Reached the end of the pattern
        if state_idx == self.states.len() {
            // If we also reached the end of the groups, this patter satisfies the group
            let exhausted_groups = if group_idx == self.groups.len() { 1 } else { 0 };

            self.cache.insert((state_idx, group_idx), exhausted_groups);
            return exhausted_groups;
        }

        if group_idx > self.groups.len() {
            return 0;
        }

        let count_if_not_start = if matches!(self.states[state_idx], State::Ok | State::Unk) {
            self.algorithm(state_idx + 1, group_idx)
        } else {
            0
        };

        let count_if_start = if group_idx < self.groups.len() {
            let end = state_idx + self.groups[group_idx] as usize;
            match end.cmp(&self.states.len()) {
                Ordering::Less => {
                    if self.states[state_idx..end]
                        .iter()
                        .all(|c| matches!(c, State::Broken | State::Unk))
                        && matches!(self.states[end], State::Ok | State::Unk)
                    {
                        // Found a pattern, keep going from after the end with the next group
                        self.algorithm(end + 1, group_idx + 1)
                    } else {
                        0
                    }
                }
                Ordering::Equal => {
                    if self.states[state_idx..]
                        .iter()
                        .all(|c| matches!(c, State::Broken | State::Unk))
                    {
                        self.algorithm(end, group_idx + 1)
                    } else {
                        0
                    }
                }
                Ordering::Greater => 0,
            }
        } else {
            0
        };

        let count = count_if_not_start + count_if_start;

        if state_idx == 0 && group_idx == 0 {
            println!("{count}");
        }
        self.cache.insert((state_idx, group_idx), count);
        count
    }
}

impl AocSolution for Solution {
    const DAY: u8 = 12;

    fn new() -> Self {
        Self
    }

    fn part1(&self, _input: &str) -> u64 {
        0
    }

    fn part2(&self, input: &str) -> u64 {
        input
            .trim()
            .lines()
            .map(parse)
            .map(|mut c| c.algorithm(0, 0))
            .sum()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
        ???.### 1,1,3
        .??..??...?##. 1,1,3
        ?#?#?#?#?#?#?#? 1,3,1,6
        ????.#...#... 4,1,1
        ????.######..#####. 1,6,5
        ?###???????? 3,2,1
        "
    );

    #[test]
    fn test_part2() {
        println!("{}", Solution.part2(TEST_CASE));
    }
}

adventofcode2023::run!(Solution);
