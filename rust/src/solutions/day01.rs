use super::AocSolution;

pub struct Solution;

impl AocSolution for Solution {
    fn new() -> Self {
        Self
    }

    fn part1(&self, input: &str) -> String {
        input
            .lines()
            .map(|line| {
                let first = line
                    .chars()
                    .find(|c| c.is_numeric())
                    .and_then(|c| c.to_digit(10))
                    .unwrap();
                let last = line
                    .chars()
                    .rev()
                    .find(|c| c.is_numeric())
                    .and_then(|c| c.to_digit(10))
                    .unwrap();

                first * 10 + last
            })
            .sum::<u32>()
            .to_string()
    }

    fn part2(&self, input: &str) -> String {
        input
            .lines()
            .map(|line| {
                let values = parse_line(line);

                let first = values[0];
                let last = values.last().unwrap();

                first * 10 + last
            })
            .sum::<u32>()
            .to_string()
    }
}

fn parse_line(line: &str) -> Vec<u32> {
    let line = line.to_ascii_lowercase();
    (0..line.len())
        .map(|i| &line[i..])
        .filter_map(|wnd| {
            let c = wnd.chars().next().unwrap();
            if c.is_ascii_digit() {
                return c.to_digit(10);
            }

            if wnd.starts_with("one") {
                Some(1)
            } else if wnd.starts_with("two") {
                Some(2)
            } else if wnd.starts_with("three") {
                Some(3)
            } else if wnd.starts_with("four") {
                Some(4)
            } else if wnd.starts_with("five") {
                Some(5)
            } else if wnd.starts_with("six") {
                Some(6)
            } else if wnd.starts_with("seven") {
                Some(7)
            } else if wnd.starts_with("eight") {
                Some(8)
            } else if wnd.starts_with("nine") {
                Some(9)
            } else {
                None
            }
        })
        .collect::<Vec<_>>()
}
