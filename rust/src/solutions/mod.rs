mod day01;
mod day02;
mod day03;
mod day04;
mod day20;
// mod day21;
// mod day22;
// mod day23;
// mod day24;
// mod day25;

pub trait AocSolution {
    fn new() -> Self
    where
        Self: Sized;
    fn part1(&self, input: &str) -> u64;
    fn part2(&self, input: &str) -> u64;
}

pub fn solution(day: u8) -> Box<dyn AocSolution> {
    match day {
        1 => Box::new(day01::Solution::new()),
        2 => Box::new(day02::Solution::new()),
        3 => Box::new(day03::Solution::new()),
        4 => Box::new(day04::Solution::new()),
        20 => Box::new(day20::Solution::new()),
        // 21 => Box::new(day21::Solution::new()),
        // 22 => Box::new(day22::Solution::new()),
        // 23 => Box::new(day23::Solution::new()),
        // 24 => Box::new(day24::Solution::new()),
        // 25 => Box::new(day25::Solution::new()),
        _ => panic!("That's just not possible dude"),
    }
}
