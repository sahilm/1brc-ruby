# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby implementation of the One Billion Row Challenge (1BRC) - a performance challenge to process 1 billion temperature measurements and compute min/mean/max statistics per weather station.

## Commands

```bash
# Install dependencies
bundle install

# Run the main computation (uses V2 by default)
./runner.rb

# Run tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/v1_1brc_spec.rb

# Lint
bundle exec rubocop
```

## Architecture

Two implementations exist with different performance characteristics:

- **V1 (`v1_1brc.rb`)**: Single-threaded sequential processing. Reads `measurements.txt` line by line, parses station names and temperatures, accumulates stats in a hash.

- **V2 (`v2_1brc.rb`)**: Multi-process parallel implementation. Forks `Etc.nprocessors` workers, each processing a file chunk. Workers communicate results back via pipes using Marshal serialization, then results are merged.

Key design decisions:
- Temperatures are stored as integers (multiplied by 10) to avoid floating-point overhead
- Custom `to_number` parsing avoids Float parsing overhead
- YJIT is enabled for JIT compilation performance
- The `measurements.txt` symlink points to the active dataset size (10k, 10m, or 1b rows)

## Test Data

- `measurements-10k.txt`, `measurements-10m.txt`, `measurements-1b.txt`: Input files of varying sizes
- `measurements.txt`: Symlink to the active test dataset
- `spec/expected-output.txt`: Symlink to expected output for current dataset size
