#!/usr/bin/env python3
"""
Duplicate File Detector and Remover

This script finds duplicate files recursively in a directory based on file content (using SHA-256 hashes).
It offers safe deletion with dry-run mode and careful handling of which duplicates to keep vs delete.

Features:
- Uses SHA-256 hashing for accurate content comparison
- Preserves the file with the shortest/simplest name
- Dry-run mode for safe preview
- Handles large files efficiently
- Detailed reporting of what would be deleted
"""

import os
import hashlib
from pathlib import Path
from collections import defaultdict
import sys

def get_file_hash(file_path, chunk_size=8192):
    """Calculate SHA-256 hash of a file."""
    hash_sha256 = hashlib.sha256()
    try:
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(chunk_size), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    except Exception as e:
        print(f"Error hashing {file_path}: {e}")
        return None

def find_duplicates(directory_path, extensions=None):
    """
    Find duplicate files in directory.
    Returns dict: {hash: [list of file paths with that hash]}
    """
    if extensions is None:
        # Common image and video extensions
        extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff', 
                     '.heic', '.heif', '.mp4', '.mov', '.avi', '.mkv', '.webp'}
    
    print(f"Scanning directory: {directory_path}")
    print(f"Looking for extensions: {', '.join(sorted(extensions))}")
    
    hash_to_files = defaultdict(list)
    total_files = 0
    processed_files = 0
    
    directory = Path(directory_path)
    
    # First pass: count files
    all_files = []
    for file_path in directory.rglob("*"):
        if file_path.is_file() and file_path.suffix.lower() in extensions:
            all_files.append(file_path)
    
    total_files = len(all_files)
    print(f"Found {total_files} files to process...")
    
    # Second pass: hash files
    for file_path in all_files:
        processed_files += 1
        if processed_files % 100 == 0 or processed_files == total_files:
            print(f"Progress: {processed_files}/{total_files} files processed")
        
        file_hash = get_file_hash(file_path)
        if file_hash:
            hash_to_files[file_hash].append(file_path)
    
    # Filter to only duplicates
    duplicates = {h: files for h, files in hash_to_files.items() if len(files) > 1}
    
    print(f"\nFound {len(duplicates)} sets of duplicate files")
    return duplicates

def choose_file_to_keep(file_list):
    """
    Choose which file to keep from a list of duplicates.
    Strategy: Keep the file with the shortest path, or if tied, alphabetically first.
    """
    # Sort by path length first, then alphabetically
    sorted_files = sorted(file_list, key=lambda f: (len(str(f)), str(f)))
    return sorted_files[0]

def format_file_size(size_bytes):
    """Convert bytes to human readable format."""
    if size_bytes == 0:
        return "0 B"
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024.0
        i += 1
    return f"{size_bytes:.1f} {size_names[i]}"

def analyze_duplicates(duplicates):
    """Analyze duplicates and determine what to delete."""
    deletion_plan = []
    total_space_to_free = 0
    total_files_to_delete = 0
    
    for file_hash, duplicate_files in duplicates.items():
        if len(duplicate_files) < 2:
            continue
            
        # Choose which file to keep
        keep_file = choose_file_to_keep(duplicate_files)
        delete_files = [f for f in duplicate_files if f != keep_file]
        
        # Calculate space that would be freed
        for delete_file in delete_files:
            try:
                file_size = delete_file.stat().st_size
                total_space_to_free += file_size
                total_files_to_delete += 1
                
                deletion_plan.append({
                    'keep': keep_file,
                    'delete': delete_file,
                    'size': file_size,
                    'hash': file_hash[:12]  # First 12 chars of hash for reference
                })
            except Exception as e:
                print(f"Error getting size for {delete_file}: {e}")
    
    return deletion_plan, total_space_to_free, total_files_to_delete

def print_deletion_plan(deletion_plan, total_space_to_free, total_files_to_delete):
    """Print what would be deleted."""
    if not deletion_plan:
        print("No duplicates found!")
        return
    
    print(f"\nDUPLICATE ANALYSIS RESULTS:")
    print("=" * 60)
    print(f"Files to delete: {total_files_to_delete}")
    print(f"Space to free: {format_file_size(total_space_to_free)}")
    print()
    
    # Group by hash for cleaner output
    by_hash = defaultdict(list)
    for item in deletion_plan:
        by_hash[item['hash']].append(item)
    
    for hash_prefix, items in by_hash.items():
        print(f"Hash {hash_prefix}... ({len(items)+1} copies found):")
        
        # Show which file we're keeping
        keep_file = items[0]['keep']
        print(f"  KEEP:   {keep_file}")
        
        # Show which files we're deleting
        for item in items:
            size_str = format_file_size(item['size'])
            print(f"  DELETE: {item['delete']} ({size_str})")
        print()

def execute_deletion(deletion_plan, dry_run=True):
    """Execute the deletion plan."""
    if dry_run:
        print("DRY RUN - No files will actually be deleted")
        return
    
    deleted_count = 0
    freed_space = 0
    errors = []
    
    for item in deletion_plan:
        try:
            file_size = item['size']
            item['delete'].unlink()  # Delete the file
            deleted_count += 1
            freed_space += file_size
            print(f"DELETED: {item['delete']}")
        except Exception as e:
            error_msg = f"Failed to delete {item['delete']}: {e}"
            errors.append(error_msg)
            print(f"ERROR: {error_msg}")
    
    print(f"\nDeletion complete!")
    print(f"Files deleted: {deleted_count}")
    print(f"Space freed: {format_file_size(freed_space)}")
    
    if errors:
        print(f"Errors encountered: {len(errors)}")
        for error in errors:
            print(f"  {error}")

def main():
    # Configuration
    target_directory = "/home/aean/Pictures/Samsung Gallery"
    
    # Supported file extensions
    supported_extensions = {
        '.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff',
        '.heic', '.heif', '.webp',
        '.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp'
    }
    
    print("Duplicate File Detector")
    print("=" * 50)
    print(f"Target directory: {target_directory}")
    
    # Check if directory exists
    if not Path(target_directory).exists():
        print(f"Error: Directory {target_directory} does not exist!")
        return 1
    
    # Find duplicates
    print("\nStep 1: Finding duplicates...")
    duplicates = find_duplicates(target_directory, supported_extensions)
    
    if not duplicates:
        print("No duplicates found!")
        return 0
    
    # Analyze what would be deleted
    print("\nStep 2: Analyzing duplicates...")
    deletion_plan, total_space_to_free, total_files_to_delete = analyze_duplicates(duplicates)
    
    # Show the plan
    print_deletion_plan(deletion_plan, total_space_to_free, total_files_to_delete)
    
    if not deletion_plan:
        return 0
    
    # Ask user what to do
    print("\nOptions:")
    print("1. Exit (do nothing)")
    print("2. Show detailed file list")
    print("3. Delete duplicates")
    
    choice = input("\nEnter your choice (1-3): ").strip()
    
    if choice == "2":
        print("\nDetailed file list:")
        print("-" * 80)
        for i, item in enumerate(deletion_plan, 1):
            size_str = format_file_size(item['size'])
            print(f"{i:3d}. DELETE: {item['delete']} ({size_str})")
            print(f"     KEEP:   {item['keep']}")
            print()
        
        choice = input("Delete these files? (y/N): ").lower().strip()
        if choice == 'y':
            execute_deletion(deletion_plan, dry_run=False)
        else:
            print("Cancelled.")
    
    elif choice == "3":
        confirm = input(f"Delete {total_files_to_delete} duplicate files and free {format_file_size(total_space_to_free)}? (y/N): ").lower().strip()
        if confirm == 'y':
            execute_deletion(deletion_plan, dry_run=False)
        else:
            print("Cancelled.")
    
    else:
        print("Exiting without changes.")
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 