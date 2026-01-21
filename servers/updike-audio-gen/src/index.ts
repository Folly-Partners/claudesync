#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";
import * as fs from "fs/promises";
import * as path from "path";

// Types
type Result<T> = { success: true; data: T } | { success: false; error: string };

interface GeneratedAudio {
  id: string;
  filepath: string;
  duration_seconds: number;
  characters_used: number;
  created_at: string;
}

interface AudioMetadata {
  id: string;
  source_text_preview: string;
  source_text_chars: number;
  chunks_used: number;
  duration_seconds: number;
  voice_id?: string;
  model_id: string;
  created_at: string;
}

interface VoiceSettings {
  stability?: number;        // 0-1, default 0.65
  similarity_boost?: number; // 0-1, default 0.80
  style?: number;            // 0-1, default 0.15
}

// Configuration
const UPDIKE_DIR = path.join(process.env.HOME || "~", ".updike");
const AUDIO_DIR = path.join(UPDIKE_DIR, "generated", "audio");
const CHUNKS_DIR = path.join(AUDIO_DIR, "chunks");

const ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1";
const DEFAULT_MODEL = "eleven_multilingual_v2";
const MAX_CHARS_PER_REQUEST = 5000;

// Default voice settings optimized for newsletter narration
const DEFAULT_VOICE_SETTINGS: VoiceSettings = {
  stability: 0.65,
  similarity_boost: 0.80,
  style: 0.15,
};

// Helper: Get credential from deep-env
function getCredential(key: string): string | null {
  try {
    const result = execSync(`deep-env get ${key}`, { encoding: "utf-8" }).trim();
    return result || null;
  } catch {
    return null;
  }
}

// Generate unique ID
function generateId(): string {
  return `audio-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

// Estimate duration from character count (~150 words/min, ~5 chars/word)
function estimateDuration(text: string): number {
  const wordsPerMinute = 150;
  const charsPerWord = 5;
  const words = text.length / charsPerWord;
  return Math.round((words / wordsPerMinute) * 60);
}

// Get audio duration using ffprobe
async function getAudioDuration(filepath: string): Promise<number> {
  try {
    const durationStr = execSync(
      `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${filepath}"`,
      { encoding: "utf-8" }
    );
    return Math.round(parseFloat(durationStr.trim()));
  } catch {
    return 0;
  }
}

// Check if FFmpeg is available
function checkFfmpeg(): boolean {
  try {
    execSync("which ffmpeg", { encoding: "utf-8" });
    return true;
  } catch {
    return false;
  }
}

// Call ElevenLabs API
async function callElevenLabsAPI(
  text: string,
  voiceSettings?: VoiceSettings,
  outputFormat: string = "mp3_44100_128"
): Promise<Result<Buffer>> {
  const apiKey = getCredential("ELEVENLABS_API_KEY");
  const voiceId = getCredential("ELEVENLABS_VOICE_ID");

  if (!apiKey) {
    return {
      success: false,
      error: "ELEVENLABS_API_KEY not configured. Run: deep-env store ELEVENLABS_API_KEY <key>",
    };
  }
  if (!voiceId) {
    return {
      success: false,
      error: "ELEVENLABS_VOICE_ID not configured. Run: deep-env store ELEVENLABS_VOICE_ID <id>",
    };
  }

  const settings = { ...DEFAULT_VOICE_SETTINGS, ...voiceSettings };
  const url = `${ELEVENLABS_API_URL}/text-to-speech/${voiceId}?output_format=${outputFormat}`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "xi-api-key": apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        text,
        model_id: DEFAULT_MODEL,
        voice_settings: {
          stability: settings.stability,
          similarity_boost: settings.similarity_boost,
          style: settings.style,
          use_speaker_boost: true,
        },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return {
        success: false,
        error: `ElevenLabs API error (${response.status}): ${errorText}`,
      };
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    return { success: true, data: buffer };
  } catch (error) {
    return { success: false, error: `ElevenLabs API request failed: ${error}` };
  }
}

// Tool: generate_audio
async function generateAudio(
  text: string,
  voiceSettings?: VoiceSettings,
  outputFormat?: string
): Promise<Result<GeneratedAudio>> {
  if (!text || text.trim().length === 0) {
    return { success: false, error: "Text cannot be empty" };
  }

  if (text.length > MAX_CHARS_PER_REQUEST) {
    return {
      success: false,
      error: `Text exceeds ${MAX_CHARS_PER_REQUEST} character limit (${text.length} chars). Use chunking for long content: split text at paragraph boundaries and call generate_audio for each chunk, then use concatenate_audio to join them.`,
    };
  }

  await fs.mkdir(AUDIO_DIR, { recursive: true });
  const id = generateId();

  const result = await callElevenLabsAPI(text, voiceSettings, outputFormat);
  if (!result.success) return result;

  const filepath = path.join(AUDIO_DIR, `${id}.mp3`);
  await fs.writeFile(filepath, result.data);

  // Get actual duration if ffprobe available, otherwise estimate
  let duration = await getAudioDuration(filepath);
  if (duration === 0) {
    duration = estimateDuration(text);
  }

  // Write metadata sidecar
  const metadata: AudioMetadata = {
    id,
    source_text_preview: text.slice(0, 100) + (text.length > 100 ? "..." : ""),
    source_text_chars: text.length,
    chunks_used: 1,
    duration_seconds: duration,
    voice_id: getCredential("ELEVENLABS_VOICE_ID") || undefined,
    model_id: DEFAULT_MODEL,
    created_at: new Date().toISOString(),
  };
  await fs.writeFile(
    path.join(AUDIO_DIR, `${id}.meta.json`),
    JSON.stringify(metadata, null, 2)
  );

  return {
    success: true,
    data: {
      id,
      filepath,
      duration_seconds: duration,
      characters_used: text.length,
      created_at: metadata.created_at,
    },
  };
}

// Tool: concatenate_audio
async function concatenateAudio(
  filePaths: string[],
  silenceBetweenMs: number = 300
): Promise<Result<{ id: string; filepath: string; duration_seconds: number }>> {
  if (filePaths.length === 0) {
    return { success: false, error: "No files provided for concatenation" };
  }

  if (filePaths.length === 1) {
    // Just return the single file
    const duration = await getAudioDuration(filePaths[0]);
    return {
      success: true,
      data: {
        id: path.basename(filePaths[0], ".mp3"),
        filepath: filePaths[0],
        duration_seconds: duration,
      },
    };
  }

  // Verify all files exist
  for (const fp of filePaths) {
    try {
      await fs.access(fp);
    } catch {
      return { success: false, error: `File not found: ${fp}` };
    }
  }

  // Check FFmpeg availability
  if (!checkFfmpeg()) {
    return {
      success: false,
      error: "FFmpeg not found. Install with: brew install ffmpeg",
    };
  }

  await fs.mkdir(AUDIO_DIR, { recursive: true });
  const id = generateId();
  const outputPath = path.join(AUDIO_DIR, `${id}.mp3`);

  try {
    // Create a temporary file list for FFmpeg concat demuxer
    const listPath = path.join(AUDIO_DIR, `${id}-concat-list.txt`);
    const silenceSeconds = silenceBetweenMs / 1000;

    // Build file list with silence between files
    let fileListContent = "";
    for (let i = 0; i < filePaths.length; i++) {
      fileListContent += `file '${filePaths[i]}'\n`;
      if (i < filePaths.length - 1 && silenceSeconds > 0) {
        // Generate silence file
        const silencePath = path.join(AUDIO_DIR, `${id}-silence-${i}.mp3`);
        execSync(
          `ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t ${silenceSeconds} -q:a 9 "${silencePath}" -y 2>/dev/null`
        );
        fileListContent += `file '${silencePath}'\n`;
      }
    }

    await fs.writeFile(listPath, fileListContent);

    // Concatenate using FFmpeg concat demuxer
    execSync(
      `ffmpeg -f concat -safe 0 -i "${listPath}" -c copy "${outputPath}" -y 2>/dev/null`
    );

    // Clean up temp files
    await fs.unlink(listPath);
    for (let i = 0; i < filePaths.length - 1; i++) {
      const silencePath = path.join(AUDIO_DIR, `${id}-silence-${i}.mp3`);
      try {
        await fs.unlink(silencePath);
      } catch {
        // Ignore if doesn't exist
      }
    }

    const duration = await getAudioDuration(outputPath);

    return {
      success: true,
      data: {
        id,
        filepath: outputPath,
        duration_seconds: duration,
      },
    };
  } catch (error) {
    return { success: false, error: `FFmpeg concatenation failed: ${error}` };
  }
}

// Tool: list_audio
async function listAudio(directory?: string): Promise<
  Result<
    Array<{
      id: string;
      filename: string;
      filepath: string;
      size_bytes: number;
      created_at: string;
      duration_seconds?: number;
      source_text_preview?: string;
    }>
  >
> {
  const dir = directory || AUDIO_DIR;

  try {
    await fs.mkdir(dir, { recursive: true });
    const files = await fs.readdir(dir);
    const audioFiles = files.filter((f) => f.endsWith(".mp3"));

    const results = await Promise.all(
      audioFiles.map(async (filename) => {
        const filepath = path.join(dir, filename);
        const stat = await fs.stat(filepath);
        const id = filename.replace(".mp3", "");

        // Try to read metadata sidecar
        let duration: number | undefined;
        let preview: string | undefined;
        try {
          const metaPath = path.join(dir, `${id}.meta.json`);
          const meta: AudioMetadata = JSON.parse(
            await fs.readFile(metaPath, "utf-8")
          );
          duration = meta.duration_seconds;
          preview = meta.source_text_preview;
        } catch {
          // No metadata file, try ffprobe
          duration = await getAudioDuration(filepath);
        }

        return {
          id,
          filename,
          filepath,
          size_bytes: stat.size,
          created_at: stat.birthtime.toISOString(),
          duration_seconds: duration,
          source_text_preview: preview,
        };
      })
    );

    // Sort by created_at descending (newest first)
    results.sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );

    return { success: true, data: results };
  } catch (error) {
    return { success: false, error: `Failed to list audio: ${error}` };
  }
}

// Tool: delete_audio
async function deleteAudio(
  filepath: string
): Promise<Result<{ deleted: string }>> {
  try {
    await fs.access(filepath);
  } catch {
    return { success: false, error: `File not found: ${filepath}` };
  }

  try {
    await fs.unlink(filepath);

    // Also delete metadata sidecar if exists
    const id = path.basename(filepath, ".mp3");
    const metaPath = path.join(path.dirname(filepath), `${id}.meta.json`);
    try {
      await fs.unlink(metaPath);
    } catch {
      // Ignore if no sidecar
    }

    return { success: true, data: { deleted: filepath } };
  } catch (error) {
    return { success: false, error: `Failed to delete: ${error}` };
  }
}

// Tool: get_voice_info
async function getVoiceInfo(): Promise<
  Result<{
    voice_id: string | null;
    api_key_configured: boolean;
    ffmpeg_available: boolean;
    default_settings: VoiceSettings;
    max_chars_per_request: number;
    audio_directory: string;
  }>
> {
  return {
    success: true,
    data: {
      voice_id: getCredential("ELEVENLABS_VOICE_ID"),
      api_key_configured: !!getCredential("ELEVENLABS_API_KEY"),
      ffmpeg_available: checkFfmpeg(),
      default_settings: DEFAULT_VOICE_SETTINGS,
      max_chars_per_request: MAX_CHARS_PER_REQUEST,
      audio_directory: AUDIO_DIR,
    },
  };
}

// MCP Server setup
const server = new Server(
  { name: "updike-audio-gen", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// Tool definitions
const tools = [
  {
    name: "generate_audio",
    description:
      "Convert text to speech using ElevenLabs API. Limited to 5000 characters per call. For longer content, split text at paragraph boundaries and call this multiple times, then use concatenate_audio to join.",
    inputSchema: {
      type: "object",
      properties: {
        text: {
          type: "string",
          description: "The text to convert to speech (max 5000 characters)",
        },
        voice_settings: {
          type: "object",
          description: "Optional voice settings to override defaults",
          properties: {
            stability: {
              type: "number",
              description: "Voice stability 0-1 (default 0.65). Higher = more consistent",
            },
            similarity_boost: {
              type: "number",
              description: "Voice similarity 0-1 (default 0.80). Higher = closer to original voice",
            },
            style: {
              type: "number",
              description: "Style exaggeration 0-1 (default 0.15). Higher = more expressive",
            },
          },
        },
        output_format: {
          type: "string",
          description: "Audio format (default: mp3_44100_128)",
          enum: ["mp3_44100_128", "mp3_44100_192", "pcm_16000", "pcm_22050", "pcm_24000", "pcm_44100"],
        },
      },
      required: ["text"],
    },
  },
  {
    name: "concatenate_audio",
    description:
      "Join multiple audio files into a single file using FFmpeg. Use this after generating multiple chunks for long content.",
    inputSchema: {
      type: "object",
      properties: {
        file_paths: {
          type: "array",
          items: { type: "string" },
          description: "Array of file paths to concatenate in order",
        },
        silence_between_ms: {
          type: "number",
          description: "Milliseconds of silence between files (default: 300)",
        },
      },
      required: ["file_paths"],
    },
  },
  {
    name: "list_audio",
    description: "List all generated audio files with metadata",
    inputSchema: {
      type: "object",
      properties: {
        directory: {
          type: "string",
          description: "Optional directory to list (defaults to standard audio directory)",
        },
      },
    },
  },
  {
    name: "delete_audio",
    description: "Delete an audio file and its metadata sidecar",
    inputSchema: {
      type: "object",
      properties: {
        file_path: {
          type: "string",
          description: "Path to the audio file to delete",
        },
      },
      required: ["file_path"],
    },
  },
  {
    name: "get_voice_info",
    description:
      "Get current voice configuration status including whether API key and voice ID are configured, FFmpeg availability, and default settings",
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
      case "generate_audio": {
        const result = await generateAudio(
          toolArgs.text as string,
          toolArgs.voice_settings as VoiceSettings | undefined,
          toolArgs.output_format as string | undefined
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "concatenate_audio": {
        const result = await concatenateAudio(
          toolArgs.file_paths as string[],
          (toolArgs.silence_between_ms as number) || 300
        );
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "list_audio": {
        const result = await listAudio(toolArgs.directory as string | undefined);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "delete_audio": {
        const result = await deleteAudio(toolArgs.file_path as string);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      }

      case "get_voice_info": {
        const result = await getVoiceInfo();
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
  console.error("Updike Audio Gen MCP server running");
}

main().catch(console.error);
