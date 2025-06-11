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
        with open('imagenet_classes.txt') as f:
            self.categories = [s.strip() for s in f.readlines()]

        # Define important categories (positive and negative)
        self.positive_categories = {
            'person', 'people', 'human', 'face', 'portrait', 'family', 'group',
            'wedding', 'event', 'celebration', 'vacation', 'travel', 'landscape',
            'nature', 'animal', 'pet', 'baby', 'child', 'building', 'architecture',
            'food', 'dish', 'meal', 'art', 'painting', 'drawing', 'sculpture'
        }

        # Expanded negative categories for low-context photos
        self.negative_categories = {
            'document', 'text', 'screenshot', 'meme', 'furniture', 'object',
            'product', 'advertisement', 'logo', 'icon', 'interface', 'toilet',
            'trash', 'garbage', 'waste', 'rubbish', 'screen', 'CRT screen',
            'web site', 'website', 'internet site', 'site', 'menu', 'envelope',
            'oscilloscope', 'scope', 'cathode-ray oscilloscope', 'CRO',
            'part', 'component', 'detail', 'close-up', 'macro', 'fragment'
        }

        # Categories that require good context
        self.context_required_categories = {
            'car', 'truck', 'bus', 'motorcycle', 'bicycle', 'vehicle',
            'boat', 'ship', 'airplane', 'aircraft', 'train', 'locomotive',
            'building', 'house', 'architecture', 'structure'
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

            # Get image quality score
            quality_score = self.get_image_quality_score(image)

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

    def organize_photos(self, source_dir, threshold=0.48):  # Adjusted threshold
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
                    elif score >= threshold - 0.18:  # Adjusted gap
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