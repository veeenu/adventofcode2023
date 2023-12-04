mod solutions;

use std::path::PathBuf;

use anyhow::Result;
use chrono::{Datelike, Local};
use clap::Parser;
use reqwest::Client;

#[derive(Parser)]
struct Cli {
    /// Download input and run solution.
    day: Option<u8>,
}

fn today() -> u8 {
    Local::now().day() as u8
}

async fn get_input(day: u8) -> Result<String> {
    let path = PathBuf::from(format!("input/day{day:02}.txt"));

    tokio::fs::create_dir_all(path.parent().unwrap()).await?;

    if tokio::fs::try_exists(&path).await? {
        return Ok(tokio::fs::read_to_string(&path).await?);
    }

    let cookie = include_str!("../.cookie").trim();

    let body = Client::new()
        .get(format!("https://adventofcode.com/2023/day/{day}/input"))
        .header("Cookie", cookie)
        .send()
        .await?
        .text()
        .await?;

    tokio::fs::write(path, &body).await?;

    Ok(body)
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();
    let day = cli.day.unwrap_or_else(today);
    let input = get_input(day).await.unwrap();
    let solution = solutions::solution(day);

    let p1 = solution.part1(&input);
    println!("\x1b[32;1mPart 1:\x1b[33;1m {p1}\x1b[0m");

    let p2 = solution.part2(&input);
    println!("\x1b[32;1mPart 2:\x1b[33;1m {p2}\x1b[0m");
}
