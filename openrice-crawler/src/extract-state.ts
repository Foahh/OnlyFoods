import { readdir, readFile, writeFile, mkdir } from "fs/promises";
import { join } from "path";

const PAGES_DIR = "output/pages";
const OUTPUT_DIR = "output/states";

interface ExtractionResult {
  filename: string;
  success: boolean;
  error?: string;
}

async function extractStateFromHtml(html: string): Promise<unknown> {
  const startMarker = "window.__INITIAL_STATE__";
  const startIndex = html.indexOf(startMarker);
  if (startIndex === -1) {
    throw new Error("Could not find window.__INITIAL_STATE__ in HTML");
  }

  const afterMarker = html.slice(startIndex + startMarker.length);
  const equalsIndex = afterMarker.search(/\s*=\s*/);
  if (equalsIndex === -1) {
    throw new Error("Could not find assignment operator after window.__INITIAL_STATE__");
  }

  const afterEquals = afterMarker.slice(equalsIndex);
  const braceIndex = afterEquals.indexOf("{");
  if (braceIndex === -1) {
    throw new Error("Could not find opening brace for JSON object");
  }

  const jsonStart = startIndex + startMarker.length + equalsIndex + braceIndex;
  let braceCount = 0;
  let inString = false;
  let escapeNext = false;
  let jsonEnd = -1;

  for (let i = jsonStart; i < html.length; i++) {
    const char = html[i];

    if (escapeNext) {
      escapeNext = false;
      continue;
    }

    if (char === "\\") {
      escapeNext = true;
      continue;
    }

    if (char === '"' && !escapeNext) {
      inString = !inString;
      continue;
    }

    if (!inString) {
      if (char === "{") {
        braceCount++;
      } else if (char === "}") {
        braceCount--;
        if (braceCount === 0) {
          jsonEnd = i + 1;
          break;
        }
      }
    }
  }

  if (jsonEnd === -1) {
    throw new Error("Could not find closing brace for JSON object");
  }

  const stateString = html.slice(jsonStart, jsonEnd);

  try {
    return JSON.parse(stateString);
  } catch (error) {
    throw new Error(
      `Failed to parse JSON: ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

async function extractStates(): Promise<void> {
  console.log("Starting state extraction...\n");

  await mkdir(OUTPUT_DIR, { recursive: true });

  const files = await readdir(PAGES_DIR);
  const htmlFiles = files.filter((f) => f.endsWith(".html"));

  console.log(`Found ${htmlFiles.length} HTML files to process\n`);

  const results: ExtractionResult[] = [];
  let successCount = 0;
  let errorCount = 0;

  for (const filename of htmlFiles) {
    const filePath = join(PAGES_DIR, filename);

    try {
      console.log(`Processing: ${filename}`);
      const html = await readFile(filePath, "utf-8");
      const state = await extractStateFromHtml(html);

      const jsonFilename = filename.replace(/\.html$/, ".json");
      const outputPath = join(OUTPUT_DIR, jsonFilename);

      await writeFile(outputPath, JSON.stringify(state, null, 2), "utf-8");

      console.log(`✓ Extracted: ${jsonFilename}\n`);
      results.push({ filename, success: true });
      successCount++;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      console.error(`✗ Error processing ${filename}: ${errorMessage}\n`);
      results.push({ filename, success: false, error: errorMessage });
      errorCount++;
    }
  }

  console.log(`\n✓ Extraction completed!`);
  console.log(`Total: ${htmlFiles.length} files`);
  console.log(`Success: ${successCount}`);
  console.log(`Errors: ${errorCount}`);
}

extractStates().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
