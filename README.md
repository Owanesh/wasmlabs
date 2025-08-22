# WASM Labs

This repository contains experiments and prototypes around WebAssembly (WASM). It serves as a sandbox to explore performance characteristics, tooling, and security/malware manipulation in the context of WASM.

## Structure

- `benchmark_wasi/` — Experiments focused on benchmarking WebAssembly workloads. This includes harnesses, patches, and integrations (e.g., UnixBench-based workloads) to assess performance across runtimes and configurations.

- `malware_analysis/` — Experiments focused on manipulation and analysis of WebAssembly malware. This may include toy samples, instrumentation, and transformation experiments aimed at understanding behavior and potential defenses.

## Notes

- Content under `wasibench/` is intended for performance analysis and reproducibility of benchmark runs.
- Content under `malprof/` is intended strictly for research and educational purposes related to malware analysis and manipulation in a controlled environment.
