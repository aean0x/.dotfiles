#!/usr/bin/env python3
"""
Script to truncate filenames by removing everything starting from "_1" suffix.
This removes artifacts left over from another script.

Example:
  IMG_20210221_103302_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1.jpg
  becomes:
  IMG_20210221_103302.jpg
"""

import os
from pathlib import Path
import re

def truncate_filename(filename):
    """Remove everything starting from the artifact pattern of multiple '_1' suffixes."""
    # Look for pattern of '_1' followed by more '_1' patterns (the actual artifact)
    # This matches '_1_1' or longer chains, but not isolated '_1' that might be legitimate
    match = re.search(r'(_1_1+.*)', filename)
    if match:
        # Keep everything before the artifact pattern starts
        base_part = filename[:match.start()]
        # Keep the file extension
        extension = Path(filename).suffix
        return base_part + extension
    return filename

def truncate_filenames_in_directory(directory_path, dry_run=True):
    """Recursively truncate filenames in the given directory."""
    directory = Path(directory_path)
    
    if not directory.exists():
        print(f"Directory {directory_path} does not exist!")
        return
    
    renamed_count = 0
    skipped_count = 0
    
    # Process all files recursively
    for file_path in directory.rglob("*"):
        if file_path.is_file():
            original_name = file_path.name
            new_name = truncate_filename(original_name)
            
            if new_name != original_name:
                new_path = file_path.parent / new_name
                
                # Check if target already exists
                if new_path.exists():
                    print(f"SKIP (target exists): {original_name} -> {new_name}")
                    skipped_count += 1
                    continue
                
                if dry_run:
                    print(f"WOULD RENAME: {original_name} -> {new_name}")
                else:
                    try:
                        file_path.rename(new_path)
                        print(f"RENAMED: {original_name} -> {new_name}")
                    except Exception as e:
                        print(f"ERROR renaming {original_name}: {e}")
                        continue
                
                renamed_count += 1
    
    print(f"\nSummary:")
    print(f"Files to rename: {renamed_count}")
    print(f"Files skipped: {skipped_count}")
    
    if dry_run:
        print(f"\nThis was a DRY RUN. Run with dry_run=False to actually rename files.")

if __name__ == "__main__":
    # Directory to process
    camera_roll_dir = "/home/aean/Pictures/Camera Roll"
    
    print("Filename Truncation Script")
    print("=" * 50)
    print(f"Target directory: {camera_roll_dir}")
    print()
    
    # Test a few examples first
    test_names = [
        "IMG_20210221_103302_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1.jpg",
        "20210915_231534720_iOS_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1.jpg",
        "normal_filename.jpg",
        "another_file_without_suffix.png",
        "legitimate_file_1.jpg",  # Should NOT be truncated
        "another_legitimate_1_version.png",  # Should NOT be truncated
        "IMG_20130626_095550_1_1_1_1_1.jpg"  # Should be truncated
    ]
    
    print("Testing filename truncation:")
    for name in test_names:
        truncated = truncate_filename(name)
        print(f"  {name} -> {truncated}")
    print()
    
    # Ask user if they want to proceed
    response = input("Do you want to run a DRY RUN first? (y/n): ").lower().strip()
    if response == 'y':
        print("\nRunning DRY RUN...")
        truncate_filenames_in_directory(camera_roll_dir, dry_run=True)
        
        response = input("\nDo you want to proceed with actual renaming? (y/n): ").lower().strip()
        if response == 'y':
            print("\nProceeding with actual renaming...")
            truncate_filenames_in_directory(camera_roll_dir, dry_run=False)
        else:
            print("Cancelled.")
    else:
        print("Skipping dry run and proceeding directly...")
        response = input("Are you sure you want to rename files without preview? (y/n): ").lower().strip()
        if response == 'y':
            truncate_filenames_in_directory(camera_roll_dir, dry_run=False)
        else:
            print("Cancelled.") 