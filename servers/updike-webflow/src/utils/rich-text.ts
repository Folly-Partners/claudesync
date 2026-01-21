import { marked } from "marked";
import { sanitizeHtml } from "./security.js";

// Configure marked for safe output
marked.setOptions({
  gfm: true, // GitHub Flavored Markdown
  breaks: true, // Convert \n to <br>
});

/**
 * Convert Markdown to Webflow-compatible rich text HTML
 * Includes sanitization for XSS prevention
 */
export function markdownToWebflowHtml(markdown: string): string {
  // Convert markdown to HTML
  const rawHtml = marked.parse(markdown) as string;

  // Sanitize the HTML
  const sanitized = sanitizeHtml(rawHtml);

  return sanitized;
}

/**
 * Generate a URL-safe slug from a title
 */
export function generateSlug(title: string): string {
  return title
    .toLowerCase()
    .normalize("NFD") // Normalize accented characters
    .replace(/[\u0300-\u036f]/g, "") // Remove diacritics
    .replace(/[^a-z0-9\s-]/g, "") // Remove non-alphanumeric
    .replace(/\s+/g, "-") // Replace spaces with hyphens
    .replace(/-+/g, "-") // Collapse multiple hyphens
    .replace(/^-|-$/g, ""); // Trim hyphens from ends
}

/**
 * Generate an excerpt from HTML content
 */
export function generateExcerpt(html: string, maxLength = 155): string {
  // Strip HTML tags
  const plainText = html
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (plainText.length <= maxLength) {
    return plainText;
  }

  // Truncate at word boundary
  const truncated = plainText.substring(0, maxLength);
  const lastSpace = truncated.lastIndexOf(" ");

  if (lastSpace > 0) {
    return truncated.substring(0, lastSpace) + "...";
  }

  return truncated + "...";
}
