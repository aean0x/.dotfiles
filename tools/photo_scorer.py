import os
import shutil
from pathlib import Path
import cv2
import numpy as np
from PIL import Image, ExifTags
import tensorflow as tf

# Enable HEIC support if available
try:
    from pillow_heif import register_heif_opener
    register_heif_opener()
    print("HEIC support enabled")
except ImportError:
    print("Warning: pillow-heif not installed, HEIC files may not be processed correctly")
    print("Install with: pip install pillow-heif")

# Define paths relative to the script's location
script_dir = os.path.dirname(os.path.abspath(__file__))
east_model_path = os.path.join(script_dir, "frozen_east_text_detection.pb")
nima_model_path = os.path.join(script_dir, "mobilenet_weights.h5")
face_cascade_path = os.path.join(script_dir, "haarcascade_frontalface_default.xml")

# Check if model files exist (make NIMA optional)
required_models = [(east_model_path, "EAST model")]
optional_models = [(face_cascade_path, "Face cascade")]
for path, name in required_models:
    if not os.path.exists(path):
        print(f"Error: {name} file not found at {path}")
        exit(1)

# Download DNN face detection model if not present
dnn_face_model_path = os.path.join(script_dir, "opencv_face_detector_uint8.pb")
dnn_face_config_path = os.path.join(script_dir, "opencv_face_detector.pbtxt")

def download_dnn_face_model():
    """Download OpenCV DNN face detection model if not present."""
    import urllib.request
    
    model_url = "https://raw.githubusercontent.com/opencv/opencv_3rdparty/dnn_samples_face_detector_20180220_uint8/opencv_face_detector_uint8.pb"
    config_url = "https://raw.githubusercontent.com/opencv/opencv/master/samples/dnn/face_detector/opencv_face_detector.pbtxt"
    
    if not os.path.exists(dnn_face_model_path):
        print("Downloading DNN face detection model...")
        urllib.request.urlretrieve(model_url, dnn_face_model_path)
        print("Model downloaded successfully")
    
    if not os.path.exists(dnn_face_config_path):
        print("Downloading DNN face detection config...")
        urllib.request.urlretrieve(config_url, dnn_face_config_path)
        print("Config downloaded successfully")

# Download DNN models if needed
download_dnn_face_model()

# Define paths
input_folder = Path("/home/aean/Pictures/Samsung Gallery")
keep_folder = input_folder / "keep"
delete_folder = input_folder / "delete"
review_folder = input_folder / "review"

# Create folders if they don't exist
for folder in [keep_folder, delete_folder, review_folder]:
    folder.mkdir(exist_ok=True)

# Define thresholds (adjust as needed)
blurriness_threshold = 100  # Lower means blurrier
text_area_threshold = 0.08   # Fraction of image with text - more liberal detection
high_text_threshold = 0.20   # Lots of text = instant delete (charts, documents, memes)
screenshot_text_threshold = 0.15  # Lower threshold for screenshot detection
min_image_size = 100  # Minimum dimension to avoid tiny images

# Global model variables - load once at startup
face_cascade = None
dnn_face_net = None
east_net = None

def load_image_for_opencv(image_path):
    """Load any image file (including HEIC) and return OpenCV-compatible format."""
    file_extension = Path(image_path).suffix.lower()
    
    if file_extension in ['.heic', '.heif']:
        # Convert HEIC to OpenCV format
        try:
            from PIL import Image
            import numpy as np
            with Image.open(image_path) as pil_image:
                if pil_image.mode != 'RGB':
                    pil_image = pil_image.convert('RGB')
                # Convert PIL image to OpenCV format (BGR)
                return cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
        except Exception as e:
            print(f"Error loading HEIC file {image_path}: {e}")
            return None
    else:
        # Use standard OpenCV loading for other formats
        return cv2.imread(image_path)

def initialize_models():
    """Initialize all models once at startup."""
    global face_cascade, dnn_face_net, east_net
    
    print("Initializing models...")
    
    # Skip NIMA model for now due to architecture issues
    print("Skipping NIMA model (architecture mismatch)")
    
    # Initialize DNN face detection (preferred)
    try:
        dnn_face_net = cv2.dnn.readNetFromTensorflow(dnn_face_model_path, dnn_face_config_path)
        print("DNN face detection model loaded successfully")
    except Exception as e:
        print(f"Warning: Could not load DNN face model: {e}")
        dnn_face_net = None
        
        # Fallback to Haar cascade if DNN fails
        try:
            face_cascade = cv2.CascadeClassifier(face_cascade_path)
            print("Fallback: Face cascade loaded successfully")
        except Exception as e:
            print(f"Warning: Could not load face cascade either: {e}")
            face_cascade = None
    
    # Initialize EAST network
    try:
        east_net = cv2.dnn.readNet(east_model_path)
        print("EAST model loaded successfully")
    except Exception as e:
        print(f"Warning: Could not load EAST model: {e}")
        east_net = None

def is_blurry(image_path, threshold=100):
    """Detect if image is blurry using Laplacian variance."""
    try:
        image = load_image_for_opencv(image_path)
        if image is None:
            return True
        
        # Check if image is too small
        h, w = image.shape[:2]
        if h < min_image_size or w < min_image_size:
            return True
            
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        variance = cv2.Laplacian(gray, cv2.CV_64F).var()
        return variance < threshold
    except Exception as e:
        print(f"Error checking blurriness for {image_path}: {e}")
        return True

def is_screenshot_aspect_ratio(image_path):
    """Detect common screenshot aspect ratios."""
    try:
        with Image.open(image_path) as img:
            width, height = img.size
            aspect_ratio = width / height
            
            # Common phone screenshot ratios (portrait and landscape)
            screenshot_ratios = [
                (9/16, 16/9),   # Common phone ratios
                (9/18, 18/9),   # Tall phones
                (2/3, 3/2),     # Some tablets
                (4/3, 3/4),     # Old tablets
            ]
            
            tolerance = 0.1
            for portrait, landscape in screenshot_ratios:
                if (abs(aspect_ratio - portrait) < tolerance or 
                    abs(aspect_ratio - landscape) < tolerance):
                    return True
            return False
    except Exception as e:
        return False

def has_exif_data(image_path):
    """Check if image has camera EXIF data (suggests it's a real photo)."""
    try:
        with Image.open(image_path) as img:
            # Use the newer getexif() method which works better with HEIC
            exif = img.getexif()
            if not exif:
                return False
            
            # Look for camera-specific EXIF tags (using tag IDs)
            camera_tag_ids = [
                271,  # Make
                272,  # Model  
                306,  # DateTime
                33434, # ExposureTime
                33437, # FNumber
                34855, # ISOSpeedRatings
                37385, # Flash
                274,  # Orientation (common in phone photos)
                36867, # DateTimeOriginal
                36868, # DateTimeDigitized
            ]
            
            # Check if any camera-specific tags exist
            for tag_id in camera_tag_ids:
                if tag_id in exif:
                    return True
            
            # Additional check: if we have any EXIF data and it's a HEIC file from iOS,
            # it's very likely a real photo
            file_extension = Path(image_path).suffix.lower()
            if file_extension in ['.heic', '.heif'] and len(exif) > 5:
                # HEIC files with substantial EXIF are almost certainly real photos
                return True
                
            return False
    except Exception as e:
        print(f"Error reading EXIF from {image_path}: {e}")
        return False

def get_text_area(image_path):
    """Calculate fraction of image covered by text using EAST model."""
    global east_net
    
    if east_net is None:
        return 0.0
        
    try:
        image = load_image_for_opencv(image_path)
        if image is None:
            return 0.0
        orig_h, orig_w = image.shape[:2]
        new_w, new_h = 320, 320
        rW = orig_w / float(new_w)
        rH = orig_h / float(new_h)
        image_resized = cv2.resize(image, (new_w, new_h))
        
        blob = cv2.dnn.blobFromImage(image_resized, 1.0, (new_w, new_h),
                                     (123.68, 116.78, 103.94), swapRB=True, crop=False)
        east_net.setInput(blob)
        (scores, geometry) = east_net.forward(["feature_fusion/Conv_7/Sigmoid", "feature_fusion/concat_3"])
        
        rectangles = []
        confidences = []
        for i in range(scores.shape[2]):
            for j in range(scores.shape[3]):
                if scores[0, 0, i, j] > 0.5:
                    # Geometry: top-left (x1,y1), bottom-right (x2,y2)
                    data = geometry[0, :, i, j]
                    if len(data) < 4:
                        continue
                    x1, y1, x2, y2 = data[:4]
                    x = int(j * 4.0 * rW)
                    y = int(i * 4.0 * rH)
                    w = int(x2 * rW)
                    h = int(y2 * rH)
                    rectangles.append((x, y, x + w, y + h))
                    confidences.append(float(scores[0, 0, i, j]))
        
        if not rectangles:
            return 0.0
            
        indices = cv2.dnn.NMSBoxes(rectangles, confidences, 0.5, 0.3)
        
        total_text_area = 0
        if len(indices) > 0:
            # Handle both old and new OpenCV versions
            if isinstance(indices, np.ndarray):
                indices = indices.flatten()
            else:
                indices = [indices] if not isinstance(indices, (list, tuple)) else indices
            
            for i in indices:
                (x1, y1, x2, y2) = rectangles[i]
                area = (x2 - x1) * (y2 - y1)
                total_text_area += area
        
        image_area = orig_w * orig_h
        text_ratio = total_text_area / image_area if image_area > 0 else 0
        return text_ratio
    except Exception as e:
        print(f"Error detecting text for {image_path}: {e}")
        return 0.0

def has_faces(image_path):
    """Detect if image contains faces using modern DNN face detection."""
    global face_cascade, dnn_face_net
    
    try:
        image = load_image_for_opencv(image_path)
        if image is None:
            return False
        
        # Try DNN face detection first (much more accurate)
        if dnn_face_net is not None:
            return detect_faces_dnn(image, image_path)
        
        # Fallback to Haar cascade if DNN not available
        elif face_cascade is not None:
            return detect_faces_haar_cascade(image, image_path)
        
        else:
            print(f"No face detection models available")
            return False
            
    except Exception as e:
        print(f"Error detecting faces for {image_path}: {e}")
        return False

def detect_faces_dnn(image, image_path):
    """Detect faces using OpenCV DNN model (much more accurate)."""
    global dnn_face_net
    
    h, w = image.shape[:2]
    
    # Create blob from image
    blob = cv2.dnn.blobFromImage(image, 1.0, (300, 300), [104, 117, 123])
    dnn_face_net.setInput(blob)
    detections = dnn_face_net.forward()
    
    faces = []
    confidence_threshold = 0.5  # Confidence threshold for face detection
    
    for i in range(detections.shape[2]):
        confidence = detections[0, 0, i, 2]
        
        if confidence > confidence_threshold:
            # Get bounding box coordinates
            x1 = int(detections[0, 0, i, 3] * w)
            y1 = int(detections[0, 0, i, 4] * h)
            x2 = int(detections[0, 0, i, 5] * w)
            y2 = int(detections[0, 0, i, 6] * h)
            
            # Convert to width/height format
            face_w = x2 - x1
            face_h = y2 - y1
            
            # Basic sanity checks
            if face_w > 10 and face_h > 10:
                faces.append((x1, y1, face_w, face_h, confidence))
    
    # Debug output
    if len(faces) > 0:
        print(f"    DEBUG: DNN detected {len(faces)} faces in {Path(image_path).name}")
        for i, (x, y, w, h, conf) in enumerate(faces):
            print(f"      Face {i+1}: size={w}x{h}, confidence={conf:.3f}")
    
    return len(faces) > 0

def detect_faces_haar_cascade(image, image_path):
    """Fallback face detection using Haar cascade."""
    global face_cascade
    
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Use moderate settings for Haar cascade
    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(30, 30),
        flags=cv2.CASCADE_SCALE_IMAGE
    )
    
    # Debug output
    if len(faces) > 0:
        print(f"    DEBUG: Haar cascade detected {len(faces)} faces in {Path(image_path).name}")
        for i, (x, y, w, h) in enumerate(faces):
            print(f"      Face {i+1}: size={w}x{h}")
    
    return len(faces) > 0

def classify_image(image_path):
    """Classify image into keep, delete, or review categories."""
    
    # Get all the detection results first
    has_face = has_faces(str(image_path))
    text_ratio = get_text_area(str(image_path))
    is_screenshot = is_screenshot_aspect_ratio(str(image_path))
    has_camera_exif = has_exif_data(str(image_path))
    is_image_blurry = is_blurry(str(image_path), blurriness_threshold)
    
    # Debug output to see what each detection returns
    print(f"    DEBUG: faces={has_face}, exif={has_camera_exif}, text={text_ratio:.3f}, blurry={is_image_blurry}")
    
    # PRIORITY 1: Faces take precedence over everything
    # If has faces and camera EXIF -> definitely keep (even if blurry)
    if has_face and has_camera_exif:
        if is_image_blurry:
            return "keep", "faces + camera EXIF (blurry but keeping)"
        else:
            return "keep", "faces + camera EXIF"
    
    # If has faces but no EXIF -> review (even if blurry)
    if has_face and not has_camera_exif:
        if is_image_blurry:
            return "review", "faces but no camera EXIF (blurry)"
        else:
            return "review", "faces but no camera EXIF"
    
    # PRIORITY 2: Very high text content = instant delete (even with faces, unless EXIF)
    if text_ratio > high_text_threshold:
        if has_face and has_camera_exif:
            return "keep", f"high text but faces + EXIF ({text_ratio:.3f})"
        else:
            return "delete", f"high text content ({text_ratio:.3f})"
    
    # PRIORITY 3: No faces - check for blurriness
    if is_image_blurry:
        return "delete", "blurry (no faces)"
    
    # PRIORITY 4: Screenshots and moderate text content
    # If moderate text content AND screenshot aspect ratio -> likely screenshot -> review
    if text_ratio > screenshot_text_threshold and is_screenshot:
        return "review", f"screenshot (text: {text_ratio:.3f})"
    
    # If moderate text content regardless -> review (documents, memes)
    if text_ratio > text_area_threshold:
        return "review", f"moderate text ({text_ratio:.3f})"
    
    # PRIORITY 5: Camera EXIF data (no faces, not blurry) -> review for manual inspection
    if has_camera_exif:
        return "review", "camera EXIF (no faces)"
    
    # PRIORITY 6: Everything else goes to review for manual inspection
    if text_ratio < 0.05:
        return "review", "no faces/EXIF, minimal text"
    else:
        return "review", "default case"

# Initialize models once at startup
initialize_models()

# Process only top-level images in the input folder
processed_count = 0
for image_path in input_folder.rglob("*.*"):
    if image_path.suffix.lower() not in [
        ".jpg",
        ".jpeg",
        ".png",
        ".bmp",
        ".tif",
        ".tiff",
        ".heic",
        ".heif",
    ]:
        continue
    
    if any(folder.name in [part.name for part in image_path.parents] for folder in [keep_folder, delete_folder, review_folder]):
        continue
    
    processed_count += 1
    print(f"Processing ({processed_count}) {image_path.name}")
    
    category, reason = classify_image(image_path)
    
    if category == "delete":
        destination = delete_folder
    elif category == "keep":
        destination = keep_folder
    else:  # review
        destination = review_folder
    
    try:
        shutil.move(str(image_path), str(destination / image_path.name))
        print(f"  -> {category}: {reason}")
    except Exception as e:
        print(f"  -> Error moving file: {e}")

print(f"\nProcessed {processed_count} images total")