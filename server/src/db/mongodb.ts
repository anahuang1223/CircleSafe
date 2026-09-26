import { MongoClient, Db } from "mongodb";

let db: Db;

export async function connectDB() {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    throw new Error("MONGODB_URI is missing from .env");
  }

  const client = new MongoClient(uri);

  await client.connect();

  db = client.db("circlesafe");

  console.log("✅ Connected to MongoDB");

  return db;
}

export function getDB() {
  if (!db) {
    throw new Error("Database not connected");
  }

  return db;
}