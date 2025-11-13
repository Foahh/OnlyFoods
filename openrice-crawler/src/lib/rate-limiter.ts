export class RateLimiter {
  private static REQUESTS_DELAY_MS = 15000; // 20 seconds
  private static JITTER_MS = 5000; // 5 second

  private minDelay: number;
  private nextAllowedTime: number = 0;

  constructor() {
    this.minDelay = RateLimiter.REQUESTS_DELAY_MS;
  }

  async wait(): Promise<void> {
    const now = Date.now();
    const jitter = Math.random() * RateLimiter.JITTER_MS;
    if (this.nextAllowedTime === 0 || now >= this.nextAllowedTime) {
      this.nextAllowedTime = now + this.minDelay + jitter;
      return;
    }
    const waitTime = this.nextAllowedTime - now;
    if (waitTime > 0) {
      await new Promise((resolve) => setTimeout(resolve, waitTime));
    }
    this.nextAllowedTime = Date.now() + this.minDelay + jitter;
  }
}
