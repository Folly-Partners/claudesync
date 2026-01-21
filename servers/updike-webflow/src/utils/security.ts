import createDOMPurify from "dompurify";
import { JSDOM } from "jsdom";
import * as path from "path";

// Set up DOMPurify with jsdom for Node.js
const window = new JSDOM("").window;
const DOMPurify = createDOMPurify(window as any);

// Allowed HTML tags for Webflow rich text
const ALLOWED_TAGS = [
  "h1", "h2", "h3", "h4", "h5", "h6",
  "p", "br", "hr",
  "ul", "ol", "li",
  "strong", "b", "em", "i", "u", "s", "strike",
  "code", "pre",
  "blockquote",
  "a",
  "img",
  "figure", "figcaption",
  "span", "div",
];

// Allowed attributes
const ALLOWED_ATTR = [
  "href", "src", "alt", "title",
  "target", "rel",
  "class", "id",
  "width", "height",
];

// Forbidden attributes (security risk)
const FORBID_ATTR = [
  "style",
  "onerror", "onclick", "onload", "onmouseover", "onfocus",
];

// Forbidden tags (security risk)
const FORBID_TAGS = [
  "script", "iframe", "object", "embed", "form", "input",
  "button", "select", "textarea", "meta", "link",
];

/**
 * Sanitize HTML content for safe injection into Webflow CMS
 * Prevents XSS attacks by removing dangerous tags and attributes
 */
export function sanitizeHtml(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS,
    ALLOWED_ATTR,
    FORBID_ATTR,
    FORBID_TAGS,
    ALLOW_DATA_ATTR: false,
  });
}

// Allowed directories for asset uploads (path traversal protection)
const ALLOWED_UPLOAD_DIRS = [
  path.join(process.env.HOME || "", "Pictures"),
  path.join(process.env.HOME || "", "Downloads"),
  path.join(process.env.HOME || "", "Desktop"),
  path.join(process.env.HOME || "", ".updike", "generated"),
  path.join(process.env.HOME || "", ".updike", "assets"),
];

/**
 * Validate that a file path is safe for upload (prevents path traversal)
 * @param filePath The path to validate
 * @returns The resolved absolute path if valid
 * @throws Error if path is outside allowed directories
 */
export function validateFilePath(filePath: string): string {
  const resolvedPath = path.resolve(filePath);

  // Check if path is within allowed directories
  const isAllowed = ALLOWED_UPLOAD_DIRS.some(dir => resolvedPath.startsWith(dir));

  if (!isAllowed) {
    throw new Error(
      `File path not in allowed directories. ` +
      `Path must be within: ${ALLOWED_UPLOAD_DIRS.join(", ")}`
    );
  }

  // Check for path traversal attempts
  if (filePath.includes("..")) {
    throw new Error("Path traversal detected: '..' not allowed in file paths");
  }

  return resolvedPath;
}

// Blocked hosts for SSRF prevention
const BLOCKED_HOSTS = [
  "localhost",
  "127.0.0.1",
  "0.0.0.0",
  "169.254.169.254", // AWS metadata
  "[::1]",
];

// Blocked IP ranges (private networks)
const BLOCKED_IP_PATTERNS = [
  /^10\./,             // 10.0.0.0/8
  /^192\.168\./,       // 192.168.0.0/16
  /^172\.(1[6-9]|2\d|3[01])\./, // 172.16.0.0/12
  /^127\./,            // 127.0.0.0/8
  /^169\.254\./,       // Link-local
];

/**
 * Validate a URL is safe for fetching (prevents SSRF)
 * @param urlString The URL to validate
 * @returns The validated URL object
 * @throws Error if URL is blocked for security reasons
 */
export function validateRemoteUrl(urlString: string): URL {
  const url = new URL(urlString);

  // Only allow HTTPS
  if (url.protocol !== "https:") {
    throw new Error("Only HTTPS URLs are allowed for remote resources");
  }

  // Check blocked hosts
  if (BLOCKED_HOSTS.includes(url.hostname.toLowerCase())) {
    throw new Error(`Blocked hostname: ${url.hostname}`);
  }

  // Check blocked IP patterns
  for (const pattern of BLOCKED_IP_PATTERNS) {
    if (pattern.test(url.hostname)) {
      throw new Error(`Blocked IP range: ${url.hostname}`);
    }
  }

  return url;
}

/**
 * Sanitize data for logging (remove sensitive information)
 */
export function sanitizeForLog(obj: Record<string, unknown>): Record<string, unknown> {
  const SENSITIVE_PATTERNS = [/token/i, /password/i, /secret/i, /key/i, /auth/i];

  const sanitized: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(obj)) {
    // Check if key matches sensitive pattern
    const isSensitive = SENSITIVE_PATTERNS.some(pattern => pattern.test(key));

    if (isSensitive) {
      sanitized[key] = "[REDACTED]";
    } else if (typeof value === "string" && value.length > 100) {
      // Truncate long strings and show hash
      sanitized[key] = value.substring(0, 50) + "...";
    } else if (typeof value === "object" && value !== null) {
      sanitized[key] = sanitizeForLog(value as Record<string, unknown>);
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
}
