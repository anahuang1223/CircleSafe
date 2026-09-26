import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export async function analyzeSafetyReport(report: string) {
  const response = await openai.responses.create({
    model: "gpt-5.4-mini",
    input: `
You are the safety report analyzer for CircleSafe.

Convert the user's report into concise structured information.
Do not speculate about someone's intentions or identity.

Report:
"${report}"

Return ONLY valid JSON in this format:
{
  "category": "string",
  "title": "string",
  "summary": "string",
  "severity": "low | medium | high",
  "actionable": true
}
`,
  });

  return JSON.parse(response.output_text);
}