# Soraya Ghassemlou

import boto3
from dotenv import dotenv_values,load_dotenv
import os
# Load environment variables from .env file
load_dotenv()
# Function to index faces in an image

def index_faces(image_path, collection_id):
    with open(image_path, 'rb') as image_file:
        response = rekognition.index_faces( #collection_id is 1st name
            CollectionId=collection_id,
            Image={'Bytes': image_file.read()}
        )
        return response['FaceRecords']


# Function to compare faces in two images
def compare_faces(face1, face2):
    response = rekognition.compare_faces(
        SourceImage={'Bytes': face1},
        TargetImage={'Bytes': face2},
        SimilarityThreshold=70
    )
    return response['FaceMatches']


# Function to detect and compare faces in uploaded images
def detect_and_compare_faces(image_paths):
    # Create a face collection
    collection_id = 'my-face-collection1'
    rekognition.create_collection(CollectionId=collection_id)

    # Index faces in the uploaded images
    face_records = []
    for path in image_paths:
        face_records.extend(index_faces(path, collection_id))

    # Compare faces to find potential matches
    print(face_records)

    matches = set()
    for i in range(len(face_records)):
        for j in range(i + 1, len(face_records)):
            face1_bytes = face_records[i]['Face']['BoundingBox']
            face2_bytes = face_records[j]['Face']['BoundingBox']
            similarity = compare_faces(face1_bytes, face2_bytes)
            if similarity:
                matches.add((i, j))

    # Print matches
    if matches:
        print("Potential matches found:")
        for match in matches:
            print(f"Image {match[0] + 1} matches with Image {match[1] + 1}")
    else:
        print("No matches found")


# Example usage
if __name__ == "__main__":
    # Create a Boto3 session with explicit credentials
    session = boto3.Session(
        aws_access_key_id=os.getenv('AWS_ACCES_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_KEY'),
        # region_name='us-east-1'
    )

    # Initialize Amazon Rekognition client

    rekognition = session.client('rekognition', region_name='us-east-1')
    s3 = boto3.client('s3')

    image_paths = ['RandomMan1.png', 'Meryl.png']
    rekognition.delete_collection(CollectionId='my-face-collection1')

    detect_and_compare_faces(image_paths)
    print("finish")

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
