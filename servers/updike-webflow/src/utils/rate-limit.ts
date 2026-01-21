import Bottleneck from "bottleneck";

// Webflow API rate limit: 60 requests per minute
// Using 50 to leave headroom for bursts
export const webflowLimiter = new Bottleneck({
  reservoir: 50,
  reservoirRefreshAmount: 50,
  reservoirRefreshInterval: 60 * 1000,
  maxConcurrent: 5,
  minTime: 100, // Minimum 100ms between requests
});

// Retry on rate limit (429)
webflowLimiter.on("failed", async (error: Error & { status?: number }, jobInfo) => {
  if (error?.status === 429 && jobInfo.retryCount < 3) {
    // Exponential backoff: 60s, 120s, 240s
    const delay = Math.min(60000 * Math.pow(2, jobInfo.retryCount), 240000);
    console.error(`Rate limited, retrying in ${delay}ms (attempt ${jobInfo.retryCount + 1})`);
    return delay;
  }
  return null;
});

// Wrap any Webflow API call with rate limiting
export async function rateLimited<T>(operation: () => Promise<T>): Promise<T> {
  return webflowLimiter.schedule(operation);
}
