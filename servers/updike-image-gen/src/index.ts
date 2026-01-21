#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  type Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { GoogleGenAI } from "@google/genai";
import sharp from "sharp";
import * as fs from "fs/promises";
import * as path from "path";
import { execSync } from "child_process";

// Types
type Result<T> = { success: true; data: T } | { success: false; error: string };

interface GeneratedImage {
  id: string;
  filepath: string;
  width: number;
  height: number;
  format: string;
  created_at: string;
}

interface CarouselSlide {
  slide_number: number;
  headline?: string;
  body?: string;
  image_path: string;
}

// Configuration
const UPDIKE_DIR = path.join(process.env.HOME || "~", ".updike");
const IMAGES_DIR = path.join(UPDIKE_DIR, "generated", "images");

// Brand colors from visual-guidelines.md
const BRAND_COLORS = {
  warmCream: "#F5F0E6",
  richBrown: "#3D3028",
  warmAccent: "#C17F59",
  softTerracotta: "#D4A574",
  mutedSage: "#8B9A7D",
  warmGray: "#9B9285",
  lightWarm: "#EDE5D8",
  subtleGold: "#B8965A",
};

// Dark theme colors for Nano Banana Pro
const DARK_BRAND_COLORS = {
  background: "#1a1a1a",
  headline: "#FAFAFA",
  body: "#9B9285",
  accent: "#C17F59",
  subtle: "#3D3D3D",
};

// Platform sizes
const PLATFORM_SIZES = {
  instagram_square: { width: 1080, height: 1080 },
  instagram_portrait: { width: 1080, height: 1350 },
  instagram_story: { width: 1080, height: 1920 },
  twitter: { width: 1200, height: 675 },
  linkedin_square: { width: 1200, height: 1200 },
  linkedin_landscape: { width: 1200, height: 628 },
};

// Helper: Get API key from deep-env
function getApiKey(key: string): string | null {
  try {
    const result = execSync(`deep-env get ${key}`, { encoding: "utf-8" }).trim();
    return result || null;
  } catch {
    return null;
  }
}

// Initialize Gemini client (lazy)
let genAI: GoogleGenAI | null = null;

function getGenAI(): GoogleGenAI | null {
  if (genAI) return genAI;

  const apiKey = getApiKey("GEMINI_API_KEY");
  if (!apiKey) return null;

  genAI = new GoogleGenAI({ apiKey });
  return genAI;
}

// Generate unique ID
function generateId(): string {
  return `img-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

// Tool implementations
async function generateQuoteCard(
  quote: string,
  attribution: string,
  platform: keyof typeof PLATFORM_SIZES = "instagram_square",
  style: "dark" | "light" = "dark"
): Promise<Result<GeneratedImage>> {
  const ai = getGenAI();
  if (!ai) {
    return {
      success: false,
      error: "Gemini API key not configured. Run: deep-env store GEMINI_API_KEY <key>",
    };
  }

  await fs.mkdir(IMAGES_DIR, { recursive: true });

  const size = PLATFORM_SIZES[platform];
  const id = generateId();

  try {
    const prompt = style === "dark"
      ? `Create a minimalist quote card image:

VISUAL REQUIREMENTS:
- Background: Deep charcoal (${DARK_BRAND_COLORS.background}) with subtle texture
- Text: Clean white (${DARK_BRAND_COLORS.headline}) for quote, warm gray (${DARK_BRAND_COLORS.body}) for attribution
- Font: Clean modern sans-serif (Helvetica Neue style), medium weight
- Quote text in large quotation marks at top-left corner

TEXT TO RENDER:
"${quote}"

— ${attribution}

STYLE:
- Dark, minimal, tasteful
- Professional editorial aesthetic
- Text left-aligned with generous padding
- NO decorative elements, borders, or gradients
- Easy to read on mobile

SIZE: ${size.width}x${size.height} pixels`
      : `Create a minimalist quote card image with these specifications:

VISUAL REQUIREMENTS:
- Background: Warm cream color (${BRAND_COLORS.warmCream}) with subtle texture
- Text: Dark brown (${BRAND_COLORS.richBrown})
- Font style: Clean, modern sans-serif similar to Inter
- Layout: Quote centered, attribution below in smaller text

QUOTE TEXT:
"${quote}"

ATTRIBUTION:
— ${attribution}

STYLE:
- Minimalist, no decorative elements
- Should feel personal and warm, NOT corporate
- No borders, no icons, no gradients
- Subtle paper-like texture on background

SIZE: ${size.width}x${size.height} pixels

DO NOT include any hashtags, handles, or social media icons.`;

    // Use Gemini 2.5 Flash Image model with responseModalities
    const response = await ai.models.generateContent({
      model: "gemini-3-pro-image-preview",
      contents: prompt,
      config: {
        responseModalities: ["TEXT", "IMAGE"],
      },
    });

    // Extract image from response
    const candidates = response.candidates;
    if (!candidates || candidates.length === 0) {
      return { success: false, error: "No response from Gemini" };
    }

    const parts = candidates[0].content?.parts;
    if (!parts) {
      return { success: false, error: "No content parts in response" };
    }

    // Find the image part
    for (const part of parts) {
      if (part.inlineData) {
        const imageData = part.inlineData.data;
        if (!imageData) continue;

        const buffer = Buffer.from(imageData, "base64");

        // Resize to exact platform size using Sharp
        const resizedBuffer = await sharp(buffer)
          .resize(size.width, size.height, {
            fit: "cover",
            position: "center",
          })
          .png()
          .toBuffer();

        const filepath = path.join(IMAGES_DIR, `${id}.png`);
        await fs.writeFile(filepath, resizedBuffer);

        return {
          success: true,
          data: {
            id,
            filepath,
            width: size.width,
            height: size.height,
            format: "png",
            created_at: new Date().toISOString(),
          },
        };
      }
    }

    return { success: false, error: "No image data in response" };
  } catch (error) {
    return { success: false, error: `Image generation failed: ${error}` };
  }
}

async function generateCarousel(
  slides: Array<{ headline?: string; body?: string }>,
  platform: "instagram_square" | "linkedin_square" = "instagram_square",
  style: "dark" | "light" = "dark"
): Promise<Result<{ id: string; slides: CarouselSlide[] }>> {
  const ai = getGenAI();
  if (!ai) {
    return {
      success: false,
      error: "Gemini API key not configured. Run: deep-env store GEMINI_API_KEY <key>",
    };
  }

  await fs.mkdir(IMAGES_DIR, { recursive: true });

  const size = PLATFORM_SIZES[platform];
  const carouselId = generateId();
  const carouselDir = path.join(IMAGES_DIR, carouselId);
  await fs.mkdir(carouselDir, { recursive: true });

  const generatedSlides: CarouselSlide[] = [];

  for (let i = 0; i < slides.length; i++) {
    const slide = slides[i];
    const slideNum = i + 1;
    const isFirst = i === 0;
    const isLast = i === slides.length - 1;

    const prompt = buildCarouselSlidePrompt(slide, slideNum, slides.length, isFirst, isLast, size, style);

    try {
      const response = await ai.models.generateContent({
        model: "gemini-3-pro-image-preview",
        contents: prompt,
        config: {
          responseModalities: ["TEXT", "IMAGE"],
        },
      });

      const candidates = response.candidates;
      if (!candidates || candidates.length === 0) {
        throw new Error("No response from Gemini");
      }

      const parts = candidates[0].content?.parts;
      if (!parts) {
        throw new Error("No content parts");
      }

      let savedPath: string | null = null;

      for (const part of parts) {
        if (part.inlineData?.data) {
          const buffer = Buffer.from(part.inlineData.data, "base64");

          const resizedBuffer = await sharp(buffer)
            .resize(size.width, size.height, {
              fit: "cover",
              position: "center",
            })
            .png()
            .toBuffer();

          savedPath = path.join(carouselDir, `slide-${slideNum}.png`);
          await fs.writeFile(savedPath, resizedBuffer);
          break;
        }
      }

      if (!savedPath) {
        throw new Error("No image generated");
      }

      generatedSlides.push({
        slide_number: slideNum,
        headline: slide.headline,
        body: slide.body,
        image_path: savedPath,
      });

      // Small delay between slides to avoid rate limiting
      if (i < slides.length - 1) {
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
    } catch (error) {
      return { success: false, error: `Failed to generate slide ${slideNum}: ${error}` };
    }
  }

  // Save carousel manifest
  const manifestPath = path.join(carouselDir, "manifest.json");
  await fs.writeFile(
    manifestPath,
    JSON.stringify({
      id: carouselId,
      total_slides: slides.length,
      platform,
      slides: generatedSlides,
      created_at: new Date().toISOString(),
    }, null, 2)
  );

  return {
    success: true,
    data: {
      id: carouselId,
      slides: generatedSlides,
    },
  };
}

function buildCarouselSlidePrompt(
  slide: { headline?: string; body?: string },
  slideNum: number,
  totalSlides: number,
  isFirst: boolean,
  isLast: boolean,
  size: { width: number; height: number },
  style: "dark" | "light" = "dark"
): string {
  if (style === "dark") {
    return `Create Instagram carousel slide ${slideNum} of ${totalSlides}:

VISUAL REQUIREMENTS:
- Background: Deep charcoal (${DARK_BRAND_COLORS.background})
- Headline: Clean white (${DARK_BRAND_COLORS.headline}), large sans-serif (Helvetica Neue style)
- Body: Warm gray (${DARK_BRAND_COLORS.body}), medium sans-serif
- Slide counter "${slideNum}/${totalSlides}" in bottom-right, small, gray

TEXT TO RENDER:
${slide.headline ? `HEADLINE: "${slide.headline}"` : ""}
${slide.body ? `BODY: "${slide.body}"` : ""}

LAYOUT:
- Text left-aligned
- Headline at top with generous top padding
- Body text below headline
- Slide counter bottom-right

STYLE:
- Dark, minimal, tasteful
- Professional editorial aesthetic
- Clean typography, no decorative elements
- Consistent with other carousel slides

SIZE: ${size.width}x${size.height} pixels`;
  }

  // Light style (original)
  let slideType = "content";
  if (isFirst) slideType = "hook";
  if (isLast) slideType = "cta";

  return `Create carousel slide ${slideNum} of ${totalSlides}:

TYPE: ${slideType} slide

VISUAL REQUIREMENTS:
- Background: Warm cream (${BRAND_COLORS.warmCream}) with subtle texture
- Text: Dark brown (${BRAND_COLORS.richBrown}) for headline, warm gray (${BRAND_COLORS.warmGray}) for body
- Font: Clean sans-serif (Inter-like)
- Slide indicator: "${slideNum}/${totalSlides}" in bottom corner

CONTENT:
${slide.headline ? `Headline: "${slide.headline}"` : ""}
${slide.body ? `Body: "${slide.body}"` : ""}

${isFirst ? "As the FIRST slide, this needs to stop the scroll. Make the headline prominent and intriguing." : ""}
${isLast ? "As the LAST slide, include a soft call-to-action or key takeaway." : ""}

SIZE: ${size.width}x${size.height} pixels

STYLE:
- Consistent with other slides in the carousel
- Clean, minimal, no decorative elements
- Should feel personal and warm
- Easy to read on mobile`;
}

async function resizeForPlatform(
  sourceImagePath: string,
  platform: keyof typeof PLATFORM_SIZES
): Promise<Result<GeneratedImage>> {
  try {
    // Check if source file exists
    await fs.access(sourceImagePath);
  } catch {
    return { success: false, error: `Source file not found: ${sourceImagePath}` };
  }

  const size = PLATFORM_SIZES[platform];
  const id = generateId();

  try {
    await fs.mkdir(IMAGES_DIR, { recursive: true });

    const outputPath = path.join(IMAGES_DIR, `${id}-${platform}.png`);

    // Use Sharp to resize the image
    await sharp(sourceImagePath)
      .resize(size.width, size.height, {
        fit: "cover",
        position: "center",
      })
      .png()
      .toFile(outputPath);

    return {
      success: true,
      data: {
        id,
        filepath: outputPath,
        width: size.width,
        height: size.height,
        format: "png",
        created_at: new Date().toISOString(),
      },
    };
  } catch (error) {
    return { success: false, error: `Resize failed: ${error}` };
  }
}

async function applyBrandStyle(
  imagePath: string
): Promise<Result<{ id: string; styled_path: string }>> {
  try {
    // Check if source file exists
    await fs.access(imagePath);
  } catch {
    return { success: false, error: `Source file not found: ${imagePath}` };
  }

  const id = generateId();

  try {
    await fs.mkdir(IMAGES_DIR, { recursive: true });

    const outputPath = path.join(IMAGES_DIR, `${id}-styled.png`);

    // Apply brand styling with Sharp
    // - Warm color grading (increase warmth)
    // - Slight desaturation for muted feel
    // - Subtle contrast boost
    await sharp(imagePath)
      .modulate({
        brightness: 1.02, // Slight brightness
        saturation: 0.9,  // Slight desaturation for muted look
      })
      .tint({ r: 245, g: 240, b: 230 }) // Warm cream tint
      .png()
      .toFile(outputPath);

    return {
      success: true,
      data: {
        id,
        styled_path: outputPath,
      },
    };
  } catch (error) {
    return { success: false, error: `Style application failed: ${error}` };
  }
}

async function listGeneratedImages(): Promise<Result<string[]>> {
  try {
    await fs.mkdir(IMAGES_DIR, { recursive: true });
    const files = await fs.readdir(IMAGES_DIR);
    return { success: true, data: files };
  } catch (error) {
    return { success: false, error: `Failed to list images: ${error}` };
  }
}

// MCP Server setup
const server = new Server(
  { name: "updike-image-gen", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// Tool definitions
const tools: Tool[] = [
  {
    name: "generate_quote_card",
    description: "Create a quote card image with brand styling using Gemini AI (Nano Banana Pro)",
    inputSchema: {
      type: "object",
      properties: {
        quote: { type: "string", description: "The quote text" },
        attribution: { type: "string", description: "Attribution (e.g., 'Andrew Wilkinson')" },
        platform: {
          type: "string",
          enum: Object.keys(PLATFORM_SIZES),
          description: "Target platform size",
        },
        style: {
          type: "string",
          enum: ["dark", "light"],
          description: "Visual style (dark = charcoal bg, light = cream bg). Default: dark",
        },
      },
      required: ["quote", "attribution"],
    },
  },
  {
    name: "generate_carousel",
    description: "Create a multi-slide carousel for Instagram or LinkedIn using Gemini AI (Nano Banana Pro)",
    inputSchema: {
      type: "object",
      properties: {
        slides: {
          type: "array",
          items: {
            type: "object",
            properties: {
              headline: { type: "string" },
              body: { type: "string" },
            },
          },
          description: "Array of slides with headline and/or body text",
        },
        platform: {
          type: "string",
          enum: ["instagram_square", "linkedin_square"],
          description: "Target platform",
        },
        style: {
          type: "string",
          enum: ["dark", "light"],
          description: "Visual style (dark = charcoal bg, light = cream bg). Default: dark",
        },
      },
      required: ["slides"],
    },
  },
  {
    name: "resize_for_platform",
    description: "Resize an existing image for a specific platform using Sharp",
    inputSchema: {
      type: "object",
      properties: {
        source_path: { type: "string", description: "Path to source image" },
        platform: {
          type: "string",
          enum: Object.keys(PLATFORM_SIZES),
          description: "Target platform",
        },
      },
      required: ["source_path", "platform"],
    },
  },
  {
    name: "apply_brand_style",
    description: "Apply brand color grading and styling to an image using Sharp",
    inputSchema: {
      type: "object",
      properties: {
        image_path: { type: "string", description: "Path to image to style" },
      },
      required: ["image_path"],
    },
  },
  {
    name: "list_generated_images",
    description: "List all generated images",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "get_platform_sizes",
    description: "Get the size specifications for all supported platforms",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "get_brand_colors",
    description: "Get the brand color palette",
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
  const toolArgs = args || {};

  try {
    switch (name) {
      case "generate_quote_card": {
        const result = await generateQuoteCard(
          toolArgs.quote as string,
          toolArgs.attribution as string,
          (toolArgs.platform as keyof typeof PLATFORM_SIZES) || "instagram_square",
          (toolArgs.style as "dark" | "light") || "dark"
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "generate_carousel": {
        const result = await generateCarousel(
          toolArgs.slides as Array<{ headline?: string; body?: string }>,
          (toolArgs.platform as "instagram_square" | "linkedin_square") || "instagram_square",
          (toolArgs.style as "dark" | "light") || "dark"
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "resize_for_platform": {
        const result = await resizeForPlatform(
          toolArgs.source_path as string,
          toolArgs.platform as keyof typeof PLATFORM_SIZES
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "apply_brand_style": {
        const result = await applyBrandStyle(toolArgs.image_path as string);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "list_generated_images": {
        const result = await listGeneratedImages();
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "get_platform_sizes": {
        return {
          content: [{ type: "text", text: JSON.stringify({ success: true, data: PLATFORM_SIZES }, null, 2) }],
        };
      }

      case "get_brand_colors": {
        return {
          content: [{ type: "text", text: JSON.stringify({ success: true, data: { light: BRAND_COLORS, dark: DARK_BRAND_COLORS } }, null, 2) }],
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
  console.error("Updike Image Gen MCP server running");
}

main().catch(console.error);
