import boto3
s3 = boto3.client('s3',region_name = 'us-east-1')
from dotenv import dotenv_values, load_dotenv
import os
# Load environment variables from .env file
load_dotenv()


def upload_image_to_s3(file_path, bucket_name, object_name):
    try:
        # Upload the file to the specified bucket and object name
        s3.upload_file(file_path, bucket_name, object_name)
        print(f"Image uploaded successfully to S3 bucket: {bucket_name} with object name: {object_name}")
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

def main():

    bucket = 'test_bucket'

    collection_id = 'test_collection_soraya1'
    photo_name = 'Meryl'
    upload_image_to_s3(file_path='Meryl.png', bucket_name='test_bucket',object_name=photo_name)
    indexed_faces_count = add_faces_to_collection(bucket, photo_name, collection_id)
    print("Faces indexed count: " + str(indexed_faces_count))


if __name__ == "__main__":
    main()
