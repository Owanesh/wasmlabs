# js2wasmi: JavaScript to Instrumented WebAssembly Compiler

`js2wasmi` is a key component of a pipeline designed to compile JavaScript files into instrumented WebAssembly (WASM). This tool is particularly tailored for processing large datasets, such as malware collections, and ensures robust error handling and logging.

## Overview
In the first step of the pipeline, `js2wasmi` successfully compiled 32,343 malware samples out of 39,452 JavaScript sources. Files that failed to compile are logged in `ERRORS.log`, along with detailed output from the `porf` compiler for debugging and analysis.

## Features
- Batch processing of JavaScript files.
- Skips already compiled files to optimize performance for large datasets.
- Logs errors for each failed file in `ERRORS.log`.
- Uses a temporary directory for atomic compilation, ensuring no partial outputs.
- Supports both single file and directory inputs.

## Usage
Refer to the script's help section for detailed usage instructions:
```bash
./js2wasmi.sh -h
```