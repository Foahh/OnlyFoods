import { RateLimiter } from "./lib/rate-limiter.js";
import { readdir, readFile, mkdir, writeFile, access } from "fs/promises";
import { join } from "path";
import { constants } from "fs";
import axios from "axios";

const OUTPUT_DIR = "output/pages";

interface SearchResult {
  paginationResult?: {
    results?: Array<{
      poiId?: number;
      latestCallName?: string;
    }>;
  };
}

async function loadSearchResults(): Promise<
  Array<{ poiId: number; latestCallName: string }>
> {
  const searchesDir = "output/searches";
  const files = await readdir(searchesDir);
  const searchFiles = files.filter(
    (f) =>
      f.startsWith("response_") && f.endsWith(".json") && !f.includes("count")
  );

  const allResults: Array<{ poiId: number; latestCallName: string }> = [];

  for (const file of searchFiles) {
    const filePath = join(searchesDir, file);
    const content = await readFile(filePath, "utf-8");
    const data: SearchResult = JSON.parse(content);

    if (data.paginationResult?.results) {
      for (const result of data.paginationResult.results) {
        if (result.poiId && result.latestCallName) {
          allResults.push({
            poiId: result.poiId,
            latestCallName: result.latestCallName,
          });
        }
      }
    }
  }

  return allResults;
}

async function fileExists(filePath: string): Promise<boolean> {
  try {
    await access(filePath, constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

async function fetchPage(url: string, rateLimiter: RateLimiter, index: number, total: number, filename: string): Promise<boolean> {
  const filePath = join(OUTPUT_DIR, filename);
  
  // Check if file already exists
  if (await fileExists(filePath)) {
    console.log(`[${index + 1}/${total}] ${url}`);
    console.log(`  ⊙ Skipped: ${filename} (already exists)`);
    return false; // Indicates file was skipped
  }

  console.log(`[${index + 1}/${total}] ${url}`);
  await rateLimiter.wait();

  try {
    const response = await axios.get(url, {
      timeout: 60000,
      headers: {
        accept:
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "accept-language": "en,zh-CN;q=0.9,zh;q=0.8,en-US;q=0.7",
        "cache-control": "max-age=0",
        priority: "u=0, i",
        "sec-ch-ua":
          '"Chromium";v="142", "Microsoft Edge";v="142", "Not_A Brand";v="99"',
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": '"Windows"',
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "same-origin",
        "sec-fetch-user": "?1",
        "upgrade-insecure-requests": "1",
        "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0",
      },
    });

    const html = response.data;

    await writeFile(filePath, html, "utf-8");
    console.log(`  ✓ Saved: ${filename}`);
    return true; // Indicates file was fetched
  } catch (error) {
    console.error(`  ✗ Error fetching ${url}:`, error);
    throw error;
  }
}

async function crawl(): Promise<void> {
  console.log("Starting OpenRice page crawler...\n");

  await mkdir(OUTPUT_DIR, { recursive: true });

  console.log("Loading search results...");
  const results = await loadSearchResults();
  console.log(`Found ${results.length} restaurants to crawl\n`);

  const rateLimiter = new RateLimiter();

  try {
    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;

    for (let i = 0; i < results.length; i++) {
      const result = results[i];
      if (!result) {
        continue;
      }
      const url = `https://www.openrice.com/en/hongkong/r-${result.latestCallName}-r${result.poiId}`;
      const urlParts = url.split("/");
      const lastPart = urlParts[urlParts.length - 1];
      const filename = `${lastPart}.html`;

      try {
        const wasFetched = await fetchPage(url, rateLimiter, i, results.length, filename);
        if (wasFetched) {
          successCount++;
        } else {
          skippedCount++;
        }
      } catch (error) {
        errorCount++;
        console.error(
          `\n✗ Error fetching page ${i + 1}/${results.length}:`,
          error
        );
      }
    }

    console.log(`\n✓ Crawling completed!`);
    console.log(`Total: ${results.length} pages`);
    console.log(`Success: ${successCount}`);
    console.log(`Skipped: ${skippedCount}`);
    console.log(`Errors: ${errorCount}`);
  } catch (error) {
    console.error("\n✗ Crawler error:", error);
    throw error;
  }
}

crawl().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
