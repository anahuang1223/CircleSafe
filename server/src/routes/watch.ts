import { Router } from "express";
import { ObjectId } from "mongodb";
import { getDB } from "../db/mongodb.js";

const router = Router();

const CIRCLE_ID = "roommates-demo";

// Start a Watch Me session
router.post("/start", async (req, res) => {
  try {
    const db = getDB();

    // MVP: only one active Watch session per Circle
    await db.collection("watchSessions").updateMany(
      {
        circleId: CIRCLE_ID,
        status: "active"
      },
      {
        $set: {
          status: "ended",
          endedAt: new Date()
        }
      }
    );

    const session = {
      circleId: CIRCLE_ID,
      status: "active",
      startedAt: new Date(),
      endedAt: null,
      watcherCount: 0
    };

    const result = await db
      .collection("watchSessions")
      .insertOne(session);

    res.status(201).json({
      ...session,
      _id: result.insertedId
    });
  } catch (error) {
    console.error("Failed to start Watch session:", error);

    res.status(500).json({
      error: "Failed to start Watch session"
    });
  }
});

// Get the Circle's current active Watch session
router.get("/active", async (_req, res) => {
  try {
    const db = getDB();

    const session = await db
      .collection("watchSessions")
      .findOne(
        {
          circleId: CIRCLE_ID,
          status: "active"
        },
        {
          sort: { startedAt: -1 }
        }
      );

    res.json(session);
  } catch (error) {
    console.error("Failed to fetch Watch session:", error);

    res.status(500).json({
      error: "Failed to fetch Watch session"
    });
  }
});

// End a Watch session
router.post("/:id/end", async (req, res) => {
  try {
    const db = getDB();

    const result = await db
      .collection("watchSessions")
      .findOneAndUpdate(
        {
          _id: new ObjectId(req.params.id)
        },
        {
          $set: {
            status: "ended",
            endedAt: new Date()
          }
        },
        {
          returnDocument: "after"
        }
      );

    if (!result) {
      return res.status(404).json({
        error: "Watch session not found"
      });
    }

    res.json(result);
  } catch (error) {
    console.error("Failed to end Watch session:", error);

    res.status(500).json({
      error: "Failed to end Watch session"
    });
  }
});
// Update location for an active Watch session
router.post("/:id/location", async (req, res) => {
  try {
    const db = getDB();
    const { latitude, longitude } = req.body;

    if (
      typeof latitude !== "number" ||
      typeof longitude !== "number"
    ) {
      return res.status(400).json({
        error: "latitude and longitude are required"
      });
    }

    const result = await db
      .collection("watchSessions")
      .findOneAndUpdate(
        {
          _id: new ObjectId(req.params.id),
          status: "active"
        },
        {
          $set: {
            latitude,
            longitude,
            locationUpdatedAt: new Date()
          }
        },
        {
          returnDocument: "after"
        }
      );

    if (!result) {
      return res.status(404).json({
        error: "Active Watch session not found"
      });
    }

    res.json(result);
  } catch (error) {
    console.error("Failed to update Watch location:", error);

    res.status(500).json({
      error: "Failed to update Watch location"
    });
  }
});
export default router;