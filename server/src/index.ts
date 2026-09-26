
import "dotenv/config";
import express from "express";
import cors from "cors";
import { connectDB } from "./db/mongodb.js";
import incidentRoutes from "./routes/incidents.js";
const app = express();

app.use(cors());
app.use(express.json());
app.use("/api/incidents", incidentRoutes);
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
      console.log(`🚀 CircleSafe API running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("❌ Failed to start CircleSafe:", error);
    process.exit(1);
  }
}

startServer();