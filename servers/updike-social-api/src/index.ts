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
import { createHmac } from "crypto";

// Types
type Result<T> = { success: true; data: T } | { success: false; error: string };

interface PostResult {
  platform: string;
  post_id: string;
  url: string;
  posted_at: string;
}

interface ScheduledPost {
  id: string;
  platform: string;
  content: string;
  scheduled_for: string;
  created_at: string;
}

interface AnalyticsData {
  post_id: string;
  platform: string;
  impressions: number;
  likes: number;
  comments: number;
  shares: number;
  saves?: number;
  fetched_at: string;
}

// Configuration
const UPDIKE_DIR = path.join(process.env.HOME || "~", ".updike");
const DECISIONS_DIR = path.join(UPDIKE_DIR, "decisions");
const ANALYTICS_FILE = path.join(UPDIKE_DIR, "analytics", "performance.json");

// Helper: Get token from deep-env (secure keychain storage)
function getToken(key: string): string | null {
  try {
    const result = execSync(`deep-env get ${key}`, { encoding: "utf-8" }).trim();
    return result || null;
  } catch {
    return null;
  }
}

// Helper: Store token via deep-env
function storeToken(key: string, value: string): boolean {
  try {
    execSync(`deep-env store ${key} "${value}"`, { encoding: "utf-8" });
    return true;
  } catch {
    return false;
  }
}

// Helper: Log decision
async function logDecision(
  action: string,
  platform: string,
  contentPreview: string,
  status: string,
  postId?: string
): Promise<void> {
  await fs.mkdir(DECISIONS_DIR, { recursive: true });

  const date = new Date().toISOString().split("T")[0];
  const logFile = path.join(DECISIONS_DIR, `${date}-decisions.json`);

  let logs: unknown[] = [];
  try {
    const existing = await fs.readFile(logFile, "utf-8");
    logs = JSON.parse(existing);
  } catch {
    // File doesn't exist yet
  }

  logs.push({
    timestamp: new Date().toISOString(),
    action,
    platform,
    content_preview: contentPreview.slice(0, 50) + "...",
    content_hash: simpleHash(contentPreview),
    status,
    post_id: postId,
  });

  await fs.writeFile(logFile, JSON.stringify(logs, null, 2));
}

function simpleHash(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return `sha256:${Math.abs(hash).toString(16)}`;
}

// Twitter/X OAuth 1.0a authentication
// OAuth 1.0a tokens don't expire, making them more reliable for automated posting

interface OAuth1Credentials {
  consumerKey: string;
  consumerSecret: string;
  accessToken: string;
  accessTokenSecret: string;
}

function getXOAuth1Credentials(): OAuth1Credentials | null {
  const consumerKey = getToken("UPDIKE_X_CLIENT_ID");
  const consumerSecret = getToken("UPDIKE_X_CLIENT_SECRET");
  const accessToken = getToken("UPDIKE_X_ACCESS_TOKEN");
  const accessTokenSecret = getToken("UPDIKE_X_ACCESS_TOKEN_SECRET");

  if (!consumerKey || !consumerSecret || !accessToken || !accessTokenSecret) {
    return null;
  }

  return { consumerKey, consumerSecret, accessToken, accessTokenSecret };
}

// Generate OAuth 1.0a signature
function generateOAuth1Signature(
  method: string,
  url: string,
  params: Record<string, string>,
  consumerSecret: string,
  tokenSecret: string
): string {
  // Sort and encode parameters
  const sortedParams = Object.keys(params)
    .sort()
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
    .join("&");

  // Create signature base string
  const signatureBase = [
    method.toUpperCase(),
    encodeURIComponent(url),
    encodeURIComponent(sortedParams),
  ].join("&");

  // Create signing key
  const signingKey = `${encodeURIComponent(consumerSecret)}&${encodeURIComponent(tokenSecret)}`;

  // Generate HMAC-SHA1 signature
  const signature = createHmac("sha1", signingKey)
    .update(signatureBase)
    .digest("base64");

  return signature;
}

// Generate OAuth 1.0a Authorization header
function generateOAuth1Header(
  method: string,
  url: string,
  credentials: OAuth1Credentials,
  additionalParams: Record<string, string> = {}
): string {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const nonce = Math.random().toString(36).substring(2) + Date.now().toString(36);

  const oauthParams: Record<string, string> = {
    oauth_consumer_key: credentials.consumerKey,
    oauth_nonce: nonce,
    oauth_signature_method: "HMAC-SHA1",
    oauth_timestamp: timestamp,
    oauth_token: credentials.accessToken,
    oauth_version: "1.0",
  };

  // Combine oauth params with additional params for signature
  const allParams = { ...oauthParams, ...additionalParams };

  // Generate signature
  const signature = generateOAuth1Signature(
    method,
    url,
    allParams,
    credentials.consumerSecret,
    credentials.accessTokenSecret
  );

  oauthParams.oauth_signature = signature;

  // Build Authorization header
  const headerParams = Object.keys(oauthParams)
    .sort()
    .map(key => `${encodeURIComponent(key)}="${encodeURIComponent(oauthParams[key])}"`)
    .join(", ");

  return `OAuth ${headerParams}`;
}

// Tool implementations
async function postToX(content: string): Promise<Result<PostResult>> {
  const credentials = getXOAuth1Credentials();
  if (!credentials) {
    return {
      success: false,
      error: "X/Twitter credentials not configured. Store UPDIKE_X_CLIENT_ID, UPDIKE_X_CLIENT_SECRET, UPDIKE_X_ACCESS_TOKEN, and UPDIKE_X_ACCESS_TOKEN_SECRET via deep-env.",
    };
  }

  try {
    // Check for taboo violations
    if (content.includes("#")) {
      return {
        success: false,
        error: "Content contains hashtags - not allowed per style guide. Remove hashtags and retry.",
      };
    }

    const url = "https://api.twitter.com/2/tweets";
    const authHeader = generateOAuth1Header("POST", url, credentials);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: authHeader,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ text: content }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      const errorMessage = errorData.detail || errorData.title || JSON.stringify(errorData);
      await logDecision("post", "x", content, `error: ${errorMessage}`);
      return { success: false, error: `X API error: ${errorMessage}` };
    }

    const data = await response.json();
    const tweetId = data.data.id;

    const result: PostResult = {
      platform: "x",
      post_id: tweetId,
      url: `https://twitter.com/awilkinson/status/${tweetId}`,
      posted_at: new Date().toISOString(),
    };

    await logDecision("post", "x", content, "success", tweetId);

    return { success: true, data: result };
  } catch (error) {
    await logDecision("post", "x", content, `error: ${error}`);
    return { success: false, error: `Failed to post: ${error}` };
  }
}

async function postToLinkedIn(content: string): Promise<Result<PostResult>> {
  const accessToken = getToken("UPDIKE_LINKEDIN_TOKEN");
  if (!accessToken) {
    return {
      success: false,
      error: "LinkedIn credentials not configured. Set up OAuth and store token via deep-env.",
    };
  }

  try {
    // LinkedIn API requires getting user ID first
    const userResponse = await fetch("https://api.linkedin.com/v2/userinfo", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!userResponse.ok) {
      return { success: false, error: "LinkedIn authentication failed. Token may be expired." };
    }

    const userData = await userResponse.json();
    const userId = userData.sub;

    // Create post
    const postResponse = await fetch("https://api.linkedin.com/v2/ugcPosts", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "X-Restli-Protocol-Version": "2.0.0",
      },
      body: JSON.stringify({
        author: `urn:li:person:${userId}`,
        lifecycleState: "PUBLISHED",
        specificContent: {
          "com.linkedin.ugc.ShareContent": {
            shareCommentary: { text: content },
            shareMediaCategory: "NONE",
          },
        },
        visibility: { "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC" },
      }),
    });

    if (!postResponse.ok) {
      const errorText = await postResponse.text();
      return { success: false, error: `LinkedIn API error: ${errorText}` };
    }

    const postData = await postResponse.json();

    const result: PostResult = {
      platform: "linkedin",
      post_id: postData.id,
      url: `https://www.linkedin.com/feed/update/${postData.id}`,
      posted_at: new Date().toISOString(),
    };

    await logDecision("post", "linkedin", content, "success", postData.id);

    return { success: true, data: result };
  } catch (error) {
    await logDecision("post", "linkedin", content, `error: ${error}`);
    return { success: false, error: `Failed to post: ${error}` };
  }
}

async function postToInstagram(
  content: string,
  imageUrl?: string
): Promise<Result<PostResult>> {
  const accessToken = getToken("UPDIKE_INSTAGRAM_TOKEN");
  const accountId = getToken("UPDIKE_INSTAGRAM_ACCOUNT_ID");

  if (!accessToken || !accountId) {
    return {
      success: false,
      error: "Instagram credentials not configured. Connect via Meta Business Suite.",
    };
  }

  if (!imageUrl) {
    return {
      success: false,
      error: "Instagram requires an image. Provide imageUrl parameter.",
    };
  }

  try {
    // Step 1: Create media container
    const containerResponse = await fetch(
      `https://graph.facebook.com/v18.0/${accountId}/media`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          image_url: imageUrl,
          caption: content,
          access_token: accessToken,
        }),
      }
    );

    if (!containerResponse.ok) {
      const errorText = await containerResponse.text();
      return { success: false, error: `Failed to create media container: ${errorText}` };
    }

    const containerData = await containerResponse.json();
    const containerId = containerData.id;

    // Step 2: Publish the container
    const publishResponse = await fetch(
      `https://graph.facebook.com/v18.0/${accountId}/media_publish`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          creation_id: containerId,
          access_token: accessToken,
        }),
      }
    );

    if (!publishResponse.ok) {
      const errorText = await publishResponse.text();
      return { success: false, error: `Failed to publish: ${errorText}` };
    }

    const publishData = await publishResponse.json();

    const result: PostResult = {
      platform: "instagram",
      post_id: publishData.id,
      url: `https://www.instagram.com/p/${publishData.id}`,
      posted_at: new Date().toISOString(),
    };

    await logDecision("post", "instagram", content, "success", publishData.id);

    return { success: true, data: result };
  } catch (error) {
    await logDecision("post", "instagram", content, `error: ${error}`);
    return { success: false, error: `Failed to post: ${error}` };
  }
}

async function postToThreads(content: string): Promise<Result<PostResult>> {
  const accessToken = getToken("UPDIKE_THREADS_TOKEN");
  const userId = getToken("UPDIKE_THREADS_USER_ID");

  if (!accessToken || !userId) {
    return {
      success: false,
      error: "Threads credentials not configured. Connect via Meta Business Suite.",
    };
  }

  try {
    // Step 1: Create media container
    const containerResponse = await fetch(
      `https://graph.threads.net/v1.0/${userId}/threads`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          media_type: "TEXT",
          text: content,
          access_token: accessToken,
        }),
      }
    );

    if (!containerResponse.ok) {
      const errorText = await containerResponse.text();
      return { success: false, error: `Failed to create thread: ${errorText}` };
    }

    const containerData = await containerResponse.json();

    // Step 2: Publish
    const publishResponse = await fetch(
      `https://graph.threads.net/v1.0/${userId}/threads_publish`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          creation_id: containerData.id,
          access_token: accessToken,
        }),
      }
    );

    if (!publishResponse.ok) {
      const errorText = await publishResponse.text();
      return { success: false, error: `Failed to publish: ${errorText}` };
    }

    const publishData = await publishResponse.json();

    const result: PostResult = {
      platform: "threads",
      post_id: publishData.id,
      url: `https://www.threads.net/@awilkinson/post/${publishData.id}`,
      posted_at: new Date().toISOString(),
    };

    await logDecision("post", "threads", content, "success", publishData.id);

    return { success: true, data: result };
  } catch (error) {
    await logDecision("post", "threads", content, `error: ${error}`);
    return { success: false, error: `Failed to post: ${error}` };
  }
}

async function schedulePost(
  platform: string,
  content: string,
  scheduledFor: string
): Promise<Result<ScheduledPost>> {
  // For now, store scheduled posts locally
  // In production, this would use platform scheduling APIs or a job queue
  const scheduledDir = path.join(UPDIKE_DIR, "scheduled");
  await fs.mkdir(scheduledDir, { recursive: true });

  const id = `scheduled-${Date.now()}`;
  const post: ScheduledPost = {
    id,
    platform,
    content,
    scheduled_for: scheduledFor,
    created_at: new Date().toISOString(),
  };

  const filepath = path.join(scheduledDir, `${id}.json`);
  await fs.writeFile(filepath, JSON.stringify(post, null, 2));

  await logDecision("schedule", platform, content, "scheduled", id);

  return { success: true, data: post };
}

async function getAnalytics(
  platform: string,
  postId: string
): Promise<Result<AnalyticsData>> {
  // Fetch analytics from respective platform APIs

  if (platform === "x") {
    const credentials = getXOAuth1Credentials();
    if (!credentials) {
      return { success: false, error: "X/Twitter credentials not configured." };
    }

    try {
      const url = `https://api.twitter.com/2/tweets/${postId}?tweet.fields=public_metrics`;
      const authHeader = generateOAuth1Header("GET", url.split("?")[0], credentials);

      const response = await fetch(url, {
        headers: {
          Authorization: authHeader,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        return { success: false, error: `X API error: ${errorData.detail || errorData.title}` };
      }

      const result = await response.json();
      const metrics = result.data?.public_metrics;

      const data: AnalyticsData = {
        post_id: postId,
        platform: "x",
        impressions: metrics?.impression_count || 0,
        likes: metrics?.like_count || 0,
        comments: metrics?.reply_count || 0,
        shares: metrics?.retweet_count || 0,
        fetched_at: new Date().toISOString(),
      };

      return { success: true, data };
    } catch (error) {
      return { success: false, error: `Failed to fetch analytics: ${error}` };
    }
  }

  // Add implementations for other platforms as needed
  return { success: false, error: `Analytics not yet implemented for ${platform}` };
}

async function deletePost(
  platform: string,
  postId: string
): Promise<Result<{ deleted: boolean }>> {
  // This is a high-stakes operation - requires full approval in the skill
  await logDecision("delete", platform, `post_id: ${postId}`, "requested");

  if (platform === "x") {
    const credentials = getXOAuth1Credentials();
    if (!credentials) {
      return { success: false, error: "X/Twitter credentials not configured." };
    }

    try {
      const url = `https://api.twitter.com/2/tweets/${postId}`;
      const authHeader = generateOAuth1Header("DELETE", url, credentials);

      const response = await fetch(url, {
        method: "DELETE",
        headers: {
          Authorization: authHeader,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        return { success: false, error: `X API error: ${errorData.detail || errorData.title}` };
      }

      await logDecision("delete", platform, `post_id: ${postId}`, "success");
      return { success: true, data: { deleted: true } };
    } catch (error) {
      return { success: false, error: `Failed to delete: ${error}` };
    }
  }

  return { success: false, error: `Delete not yet implemented for ${platform}` };
}

async function checkCredentials(): Promise<Result<Record<string, boolean | string>>> {
  // Check X OAuth 1.0a credentials (these don't expire)
  const xCredentials = getXOAuth1Credentials();
  const xConfigured = xCredentials !== null;

  const credentials: Record<string, boolean | string> = {
    x_configured: xConfigured,
    x_status: xConfigured ? "configured" : "not_configured",
    linkedin_configured: !!getToken("UPDIKE_LINKEDIN_TOKEN"),
    instagram_configured: !!getToken("UPDIKE_INSTAGRAM_TOKEN") && !!getToken("UPDIKE_INSTAGRAM_ACCOUNT_ID"),
    threads_configured: !!getToken("UPDIKE_THREADS_TOKEN") && !!getToken("UPDIKE_THREADS_USER_ID"),
  };

  return { success: true, data: credentials };
}

// MCP Server setup
const server = new Server(
  { name: "updike-social-api", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// Tool definitions
const tools: z.infer<typeof ToolSchema>[] = [
  {
    name: "post_to_x",
    description: "Post content to X/Twitter. Requires quick-confirm approval.",
    inputSchema: {
      type: "object",
      properties: {
        content: { type: "string", description: "Post content (max 280 chars, or 4000 for premium)" },
      },
      required: ["content"],
    },
  },
  {
    name: "post_to_linkedin",
    description: "Post content to LinkedIn. Requires quick-confirm approval.",
    inputSchema: {
      type: "object",
      properties: {
        content: { type: "string", description: "Post content (max 3000 chars)" },
      },
      required: ["content"],
    },
  },
  {
    name: "post_to_instagram",
    description: "Post content to Instagram. Requires full approval and an image.",
    inputSchema: {
      type: "object",
      properties: {
        content: { type: "string", description: "Caption (max 2200 chars)" },
        image_url: { type: "string", description: "URL of the image to post" },
      },
      required: ["content", "image_url"],
    },
  },
  {
    name: "post_to_threads",
    description: "Post content to Threads. Requires quick-confirm approval.",
    inputSchema: {
      type: "object",
      properties: {
        content: { type: "string", description: "Post content (max 500 chars)" },
      },
      required: ["content"],
    },
  },
  {
    name: "schedule_post",
    description: "Schedule a post for future publishing",
    inputSchema: {
      type: "object",
      properties: {
        platform: { type: "string", enum: ["x", "linkedin", "instagram", "threads"] },
        content: { type: "string", description: "Post content" },
        scheduled_for: { type: "string", description: "ISO timestamp for when to post" },
      },
      required: ["platform", "content", "scheduled_for"],
    },
  },
  {
    name: "get_analytics",
    description: "Fetch engagement metrics for a specific post",
    inputSchema: {
      type: "object",
      properties: {
        platform: { type: "string", enum: ["x", "linkedin", "instagram", "threads"] },
        post_id: { type: "string", description: "Platform-specific post ID" },
      },
      required: ["platform", "post_id"],
    },
  },
  {
    name: "delete_post",
    description: "Delete a post. Requires full approval - this cannot be undone.",
    inputSchema: {
      type: "object",
      properties: {
        platform: { type: "string", enum: ["x", "linkedin", "instagram", "threads"] },
        post_id: { type: "string", description: "Platform-specific post ID" },
      },
      required: ["platform", "post_id"],
    },
  },
  {
    name: "check_credentials",
    description: "Check which platform credentials are configured",
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
      case "post_to_x": {
        const result = await postToX(args.content as string);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "post_to_linkedin": {
        const result = await postToLinkedIn(args.content as string);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "post_to_instagram": {
        const result = await postToInstagram(
          args.content as string,
          args.image_url as string
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "post_to_threads": {
        const result = await postToThreads(args.content as string);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "schedule_post": {
        const result = await schedulePost(
          args.platform as string,
          args.content as string,
          args.scheduled_for as string
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "get_analytics": {
        const result = await getAnalytics(
          args.platform as string,
          args.post_id as string
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "delete_post": {
        const result = await deletePost(
          args.platform as string,
          args.post_id as string
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "check_credentials": {
        const result = await checkCredentials();
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
  console.error("Updike Social API MCP server running");
}

main().catch(console.error);
