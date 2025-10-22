import { params, https, onInit } from "firebase-functions";
import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const EXPIRES_IN_SECONDS = 7 * 24 * 60 * 60; // 7 days × 24 hours × 60 minutes × 60 seconds
const r2Endpoint = params.defineString("R2_ENDPOINT");
const r2AccessKey = params.defineString("R2_ACCESS_KEY");
const r2SecretKey = params.defineSecret("R2_SECRET_KEY");
const r2Bucket = params.defineString("R2_BUCKET");

let s3Client: S3Client;

onInit(() => {
  s3Client = new S3Client({
    endpoint: r2Endpoint.value(),
    region: "auto",
    credentials: {
      accessKeyId: r2AccessKey.value(),
      secretAccessKey: r2SecretKey.value(),
    },
  });
});

export const getPresignedUrl = https.onCall(
  {
    region: "asia-east1",
  },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "User must be signed in");
    }

    const filename = request.data.filename;

    const command = new GetObjectCommand({
      Bucket: r2Bucket.value(),
      Key: filename,
    });

    const url = await getSignedUrl(s3Client, command, {
      expiresIn: EXPIRES_IN_SECONDS,
    });

    return { url };
  }
);

export const getStoryUploadUrl = https.onCall(
  {
    region: "asia-east1",
  },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "User must be signed in");
    }

    const filename = request.data.filename;
    const contentType = request.data.contentType;
    const key = `stories/${filename}`;

    const command = new PutObjectCommand({
      Bucket: r2Bucket.value(),
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3Client, command, {
      expiresIn: EXPIRES_IN_SECONDS,
    });

    return { uploadUrl, key };
  }
);

export const deleteStoryImage = https.onCall(
  {
    region: "asia-east1",
  },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "User must be signed in");
    }

    const key = request.data.key;

    const command = new DeleteObjectCommand({
      Bucket: r2Bucket.value(),
      Key: key,
    });

    await s3Client.send(command);
  }
);

export const getProfilePictureUploadUrl = https.onCall(
  {
    region: "asia-east1",
  },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "User must be signed in");
    }

    const filename = request.data.filename;
    const contentType = request.data.contentType;
    const key = `profile_pictures/${filename}`;

    const command = new PutObjectCommand({
      Bucket: r2Bucket.value(),
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3Client, command, {
      expiresIn: EXPIRES_IN_SECONDS,
    });

    return { uploadUrl, key };
  }
);

export const deleteProfilePicture = https.onCall(
  {
    region: "asia-east1",
  },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "User must be signed in");
    }

    const key = request.data.key;

    const command = new DeleteObjectCommand({
      Bucket: r2Bucket.value(),
      Key: key,
    });

    await s3Client.send(command);
  }
);
