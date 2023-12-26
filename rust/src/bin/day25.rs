use std::collections::VecDeque;

use adventofcode2023::AocSolution;

use hashbrown::{HashMap, HashSet};
use itertools::Itertools;

struct Solution;

impl AocSolution for Solution {
    const DAY: u8 = 25;

    fn new() -> Self
    where
        Self: Sized,
    {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        AdjLists::parse(input).find_cut() as u64
    }

    fn part2(&self, _input: &str) -> u64 {
        0
    }
}

#[derive(Debug, Clone)]
struct AdjLists(HashMap<String, HashSet<String>>);

impl AdjLists {
    fn parse(input: &str) -> Self {
        Self(
            input
                .trim()
                .lines()
                .flat_map(|line| {
                    let (k, vs) = line.split(": ").next_tuple().unwrap();
                    vs.split_whitespace()
                        .map(String::from)
                        .map(|v| (k.to_string(), v))
                        .flat_map(|(k, v)| [(k.clone(), v.clone()), (v, k)])
                })
                .fold(HashMap::new(), |mut h, (k, v)| {
                    h.entry(k.clone()).or_default().insert(v.clone());
                    h.entry(v).or_default().insert(k);
                    h
                }),
        )
    }

    fn most_traversed_edges(&self) -> Vec<((&str, &str), usize)> {
        let mut traversed_count = HashMap::new();
        for a in self.0.keys() {
            let mut q = VecDeque::new();
            let mut visited = HashSet::new();
            q.push_back(a.as_str());
            visited.insert(a.as_str());

            while let Some(head) = q.pop_front() {
                for b in self.0.get(head).unwrap() {
                    if visited.insert(b.as_str()) {
                        let k = if head.cmp(b).is_lt() {
                            (head, b.as_str())
                        } else {
                            (b.as_str(), head)
                        };

                        *traversed_count.entry(k).or_default() += 1;
                        q.push_back(b.as_str());
                    }
                }
            }
        }

        let mut most_traversed = traversed_count.into_iter().collect::<Vec<_>>();
        most_traversed.sort_unstable_by_key(|(_, count)| *count);
        most_traversed.reverse();
        most_traversed
    }

    fn compute_cut(&self, cut: HashSet<(&str, &str)>) -> Option<usize> {
        let mut q = VecDeque::new();
        let mut visited = HashSet::new();
        let mut size = 1usize;

        let start = self.0.keys().next().unwrap().as_str();

        q.push_back(start);
        visited.insert(start);

        while let Some(head) = q.pop_front() {
            for b in self.0.get(head).unwrap() {
                let k = if head.cmp(b).is_lt() {
                    (head, b.as_str())
                } else {
                    (b.as_str(), head)
                };

                if cut.contains(&k) {
                    continue;
                }

                if visited.insert(b) {
                    size += 1;
                    q.push_back(b.as_str());
                }
            }
        }

        if size < self.0.len() {
            Some(size)
        } else {
            None
        }
    }

    fn find_cut(&self) -> usize {
        let most_traversed = self
            .most_traversed_edges()
            .into_iter()
            .map(|(k, _)| k)
            .take(10)
            .collect::<Vec<_>>();

        let count = most_traversed
            .iter()
            .cartesian_product(most_traversed.iter())
            .cartesian_product(most_traversed.iter())
            .filter_map(|((e1, e2), e3)| {
                if e1 != e2 && e2 != e3 && e1 != e3 {
                    Some((e1, e2, e3))
                } else {
                    None
                }
            })
            .find_map(|(e1, e2, e3)| self.compute_cut([*e1, *e2, *e3].into_iter().collect()))
            .unwrap();

        count * (self.0.len() - count)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
        jqt: rhn xhk nvd
        rsh: frs pzl lsr
        xhk: hfx
        cmg: qnr nvd lhk bvb
        rhn: xhk bvb hfx
        bvb: xhk hfx
        pzl: lsr hfx nvd
        qnr: nvd
        ntq: jqt hfx bvb xhk
        nvd: lhk
        lsr: lhk
        rzs: qnr cmg lsr rsh
        frs: qnr lhk lsr
        "
    );

    #[test]
    fn test_parse() {
        let al = AdjLists::parse(TEST_CASE);
        println!("{}", al.find_cut());
    }
}

adventofcode2023::run!(Solution);
