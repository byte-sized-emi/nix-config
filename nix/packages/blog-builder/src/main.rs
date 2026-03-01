use chrono::Local;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "blog-builder")]
struct Args {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    Build {
        #[arg(long, help = "Path to the base directory containing markdown files")]
        input: String,
        #[arg(
            long,
            help = "Path to the output directory for generated HTML/CSS/JS files"
        )]
        output: String,
    },
    Sample,
}

fn main() {
    match Args::parse().command {
        Some(Commands::Sample) => {
            let now = Local::now().format("%Y-%m-%dT%H:%M:%S%z");
            let sample = format!(
                r#"---
title: Hello World!
date: {now}
tags: [NixOS, nix, rust]
authors: [byte-sized-emi]
released: false
---

# This is a blog post.
"#
            );
            println!("{}", sample);
        }
        Some(Commands::Build { input, output }) => {
            println!("Processing files in '{input}' and outputting to '{output}'");
            match blog_builder::process_website(&input, &output) {
                Ok(_) => println!("Finished processing files."),
                Err(e) => eprintln!("Error processing files: {}", e),
            }
        }
        None => {
            eprintln!("No command specified. Use --help for usage information.");
        }
    }
}
