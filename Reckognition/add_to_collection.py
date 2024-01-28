import boto3

from dotenv import dotenv_values, load_dotenv
import os
from botocore.exceptions import NoCredentialsError
import requests
import mimetypes
# Load environment variables from .env file
load_dotenv()
s3 = boto3.client('s3',region_name = 'us-east-1')

def upload_image_to_s3(file_path, bucket_name, object_name):
    try:
        # Upload the file to the specified bucket and object name
        s3.upload_file(file_path, bucket_name, object_name)
        print(f"Image uploaded successfully to S3 bucket: {bucket_name} with object name: {object_name}")
        # imageResponse = requests.get(file_path, stream=True).raw
        # content_type = imageResponse.headers['content-type']
        # extension = mimetypes.guess_extension(content_type)
        # s3.upload_fileobj(imageResponse, bucket_name, object_name)
        # print("Upload Successful")
    except Exception as e:
        print(f"Error uploading image to S3: {e}")


def add_faces_to_collection(bucket, photo, collection_id):

    session = boto3.Session(profile_name=os.getenv('PROFILE_NAME'))
    client = session.client('rekognition')

    response = client.index_faces(CollectionId=collection_id,
                                  Image={'S3Object': {'Bucket': bucket, 'Name': photo}},
                                  ExternalImageId=photo,
                                  MaxFaces=1,
                                  QualityFilter="AUTO",
                                  DetectionAttributes=['ALL'])

    print('Results for ' + photo)
    print('Faces indexed:')
    for faceRecord in response['FaceRecords']:
        print('  Face ID: ' + faceRecord['Face']['FaceId'])
        print('  Location: {}'.format(faceRecord['Face']['BoundingBox']))

    print('Faces not indexed:')
    for unindexedFace in response['UnindexedFaces']:
        print(' Location: {}'.format(unindexedFace['FaceDetail']['BoundingBox']))
        print(' Reasons:')
        for reason in unindexedFace['Reasons']:
            print('   ' + reason)
    return len(response['FaceRecords'])


def create_collection(collection_id):
    try:
        # Create a session with your AWS profile
        session = boto3.Session(profile_name=os.getenv('PROFILE_NAME'))

        # Create a Rekognition client
        client = session.client('rekognition')

        # Create the collection
        response = client.create_collection(CollectionId=collection_id)

        print(f"Collection '{collection_id}' created successfully.")
        return True
    except Exception as e:
        print(f"Error creating collection: {e}")
        return False


def compare_faces(sourceFile, targetFile):

    session = boto3.Session(profile_name=os.getenv('PROFILE_NAME'))
    client = session.client('rekognition')

    imageSource = open(sourceFile, 'rb')
    imageTarget = open(targetFile, 'rb')

    response = client.compare_faces(SimilarityThreshold=80,
                                    SourceImage={'Bytes': imageSource.read()},
                                    TargetImage={'Bytes': imageTarget.read()})
    if len(response['FaceMatches']) == 0:
        print("New Face")#TODO:make actions

    for faceMatch in response['FaceMatches']:
        position = faceMatch['Face']['BoundingBox']
        similarity = str(faceMatch['Similarity'])
        print('The face at ' +
              str(position['Left']) + ' ' +
              str(position['Top']) +
              ' matches with ' + similarity + '% confidence')

    imageSource.close()
    imageTarget.close()
    return len(response['FaceMatches'])

#def check_face_in_collection(face_id, collection_id):
    session = boto3.Session(profile_name=os.getenv('PROFILE_NAME'))
    client = session.client('rekognition')

    # Check if the face already exists in the collection
    response = client.search_faces(CollectionId=collection_id, FaceId=face_id)
    if 'FaceMatches' in response and response['FaceMatches']:
        return True  # Face already exists in the collection
    else:
        return False  # Face not found in the collection

#def add_faces_to_collection_new(bucket, photo, collection_id):
    session = boto3.Session(profile_name=os.getenv('PROFILE_NAME'))
    client = session.client('rekognition')

    # Check if the collection exists, and create it if needed
    #create_collection(collection_id)

    # Detect faces in the input image
    response = client.detect_faces(Image={'S3Object': {'Bucket': bucket, 'Name': photo}})

    # Index faces only if they are not already in the collection
    for face_detail in response['FaceDetails']:
        # Check if the face already exists in the collection
        face_id = face_detail['Face']['FaceId']
        if not check_face_in_collection(face_id, collection_id):
            # Face not found in the collection, so add it
            client.index_faces(CollectionId=collection_id,
                               Image={'S3Object': {'Bucket': bucket, 'Name': photo}},
                               ExternalImageId=photo,
                               DetectionAttributes=['ALL'])
            print(f"Face with ID '{face_id}' added to collection '{collection_id}'.") #TODO:only run if voice command
        else:
            print(f"Face with ID '{face_id}' already exists in collection '{collection_id}'.") #TODO: make output show name

    return len(response['FaceDetails'])

def search_collection():
def main():

    bucket = os.getenv('BUCKET_NAME')
    collection_id = 'meryl-collection'
    photo_name = 'Meryl'
    upload_image_to_s3(file_path='Meryl2.png', bucket_name='face-book-faces',object_name=photo_name)
    #upload_image_to_s3(file_path='RandomWoman1.png', bucket_name='face-book-faces', object_name='RandomSteamWoman')
    create_collection(collection_id) #uncomment if doesnt allready exist
    indexed_faces_count = add_faces_to_collection(bucket, photo_name, collection_id)
    print("Faces indexed count: " + str(indexed_faces_count))
    compare_faces('Meryl.png', 'RandomMan1.png')
    #add_faces_to_collection_new(bucket,'RandomSteamWoman',collection_id)


if __name__ == "__main__":
    main()
