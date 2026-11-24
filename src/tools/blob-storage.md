## Presigned URL
%TODO% Dig deeper. look at an object storage service documents.
A presigned URL is a URL that grants temporary permission to access a specific object in blob storage, such as Amazon S3, without requiring the client to have AWS credentials. Think of it as a temporary, limited-access key embedded in a URL. 
How it works? Suppose you're building a .NET application where users upload profile pictures. 
1. Client requests permission
Your Angular application asks your .NET backend to upload a profile picture.
2. Backend generates a presigned URL
Your backend authenticates the user, checks authorization, and generates a URL that allows uploading to a specific S3 object for, say, 5 minutes.
3. Client uploads directly to S3
Angular sends the file directly to S3 using the presigned URL. The file does not pass through your .NET backend.
Key challenges include state synchronization between your database metadata and blob storage, handling upload failures, and managing the lifecycle of large files. Event notifications from storage services help keep your application state consistent.
### Key benefits:
- Lower backend load: your API doesn't have to stream large files.
- Better scalability: storage handles the data transfer.
- Reduced bandwidth costs on your application servers: the file bytes don't pass through your API servers.
- Limited access: you can grant access to a particular object for a limited time without exposing your object storage secret access key.

### How it looks like
A simplified example:

```
https://my-bucket.s3.amazonaws.com/profile-pictures/123.jpg
  ?X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=...
  &X-Amz-Date=...
  &X-Amz-Expires=300
  &X-Amz-Signature=...
```

The query parameters contain the information S3 needs to verify the request's signature and permissions.
- `X-Amz-Expires=300`: the URL is valid for 300 seconds (5 minutes).
- `X-Amz-Signature`: a cryptographic signature proving that the URL was authorized by someone with the relevant signing credentials.
- The object path identifies the resource being accessed.
The URL is a bearer credential: anyone who obtains it can use it within its permitted scope and validity period, subject to the applicable storage policies.

### You can take this approach in some cases:
Generate a presigned URL (get from object storage) for a unique object key in a private quarantine bucket or prefix.
Upload directly to object storage from client.
Notify your .NET API that the upload has finished (events from object storage or any other method).
Have a background worker retrieve the object and validate it.
Re-encode if necessary and save the result under a new key in the approved storage location.
Update the database to reference the approved object only.
