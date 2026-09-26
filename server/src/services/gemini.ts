import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function analyzeLocationContext(
  latitude: number,
  longitude: number,
  locationName: string
) {
  const maxAttempts = 3;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const response = await ai.models.generateContent({
        model: "gemini-3.8-flash",
        contents: `
You are the location-context system for CircleSafe, a private safety app.

Location:
${locationName}

Coordinates:
${latitude}, ${longitude}

Describe only the most useful location context for someone viewing
a safety report.

Keep "areaType" to 2-4 words.

Keep "context" to ONE short sentence, maximum 15 words.
Mention only useful characteristics such as pedestrian activity,
campus, residential, commercial, transit, parking, nightlife, or parks.

Do not give a neighborhood history or general description.
Do not claim the area is safe or dangerous.
Do not claim current crime or safety conditions.
Do not invent events.

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

    } catch (error: any) {
      console.log(
        `⚠️ Gemini attempt ${attempt}/${maxAttempts} failed`
      );

      if (attempt === maxAttempts) {
        throw error;
      }

      // Wait longer after each failed attempt:
      // 2 seconds, then 4 seconds
      await wait(attempt * 2000);
    }
  }

  throw new Error("Gemini enrichment failed");
}