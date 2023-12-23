use adventofcode2023::AocSolution;

use std::{
    cell::RefCell,
    collections::{HashMap, VecDeque},
};

use itertools::Itertools;

pub struct Solution;

#[derive(Clone, Copy, Debug)]
enum Pulse {
    High,
    Low,
}

#[derive(Clone, Copy, Debug)]
struct PulseSignal<'a> {
    src: &'a str,
    dst: &'a str,
    pulse: Pulse,
}

#[derive(Debug)]
enum Module<'a> {
    Broadcaster {
        output: Vec<&'a str>,
    },
    FlipFlop {
        name: &'a str,
        output: Vec<&'a str>,
        state: bool,
    },
    Conjunction {
        name: &'a str,
        output: Vec<&'a str>,
        inputs: HashMap<String, Pulse>,
    },
    Untyped {
        name: &'a str,
    },
}

impl<'a> Module<'a> {
    fn parse(input: &'a str) -> (&'a str, Self) {
        let (name, output_names) = input.split(" -> ").next_tuple().unwrap();

        let output = output_names.split(", ").collect::<Vec<_>>();

        match name {
            "broadcaster" => ("broadcaster", Module::Broadcaster { output }),
            name if name.starts_with('%') => (
                &name[1..],
                Module::FlipFlop {
                    name: &name[1..],
                    output,
                    state: false,
                },
            ),
            name if name.starts_with('&') => (
                &name[1..],
                Module::Conjunction {
                    name: &name[1..],
                    inputs: HashMap::new(),
                    output,
                },
            ),
            _ => unreachable!(),
        }
    }

    fn output_names(&self) -> &[&'a str] {
        match self {
            Module::Broadcaster { output } => output,
            Module::FlipFlop { output, .. } => output,
            Module::Conjunction { output, .. } => output,
            Module::Untyped { .. } => &[],
        }
    }

    fn receive(&mut self, source: &'a str, pulse: Pulse) -> Option<Vec<PulseSignal<'a>>> {
        match self {
            Module::Broadcaster { output } => Some(
                output
                    .iter()
                    .map(|dst| PulseSignal {
                        src: "broadcaster",
                        dst,
                        pulse,
                    })
                    .collect(),
            ),
            Module::FlipFlop {
                name,
                output,
                state,
            } => {
                if let Pulse::High = pulse {
                    None
                } else {
                    *state = !*state;
                    let pulse = if *state { Pulse::High } else { Pulse::Low };
                    Some(
                        output
                            .iter()
                            .map(|dst| PulseSignal {
                                src: name,
                                dst,
                                pulse,
                            })
                            .collect(),
                    )
                }
            }
            Module::Conjunction {
                name,
                output,
                inputs,
            } => {
                inputs.insert(source.to_string(), pulse);
                let pulse = if inputs.values().all(|pulse| matches!(pulse, Pulse::High)) {
                    Pulse::Low
                } else {
                    Pulse::High
                };

                Some(
                    output
                        .iter()
                        .map(|dst| PulseSignal {
                            src: name,
                            dst,
                            pulse,
                        })
                        .collect(),
                )
            }
            Module::Untyped { name: _ } => None,
        }
    }
}

#[derive(Debug)]
struct ModuleMap<'a> {
    modules: RefCell<HashMap<String, Module<'a>>>,
    count_high: u64,
    count_low: u64,
    count_rx: u64,
}

impl<'a> ModuleMap<'a> {
    fn parse(input: &'a str) -> Self {
        let mut module_map = input
            .trim()
            .lines()
            .map(Module::parse)
            .map(|(k, v)| (k.to_string(), v))
            .collect::<HashMap<_, _>>();

        let input_names = module_map
            .iter()
            .flat_map(|(name, module)| {
                module.output_names().iter().filter_map(|&dst_name| {
                    if matches!(module_map.get(dst_name), Some(Module::Conjunction { .. })) {
                        Some((name.to_string(), dst_name.to_string()))
                    } else {
                        None
                    }
                })
            })
            .collect_vec();

        for (input_name, conj_name) in input_names {
            if let Some(Module::Conjunction { inputs, .. }) = module_map.get_mut(conj_name.as_str())
            {
                inputs.insert(input_name, Pulse::Low);
            } else {
                panic!();
            }
        }

        Self {
            modules: RefCell::new(module_map),
            count_low: 0,
            count_high: 0,
            count_rx: 0,
        }
    }

    fn push_button(&mut self) {
        self.count_rx = 0;

        let mut q = VecDeque::new();
        q.push_front(PulseSignal {
            src: "button",
            dst: "broadcaster",
            pulse: Pulse::Low,
        });

        while !q.is_empty() {
            let mut map = self.modules.borrow_mut();
            let signal = q.pop_front().unwrap();
            match signal.pulse {
                Pulse::High => self.count_high += 1,
                Pulse::Low => self.count_low += 1,
            }

            if matches!(signal.pulse, Pulse::Low) && signal.dst == "rx" {
                self.count_rx += 1;
            }

            if !map.contains_key(signal.dst) {
                map.insert(signal.dst.to_string(), Module::Untyped { name: signal.dst });
            }

            if let Some(signals) = map
                .get_mut(signal.dst)
                .and_then(|m| m.receive(signal.src, signal.pulse))
            {
                signals.into_iter().for_each(|s| q.push_back(s));
            }
        }
    }

    fn counts(&self) -> u64 {
        self.count_high * self.count_low
    }
}

impl AocSolution for Solution {
    const DAY: u8 = 20;

    fn new() -> Self {
        Self
    }

    fn part1(&self, input: &str) -> u64 {
        let mut mm = ModuleMap::parse(input);
        for _ in 0..1000 {
            mm.push_button();
        }
        mm.counts()
    }

    fn part2(&self, input: &str) -> u64 {
        let mut mm = ModuleMap::parse(input);
        (0u64..)
            .find(|i| {
                mm.push_button();
                if i % 10000 == 0 {
                    println!("{i} {}", mm.count_rx);
                }
                mm.count_rx == 1
            })
            .unwrap()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_CASE: &str = textwrap_macros::dedent!(
        r"
    broadcaster -> a, b, c
    %a -> b
    %b -> c
    %c -> inv
    &inv -> a
    "
    );

    const TEST_CASE2: &str = textwrap_macros::dedent!(
        r"
    broadcaster -> a
    %a -> inv, con
    &inv -> b
    %b -> con
    &con -> output
    "
    );

    #[test]
    fn test_parse() {
        let mut mm = ModuleMap::parse(TEST_CASE);
        for _ in 0..1000 {
            mm.push_button();
        }
        println!("{}x{} -> {}", mm.count_low, mm.count_high, mm.counts());

        let mut mm = ModuleMap::parse(TEST_CASE2);
        for _ in 0..1000 {
            mm.push_button();
        }
        println!("{}x{} -> {}", mm.count_low, mm.count_high, mm.counts());
    }
}

adventofcode2023::run!(Solution);
