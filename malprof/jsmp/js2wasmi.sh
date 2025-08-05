#!/usr/bin/env bash

# js2wasmi.sh - Convert JavaScript to WebAssembly using porf
#
# Supports compiling a single file or all .js files in a directory tree.
# Only produces output files when compilation succeeds without errors.
#
# Usage:
#   js2wasmi.sh INPUT [-o OUTPUT]
#     - INPUT: a .js file or a directory
#     - -o/--output:
#         * if INPUT is a file: optional output .wasm file path
#         * if INPUT is a directory: optional output directory; defaults to malprof/jsmp/export_j2m
#
# Exit codes:
#   0 - success (all compiled)
#   1 - invalid args, dependency missing, path missing, or any compilation failure

# ------------- Config -------------
DEFAULT_OUTPUT_DIR="export_j2m"  # Default output directory for compiled files
ERROR_LOG_NAME="ERRORS.log"  # Name of the error log file

# ------------- Logging -------------
# Use colors if terminal supports it
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; BLU=$'\033[34m'; NC=$'\033[0m'
else
  RED=""; GRN=""; YLW=""; BLU=""; NC=""
fi

# Logging functions
log_info()    { printf "%s[INFO]%s %s\n" "$BLU" "$NC" "$*"; }
log_warn()    { printf "%s[WARN]%s %s\n" "$YLW" "$NC" "$*"; }
log_error()   { printf "%s[ERROR]%s %s\n" "$RED" "$NC" "$*"; }
log_success() { printf "%s[SUCCESS]%s %s\n" "$GRN" "$NC" "$*"; }

# ------------- Helpers -------------

# Print usage instructions
#
# Usage:
#   print_usage
print_usage() {
  cat <<EOF
Usage: $0 INPUT [-o OUTPUT]

Convert JavaScript to WebAssembly using porf.

Arguments:
  INPUT
    - a .js file to compile
    - OR a directory to scan recursively for .js files

Options:
  -o, --output OUTPUT
    - If INPUT is a file: OUTPUT must be a .wasm file (optional, default: same path with .wasm)
    - If INPUT is a directory: OUTPUT must be a directory (optional, default: ${DEFAULT_OUTPUT_DIR})

Examples:
  $0 file.js
  $0 file.js -o out/file.wasm
  $0 src/dir
  $0 src/dir -o build_wasm
EOF
}

# Normalize a file or directory path to an absolute path
#
# Arguments:
#   $1 - Path to normalize
#
# Outputs:
#   Prints the normalized absolute path
normalize_path() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p"
  else
    case "$p" in
      /*) printf "%s\n" "$p" ;;
      *) printf "%s/%s\n" "$PWD" "$p" ;;
    esac
  fi
}

# Ensure a directory exists, creating it if necessary
#
# Arguments:
#   $1 - Directory path
ensure_directory() {
  local dir="$1"
  if [[ -z "$dir" ]]; then
    return 1
  fi
  mkdir -p "$dir"
}

# Check if a file is a JavaScript file
#
# Arguments:
#   $1 - File path
#
# Returns:
#   0 if the file is a JavaScript file, 1 otherwise
is_js_file() {
  local p="$1"
  [[ -f "$p" && "$p" == *.js ]]
}

# Check for required dependencies
#
# Exits:
#   1 if a required dependency is missing
check_dependencies() {
  if ! command -v porf >/dev/null 2>&1; then
    log_error "porf could not be found. Please install it first."
    exit 1
  fi
}

# Compile a single JavaScript file to WebAssembly
#
# Arguments:
#   $1 - Input JavaScript file
#   $2 - Output WebAssembly file
#   $3 - Error log file
#
# Returns:
#   0 if compilation succeeds, 1 otherwise
compile_one() {
  local input_js="$1"
  local output_wasm="$2"
  local error_log="$3"

  # Skip compilation if the output file already exists and is newer than the input file
  if [[ -f "$output_wasm" && "$output_wasm" -nt "$input_js" ]]; then
    log_info "Skipping already compiled file: ${input_js#$PWD/}"
    return 0
  fi

  # Validate that the input file exists and is readable
  if [[ ! -f "$input_js" || ! -r "$input_js" ]]; then
    log_error "Input file does not exist or is not readable: ${input_js#$PWD/}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Input file does not exist or is not readable: ${input_js#$PWD/}" >> "$error_log"
    return 1
  fi

  # Validate input file is not empty
  if [[ ! -s "$input_js" ]]; then
    log_error "Input file is empty: ${input_js#$PWD/}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Input file is empty: ${input_js#$PWD/}" >> "$error_log"
    return 1
  fi

  # Use a temporary folder for compilation
  local temp_dir="$(mktemp -d)"
  local temp_output_wasm="$temp_dir/$(basename "$output_wasm")"
  local temp_error_log="$temp_dir/compile_error.log"

  # Compile the file into the temporary folder with detailed error capture
  if porf wasm "$input_js" "$temp_output_wasm" > "$temp_error_log" 2>&1; then
    # Verify the output file was actually created and has content
    if [[ -f "$temp_output_wasm" && -s "$temp_output_wasm" ]]; then
      # Move the compiled file to the final output directory only if successful
      ensure_directory "$(dirname "$output_wasm")"
      mv "$temp_output_wasm" "$output_wasm"
      log_success "${input_js#$PWD/} → ${output_wasm#$PWD/}"
      rm -rf "$temp_dir"
      return 0
    else
      log_error "Compilation succeeded but no valid output was produced: ${input_js#$PWD/}"
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Compilation succeeded but no valid output was produced: ${input_js#$PWD/}" >> "$error_log"
      rm -rf "$temp_dir"
      return 1
    fi
  else
    # Capture detailed error information
    local error_details=""
    if [[ -f "$temp_error_log" ]]; then
      error_details=$(cat "$temp_error_log" | head -20 | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')
    fi
    
    log_error "Failed to compile: ${input_js#$PWD/}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Compilation failed for: ${input_js#$PWD/}" >> "$error_log"
    if [[ -n "$error_details" ]]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error details: $error_details" >> "$error_log"
    fi
    rm -rf "$temp_dir"
    return 1
  fi
}

# Process a single JavaScript file
#
# Arguments:
#   $1 - Input JavaScript file
#   $2 - Output WebAssembly file (optional)
process_single_file() {
  local input_js="$1"
  local output_option="$2"

  local output_wasm
  if [[ -n "${output_option:-}" ]]; then
    output_wasm="$output_option"
    if [[ "${output_wasm##*.}" != "wasm" ]]; then
      log_error "For single file input, -o must point to a .wasm file"
      exit 1
    fi
  else
    output_wasm="${input_js%.js}.wasm"
  fi

  local error_log_dir
  error_log_dir="$(dirname "$output_wasm")"
  ensure_directory "$error_log_dir"
  local error_log="$error_log_dir/$ERROR_LOG_NAME"

  log_info "Compiling single file:"
  log_info "  Input : $input_js"
  log_info "  Output: $output_wasm"
  log_info "  Errors: $error_log"

  local failed=0
  if ! compile_one "$input_js" "$output_wasm" "$error_log"; then
    failed=1
  fi

  echo
  log_info "=== COMPILATION SUMMARY ==="
  if [[ $failed -eq 0 ]]; then
    log_success "All files compiled successfully."
    return 0
  else
    log_warn "Some files failed. Check error log: $error_log"
    return 1
  fi
}

# Process a directory of JavaScript files
#
# Arguments:
#   $1 - Input directory
#   $2 - Output directory (optional)
process_directory() {
  local input_dir="$1"
  local output_dir="$2"

  if [[ -z "${output_dir:-}" ]]; then
    output_dir="$DEFAULT_OUTPUT_DIR"
  fi

  if [[ "$output_dir" == *.wasm ]]; then
    log_error "When INPUT is a directory, -o must specify a directory, not a .wasm file"
    exit 1
  fi

  ensure_directory "$output_dir"
  local error_log="$output_dir/$ERROR_LOG_NAME"
  : > "$error_log"

  log_info "Processing directory: ${input_dir#$PWD/}"

  # Build list safely (null-terminated)
  local temp_file_list
  temp_file_list="$(mktemp)"
  find "$input_dir" -type f -name "*.js" -print0 > "$temp_file_list"
  local file_count
  file_count="$(find "$input_dir" -type f -name "*.js" | wc -l | tr -d ' ')"

  if [[ "$file_count" -eq 0 ]]; then
    log_warn "No .js files found in ${input_dir#$PWD/}"
    rm -f "$temp_file_list"
    return 0
  fi

  log_info "Found $file_count JavaScript files. Starting compilation..."

  local current=0
  local processed_count=0
  local failed_count=0

  while IFS= read -r -d '' input_js; do
    ((current++))

    # Compute relative path and destination
    local relative="${input_js#"$input_dir"/}"
    local relative_wasm="${relative%.js}.wasm"
    local dest="$output_dir/$relative_wasm"

    ensure_directory "$(dirname "$dest")"

    if compile_one "$input_js" "$dest" "$error_log"; then
      ((processed_count++))
    else
      ((failed_count++))
    fi

    # Log progress every 10% or every 100 files
    if (( current % 100 == 0 || current * 10 / file_count > (current - 1) * 10 / file_count )); then
      log_info "Progress: $current/$file_count files processed"
    fi
  done < "$temp_file_list"

  rm -f "$temp_file_list"

  echo
  log_info "=== COMPILATION SUMMARY ==="
  log_info "Processed: $processed_count files"
  if [[ $failed_count -gt 0 ]]; then
    log_warn "Failed   : $failed_count files"
    log_info "Check error log: ${error_log#$PWD/}"
    return 1
  else
    log_success "All files compiled successfully!"
    return 0
  fi
}

# ------------- Argument parsing and main -------------
main() {
  check_dependencies

  local input_path=""
  local output_option=""

  # Parse args
  if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        print_usage
        exit 0
        ;;
      -o|--output)
        if [[ $# -lt 2 ]]; then
          log_error "Option -o requires a value"
          print_usage
          exit 1
        fi
        output_option="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        log_error "Unknown option: $1"
        print_usage
        exit 1
        ;;
      *)
        if [[ -z "$input_path" ]]; then
          input_path="$1"
          shift
        else
          log_error "Multiple INPUT paths provided; only one is supported"
          print_usage
          exit 1
        fi
        ;;
    esac
  done

  # Validate input path before normalization
  if [[ -z "$input_path" ]]; then
    log_error "INPUT path is empty. Please provide a valid path."
    exit 1
  fi

  # Check for boolean values that might cause the TypeError
  if [[ "$input_path" == "true" || "$input_path" == "false" ]]; then
    log_error "INPUT path appears to be a boolean value: '$input_path'. Please provide a valid file or directory path."
    exit 1
  fi

  # Normalize input path
  input_path="$(normalize_path "$input_path")"
  
  # Validate normalized path
  if [[ -z "$input_path" ]]; then
    log_error "Failed to normalize input path"
    exit 1
  fi

  if [[ ! -e "$input_path" ]]; then
    log_error "INPUT path does not exist: $input_path"
    exit 1
  fi

  # Dispatch
  if is_js_file "$input_path"; then
    if process_single_file "$input_path" "${output_option:-}"; then
      exit 0
    else
      exit 1
    fi
  elif [[ -d "$input_path" ]]; then
    if process_directory "$input_path" "${output_option:-}"; then
      exit 0
    else
      exit 1
    fi
  else
    log_error "INPUT must be a .js file or a directory"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
