#!/usr/bin/env python3
import os
import sys
import argparse
import re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import threading
from collections import defaultdict, Counter
import json

class ErrorAnalyzer:
    def __init__(self, track_dir=".wstring_scan_log", max_workers=4):
        self.track_dir = Path(track_dir)
        self.max_workers = max_workers
        
        # Error patterns to search for
        self.error_patterns = {
            "Error": re.compile(r'\bError\b', re.IGNORECASE),
            "ReferenceError": re.compile(r'\bReferenceError\b', re.IGNORECASE),
            "SyntaxError": re.compile(r'\bSyntaxError\b', re.IGNORECASE),
            "ERR_SCRIPT_EXECUTION_TIMEOUT": re.compile(r'\bERR_SCRIPT_EXECUTION_TIMEOUT\b', re.IGNORECASE)
        }
        
        # More detailed error patterns for analysis
        self.detailed_error_patterns = {
            # JavaScript Errors
            "ReferenceError": re.compile(r'ReferenceError[:\s]+([^\n\r]+)', re.IGNORECASE),
            "SyntaxError": re.compile(r'SyntaxError[:\s]+([^\n\r]+)', re.IGNORECASE),
            "TypeError": re.compile(r'TypeError[:\s]+([^\n\r]+)', re.IGNORECASE),
            "Error": re.compile(r'(?<!Reference)(?<!Syntax)(?<!Type)Error[:\s]+([^\n\r]+)', re.IGNORECASE),
            
            # Node.js/V8 Errors
            "ERR_SCRIPT_EXECUTION_TIMEOUT": re.compile(r'ERR_SCRIPT_EXECUTION_TIMEOUT', re.IGNORECASE),
            "FATAL ERROR": re.compile(r'FATAL ERROR[:\s]+([^\n\r]+)', re.IGNORECASE),
            "Maximum call stack": re.compile(r'Maximum call stack size exceeded', re.IGNORECASE),
            "out of memory": re.compile(r'out of memory|ENOMEM', re.IGNORECASE),
            
            # Process Errors
            "SIGKILL": re.compile(r'SIGKILL|killed', re.IGNORECASE),
            "SIGTERM": re.compile(r'SIGTERM|terminated', re.IGNORECASE),
            
            # Other patterns
            "Invalid": re.compile(r'Invalid[:\s]+([^\n\r]+)', re.IGNORECASE),
            "Cannot": re.compile(r'Cannot[:\s]+([^\n\r]+)', re.IGNORECASE),
            "Failed": re.compile(r'Failed[:\s]+([^\n\r]+)', re.IGNORECASE),
        }
        
        # Thread-safe containers
        self.lock = threading.Lock()
        self.results = {
            "files_with_errors": defaultdict(list),
            "error_counts": Counter(),
            "detailed_errors": defaultdict(list),
            "total_no_pattern_files": 0,
            "analyzed_files": 0,
            "files_with_any_error": 0
        }
    
    def load_no_pattern_files(self):
        """Load files that don't have the main patterns"""
        not_found_log = self.track_dir / "not_found.txt"
        
        if not not_found_log.exists():
            print(f"Error: {not_found_log} not found. Run the scanner first.")
            return []
        
        files = []
        try:
            with open(not_found_log, 'r', encoding='utf-8') as f:
                files = [line.strip() for line in f if line.strip()]
        except Exception as e:
            print(f"Error reading {not_found_log}: {e}")
            return []
        
        self.results["total_no_pattern_files"] = len(files)
        return files
    
    def analyze_file(self, file_path):
        """Analyze a single file for error patterns"""
        try:
            if not os.path.exists(file_path):
                return
            
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            file_errors = []
            file_has_error = False
            
            # Check basic error patterns
            for error_name, pattern in self.error_patterns.items():
                if pattern.search(content):
                    file_errors.append(error_name)
                    file_has_error = True
            
            # Extract detailed error messages
            detailed_findings = {}
            for error_type, pattern in self.detailed_error_patterns.items():
                matches = pattern.findall(content)
                if matches:
                    # For patterns with groups, take the captured group
                    if isinstance(matches[0], str):
                        detailed_findings[error_type] = matches[:5]  # Limit to first 5 matches
                    else:
                        detailed_findings[error_type] = [str(m) for m in matches[:5]]
                elif pattern.search(content):  # Pattern matches but no groups
                    detailed_findings[error_type] = ["(pattern found)"]
            
            # Filter out generic errors that are actually specific errors
            if detailed_findings.get("GenericError"):
                filtered_generic = []
                for error_msg in detailed_findings["GenericError"]:
                    # Skip if it's actually a ReferenceError, SyntaxError, or TypeError
                    if not any(specific in error_msg for specific in ["ReferenceError", "SyntaxError", "TypeError"]):
                        filtered_generic.append(error_msg)
                
                if filtered_generic:
                    detailed_findings["GenericError"] = filtered_generic
                else:
                    del detailed_findings["GenericError"]
            
            with self.lock:
                self.results["analyzed_files"] += 1
                
                if file_has_error:
                    self.results["files_with_any_error"] += 1
                    self.results["files_with_errors"][file_path] = file_errors
                
                # Update counters
                for error in file_errors:
                    self.results["error_counts"][error] += 1
                
                # Store detailed findings
                if detailed_findings:
                    self.results["detailed_errors"][file_path] = detailed_findings
                    
        except Exception as e:
            with self.lock:
                self.results["analyzed_files"] += 1
                print(f"Error analyzing {file_path}: {e}")
    
    def analyze(self):
        """Main analysis function"""
        print("Error Analysis for Files WITHOUT Main Patterns")
        print("=" * 60)
        
        # Load files to analyze
        no_pattern_files = self.load_no_pattern_files()
        
        if not no_pattern_files:
            print("No files to analyze.")
            return
        
        print(f"Analyzing {len(no_pattern_files)} files without main patterns...")
        print(f"Looking for: {', '.join(self.error_patterns.keys())}")
        print("-" * 60)
        
        # Analyze files in parallel
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            executor.map(self.analyze_file, no_pattern_files)
        
        self.print_results()
        self.save_results()
    
    def print_results(self):
        """Print analysis results"""
        print(f"\nANALYSIS RESULTS")
        print("=" * 60)
        print(f"Total files without main patterns: {self.results['total_no_pattern_files']}")
        print(f"Files analyzed: {self.results['analyzed_files']}")
        print(f"Files with error indicators: {self.results['files_with_any_error']}")
        print(f"Error rate: {self.results['files_with_any_error']/self.results['analyzed_files']*100:.1f}%")
        
        print(f"\nERROR TYPE BREAKDOWN:")
        print("-" * 30)
        for error_type, count in self.results["error_counts"].most_common():
            percentage = count / self.results["analyzed_files"] * 100
            print(f"  {error_type}: {count} files ({percentage:.1f}%)")
        
        # Detailed error analysis
        print(f"\nDETAILED ERROR ANALYSIS:")
        print("-" * 30)
        
        error_type_stats = defaultdict(Counter)
        
        for file_path, errors in self.results["detailed_errors"].items():
            for error_type, messages in errors.items():
                for msg in messages:
                    # Clean up the message
                    clean_msg = msg.strip()[:100]  # First 100 chars
                    error_type_stats[error_type][clean_msg] += 1
        
        for error_type, message_counts in error_type_stats.items():
            print(f"\n📋 {error_type.upper()}:")
            top_messages = message_counts.most_common(10)  # Top 10 messages
            for message, count in top_messages:
                print(f"  [{count:3d}x] {message}")
        
        # Sample files for each error type
        print(f"\nSAMPLE FILES BY ERROR TYPE:")
        print("-" * 30)
        
        for error_type in self.results["error_counts"]:
            sample_files = []
            for file_path, errors in self.results["files_with_errors"].items():
                if error_type in errors:
                    sample_files.append(Path(file_path).name)
                    if len(sample_files) >= 3:  # Show max 3 samples
                        break
            
            if sample_files:
                print(f"  {error_type}: {', '.join(sample_files)}")
    
    def save_results(self):
        """Save results to JSON file"""
        output_file = self.track_dir / "error_analysis.json"
        
        try:
            # Convert defaultdict to regular dict for JSON serialization
            json_data = {
                "summary": {
                    "total_no_pattern_files": self.results["total_no_pattern_files"],
                    "analyzed_files": self.results["analyzed_files"],
                    "files_with_any_error": self.results["files_with_any_error"],
                    "error_rate_percentage": round(self.results["files_with_any_error"]/self.results["analyzed_files"]*100, 1)
                },
                "error_counts": dict(self.results["error_counts"]),
                "files_with_errors": dict(self.results["files_with_errors"]),
                "detailed_errors": dict(self.results["detailed_errors"])
            }
            
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(json_data, f, indent=2, ensure_ascii=False)
            
            print(f"\nDetailed results saved to: {output_file}")
            
        except Exception as e:
            print(f"Warning: Could not save results to JSON: {e}")

def parse_arguments():
    parser = argparse.ArgumentParser(description="Analyze errors in files without main patterns")
    parser.add_argument("-t", "--track-dir", default=".wstring_scan_log",
                       help="Directory containing scan logs")
    parser.add_argument("-w", "--workers", type=int, default=4,
                       help="Number of worker threads")
    return parser.parse_args()

def main():
    args = parse_arguments()
    
    analyzer = ErrorAnalyzer(
        track_dir=args.track_dir,
        max_workers=args.workers
    )
    
    analyzer.analyze()

if __name__ == "__main__":
    main()