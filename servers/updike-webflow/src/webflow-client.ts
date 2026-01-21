import { WebflowClient } from "webflow-api";
import { execSync } from "child_process";
import { rateLimited } from "./utils/rate-limit.js";

// Singleton client instance
let client: WebflowClient | null = null;

// Credential cache (5 minute TTL)
const credentialCache: Map<string, { value: string; expiresAt: number }> = new Map();
const CREDENTIAL_TTL_MS = 5 * 60 * 1000;

/**
 * Get credential from deep-env with caching
 * Matches the pattern used in other Updike MCP servers
 */
export function getCredential(key: string): string | null {
  const now = Date.now();
  const cached = credentialCache.get(key);

  if (cached && cached.expiresAt > now) {
    return cached.value;
  }

  try {
    const result = execSync(`deep-env get ${key}`, { encoding: "utf-8" }).trim();
    if (result) {
      credentialCache.set(key, { value: result, expiresAt: now + CREDENTIAL_TTL_MS });
      return result;
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Get Webflow client singleton
 * Creates new instance if not exists or token changed
 */
export function getWebflowClient(): WebflowClient | null {
  const token = getCredential("UPDIKE_WEBFLOW_TOKEN");

  if (!token) {
    return null;
  }

  if (!client) {
    client = new WebflowClient({ accessToken: token });
  }

  return client;
}

/**
 * Get the configured site ID
 */
export function getSiteId(): string | null {
  return getCredential("UPDIKE_WEBFLOW_SITE_ID");
}

/**
 * Get the configured blog collection ID (optional, for blog-specific operations)
 */
export function getBlogCollectionId(): string | null {
  return getCredential("UPDIKE_WEBFLOW_COLLECTION_ID");
}

/**
 * Execute a Webflow API call with rate limiting and error handling
 */
export async function webflowCall<T>(
  operation: (client: WebflowClient) => Promise<T>,
  resourceType: string
): Promise<T> {
  const webflow = getWebflowClient();

  if (!webflow) {
    throw new Error(
      "Webflow credentials not configured. " +
      "Run: deep-env store UPDIKE_WEBFLOW_TOKEN 'your-token'"
    );
  }

  try {
    return await rateLimited(() => operation(webflow));
  } catch (error) {
    // Enhance error message
    const message = error instanceof Error ? error.message : String(error);

    if (message.includes("401") || message.includes("Unauthorized")) {
      throw new Error(
        `Webflow authentication failed for ${resourceType}. ` +
        "Your token may be expired. Generate a new one at webflow.com and update with: " +
        "deep-env store UPDIKE_WEBFLOW_TOKEN 'new-token'"
      );
    }

    if (message.includes("403") || message.includes("Forbidden")) {
      throw new Error(
        `Permission denied for ${resourceType}. ` +
        "Your token may lack required scopes. Check API token settings at webflow.com."
      );
    }

    if (message.includes("404") || message.includes("Not Found")) {
      throw new Error(`Resource not found: ${resourceType}`);
    }

    if (message.includes("429") || message.includes("rate limit")) {
      throw new Error(
        `Rate limit exceeded for ${resourceType}. ` +
        "Webflow allows 60 requests per minute. Please wait and try again."
      );
    }

    throw error;
  }
}
