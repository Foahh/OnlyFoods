# OpenRice Crawler

⚠️ **For testing purposes only**. This tool is intended for demonstration and academic purposes in the ELEC3644 course project. It may not comply with OpenRice's Terms of Service when using this crawler.

## Prerequisites

- [Bun](https://bun.sh) (JavaScript runtime)
- Node.js (if not using Bun)

## Installation

```bash
# Install dependencies
bun install

# if not using Bun
npm install
```

## Project Structure

```
openrice-crawler/
├── src/
│   ├── crawler-json.ts      # Step 1: Fetch search results from API
│   ├── crawler-page.ts      # Step 2: Fetch individual restaurant pages
│   ├── extract-state.ts     # Step 3: Extract state data from HTML
│   ├── extract-payment.ts   # Step 4: Extract payment metadata
│   ├── transform.ts         # Step 5: Transform and combine all data
│   └── lib/
│       └── rate-limiter.ts  # Rate limiting utility
├── output/                  # Generated output files
│   ├── searches/            # Raw API search responses
│   ├── pages/               # Raw HTML pages
│   ├── states/              # Extracted state data
│   ├── metadata/            # Extracted metadata
│   └── openrice.json        # Final transformed output
└── package.json
```

## Usage

The crawler runs in a sequential pipeline. Execute each script in order:

### Step 1: Fetch Search Results
```bash
bun src/crawler-json.ts
```
Fetches restaurant search results from OpenRice API endpoints and saves JSON responses to `output/searches/`.

### Step 2: Fetch Restaurant Pages
```bash
bun src/crawler-page.ts
```
Crawls individual restaurant pages for each restaurant found in Step 1. Saves HTML pages to `output/pages/`.

### Step 3: Extract State Data
```bash
bun src/extract-state.ts
```
Extracts the `window.__INITIAL_STATE__` JavaScript object from HTML pages and saves to `output/states/`.

### Step 4: Extract Payment Metadata
```bash
bun src/extract-payment.ts
```
Extracts payment method information from state files and saves to `output/metadata/payments.json`.

### Step 5: Transform Data
```bash
bun src/transform.ts
```
Transforms and combines all extracted data into a final structured JSON file at `output/openrice.json`.