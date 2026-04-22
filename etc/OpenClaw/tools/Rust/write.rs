use std::env;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;

const WORKSPACE: &str = "/var/lib/openclaw";

fn main() {
    let args: Vec<String> = env::args().collect();

    let mut append = false;
    let mut filepath = None;
    let mut content = None;

    for arg in args.iter().skip(1) {
        if arg == "--append" {
            append = true;
        } else if filepath.is_none() {
            filepath = Some(arg);
        } else if content.is_none() {
            content = Some(arg);
        } else {
            eprintln!("{{\"error\": \"Extra argument detected: {}\"}}", arg);
            std::process::exit(1);
        }
    }

    let filepath = match filepath {
        Some(p) => p,
        None => {
            eprintln!("{{\"error\": \"Usage: write <filepath> <content> [--append]\"}}");
            std::process::exit(1);
        }
    };

    let content = match content {
        Some(c) => c,
        None => {
            eprintln!(
                "{{\"error\": \"Missing content. Usage: write <filepath> <content> [--append]\"}}"
            );
            std::process::exit(1);
        }
    };

    // Resolve relative paths to workspace, require absolute for non-workspace
    let resolved = if filepath.starts_with("/") {
        filepath.clone()
    } else {
        format!("{}/{}", WORKSPACE, filepath)
    };

    let path = Path::new(&resolved);

    // Must be within workspace
    if !resolved.starts_with(WORKSPACE) {
        eprintln!("{{\"error\": \"Security: Path must be within /var/lib/openclaw/\"}}");
        std::process::exit(1);
    }

    // Block .openclaw
    if resolved.contains(".openclaw") {
        eprintln!("{{\"error\": \"Security: Modifying files inside .openclaw is prohibited.\"}}");
        std::process::exit(1);
    }

    // Create parent dirs
    if let Some(parent) = path.parent() {
        if let Err(e) = fs::create_dir_all(parent) {
            eprintln!(
                "{{\"error\": \"Failed creating parent directories: {}\"}}",
                e
            );
            std::process::exit(1);
        }
    }

    let written_bytes = content.len();
    let op_name = if append { "appended" } else { "overwritten" };

    let mut file = OpenOptions::new()
        .create(true)
        .write(!append)
        .truncate(!append)
        .append(append)
        .open(path)
        .unwrap_or_else(|e| {
            eprintln!("{{\"error\": \"Failed opening file: {}\"}}", e);
            std::process::exit(1);
        });

    if append {
        if let Err(e) = writeln!(file, "{}", content) {
            eprintln!("{{\"error\": \"Failed appending to file: {}\"}}", e);
            std::process::exit(1);
        }
    } else {
        if let Err(e) = write!(file, "{}", content) {
            eprintln!("{{\"error\": \"Failed writing to file: {}\"}}", e);
            std::process::exit(1);
        }
    }

    let total_bytes = fs::metadata(path).map(|m| m.len()).unwrap_or(0);

    println!(
        "{{\"success\": true, \"operation\": \"{}\", \"path\": \"{}\", \"written_bytes\": {}, \"total_bytes\": {}}}",
        op_name, resolved, written_bytes, total_bytes
    );
}
