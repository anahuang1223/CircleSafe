import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

export async function analyzeLocationContext(
  latitude: number,
  longitude: number,
  locationName: string
) {
  const response = await ai.models.generateContent({
    model: "gemini-3.8-flash",
    contents: `
You are the location-context system for CircleSafe, a private safety app.

Location:
${locationName}

Coordinates:
${latitude}, ${longitude}

Describe the general context of this location that could help someone
understand a safety report.

Do NOT claim current crime, danger, or safety conditions unless provided.
Do NOT invent events.

Return ONLY valid JSON:
{
  "areaType": "string",
  "context": "string"
}
`,
  });

  const text = response.text ?? "";

  const cleaned = text
    .replace(/```json/g, "")
    .replace(/```/g, "")
    .trim();

  return JSON.parse(cleaned);
}