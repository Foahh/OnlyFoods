import { writeFile, mkdir } from "fs/promises";
import { existsSync } from "fs";
import { join } from "path";
import axios from "axios";
import { CookieJar } from "tough-cookie";
import { wrapper } from "axios-cookiejar-support";
import { RateLimiter } from "./lib/rate-limiter";

const OUTPUT_DIR = "output/searches";
const BATCH_SIZE = 15;

const REFERER = "https://www.openrice.com/en/hongkong/restaurants?";

const cookieJar = new CookieJar();
const client = wrapper(axios.create({ jar: cookieJar }));

async function saveResponse(data: unknown, filename: string): Promise<void> {
  const filePath = join(OUTPUT_DIR, filename);
  await writeFile(filePath, JSON.stringify(data, null, 2), "utf-8");
  console.log(`✓ Saved: ${filename}`);
}

async function makeRequest(url: string, referer?: string): Promise<unknown> {
  console.log(`→ ${url}`);

  const response = await client.get(url, {
    headers: {
      accept: "application/json, text/plain, */*",
      "accept-language": "en,zh-CN;q=0.9,zh;q=0.8,en-US;q=0.7",
      referer: referer,
      "sec-ch-ua":
        '"Chromium";v="142", "Microsoft Edge";v="142", "Not_A Brand";v="99"',
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": '"Windows"',
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
      "user-agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0",
    },
  });

  return response.data;
}

async function getInitialCount(rateLimiter: RateLimiter): Promise<number> {
  console.log("Making initial count request...");
  console.log("Fetching cookies from initial page visit...");
  await rateLimiter.wait();

  await makeRequest(
    "https://www.openrice.com/en/hongkong/restaurants?tc=sr1quick&region=0&s=1&district_id=1019"
  );
  console.log("✓ Retrieved cookies from initial page visit");

  const countData = await makeRequest(
    "https://www.openrice.com/api/v2/search/count/nofacet?sortBy=ORScoreDesc&apiEntryPoint=11&regionId=0&uiLang=en&uiCity=hongkong",
    REFERER
  );
  await saveResponse(countData, "response_000_count.json");

  if (!countData || typeof countData !== "object") {
    throw new Error("Invalid count data");
  }

  if (!("paginationResult" in countData)) {
    throw new Error("Invalid pagination result");
  }

  const { paginationResult } = countData;

  if (
    !(
      typeof paginationResult === "object" &&
      paginationResult &&
      "totalReturnCount" in paginationResult
    )
  ) {
    throw new Error("Invalid totalReturnCount");
  }

  const { totalReturnCount } = paginationResult;

  if (!(typeof totalReturnCount === "number")) {
    throw new Error("Invalid totalReturnCount");
  }

  console.log(`Total restaurants found: ${totalReturnCount}`);
  return totalReturnCount;
}

async function fetchPaginatedListings(
  totalCount: number,
  rateLimiter: RateLimiter
): Promise<void> {
  const totalBatches = Math.ceil(totalCount / BATCH_SIZE);
  console.log(
    `\nFetching ${totalBatches} batches of ${BATCH_SIZE} restaurants each...\n`
  );

  let errCount = 0;
  for (let batch = 0; batch < totalBatches; batch++) {
    const startAt = batch * BATCH_SIZE;
    const url = `https://www.openrice.com/api/v2/search?regionId=0&startAt=${startAt}&rows=15&pageToken=CONST_DUMMY_TOKEN&uiLang=en&uiCity=hongkong`;
    const filename = `response_${String(batch + 1).padStart(3, "0")}.json`;

    try {
      await rateLimiter.wait();
      console.log(
        `[${batch + 1}/${totalBatches}] Fetching restaurants ${startAt} to ${startAt + BATCH_SIZE - 1}...`
      );

      const data = await makeRequest(url, REFERER);
      await saveResponse(data, filename);

      if (!data || typeof data !== "object") {
        throw new Error("Invalid data");
      }

      if (!("paginationResult" in data)) {
        throw new Error("Invalid pagination result");
      }

      const { paginationResult } = data;
      if (
        !(
          typeof paginationResult === "object" &&
          paginationResult &&
          "results" in paginationResult
        )
      ) {
        throw new Error("Invalid pagination result");
      }

      const { results } = paginationResult;
      if (!Array.isArray(results)) {
        throw new Error("Invalid results");
      }

      if (results.length === 0) {
        console.log(`\nNo more results. Stopping at batch ${batch + 1}.`);
        break;
      }

      console.log(`Fetched ${results.length} restaurants`);
      errCount = 0;
    } catch (error) {
      console.error(`\n✗ Error fetching batch ${batch + 1}:`, error);
      errCount++;
      if (errCount >= 3) {
        console.error(
          `\n✗ Too many consecutive errors (${errCount}). Stopping crawler.`
        );
        break;
      }
    }
  }
}

async function crawl(): Promise<void> {
  console.log("Starting OpenRice Hong Kong crawler...\n");

  if (!existsSync(OUTPUT_DIR)) {
    await mkdir(OUTPUT_DIR, { recursive: true });
    console.log(`Created output directory: ${OUTPUT_DIR}\n`);
  }

  const rateLimiter = new RateLimiter();

  try {
    const totalCount = await getInitialCount(rateLimiter);

    if (totalCount === 0) {
      console.log("No restaurants found. Exiting.");
      return;
    }

    await fetchPaginatedListings(totalCount, rateLimiter);

    console.log("\n✓ Crawling completed successfully!");
  } catch (error) {
    console.error("\n✗ Crawler error:", error);
    throw error;
  }
}

crawl().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
