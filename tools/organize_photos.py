#!nix-shell
#!nix-shell -i python3 -p python3 python3Packages.exifread python3Packages.pillow

import os
import shutil
from datetime import datetime
from pathlib import Path
import exifread
from PIL import Image

def get_media_date(file_path):
    """Get the creation date of a media file from file modified date first, then EXIF data or other metadata."""
    try:
        # First try to get file modified date
        return datetime.fromtimestamp(os.path.getmtime(file_path))
    except:
        pass

    try:
        # Fallback to EXIF data for images
        if file_path.suffix.lower() in {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.dng', '.heic', '.heif'}:
            with open(file_path, 'rb') as f:
                tags = exifread.process_file(f)
                if 'EXIF DateTimeOriginal' in tags:
                    date_str = str(tags['EXIF DateTimeOriginal'])
                    return datetime.strptime(date_str, '%Y:%m:%d %H:%M:%S')
                elif 'Image DateTime' in tags:
                    date_str = str(tags['Image DateTime'])
                    return datetime.strptime(date_str, '%Y:%m:%d %H:%M:%S')
    except:
        pass

    try:
        # Try to get date from file metadata for images using PIL
        if file_path.suffix.lower() in {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.dng', '.heic', '.heif'}:
            image = Image.open(file_path)
            if hasattr(image, '_getexif') and image._getexif():
                exif = image._getexif()
                if 36867 in exif:  # DateTimeOriginal
                    date_str = exif[36867]
                    return datetime.strptime(date_str, '%Y:%m:%d %H:%M:%S')
    except:
        pass

    # For videos and files without EXIF data, try to get date from filename
    try:
        # Common video filename patterns
        filename = file_path.stem.lower()
        if any(pattern in filename for pattern in ['_', '-']):
            # Try to extract date from filename patterns like IMG_20200101_123456
            parts = filename.replace('_', '-').replace('.', '-').split('-')
            for part in parts:
                if len(part) == 8 and part.isdigit():
                    return datetime.strptime(part, '%Y%m%d')
    except:
        pass

    # Final fallback to file creation time
    return datetime.fromtimestamp(os.path.getctime(file_path))

def find_media_files(directory):
    """Recursively find all media files in the directory and its subdirectories."""
    image_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp'}
    video_extensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm'}
    raw_extensions = {'.dng', '.heic', '.heif'}
    all_extensions = image_extensions | video_extensions | raw_extensions
    
    media_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            file_path = Path(root) / file
            if file_path.suffix.lower() in all_extensions:
                media_files.append(file_path)
    return media_files

def organize_media(source_dir):
    """Organize media files into year/month folders based on their creation date."""
    source_path = Path(source_dir)
    
    # Find all media files recursively
    files = find_media_files(source_path)
    
    for file_path in files:
        try:
            # Get the creation date
            date = get_media_date(file_path)
            year = str(date.year)
            month = f"{date.month:02d}"  # Format month as two digits
            
            # Create year/month directory if it doesn't exist
            target_dir = source_path / year / month
            target_dir.mkdir(parents=True, exist_ok=True)
            
            # Move the file to the appropriate directory
            destination = target_dir / file_path.name
            if destination.exists():
                # If file already exists, add a number to the filename
                base = file_path.stem
                suffix = file_path.suffix
                counter = 1
                while destination.exists():
                    new_name = f"{base}_{counter}{suffix}"
                    destination = target_dir / new_name
                    counter += 1
            
            shutil.move(str(file_path), str(destination))
            print(f"Moved {file_path.name} to {year}/{month}/")
            
        except Exception as e:
            print(f"Error processing {file_path.name}: {str(e)}")

if __name__ == "__main__":
    source_directory = "/home/aean/Pictures/Samsung Gallery"
    organize_media(source_directory) 