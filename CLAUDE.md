# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby implementation of the One Billion Row Challenge (1BRC) - a performance challenge to process 1 billion temperature measurements and compute min/mean/max statistics per weather station.

## Commands

```bash
# Install dependencies
bundle install

# Run the main computation (uses V3 by default)
./runner.rb

# Run tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/v1_1brc_spec.rb

# Lint
bundle exec rubocop
```

## Architecture

Three implementations exist with different performance characteristics:

- **V1 (`v1_1brc.rb`)**: Single-threaded sequential processing. Uses a `Stats` Struct for station data, finds separators via `String#index`, and parses temperatures with string slicing and `to_i`.

- **V2 (`v2_1brc.rb`)**: Multi-process parallel implementation. Forks `Etc.nprocessors` workers, each processing a file chunk. Uses byte-level operations (`getbyte`, `byteslice`) for parsing. Workers communicate results back via pipes using Marshal serialization, then results are merged.

- **V3 (`v3_1brc.rb`)**: Fastest single-threaded implementation. Key optimizations over V1:
  - Uses raw arrays `[min, max, sum, count]` instead of Struct to eliminate method call overhead
  - Uses byte scanning with `getbyte` to find the semicolon separator
  - Uses `byteslice` to extract station names (more efficient than `slice!`)
  - Byte-based temperature parsing that works directly with ASCII values, avoiding string operations
  - Minimizes object allocations and method dispatch

Key design decisions:
- Temperatures are stored as integers (multiplied by 10) to avoid floating-point overhead
- YJIT is enabled for JIT compilation performance
- The `measurements.txt` symlink points to the active dataset size (10k, 10m, or 1b rows)

## Test Data

- `measurements-10k.txt`, `measurements-10m.txt`, `measurements-1b.txt`: Input files of varying sizes
- `measurements.txt`: Symlink to the active test dataset
- `spec/expected-output.txt`: Symlink to expected output for current dataset size
