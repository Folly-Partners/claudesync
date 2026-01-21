#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ToolSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import * as fs from "fs/promises";
import * as path from "path";
import { execSync } from "child_process";
import { Pinecone } from "@pinecone-database/pinecone";
import * as cheerio from "cheerio";

// Types
interface ContentItem {
  id: string;
  source: "tweet" | "newsletter" | "book" | "youtube";
  content: string;
  title?: string;
  url?: string;
  date: string;
  metadata: Record<string, unknown>;
}

interface SearchResult {
  id: string;
  score: number;
  content: string;
  source: string;
  date: string;
  metadata: Record<string, unknown>;
}

type Result<T> = { success: true; data: T } | { success: false; error: string };

// Configuration
const UPDIKE_DIR = path.join(process.env.HOME || "~", ".updike");
const CONTENT_DIR = path.join(UPDIKE_DIR, "content");
const PINECONE_INDEX = "updike-content";

// Initialize clients (lazy)
let pinecone: Pinecone | null = null;

// Helper: Get API key from deep-env (consistent with other Updike servers)
function getApiKey(key: string): string | null {
  try {
    const result = execSync(`deep-env get ${key}`, { encoding: "utf-8" }).trim();
    return result || null;
  } catch {
    return null;
  }
}

async function getPinecone(): Promise<Pinecone> {
  if (!pinecone) {
    const apiKey = getApiKey("PINECONE_API_KEY");
    if (!apiKey) {
      throw new Error(
        "PINECONE_API_KEY not found. Run: deep-env store PINECONE_API_KEY <your-key>"
      );
    }
    pinecone = new Pinecone({ apiKey });
  }
  return pinecone;
}

// Helper: Generate embedding using Pinecone Inference API (multilingual-e5-large)
async function generateEmbedding(
  text: string,
  inputType: "passage" | "query" = "passage"
): Promise<number[]> {
  const pc = await getPinecone();

  const result = await pc.inference.embed(
    "multilingual-e5-large",
    [text],
    { inputType, truncate: "END" }
  );

  return result.data[0].values;
}

// Helper: Save content to local file
async function saveContentLocally(item: ContentItem): Promise<void> {
  const sourceDir = path.join(CONTENT_DIR, `${item.source}s`);
  await fs.mkdir(sourceDir, { recursive: true });

  const filename = `${item.date}-${item.id}.md`;
  const filepath = path.join(sourceDir, filename);

  const frontmatter = `---
id: ${item.id}
source: ${item.source}
date: ${item.date}
${item.title ? `title: "${item.title}"` : ""}
${item.url ? `url: ${item.url}` : ""}
${Object.entries(item.metadata).map(([k, v]) => `${k}: ${JSON.stringify(v)}`).join("\n")}
---

`;

  await fs.writeFile(filepath, frontmatter + item.content);
}

// Helper: Index content in Pinecone
async function indexContent(item: ContentItem): Promise<void> {
  const pc = await getPinecone();
  const index = pc.index(PINECONE_INDEX);

  const embedding = await generateEmbedding(item.content);

  await index.upsert([{
    id: item.id,
    values: embedding,
    metadata: {
      source: item.source,
      date: item.date,
      title: item.title || "",
      url: item.url || "",
      content_preview: item.content.slice(0, 500),
      ...item.metadata,
    },
  }]);
}

// Tool implementations
async function ingestNewsletter(url: string): Promise<Result<ContentItem>> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      return { success: false, error: `Failed to fetch: ${response.status}` };
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    // Extract content from Webflow blog post structure
    const title = $("h1").first().text().trim() || $("title").text().trim();
    const content = $(".blog-post-content, .w-richtext, article").first().text().trim();

    if (!content) {
      return { success: false, error: "Could not extract content from page" };
    }

    // Generate ID from URL slug
    const slug = url.split("/").pop()?.replace(/[^a-z0-9]/gi, "-") || "unknown";
    const date = new Date().toISOString().split("T")[0];

    const item: ContentItem = {
      id: `newsletter-${slug}`,
      source: "newsletter",
      content,
      title,
      url,
      date,
      metadata: {
        word_count: content.split(/\s+/).length,
        ingested_at: new Date().toISOString(),
      },
    };

    await saveContentLocally(item);
    await indexContent(item);

    return { success: true, data: item };
  } catch (error) {
    return { success: false, error: `Ingestion failed: ${error}` };
  }
}

async function ingestTweet(
  tweetId: string,
  content: string,
  metrics: Record<string, number>
): Promise<Result<ContentItem>> {
  try {
    const date = new Date().toISOString().split("T")[0];

    const item: ContentItem = {
      id: `tweet-${tweetId}`,
      source: "tweet",
      content,
      date,
      metadata: {
        tweet_id: tweetId,
        likes: metrics.likes || 0,
        retweets: metrics.retweets || 0,
        replies: metrics.replies || 0,
        impressions: metrics.impressions || 0,
        ingested_at: new Date().toISOString(),
      },
    };

    await saveContentLocally(item);
    await indexContent(item);

    return { success: true, data: item };
  } catch (error) {
    return { success: false, error: `Ingestion failed: ${error}` };
  }
}

async function ingestYouTube(
  videoId: string,
  title: string,
  transcript: string
): Promise<Result<ContentItem>> {
  try {
    const date = new Date().toISOString().split("T")[0];

    const item: ContentItem = {
      id: `youtube-${videoId}`,
      source: "youtube",
      content: transcript,
      title,
      url: `https://youtube.com/watch?v=${videoId}`,
      date,
      metadata: {
        video_id: videoId,
        word_count: transcript.split(/\s+/).length,
        ingested_at: new Date().toISOString(),
      },
    };

    await saveContentLocally(item);
    await indexContent(item);

    return { success: true, data: item };
  } catch (error) {
    return { success: false, error: `Ingestion failed: ${error}` };
  }
}

async function ingestBookChapter(
  chapterNumber: number,
  title: string,
  content: string
): Promise<Result<ContentItem>> {
  try {
    const date = new Date().toISOString().split("T")[0];

    const item: ContentItem = {
      id: `book-chapter-${chapterNumber}`,
      source: "book",
      content,
      title,
      date,
      metadata: {
        chapter_number: chapterNumber,
        word_count: content.split(/\s+/).length,
        ingested_at: new Date().toISOString(),
      },
    };

    await saveContentLocally(item);
    await indexContent(item);

    return { success: true, data: item };
  } catch (error) {
    return { success: false, error: `Ingestion failed: ${error}` };
  }
}

async function searchContent(
  query: string,
  limit: number = 10,
  source?: string
): Promise<Result<SearchResult[]>> {
  try {
    const pc = await getPinecone();
    const index = pc.index(PINECONE_INDEX);

    // Use 'query' inputType for search queries
    const embedding = await generateEmbedding(query, "query");

    const filter = source ? { source: { $eq: source } } : undefined;

    const results = await index.query({
      vector: embedding,
      topK: limit,
      includeMetadata: true,
      filter,
    });

    const searchResults: SearchResult[] = results.matches.map((match) => ({
      id: match.id,
      score: match.score || 0,
      content: (match.metadata?.content_preview as string) || "",
      source: (match.metadata?.source as string) || "unknown",
      date: (match.metadata?.date as string) || "",
      metadata: match.metadata || {},
    }));

    return { success: true, data: searchResults };
  } catch (error) {
    return { success: false, error: `Search failed: ${error}` };
  }
}

async function getContent(id: string): Promise<Result<ContentItem | null>> {
  try {
    // Determine source from ID prefix
    const source = id.split("-")[0] as ContentItem["source"];
    const sourceDir = path.join(CONTENT_DIR, `${source}s`);

    const files = await fs.readdir(sourceDir);
    const file = files.find((f) => f.includes(id));

    if (!file) {
      return { success: true, data: null };
    }

    const filepath = path.join(sourceDir, file);
    const content = await fs.readFile(filepath, "utf-8");

    // Parse frontmatter
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
    const body = content.replace(/^---\n[\s\S]*?\n---\n/, "");

    let metadata: Record<string, unknown> = {};
    if (frontmatterMatch) {
      const lines = frontmatterMatch[1].split("\n");
      for (const line of lines) {
        const [key, ...valueParts] = line.split(": ");
        if (key && valueParts.length) {
          try {
            metadata[key] = JSON.parse(valueParts.join(": "));
          } catch {
            metadata[key] = valueParts.join(": ").replace(/^"|"$/g, "");
          }
        }
      }
    }

    const item: ContentItem = {
      id: (metadata.id as string) || id,
      source: (metadata.source as ContentItem["source"]) || source,
      content: body,
      title: metadata.title as string | undefined,
      url: metadata.url as string | undefined,
      date: (metadata.date as string) || "",
      metadata,
    };

    return { success: true, data: item };
  } catch (error) {
    return { success: false, error: `Failed to get content: ${error}` };
  }
}

async function listSources(): Promise<Result<{ source: string; count: number }[]>> {
  try {
    const sources: { source: string; count: number }[] = [];

    for (const source of ["tweets", "newsletters", "book", "youtube"]) {
      const sourceDir = path.join(CONTENT_DIR, source);
      try {
        const files = await fs.readdir(sourceDir);
        sources.push({ source, count: files.length });
      } catch {
        sources.push({ source, count: 0 });
      }
    }

    return { success: true, data: sources };
  } catch (error) {
    return { success: false, error: `Failed to list sources: ${error}` };
  }
}

async function scrapeAllNewsletters(): Promise<Result<{ ingested: number; errors: string[] }>> {
  try {
    const baseUrl = "https://www.neverenough.com/post";
    const errors: string[] = [];
    let ingested = 0;

    // Fetch the blog index pages
    for (let page = 1; page <= 5; page++) {
      const indexUrl = page === 1 ? baseUrl : `${baseUrl}?page=${page}`;

      try {
        const response = await fetch(indexUrl);
        if (!response.ok) continue;

        const html = await response.text();
        const $ = cheerio.load(html);

        // Find all blog post links
        const links: string[] = [];
        $('a[href*="/post/"]').each((_, el) => {
          const href = $(el).attr("href");
          if (href && !href.endsWith("/post") && !href.includes("?page=")) {
            const fullUrl = href.startsWith("http") ? href : `https://www.neverenough.com${href}`;
            if (!links.includes(fullUrl)) {
              links.push(fullUrl);
            }
          }
        });

        // Ingest each post
        for (const link of links) {
          const result = await ingestNewsletter(link);
          if (result.success) {
            ingested++;
          } else {
            errors.push(`${link}: ${result.error}`);
          }

          // Rate limit
          await new Promise((resolve) => setTimeout(resolve, 1000));
        }
      } catch (e) {
        errors.push(`Page ${page}: ${e}`);
      }
    }

    return { success: true, data: { ingested, errors } };
  } catch (error) {
    return { success: false, error: `Scrape failed: ${error}` };
  }
}

// MCP Server setup
const server = new Server(
  { name: "updike-content-archive", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// Tool definitions
const tools: z.infer<typeof ToolSchema>[] = [
  {
    name: "ingest_newsletter",
    description: "Scrape and store a newsletter post from neverenough.com",
    inputSchema: {
      type: "object",
      properties: {
        url: { type: "string", description: "Full URL of the newsletter post" },
      },
      required: ["url"],
    },
  },
  {
    name: "ingest_tweet",
    description: "Store a tweet with engagement metrics",
    inputSchema: {
      type: "object",
      properties: {
        tweet_id: { type: "string", description: "Twitter/X tweet ID" },
        content: { type: "string", description: "Tweet text content" },
        likes: { type: "number", description: "Number of likes" },
        retweets: { type: "number", description: "Number of retweets" },
        replies: { type: "number", description: "Number of replies" },
        impressions: { type: "number", description: "Number of impressions" },
      },
      required: ["tweet_id", "content"],
    },
  },
  {
    name: "ingest_youtube",
    description: "Store a YouTube video transcript",
    inputSchema: {
      type: "object",
      properties: {
        video_id: { type: "string", description: "YouTube video ID" },
        title: { type: "string", description: "Video title" },
        transcript: { type: "string", description: "Full video transcript" },
      },
      required: ["video_id", "title", "transcript"],
    },
  },
  {
    name: "ingest_book_chapter",
    description: "Store a book chapter",
    inputSchema: {
      type: "object",
      properties: {
        chapter_number: { type: "number", description: "Chapter number" },
        title: { type: "string", description: "Chapter title" },
        content: { type: "string", description: "Chapter content" },
      },
      required: ["chapter_number", "title", "content"],
    },
  },
  {
    name: "search_content",
    description: "Semantic search across all content archives",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search query" },
        limit: { type: "number", description: "Max results (default 10)" },
        source: {
          type: "string",
          enum: ["tweet", "newsletter", "book", "youtube"],
          description: "Filter by source type",
        },
      },
      required: ["query"],
    },
  },
  {
    name: "get_content",
    description: "Retrieve specific content by ID",
    inputSchema: {
      type: "object",
      properties: {
        id: { type: "string", description: "Content ID" },
      },
      required: ["id"],
    },
  },
  {
    name: "list_sources",
    description: "Show available content sources and counts",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "scrape_all_newsletters",
    description: "Scrape all newsletter posts from neverenough.com (use for initial ingestion)",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools,
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "ingest_newsletter": {
        const result = await ingestNewsletter(args.url as string);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "ingest_tweet": {
        const result = await ingestTweet(
          args.tweet_id as string,
          args.content as string,
          {
            likes: (args.likes as number) || 0,
            retweets: (args.retweets as number) || 0,
            replies: (args.replies as number) || 0,
            impressions: (args.impressions as number) || 0,
          }
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "ingest_youtube": {
        const result = await ingestYouTube(
          args.video_id as string,
          args.title as string,
          args.transcript as string
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "ingest_book_chapter": {
        const result = await ingestBookChapter(
          args.chapter_number as number,
          args.title as string,
          args.content as string
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "search_content": {
        const result = await searchContent(
          args.query as string,
          (args.limit as number) || 10,
          args.source as string | undefined
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "get_content": {
        const result = await getContent(args.id as string);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "list_sources": {
        const result = await listSources();
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "scrape_all_newsletters": {
        const result = await scrapeAllNewsletters();
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      default:
        return {
          content: [{ type: "text", text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }
  } catch (error) {
    return {
      content: [{ type: "text", text: `Error: ${error}` }],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Updike Content Archive MCP server running");
}

main().catch(console.error);
