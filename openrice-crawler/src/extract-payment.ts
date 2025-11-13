import { readdir, readFile, writeFile, mkdir } from "fs/promises";
import { join } from "path";

const OUTPUT = "output/metadata/payments.json";
const STATES_DIR = "output/states";

interface Payment {
  paymentId: number;
  isCreditCard: number;
  name: string;
  remark: string;
}

async function extractPayments(): Promise<void> {
  console.log("Starting payment extraction...\n");

  // Ensure output directory exists
  await mkdir("output/metadata", { recursive: true });

  const files = await readdir(STATES_DIR);
  const jsonFiles = files.filter((f) => f.endsWith(".json"));

  console.log(`Found ${jsonFiles.length} state files to process\n`);

  const paymentsMap = new Map<number, Payment>();
  let processedCount = 0;
  let errorCount = 0;

  for (const filename of jsonFiles) {
    const filePath = join(STATES_DIR, filename);

    try {
      const content = await readFile(filePath, "utf-8");
      const state = JSON.parse(content);

      // Extract payments from services.PoiDetailPage.services.poiDetail.state.payments
      // Also check state.data.payments as fallback
      const stateObj = state?.services?.PoiDetailPage?.services?.poiDetail?.state?.data;
      const payments = stateObj?.payments;

      if (Array.isArray(payments)) {
        for (const payment of payments) {
          if (payment?.paymentId != null) {
            // Deduplicate by paymentId - keep first occurrence
            if (!paymentsMap.has(payment.paymentId)) {
              paymentsMap.set(payment.paymentId, payment);
            }
          }
        }
      }

      processedCount++;
      if (processedCount % 100 === 0) {
        console.log(`Processed ${processedCount}/${jsonFiles.length} files...`);
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      console.error(`✗ Error processing ${filename}: ${errorMessage}`);
      errorCount++;
    }
  }

  // Convert map to array and sort by paymentId
  const uniquePayments = Array.from(paymentsMap.values()).sort(
    (a, b) => a.paymentId - b.paymentId
  );

  // Write output
  await writeFile(
    OUTPUT,
    JSON.stringify(uniquePayments, null, 2),
    "utf-8"
  );

  console.log(`\n✓ Extraction completed!`);
  console.log(`Total files processed: ${processedCount}`);
  console.log(`Errors: ${errorCount}`);
  console.log(`Unique payments found: ${uniquePayments.length}`);
  console.log(`Output written to: ${OUTPUT}`);
}

extractPayments().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
