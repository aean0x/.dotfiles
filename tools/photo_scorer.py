#!/usr/bin/env python3

import os
from pathlib import Path
import torch
from torchvision import models, transforms
from PIL import Image
import face_recognition
import numpy as np
from datetime import datetime
import shutil
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

class PhotoScorer:
    def __init__(self):
        # Initialize the model with explicit CUDA settings
        if not torch.cuda.is_available():
            logging.warning("CUDA is not available. Please check your PyTorch installation and NVIDIA drivers.")
        else:
            logging.info("CUDA is available. Enabling GPU acceleration.")
            # Force CUDA device selection
            torch.cuda.set_device(0)
            # Enable CUDA optimizations
            torch.backends.cudnn.benchmark = True
            torch.backends.cuda.matmul.allow_tf32 = True
            torch.backends.cudnn.allow_tf32 = True
        
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logging.info(f"Using device: {self.device}")
        
        # Initialize model with explicit weights
        self.model = models.resnet50(weights=models.ResNet50_Weights.IMAGENET1K_V1)
        self.model = self.model.to(self.device)
        self.model.eval()

        # Image preprocessing
        self.transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            )
        ])

        # Load ImageNet class names
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'imagenet_classes.txt')) as f:
            self.categories = [s.strip() for s in f.readlines()]

        # Define important categories (positive and negative)
        self.positive_categories = {
            'person', 'people', 'human', 'face', 'portrait', 'family', 'group',
            'wedding', 'event', 'celebration', 'vacation', 'travel', 'landscape',
            'nature', 'animal', 'pet', 'baby', 'child', 'building', 'architecture',
            'food', 'dish', 'meal', 'art', 'painting', 'drawing', 'sculpture',
            # Animals and pets (comprehensive)
            'dog', 'puppy', 'cat', 'kitten', 'horse', 'bird', 'fish', 'rabbit',
            'hamster', 'guinea pig', 'ferret', 'parrot', 'canary', 'goldfish',
            'Chihuahua', 'beagle', 'golden retriever', 'Labrador retriever', 'German shepherd',
            'bulldog', 'poodle', 'husky', 'dalmatian', 'collie', 'boxer', 'basset',
            'Persian cat', 'Siamese cat', 'tabby', 'tiger cat', 'Egyptian cat',
            # Musical instruments
            'microphone', 'mike', 'harmonica', 'mouth organ', 'harp', 'mouth harp',
            'drumstick', 'guitar', 'piano', 'violin', 'trumpet', 'saxophone',
            'drum', 'flute', 'music', 'concert', 'performance', 'stage', 'accordion',
            'acoustic guitar', 'electric guitar', 'banjo', 'bassoon', 'cello',
            'French horn', 'grand piano', 'marimba', 'xylophone', 'oboe', 'organ',
            'trombone', 'sax', 'violin', 'fiddle',
            # Sports and recreation
            'basketball', 'baseball', 'football helmet', 'golf ball', 'tennis ball',
            'soccer ball', 'volleyball', 'rugby ball', 'ping-pong ball', 'hockey puck',
            # Food items
            'pizza', 'burger', 'hotdog', 'ice cream', 'cake', 'fruit', 'vegetable',
            'strawberry', 'orange', 'banana', 'apple', 'pineapple', 'lemon',
            # Wildlife and nature
            'elephant', 'lion', 'tiger', 'bear', 'deer', 'zebra', 'giraffe',
            'eagle', 'owl', 'dolphin', 'whale', 'butterfly', 'flower', 'tree'
        }
        
        # Categories that indicate human presence (bodies, clothing, etc.)
        self.human_presence_categories = {
            'person', 'people', 'human', 'face', 'portrait', 'man', 'woman',
            'boy', 'girl', 'child', 'baby', 'adult', 'body', 'torso',
            'clothing', 'shirt', 'dress', 'jacket', 'coat', 'pants',
            'shoes', 'hat', 'sunglasses', 'glasses', 'hair', 'hand',
            'arm', 'leg', 'foot', 'head', 'shoulder', 'maillot', 'bikini',
            'two-piece', 'miniskirt', 'mini', 'academic gown', 'robe',
            'wig', 'mask', 'costume', 'uniform', 'suit', 'fur coat',
            'dark glasses', 'shades', 'seat belt', 'seatbelt', 'hair spray',
            'sweater', 'pullover', 'cardigan', 'hoodie', 'jeans', 'shorts',
            # Additional clothing and accessories from ImageNet
            'abaya', 'apron', 'backpack', 'brassiere', 'bra', 'bandeau',
            'bulletproof vest', 'cardigan', 'cloak', 'clog', 'cowboy boot',
            'cowboy hat', 'crash helmet', 'gown', 'handkerchief', 'holster',
            'jersey', 'T-shirt', 'tee shirt', 'jean', 'blue jean', 'denim',
            'kimono', 'knee pad', 'lab coat', 'Loafer', 'military uniform',
            'mitten', 'muzzle', 'neck brace', 'necklace', 'overskirt',
            'pajama', 'pyjama', 'poncho', 'purse', 'sandal', 'sarong',
            'shoe shop', 'shower cap', 'ski mask', 'sock', 'sombrero',
            'stole', 'sweatshirt', 'swimming trunks', 'bathing trunks',
            'thimble', 'vestment', 'wallet', 'Windsor tie', 'mortarboard'
        }

        # Expanded negative categories for low-context photos
        self.negative_categories = {
            'document', 'text', 'screenshot', 'meme', 'furniture', 'object',
            'product', 'advertisement', 'logo', 'icon', 'interface', 'toilet',
            'trash', 'garbage', 'waste', 'rubbish', 'screen', 'CRT screen',
            'web site', 'website', 'internet site', 'site', 'menu', 'envelope',
            'oscilloscope', 'scope', 'cathode-ray oscilloscope', 'CRO',
            'part', 'component', 'detail', 'close-up', 'macro', 'fragment',
            'monitor', 'computer screen', 'laptop', 'smartphone', 'tablet',
            'display', 'receipt', 'invoice', 'form', 'paper', 'notebook',
            'clipboard', 'whiteboard', 'blackboard', 'chart', 'graph',
            # Additional tech/document items from ImageNet
            'desktop computer', 'computer keyboard', 'keypad', 'dial telephone',
            'digital clock', 'digital watch', 'disk brake', 'electric fan',
            'typewriter keyboard', 'hand-held computer', 'laptop computer',
            'notebook computer', 'mouse', 'computer mouse', 'modem', 'monitor',
            'cellular telephone', 'cellular phone', 'cellphone', 'cell',
            'mobile phone', 'iPod', 'remote control', 'remote', 'photocopier',
            'printer', 'projector', 'radio telescope', 'radio reflector',
            'cassette', 'cassette player', 'CD player', 'tape player',
            'television', 'television system', 'loudspeaker', 'speaker',
            'microwave', 'microwave oven', 'abacus', 'cash machine',
            'automated teller machine', 'ATM', 'combination lock',
            'crossword puzzle', 'crossword', 'jigsaw puzzle', 'book jacket',
            'dust cover', 'comic book', 'menu', 'plate', 'toilet tissue',
            'toilet paper', 'bathroom tissue'
        }

        # Categories that require good context (vehicles and transportation)
        self.context_required_categories = {
            'car', 'truck', 'bus', 'motorcycle', 'bicycle', 'vehicle',
            'boat', 'ship', 'airplane', 'aircraft', 'train', 'locomotive',
            'building', 'house', 'architecture', 'structure', 'minivan',
            'minibus', 'police van', 'police wagon', 'paddy wagon', 'patrol wagon',
            'wagon', 'black maria', 'van', 'jeep', 'landrover', 'suv',
            'pickup truck', 'taxi', 'taxicab', 'cab', 'hack', 'limousine',
            'ambulance', 'fire truck', 'fire engine', 'school bus',
            # Additional vehicles from ImageNet
            'aircraft carrier', 'airliner', 'airship', 'dirigible', 'amphibian',
            'beach wagon', 'station wagon', 'estate car', 'beach waggon',
            'station waggon', 'waggon', 'bobsled', 'bobsleigh', 'bob',
            'bullet train', 'bullet', 'canoe', 'catamaran', 'convertible',
            'dogsled', 'dog sled', 'dog sleigh', 'forklift', 'freight car',
            'garbage truck', 'dustcart', 'go-kart', 'golfcart', 'golf cart',
            'gondola', 'half track', 'jinrikisha', 'ricksha', 'rickshaw',
            'liner', 'ocean liner', 'limousine', 'limo', 'Model T', 'moped',
            'motor scooter', 'scooter', 'mountain bike', 'moving van',
            'oxcart', 'passenger car', 'coach', 'carriage', 'pickup',
            'pickup truck', 'police van', 'recreational vehicle', 'RV',
            'schooner', 'snowmobile', 'snowplow', 'speedboat', 'sports car',
            'steam locomotive', 'streetcar', 'tram', 'tramcar', 'trolley',
            'submarine', 'tank', 'tow truck', 'tow car', 'wrecker',
            'trailer truck', 'tractor trailer', 'trucking rig', 'rig',
            'tricycle', 'trike', 'trimaran', 'trolleybus', 'unicycle',
            'warplane', 'military plane', 'yawl'
        }

    def detect_faces(self, image_path):
        """Detect faces in the image and return the number of faces."""
        try:
            image = face_recognition.load_image_file(image_path)
            face_locations = face_recognition.face_locations(image)
            return len(face_locations)
        except Exception as e:
            logging.warning(f"Error detecting faces in {image_path}: {e}")
            return 0



    def get_image_quality_score(self, image):
        """Calculate a basic image quality score based on sharpness and contrast."""
        try:
            # Convert to grayscale
            gray = image.convert('L')
            # Calculate sharpness using Laplacian variance
            laplacian = np.array(gray).astype(np.float32)
            laplacian = np.abs(np.gradient(laplacian)[0]) + np.abs(np.gradient(laplacian)[1])
            sharpness = np.var(laplacian)
            
            # Calculate contrast
            contrast = np.std(np.array(gray))
            
            # Combine scores with adjusted thresholds
            quality_score = (sharpness * 0.4 + contrast * 0.6) / 900  # Adjusted divisor
            return min(quality_score, 1.0)
        except Exception as e:
            logging.warning(f"Error calculating image quality: {e}")
            return 0.35  # Adjusted default score

    def analyze_image(self, image_path):
        """Analyze an image and return a score and category."""
        try:
            # Load and preprocess image
            image = Image.open(image_path).convert('RGB')
            input_tensor = self.transform(image)
            input_batch = input_tensor.unsqueeze(0).to(self.device)

            # Get model predictions
            with torch.no_grad():
                output = self.model(input_batch)
                probabilities = torch.nn.functional.softmax(output[0], dim=0)
                
            # Get top 5 predictions
            top5_prob, top5_catid = torch.topk(probabilities, 5)
            
            # Convert predictions to categories
            categories = [self.categories[catid] for catid in top5_catid]
            probs = top5_prob.cpu().numpy()

            # Detect faces first
            num_faces = self.detect_faces(image_path)
            
            # Get image quality score
            quality_score = self.get_image_quality_score(image)

            # Check for auto-delete conditions first (screenshots/documents) - VERY AGGRESSIVE
            auto_delete_score = 0
            screen_keywords = {'web site', 'website', 'internet site', 'site', 'menu', 'screen', 'CRT screen', 'monitor', 'display'}
            
            for cat, prob in zip(categories, probs):
                if cat in self.negative_categories and prob > 0.2:  # Even lower threshold
                    auto_delete_score += prob
                    # Extra penalty for obvious screen/website content
                    if cat in screen_keywords and prob > 0.4:
                        auto_delete_score += prob * 0.5  # Boost screen detection
            
            # Auto-delete for clear screenshots/documents - VERY AGGRESSIVE  
            if auto_delete_score > 0.25:  # Much lower threshold for auto-delete
                logging.info(f"AUTO-DELETE triggered: screenshot/document detected (confidence: {auto_delete_score:.2f})")
                return {
                    'score': 0.05,  # Even lower score for auto-delete
                    'categories': categories,
                    'num_faces': num_faces,
                    'quality_score': quality_score
                }

            # Check for human presence (faces OR body parts/clothing) - VERY LENIENT
            human_presence_score = 0
            for cat, prob in zip(categories, probs):
                if cat in self.human_presence_categories and prob > 0.15:  # Lower threshold
                    human_presence_score += prob
            
            # Check for auto-keep conditions (faces OR human presence) - EXTREMELY LENIENT
            if (num_faces > 0) or (human_presence_score > 0.3):  # No quality requirement for human presence
                if num_faces > 0:
                    logging.info(f"AUTO-KEEP triggered: faces detected ({num_faces} faces, quality: {quality_score:.2f})")
                else:
                    logging.info(f"AUTO-KEEP triggered: human presence detected (confidence: {human_presence_score:.2f}, quality: {quality_score:.2f})")
                return {
                    'score': 0.85,  # High score for auto-keep
                    'categories': categories,
                    'num_faces': num_faces,
                    'quality_score': quality_score
                }

            # Check for vehicle photos - EXTREMELY LENIENT
            vehicle_score = 0
            has_vehicle = False
            for cat, prob in zip(categories, probs):
                if cat in self.context_required_categories and prob > 0.2:  # Even lower threshold
                    vehicle_score += prob
                    has_vehicle = True

            # MASSIVE BUFF for vehicle images - EXTREMELY LENIENT
            if has_vehicle and vehicle_score > 0.25:  # Removed quality requirement entirely
                logging.info(f"VEHICLE-BOOST triggered: vehicle detected (confidence: {vehicle_score:.2f}, quality: {quality_score:.2f})")
                return {
                    'score': 0.80,  # Even higher score for vehicles
                    'categories': categories,
                    'num_faces': num_faces,
                    'quality_score': quality_score
                }

            # Calculate base score from categories with adjusted weights
            category_score = 0
            has_human = False
            has_context_required = False
            
            for cat, prob in zip(categories, probs):
                if cat in self.positive_categories:
                    category_score += prob * 1.5
                    if 'person' in cat or 'human' in cat or 'face' in cat:
                        has_human = True
                elif cat in self.negative_categories:
                    category_score -= prob * 1.8  # Adjusted negative weight
                if cat in self.context_required_categories:
                    has_context_required = True

            # Face detection score with higher weight
            face_score = min(num_faces * 0.8, 1.0)

            # Calculate final score with adjusted weights
            if has_human or num_faces > 0:
                # Human photos get more lenient scoring
                final_score = (
                    category_score * 0.2 +
                    face_score * 0.7 +
                    quality_score * 0.1
                )
            else:
                # Non-human photos need better quality and context
                context_penalty = 0.4 if has_context_required and quality_score < 0.55 else 0  # Adjusted penalty
                final_score = (
                    category_score * 0.4 +
                    quality_score * 0.6
                ) - context_penalty

            # Normalize score to 0-1 range with balanced scaling
            if final_score > 0:
                final_score = 0.35 + (final_score * 0.65)  # Adjusted base score
            else:
                final_score = 0.35 * (1 + final_score)    # Adjusted base score

            return {
                'score': final_score,
                'categories': categories,
                'num_faces': num_faces,
                'quality_score': quality_score
            }

        except Exception as e:
            logging.error(f"Error analyzing image {image_path}: {e}")
            return {
                'score': 0.45,  # Adjusted default score
                'categories': [],
                'num_faces': 0,
                'quality_score': 0.35
            }

    def organize_photos(self, source_dir, threshold=0.50):  # Adjusted threshold higher due to new scoring
        """Organize photos based on their scores."""
        source_path = Path(source_dir)
        keep_dir = source_path / "keep"
        review_dir = source_path / "review"
        delete_dir = source_path / "delete"

        # Create directories
        for dir_path in [keep_dir, review_dir, delete_dir]:
            dir_path.mkdir(exist_ok=True)

        # Process each image
        for image_path in source_path.glob("**/*"):
            if image_path.is_file() and image_path.suffix.lower() in {'.jpg', '.jpeg', '.png', '.heic', '.heif'}:
                try:
                    # Skip if already in a category directory
                    if any(cat in str(image_path) for cat in ['/keep/', '/review/', '/delete/']):
                        continue

                    # Analyze image
                    result = self.analyze_image(str(image_path))
                    score = result['score']

                    # Log the analysis
                    logging.info(f"\nAnalyzing: {image_path.name}")
                    logging.info(f"Score: {score:.2f}")
                    logging.info(f"Categories: {', '.join(result['categories'][:3])}")
                    logging.info(f"Faces detected: {result['num_faces']}")
                    logging.info(f"Quality score: {result['quality_score']:.2f}")

                    # Move file based on score with adjusted thresholds
                    if score >= threshold:
                        target_dir = keep_dir
                        logging.info("Decision: KEEP")
                    elif score >= threshold - 0.20:  # Slightly larger review gap
                        target_dir = review_dir
                        logging.info("Decision: REVIEW")
                    else:
                        target_dir = delete_dir
                        logging.info("Decision: DELETE")

                    # Move the file
                    target_path = target_dir / image_path.name
                    if target_path.exists():
                        # Add timestamp to filename if duplicate
                        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                        target_path = target_dir / f"{image_path.stem}_{timestamp}{image_path.suffix}"
                    
                    shutil.move(str(image_path), str(target_path))
                    logging.info(f"Moved to: {target_path}\n")

                except Exception as e:
                    logging.error(f"Error processing {image_path}: {e}")

def main():
    scorer = PhotoScorer()
    source_directory = "/home/aean/Pictures/Camera Roll"
    scorer.organize_photos(source_directory)

if __name__ == "__main__":
    main() 