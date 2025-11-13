import { readdir, readFile, writeFile, mkdir } from "fs/promises";
import { join } from "path";

const OUTPUT = "output/openrice.json";
const SEARCHES_DIR = "output/searches";
const STATES_DIR = "output/states";
const PAYMENTS_FILE = "output/metadata/payments.json";

interface Payment {
  paymentId: number;
  isCreditCard: number;
  name: string;
  remark: string;
}

interface PoiResult {
  poiId: number;
  latestCallName: string;
  name: string;
  info?: string;
  address?: string;
  mapLatitude: number;
  mapLongitude: number;
  categories: Array<{
    categoryId: number;
    categoryTypeId: number;
    name: string;
    callName: string;
  }>;
  doorPhoto?: {
    url: string;
    urls?: {
      full?: string;
      standard?: string;
      thumbnail?: string;
      icon?: string;
    };
  };
  rmsPhotos?: Array<{
    url: string;
    urls?: {
      full?: string;
      standard?: string;
      thumbnail?: string;
      icon?: string;
    };
  }>
  photos?: Array<{
    url: string;
    urls?: {
      full?: string;
      standard?: string;
      thumbnail?: string;
      icon?: string;
    };
  }>;
  paymentIds?: number[];
  phones?: string[];
  priceRangeId?: number;
  poiHours?: Array<{
    poiId: number;
    pos: number;
    weight: number;
    period1Start?: string;
    period1End?: string;
    period2Start?: string;
    period2End?: string;
    day: number;
    lunarDay: number;
    dayOfWeek: number;
    weekOfMonth: number;
    is24hr: boolean;
    isClose: boolean;
    isHoliday: boolean;
    isHolidayEve: boolean;
    modifyTime: string;
    isUncertain: boolean;
  }>;
}

interface SearchResponse {
  paginationResult?: {
    results?: PoiResult[];
  };
}

interface Condition {
  conditionId: number;
  name: string;
  isThisPoiEnabled: boolean;
  [key: string]: unknown;
}

interface StateFile {
  services?: {
    PoiDetailPage?: {
      services?: {
        poiDetail?: {
          state?: {
            poiId?: number;
            data?: {
              poiId?: number;
              conditions?: Condition[];
            };
          };
        };
      };
    };
  };
}

interface TransformedPoi {
  id: string;
  name: string;
  description: string;
  latitude: number;
  longitude: number;
  images: string[];
  doorImage: string | null;
  categories: string[];
  services: string[];
  paymentMethods: string[];
  contactPhone: string | null;
  addressString: string;
  priceLevel: number | null;
  businessHours: Array<{
    dayOfWeek: number;
    periods: Array<{ start: string; end: string }>;
    isClosed: boolean;
    is24hr: boolean;
  }>;
}

async function loadServicesFromStates(): Promise<Map<number, string[]>> {
  console.log("Loading services from state files...");
  const servicesMap = new Map<number, string[]>();
  
  try {
    const stateFiles = await readdir(STATES_DIR);
    const jsonFiles = stateFiles.filter((f) => f.endsWith(".json"));
    
    let loadedCount = 0;
    let errorCount = 0;
    
    for (const filename of jsonFiles) {
      try {
        const filePath = join(STATES_DIR, filename);
        const content = await readFile(filePath, "utf-8");
        const state: StateFile = JSON.parse(content);
        
        // Try to get POI ID from state file first
        let poiId: number | null = null;
        const statePoiId = state.services?.PoiDetailPage?.services?.poiDetail?.state?.data?.poiId;
        if (typeof statePoiId === 'number') {
          poiId = statePoiId;
        } else {
          // Fallback: Extract POI ID from filename (format: r-{name}-r{poiId}.json)
          const match = filename.match(/-r(\d+)\.json$/);
          if (match?.[1]) {
            poiId = parseInt(match[1], 10);
          }
        }
        
        if (!poiId) continue;
        
        const conditions = state.services?.PoiDetailPage?.services?.poiDetail?.state?.data?.conditions;
        if (Array.isArray(conditions)) {
          const services: string[] = [];
          for (const condition of conditions) {
            if (condition.isThisPoiEnabled && condition.name) {
              if (condition.name === "Online Reservation") continue;
              if (condition.name === "Exclusive Online Booking") continue;
              if (condition.name === "Reward Dining Points") continue;
              services.push(condition.name);
            }
          }
          if (services.length > 0) {
            servicesMap.set(poiId, services);
            loadedCount++;
          }
        }
      } catch {
        errorCount++;
        // Silently skip errors for individual files
      }
    }
    
    console.log(`Loaded services for ${loadedCount} POIs from ${jsonFiles.length} state files`);
    if (errorCount > 0) {
      console.log(`  (${errorCount} files had errors)`);
    }
    console.log();
  } catch (error) {
    console.log(`⚠ Could not load state files: ${error instanceof Error ? error.message : String(error)}`);
    console.log("  Continuing without services data...\n");
  }
  
  return servicesMap;
}

async function transformPois(): Promise<void> {
  console.log("Starting POI transformation...\n");

  // Ensure output directory exists
  await mkdir("output", { recursive: true });

  // Load payment mappings
  console.log("Loading payment mappings...");
  const paymentsContent = await readFile(PAYMENTS_FILE, "utf-8");
  const payments: Payment[] = JSON.parse(paymentsContent);
  const paymentMap = new Map<number, string>();
  for (const payment of payments) {
    paymentMap.set(payment.paymentId, payment.name);
  }
  console.log(`Loaded ${paymentMap.size} payment methods\n`);

  // Load services from state files
  const servicesMap = await loadServicesFromStates();

  // Read all response files
  const files = await readdir(SEARCHES_DIR);
  const responseFiles = files
    .filter((f) => f.startsWith("response_") && f.endsWith(".json"))
    .filter((f) => !f.includes("_count")) // Exclude count files
    .sort();

  console.log(`Found ${responseFiles.length} response files to process\n`);

  const allPois: TransformedPoi[] = [];
  const seenIds = new Set<string>();
  let processedCount = 0;
  let errorCount = 0;
  let duplicateCount = 0;

  for (const filename of responseFiles) {
    const filePath = join(SEARCHES_DIR, filename);

    try {
      const content = await readFile(filePath, "utf-8");
      const response: SearchResponse = JSON.parse(content);

      const results = response?.paginationResult?.results;
      if (!Array.isArray(results)) {
        console.log(`⚠ No results found in ${filename}`);
        continue;
      }

      for (const poi of results) {
        // Skip if required fields are missing
        if (
          !poi.poiId ||
          !poi.latestCallName ||
          !poi.name ||
          poi.mapLatitude == null ||
          poi.mapLongitude == null
        ) {
          continue;
        }

        // Create unique ID
        const id = `${poi.latestCallName}-${poi.poiId}`;

        // Skip duplicates
        if (seenIds.has(id)) {
          duplicateCount++;
          continue;
        }
        seenIds.add(id);

        // Extract images from photos array
        const images: string[] = [];

        if (Array.isArray(poi.rmsPhotos)) {
          for (const photo of poi.rmsPhotos) {
            if (photo?.url) {
              images.push(photo.url);
            }
          }
        }
        
        if (Array.isArray(poi.photos)) {
          for (const photo of poi.photos) {
            if (photo?.url) {
              images.push(photo.url);
            }
          }
        }

        // Extract door image
        const doorImage = poi.doorPhoto?.url || null;

        // Extract categories (just names)
        const categories: string[] = [];
        if (Array.isArray(poi.categories)) {
          for (const category of poi.categories) {
            if (category?.name) {
              categories.push(category.name);
            }
          }
        }

        // Map payment IDs to names
        const paymentMethods: string[] = [];
        if (Array.isArray(poi.paymentIds)) {
          for (const paymentId of poi.paymentIds) {
            const paymentName = paymentMap.get(paymentId);
            if (paymentName === "OpenRice Pay") continue;
            if (paymentName) {
              paymentMethods.push(paymentName);
            }
          }
        }

        // Extract services from state files
        const services = servicesMap.get(poi.poiId) || [];

        // Extract contact phone (use first phone if available)
        const contactPhone =
          Array.isArray(poi.phones) && poi.phones.length > 0 && poi.phones[0]
            ? poi.phones[0]
            : null;

        // Transform business hours
        const businessHours: Array<{
          dayOfWeek: number;
          periods: Array<{ start: string; end: string }>;
          isClosed: boolean;
          is24hr: boolean;
        }> = [];

        if (Array.isArray(poi.poiHours)) {
          // Group hours by dayOfWeek
          const hoursByDay = new Map<
            number,
            Array<{
              period1Start?: string;
              period1End?: string;
              period2Start?: string;
              period2End?: string;
              isClose: boolean;
              is24hr: boolean;
            }>
          >();

          for (const hour of poi.poiHours) {
            if (hour.dayOfWeek == null) continue;

            if (!hoursByDay.has(hour.dayOfWeek)) {
              hoursByDay.set(hour.dayOfWeek, []);
            }

            const dayHours = hoursByDay.get(hour.dayOfWeek);
            if (dayHours) {
              dayHours.push({
                period1Start: hour.period1Start,
                period1End: hour.period1End,
                period2Start: hour.period2Start,
                period2End: hour.period2End,
                isClose: hour.isClose,
                is24hr: hour.is24hr,
              });
            }
          }

          // Convert to output format, sorted by dayOfWeek
          const sortedDays = Array.from(hoursByDay.keys()).sort((a, b) => a - b);
          for (const dayOfWeek of sortedDays) {
            const dayHours = hoursByDay.get(dayOfWeek);
            if (!dayHours || dayHours.length === 0) continue;

            // Use the first entry for flags (assuming they're consistent per day)
            const firstHour = dayHours[0];
            if (!firstHour) continue;

            const periods: Array<{ start: string; end: string }> = [];

            // Collect all periods from all entries for this day
            for (const hour of dayHours) {
              if (hour.period1Start && hour.period1End) {
                periods.push({
                  start: hour.period1Start,
                  end: hour.period1End,
                });
              }
              if (hour.period2Start && hour.period2End) {
                periods.push({
                  start: hour.period2Start,
                  end: hour.period2End,
                });
              }
            }

            businessHours.push({
              dayOfWeek,
              periods,
              isClosed: firstHour.isClose,
              is24hr: firstHour.is24hr,
            });
          }
        }

        // Transform to output format
        const transformed: TransformedPoi = {
          id,
          name: poi.name,
          description: poi.info || "",
          latitude: poi.mapLatitude,
          longitude: poi.mapLongitude,
          images,
          doorImage,
          categories,
          services,
          paymentMethods,
          contactPhone,
          addressString: poi.address || "",
          priceLevel: poi.priceRangeId ?? null,
          businessHours,
        };

        allPois.push(transformed);
      }

      processedCount++;
      console.log(
        `✓ Processed ${filename}: ${results.length} POIs (${allPois.length} total unique)`
      );
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      console.error(`✗ Error processing ${filename}: ${errorMessage}`);
      errorCount++;
    }
  }

  // Write output
  await writeFile(
    OUTPUT,
    JSON.stringify(allPois, null, 2),
    "utf-8"
  );

  console.log(`\n✓ Transformation completed!`);
  console.log(`Total files processed: ${processedCount}`);
  console.log(`Errors: ${errorCount}`);
  console.log(`Total unique POIs: ${allPois.length}`);
  console.log(`Duplicates skipped: ${duplicateCount}`);
  console.log(`Output written to: ${OUTPUT}`);
}

transformPois().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});

