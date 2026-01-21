import * as fs from "fs/promises";
import * as path from "path";

const UPDIKE_DIR = path.join(process.env.HOME || "~", ".updike");
const DECISIONS_DIR = path.join(UPDIKE_DIR, "decisions", "webflow");

// Simple hash for logging (matches social-api pattern)
function simpleHash(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return `sha256:${Math.abs(hash).toString(16)}`;
}

export interface LogEntry {
  timestamp: string;
  action: string;
  resource_type: string;
  resource_id: string;
  content_preview?: string;
  content_hash?: string;
  status: "success" | "error";
  error_message?: string;
}

export async function logDecision(
  action: string,
  resourceType: string,
  resourceId: string,
  status: "success" | "error",
  options?: {
    contentPreview?: string;
    errorMessage?: string;
  }
): Promise<void> {
  await fs.mkdir(DECISIONS_DIR, { recursive: true });

  const date = new Date().toISOString().split("T")[0];
  const logFile = path.join(DECISIONS_DIR, `${date}-decisions.json`);

  let logs: LogEntry[] = [];
  try {
    const existing = await fs.readFile(logFile, "utf-8");
    logs = JSON.parse(existing);
  } catch {
    // File doesn't exist yet
  }

  const entry: LogEntry = {
    timestamp: new Date().toISOString(),
    action,
    resource_type: resourceType,
    resource_id: resourceId,
    status,
  };

  if (options?.contentPreview) {
    entry.content_preview = options.contentPreview.slice(0, 50) + "...";
    entry.content_hash = simpleHash(options.contentPreview);
  }

  if (options?.errorMessage) {
    entry.error_message = options.errorMessage;
  }

  logs.push(entry);

  await fs.writeFile(logFile, JSON.stringify(logs, null, 2));
}
