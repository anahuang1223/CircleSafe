import { Router } from "express";
import { analyzeSafetyReport } from "../services/openai.js";
import { getDB } from "../db/mongodb.js";
import { analyzeLocationContext } from "../services/gemini.js";
const router = Router();

// Analyze AND save a friend's report
router.post("/analyze", async (req, res) => {
  try {
    const { report, latitude, longitude, circleId } = req.body;

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
      circleId,
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
    
    // Run Gemini enrichment in the background.
    // Do NOT make the iPhone wait for it.
    analyzeLocationContext(
      latitude,
      longitude,
      "Selected incident location"
    )
      .then(async (locationContext) => {
        await db.collection("incidents").updateOne(
          { _id: result.insertedId },
          {
            $set: {
              locationContext
            }
          }
        );

        console.log("✅ Gemini location context added");
      })
      .catch((error) => {
        console.error(
          "⚠️ Gemini enrichment failed, report still saved:",
          error
        );
      });

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
router.get("/", async (req, res) => {
  const circleId = req.query.circleId as string;
  try {
    const db = getDB();

    const incidents = await db
      .collection("incidents")
      .find({"location.coordinates": { $exists: true },
        $or: [
          { circleId },
          { circleId: { $exists: false } }
        ]
      })
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