import os
import sys
import csv
import threading
from concurrent.futures import ThreadPoolExecutor
import subprocess
import argparse
import tempfile
import shutil
from pathlib import Path

def parse_arguments():
    parser = argparse.ArgumentParser(description="Deobfuscate JavaScript files.")
    parser.add_argument("target_dir", help="Target directory containing JavaScript files.")
    parser.add_argument("-rescan", action="store_true", help="Reprocess failed files.")
    parser.add_argument("-timeout", action="store_true", help="Rescan only timeout files with doubled timeout.")
    parser.add_argument("-find-timeout", action="store_true", help="Find and list files with ERR_SCRIPT_EXECUTION_TIMEOUT.")
    parser.add_argument("-o", "--output", default="timeout_files.txt", 
                       help="Output file for timeout list (default: timeout_files.txt)")
    return parser.parse_args()

def load_report(report_path):
    """Load the existing report and return a dictionary with the status of the files"""
    file_status = {}
    failed_files = []
    
    if not os.path.exists(report_path):
        return file_status, failed_files
    
    with open(report_path, "r", encoding='utf-8') as f:
        reader = csv.reader(f)
        try:
            next(reader)  # Skip header
        except StopIteration:
            return file_status, failed_files
            
        for row in reader:
            if len(row) >= 3:
                number, filepath, status = row[0], row[1], row[2]
                file_status[filepath] = {
                    'number': number,
                    'status': status
                }
                if status == "fail":
                    failed_files.append(filepath)
    
    return file_status, failed_files

def find_timeout_files(search_dir, output_file=None):
    """Find all .jailed.txt files that contain ERR_SCRIPT_EXECUTION_TIMEOUT"""
    
    if not os.path.exists(search_dir):
        print(f"Error: Directory {search_dir} does not exist.")
        return []
    
    timeout_files = []
    processed_count = 0
    
    print(f"Scanning .jailed.txt files in: {search_dir}")
    print("Looking for string: ERR_SCRIPT_EXECUTION_TIMEOUT")
    
    # Recursively search all .jailed.txt files
    for root, dirs, files in os.walk(search_dir):
        for file in files:
            if file.endswith('.jailed.txt'):
                file_path = os.path.join(root, file)
                processed_count += 1
                
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if 'ERR_SCRIPT_EXECUTION_TIMEOUT' in content:
                            # Get the original .js file by removing .jailed.txt
                            original_js = file_path.replace('.jailed.txt', '.js')
                            if os.path.exists(original_js):
                                timeout_files.append(original_js)
                            
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
                
                # Progress every 1000 files
                if processed_count % 1000 == 0:
                    print(f"Processed: {processed_count} files, timeouts found: {len(timeout_files)}")
    
    print(f"\nTimeout scan completed!")
    print(f".jailed.txt files processed: {processed_count}")
    print(f"Original JS files with timeout: {len(timeout_files)}")
    
    if output_file and timeout_files:
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                for file_path in sorted(timeout_files):
                    f.write(f"{file_path}\n")
            print(f"Timeout files saved in: {output_file}")
        except Exception as e:
            print(f"Error saving output file: {e}")
    
    return timeout_files

def update_report(report_path, file_status, updated_files):
    """Update the existing report without completely overwriting it"""
    if not updated_files:
        return
    
    # Update the status of modified files
    for filepath, new_status in updated_files.items():
        if filepath in file_status:
            file_status[filepath]['status'] = new_status
    
    # Create a temporary file for safe writing
    temp_file = tempfile.NamedTemporaryFile(mode='w', delete=False, newline='', encoding='utf-8')
    
    try:
        writer = csv.writer(temp_file)
        writer.writerow(["Number", "File", "ExitStatus"])
        
    # Write all records sorted by number
        sorted_records = sorted(file_status.items(), key=lambda x: int(x[1]['number']))
        for filepath, data in sorted_records:
            writer.writerow([data['number'], filepath, data['status']])
        
        temp_file.close()
        
    # Atomically replace the original file
        shutil.move(temp_file.name, report_path)
        print(f"Report updated: {report_path}")
        
    except Exception as e:
    # Clean up the temporary file in case of error
        try:
            os.unlink(temp_file.name)
        except:
            pass
        raise e

def main(target_dir, rescan, timeout_mode, find_timeout_mode, output_file):
    if not target_dir:
        print("Usage: python wstrace.py <target-directory>")
        sys.exit(1)

    if not os.path.exists(target_dir):
        print(f"Error: Target directory {target_dir} does not exist.")
        sys.exit(1)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    report_path = os.path.join(script_dir, "report.csv")

    # find-timeout mode: find and list files with timeout
    if find_timeout_mode:
        find_timeout_files(target_dir, output_file)
        return

    jailme_js = os.path.join(script_dir, "jailme.js")
    if not os.path.isfile(jailme_js):
        print(f"Error: jailme.js not found at {jailme_js}")
        sys.exit(1)

    file_status, failed_files = load_report(report_path)

    # Determine which files to process
    if timeout_mode:
        print("Timeout mode: reprocessing files with ERR_SCRIPT_EXECUTION_TIMEOUT...")
        timeout_files = find_timeout_files(target_dir)
        js_files = timeout_files
        if not js_files:
            print("No files with timeout found.")
            sys.exit(0)
        print(f"Found {len(js_files)} files with timeout to reprocess with doubled timeout.")
        timeout_duration = 120  # Timeout doubled to 120 seconds
        
    elif rescan:
        print("Processing only files with status 'fail'...")
        js_files = failed_files
        if not js_files:
            print("No files with status 'fail' found in the report.")
            sys.exit(0)
        print(f"Found {len(js_files)} files with status 'fail' to reprocess.")
        timeout_duration = 60  # Normal timeout
        
    else:
        print(f"Scanning .js files in: {target_dir}")
        js_files = [
            os.path.join(root, file)
            for root, _, files in os.walk(target_dir)
            for file in files
            if file.endswith(".js") and not file.endswith(".jailed.js")
        ]
        
        # Filter only files not yet successfully processed
        js_files = [f for f in js_files if file_status.get(f, {}).get('status') != 'success']
        timeout_duration = 60  # Normal timeout

    if not js_files:
        print("Nessun file JavaScript da processare.")
        sys.exit(0)

    print(f"Starting jailme.js processing ({len(js_files)} files)...")
    print(f"Timeout set to: {timeout_duration} seconds")

    updated_files = {}
    lock = threading.Lock()
    processed_count = 0
    success_count = 0
    fail_count = 0
    timeout_count = 0

    def process_file(file):
        nonlocal processed_count, success_count, fail_count, timeout_count
        
        output_file = f"{os.path.splitext(file)[0]}.jailed.txt"

        # Skip/reprocessing logic
        current_status = file_status.get(file, {}).get('status')
        
        if not (rescan or timeout_mode) and os.path.isfile(output_file) and current_status != 'fail':
            with lock:
                processed_count += 1
            return
            
        # If we are rescanning or in timeout mode, remove the old output if it exists
        if (rescan or timeout_mode) and os.path.exists(output_file):
            try:
                os.remove(output_file)
            except OSError:
                pass

        try:
            with open(output_file, "w", encoding='utf-8') as jailed_output:
                result = subprocess.run(
                    ["node", jailme_js, file, "-t", "444"],
                    stdout=jailed_output,
                    stderr=subprocess.PIPE,
                    timeout=timeout_duration
                )
            exit_status = "success" if result.returncode == 0 else "fail"
            
        except subprocess.TimeoutExpired:
            exit_status = "fail"
            timeout_count += 1
            # Remove partial output file
            if os.path.exists(output_file):
                os.remove(output_file)
                
        except Exception as e:
            exit_status = "fail"
            # Remove partial output file
            if os.path.exists(output_file):
                os.remove(output_file)

        with lock:
            processed_count += 1
            if exit_status == "success":
                success_count += 1
            else:
                fail_count += 1
                
            # Register only if the status has changed
            current_status = file_status.get(file, {}).get('status')
            if current_status != exit_status:
                updated_files[file] = exit_status

            # Progress reporting every 50 files
            if processed_count % 50 == 0:
                print(f"Progress: {processed_count}/{len(js_files)} - "
                      f"Success: {success_count}, Failed: {fail_count}, Timeout: {timeout_count}")

    # Use a ThreadPoolExecutor with fewer workers to avoid overload
    max_workers = min(4, len(js_files))
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        executor.map(process_file, js_files)

    print(f"\nProcessing completed.")
    print(f"Files processed: {processed_count}")
    print(f"Successes: {success_count}")
    print(f"Failed: {fail_count}")
    print(f"Timeout: {timeout_count}")
    print(f"Files with updated status: {len(updated_files)}")

    # Update the report only if there are changes
    if updated_files:
        update_report(report_path, file_status, updated_files)
    else:
        print("No report update needed.")

if __name__ == "__main__":
    args = parse_arguments()
    main(args.target_dir, args.rescan, args.timeout, args.find_timeout, args.output)