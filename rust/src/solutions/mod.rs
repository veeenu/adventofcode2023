mod day01;
mod day02;
mod day03;
mod day04;
// mod day05;
// mod day06;
// mod day07;
// mod day08;
// mod day09;
// mod day10;
// mod day11;
// mod day12;
// mod day13;
// mod day14;
// mod day15;
// mod day16;
// mod day17;
// mod day18;
// mod day19;
// mod day20;
// mod day21;
// mod day22;
// mod day23;
// mod day24;
// mod day25;

pub trait AocSolution {
    fn new() -> Self
    where
        Self: Sized;
    fn part1(&self, input: &str) -> String;
    fn part2(&self, input: &str) -> String;
}

pub fn solution(day: u8) -> Box<dyn AocSolution> {
    match day {
        1 => Box::new(day01::Solution::new()),
        2 => Box::new(day02::Solution::new()),
        3 => Box::new(day03::Solution::new()),
        4 => Box::new(day04::Solution::new()),
        5 => Box::new(day05::Solution::new()),
        6 => Box::new(day06::Solution::new()),
        7 => Box::new(day07::Solution::new()),
        8 => Box::new(day08::Solution::new()),
        9 => Box::new(day09::Solution::new()),
        10 => Box::new(day10::Solution::new()),
        11 => Box::new(day11::Solution::new()),
        12 => Box::new(day12::Solution::new()),
        13 => Box::new(day13::Solution::new()),
        14 => Box::new(day14::Solution::new()),
        15 => Box::new(day15::Solution::new()),
        16 => Box::new(day16::Solution::new()),
        17 => Box::new(day17::Solution::new()),
        18 => Box::new(day18::Solution::new()),
        19 => Box::new(day19::Solution::new()),
        20 => Box::new(day20::Solution::new()),
        21 => Box::new(day21::Solution::new()),
        22 => Box::new(day22::Solution::new()),
        23 => Box::new(day23::Solution::new()),
        24 => Box::new(day24::Solution::new()),
        25 => Box::new(day25::Solution::new()),
        _ => panic!("That's just not possible dude"),
    }
}
