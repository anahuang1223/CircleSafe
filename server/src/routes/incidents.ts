import { Router } from "express";
import { analyzeSafetyReport } from "../services/openai.js";
import { getDB } from "../db/mongodb.js";
import { analyzeLocationContext } from "../services/gemini.js";
const router = Router();

// Analyze AND save a friend's report
router.post("/analyze", async (req, res) => {
  try {
    const { report, latitude, longitude } = req.body;

    if (!report) {
      return res.status(400).json({
        error: "Report is required",
      });
    }

    const analysis = await analyzeSafetyReport(report);
    let locationContext = null;

    

    const incident = {
      originalReport: report,
      ...analysis,
      source: "circle",
      location: {
        type: "Point",
        coordinates: [longitude, latitude]
      },
      createdAt: new Date(),
    };

    const db = getDB();

    const result = await db
      .collection("incidents")
      .insertOne(incident);

    res.json({
      _id: result.insertedId,
      ...incident,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Failed to analyze and save report",
    });
  }
});

// Get all incidents
router.get("/", async (_req, res) => {
  try {
    const db = getDB();

    const incidents = await db
      .collection("incidents")
      .find({"location.coordinates": { $exists: true }})
      .sort({ createdAt: -1 })
      .toArray();

    res.json(incidents);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Failed to fetch incidents",
    });
  }
});

export default router;