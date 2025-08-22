#!/usr/bin/env python3
import os
import sys
import argparse
import re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
import time

class WStringScanner:
    def __init__(self, search_dir, patterns=None, extensions=None, track_dir=".wstring_scan_log", 
                 case_sensitive=False, max_workers=4):
        self.search_dir = Path(search_dir)
        self.patterns = patterns or ["ADODB_Stream", "ActiveXObject", "WScript.Shell"]
        self.extensions = extensions or [".jailed.txt"]
        self.track_dir = Path(track_dir)
        self.case_sensitive = case_sensitive
        self.max_workers = max_workers
        
        # Create tracking directory
        self.track_dir.mkdir(exist_ok=True)
        
        # Log files
        self.found_log = self.track_dir / "found.txt"
        self.not_found_log = self.track_dir / "not_found.txt"
        self.stats_log = self.track_dir / "stats.txt"
        
        # Thread-safe counters
        self.lock = threading.Lock()
        self.current = 0
        self.new_match_count = 0
        self.new_no_match_count = 0
        self.skipped_count = 0
        
        # Load existing scanned files and counts
        self.scanned_files = self._load_scanned_files()
        self.existing_match_count = self._count_lines(self.found_log)
        self.existing_no_match_count = self._count_lines(self.not_found_log)
        
        # Compile regex patterns for better performance
        flags = 0 if case_sensitive else re.IGNORECASE
        self.compiled_patterns = [re.compile(re.escape(pattern), flags) for pattern in self.patterns]
    
    def _count_lines(self, file_path):
        """Count lines in a file"""
        if not file_path.exists():
            return 0
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return sum(1 for line in f if line.strip())
        except Exception:
            return 0
    
    def _load_scanned_files(self):
        """Load previously scanned files from log files"""
        scanned = set()
        
        for log_file in [self.found_log, self.not_found_log]:
            if log_file.exists():
                try:
                    with open(log_file, 'r', encoding='utf-8') as f:
                        scanned.update(line.strip() for line in f if line.strip())
                except Exception as e:
                    print(f"Warning: Error reading {log_file}: {e}")
        
        return scanned
    
    def _find_files(self):
        """Find all files to scan"""
        files = []
        
        for ext in self.extensions:
            if ext.startswith('.'):
                pattern = f"**/*{ext}"
            else:
                pattern = f"**/*.{ext}"
            
            files.extend(self.search_dir.glob(pattern))
        
        return [str(f) for f in files if f.is_file()]
    
    def _scan_file(self, file_path):
        """Scan a single file for patterns"""
        file_path = str(file_path)
        
        # Skip if already scanned
        if file_path in self.scanned_files:
            with self.lock:
                self.current += 1
                self.skipped_count += 1
            return file_path, "skipped", []
        
        found_patterns = []
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
                for i, pattern in enumerate(self.compiled_patterns):
                    if pattern.search(content):
                        found_patterns.append(self.patterns[i])
        
        except Exception as e:
            # File couldn't be read, treat as not found
            with self.lock:
                self.current += 1
                self.new_no_match_count += 1
            return file_path, "error", [f"Error: {str(e)}"]
        
        # Determine result
        if found_patterns:
            result = "found"
            with self.lock:
                self.current += 1
                self.new_match_count += 1
        else:
            result = "not_found"
            with self.lock:
                self.current += 1
                self.new_no_match_count += 1
        
        return file_path, result, found_patterns
    
    def _log_result(self, file_path, result, patterns):
        """Log scan result to appropriate file"""
        try:
            if result == "found":
                with open(self.found_log, 'a', encoding='utf-8') as f:
                    f.write(f"{file_path}\n")
            elif result == "not_found" or result == "error":
                with open(self.not_found_log, 'a', encoding='utf-8') as f:
                    f.write(f"{file_path}\n")
        except Exception as e:
            print(f"Warning: Error logging result for {file_path}: {e}")
    
    def scan(self, show_progress=True):
        """Main scanning function"""
        print(f"WString Scanner")
        print(f"Search directory: {self.search_dir}")
        print(f"Patterns: {', '.join(self.patterns)}")
        print(f"Extensions: {', '.join(self.extensions)}")
        print(f"Case sensitive: {self.case_sensitive}")
        print(f"Max workers: {self.max_workers}")
        print("-" * 60)
        
        # Find all files
        print("Finding files to scan...")
        all_files = self._find_files()
        total_files = len(all_files)
        
        if total_files == 0:
            print("No files found to scan.")
            return
        
        print(f"Found {total_files} files to process")
        
        if self.existing_match_count > 0 or self.existing_no_match_count > 0:
            print(f"Previous scan results: {self.existing_match_count} matches, {self.existing_no_match_count} no matches")
        
        start_time = time.time()
        
        # Process files with ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            future_to_file = {executor.submit(self._scan_file, file): file for file in all_files}
            
            for future in as_completed(future_to_file):
                file_path, result, patterns = future.result()
                
                # Log result
                if result != "skipped":
                    self._log_result(file_path, result, patterns)
                
                # Show progress
                if show_progress:
                    with self.lock:
                        if result == "found":
                            status = f"✅ {', '.join(patterns)}"
                        elif result == "skipped":
                            status = "⏭️  (already scanned)"
                        elif result == "error":
                            status = f"⚠️  {', '.join(patterns)}"
                        else:
                            status = "❌"
                        
                        print(f"[{self.current}/{total_files}] {Path(file_path).name} {status}")
                        
                        # Progress summary every 100 files
                        if self.current % 100 == 0:
                            elapsed = time.time() - start_time
                            rate = self.current / elapsed if elapsed > 0 else 0
                            print(f"  📊 Progress: {self.current}/{total_files} "
                                  f"({self.current/total_files*100:.1f}%) - "
                                  f"Rate: {rate:.1f} files/sec")
        
        # Final summary
        elapsed_time = time.time() - start_time
        self._print_summary(total_files, elapsed_time)
        self._save_stats(total_files, elapsed_time)
    
    def _print_summary(self, total_files, elapsed_time):
        """Print final summary"""
        total_match_count = self.existing_match_count + self.new_match_count
        total_no_match_count = self.existing_no_match_count + self.new_no_match_count
        total_processed_ever = total_match_count + total_no_match_count
        
        print("\n" + "=" * 60)
        print("SCAN SUMMARY")
        print("=" * 60)
        print(f"Total files found: {total_files}")
        print(f"Files processed this run: {self.current}")
        print(f"Files skipped (already scanned): {self.skipped_count}")
        print("-" * 30)
        print(f"NEW RESULTS THIS RUN:")
        print(f"  Files with patterns: {self.new_match_count} ✅")
        print(f"  Files without patterns: {self.new_no_match_count} ❌")
        print("-" * 30)
        print(f"CUMULATIVE TOTALS:")
        print(f"  Total files ever processed: {total_processed_ever}")
        print(f"  Total files with patterns: {total_match_count} ✅")
        print(f"  Total files without patterns: {total_no_match_count} ❌")
        if total_processed_ever > 0:
            print(f"  Overall success rate: {total_match_count/total_processed_ever*100:.1f}%")
        print("-" * 30)
        print(f"Time elapsed: {elapsed_time:.2f} seconds")
        if self.current > 0:
            print(f"Average rate: {self.current/elapsed_time:.1f} files/second")
        print(f"\nLogs saved to: {self.track_dir}")
    
    def _save_stats(self, total_files, elapsed_time):
        """Save statistics to file"""
        total_match_count = self.existing_match_count + self.new_match_count
        total_no_match_count = self.existing_no_match_count + self.new_no_match_count
        total_processed_ever = total_match_count + total_no_match_count
        
        try:
            with open(self.stats_log, 'w', encoding='utf-8') as f:
                f.write(f"Scan Statistics\n")
                f.write(f"===============\n")
                f.write(f"Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Search directory: {self.search_dir}\n")
                f.write(f"Patterns: {', '.join(self.patterns)}\n")
                f.write(f"Extensions: {', '.join(self.extensions)}\n")
                f.write(f"\nThis Run:\n")
                f.write(f"Total files found: {total_files}\n")
                f.write(f"Files processed: {self.current}\n")
                f.write(f"Files skipped: {self.skipped_count}\n")
                f.write(f"New matches: {self.new_match_count}\n")
                f.write(f"New no-matches: {self.new_no_match_count}\n")
                f.write(f"\nCumulative Totals:\n")
                f.write(f"Total files ever processed: {total_processed_ever}\n")
                f.write(f"Total files with patterns: {total_match_count}\n")
                f.write(f"Total files without patterns: {total_no_match_count}\n")
                if total_processed_ever > 0:
                    f.write(f"Overall success rate: {total_match_count/total_processed_ever*100:.1f}%\n")
                f.write(f"\nPerformance:\n")
                f.write(f"Time elapsed: {elapsed_time:.2f} seconds\n")
                if self.current > 0:
                    f.write(f"Rate: {self.current/elapsed_time:.1f} files/second\n")
        except Exception as e:
            print(f"Warning: Could not save stats: {e}")

def parse_arguments():
    parser = argparse.ArgumentParser(description="Scan files for specific string patterns")
    parser.add_argument("search_dir", nargs='?', default=".", 
                       help="Directory to search (default: current directory)")
    parser.add_argument("-p", "--patterns", nargs='+', 
                       default=["ADODB_Stream", "ActiveXObject", "WScript.Shell"],
                       help="Patterns to search for")
    parser.add_argument("-e", "--extensions", nargs='+', default=[".jailed.txt"],
                       help="File extensions to scan")
    parser.add_argument("-t", "--track-dir", default=".wstring_scan_log",
                       help="Directory for tracking logs")
    parser.add_argument("-c", "--case-sensitive", action="store_true",
                       help="Case sensitive search")
    parser.add_argument("-w", "--workers", type=int, default=4,
                       help="Number of worker threads")
    parser.add_argument("-q", "--quiet", action="store_true",
                       help="Quiet mode - no progress output")
    parser.add_argument("--reset", action="store_true",
                       help="Reset tracking logs and start fresh")
    
    return parser.parse_args()

def main():
    args = parse_arguments()
    
    # Reset logs if requested
    if args.reset:
        track_dir = Path(args.track_dir)
        if track_dir.exists():
            for log_file in track_dir.glob("*.txt"):
                log_file.unlink()
            print(f"Reset tracking logs in {track_dir}")
    
    # Create and run scanner
    scanner = WStringScanner(
        search_dir=args.search_dir,
        patterns=args.patterns,
        extensions=args.extensions,
        track_dir=args.track_dir,
        case_sensitive=args.case_sensitive,
        max_workers=args.workers
    )
    
    scanner.scan(show_progress=not args.quiet)

if __name__ == "__main__":
    main()