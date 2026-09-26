
import "dotenv/config";
import express from "express";
import cors from "cors";
import { connectDB } from "./db/mongodb.js";
import incidentRoutes from "./routes/incidents.js";
import watchRoutes from "./routes/watch.js";
import { analyzeLocationContext } from "./services/gemini.js";
const app = express();

app.use(cors());
app.use(express.json());
app.get("/test-gemini", async (_req, res) => {
  try {
    const result = await analyzeLocationContext(
      33.7765,
      -84.3895,
      "Tech Square, Atlanta, GA"
    );

    res.json(result);
  } catch (error) {
    console.error("Gemini error:", error);

    res.status(500).json({
      error: "Gemini test failed"
    });
  }
});
app.use("/api/incidents", incidentRoutes);
app.use("/api/watch", watchRoutes);
app.get("/", (_req, res) => {
  res.json({
    app: "CircleSafe",
    status: "running"
  });
});

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await connectDB();

    app.listen(PORT, () => {
      console.log(`CircleSafe API running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Failed to start CircleSafe:", error);
    process.exit(1);
  }
}

startServer();