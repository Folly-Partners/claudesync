#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import * as fs from "fs/promises";
import * as path from "path";

import { webflowCall, getSiteId } from "./webflow-client.js";
import { logDecision } from "./utils/logging.js";
import { sanitizeHtml, validateFilePath, validateRemoteUrl } from "./utils/security.js";
import { markdownToWebflowHtml, generateSlug, generateExcerpt } from "./utils/rich-text.js";
import * as Types from "./types.js";

// Result type
type Result<T> = Types.Result<T>;

function success<T>(data: T): Result<T> {
  return { success: true, data };
}

function failure(error: string): Result<never> {
  return { success: false, error };
}

// ============================================================
// TOOL IMPLEMENTATIONS
// ============================================================

// ---------- SITES ----------

async function listSites(): Promise<Result<{ sites: Array<{ id: string; name: string; shortName: string }> }>> {
  try {
    const response = await webflowCall(
      (client) => client.sites.list(),
      "sites"
    );

    const sites = (response.sites || []).map((site) => ({
      id: site.id!,
      name: site.displayName!,
      shortName: site.shortName!,
    }));

    return success({ sites });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getSite(input: unknown): Promise<Result<Types.WebflowSite>> {
  const parsed = Types.GetSiteSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const site = await webflowCall(
      (client) => client.sites.get(parsed.data.site_id),
      "site"
    );

    return success({
      id: site.id!,
      workspaceId: site.workspaceId!,
      displayName: site.displayName!,
      shortName: site.shortName!,
      previewUrl: site.previewUrl || undefined,
      timeZone: site.timeZone!,
      createdOn: site.createdOn!,
      lastUpdated: site.lastUpdated!,
      lastPublished: site.lastPublished || undefined,
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function publishSite(input: unknown): Promise<Result<{ published: boolean }>> {
  const parsed = Types.PublishSiteSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.sites.publish(parsed.data.site_id, {
        publishToWebflowSubdomain: true,
        customDomains: parsed.data.domains,
      }),
      "publish"
    );

    await logDecision("publish", "site", parsed.data.site_id, "success");
    return success({ published: true });
  } catch (error) {
    await logDecision("publish", "site", parsed.data.site_id, "error", {
      errorMessage: error instanceof Error ? error.message : String(error),
    });
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getDomains(input: unknown): Promise<Result<{ domains: Array<{ id: string; url: string }> }>> {
  const parsed = Types.GetDomainsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.sites.getCustomDomain(parsed.data.site_id),
      "domains"
    );

    // Response may be single domain or array
    const domainsArray = Array.isArray(response) ? response : [response];
    const domains = domainsArray.map((d: { id?: string; url?: string }) => ({
      id: d.id || "",
      url: d.url || "",
    }));

    return success({ domains });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- COLLECTIONS ----------

async function listCollections(input: unknown): Promise<Result<{ collections: Array<{ id: string; name: string; slug: string }> }>> {
  const parsed = Types.ListCollectionsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.collections.list(parsed.data.site_id),
      "collections"
    );

    const collections = (response.collections || []).map((c) => ({
      id: c.id!,
      name: c.displayName!,
      slug: c.slug!,
    }));

    return success({ collections });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getCollection(input: unknown): Promise<Result<{ collection: { id: string; name: string; slug: string; fields: Array<{ id: string; name: string; type: string; required: boolean }> } }>> {
  const parsed = Types.GetCollectionSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const collection = await webflowCall(
      (client) => client.collections.get(parsed.data.collection_id),
      "collection"
    );

    return success({
      collection: {
        id: collection.id!,
        name: collection.displayName!,
        slug: collection.slug!,
        fields: (collection.fields || []).map((f) => ({
          id: f.id!,
          name: f.displayName!,
          type: f.type!,
          required: f.isRequired!,
        })),
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function createCollection(input: unknown): Promise<Result<{ collection: { id: string; name: string; slug: string } }>> {
  const parsed = Types.CreateCollectionSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const collection = await webflowCall(
      (client) => client.collections.create(parsed.data.site_id, {
        displayName: parsed.data.display_name,
        singularName: parsed.data.singular_name,
        slug: parsed.data.slug,
      }),
      "collection"
    );

    await logDecision("create", "collection", collection.id!, "success", {
      contentPreview: parsed.data.display_name,
    });

    return success({
      collection: {
        id: collection.id!,
        name: collection.displayName!,
        slug: collection.slug!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function createCollectionField(input: unknown): Promise<Result<{ field: { id: string; name: string; type: string } }>> {
  const parsed = Types.CreateCollectionFieldSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const field = await webflowCall(
      (client) => (client.collections.fields as any).create(parsed.data.collection_id, {
        displayName: parsed.data.display_name,
        type: parsed.data.type,
        isRequired: parsed.data.is_required,
      }),
      "field"
    );

    await logDecision("create", "field", (field as any).id!, "success", {
      contentPreview: parsed.data.display_name,
    });

    return success({
      field: {
        id: (field as any).id!,
        name: (field as any).displayName!,
        type: (field as any).type!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- CMS ITEMS - SINGLE ----------

async function createCmsItem(input: unknown): Promise<Result<{ item: { id: string; isDraft: boolean } }>> {
  const parsed = Types.CreateCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Sanitize any HTML content in field data
    const sanitizedFieldData = { ...parsed.data.field_data };
    for (const [key, value] of Object.entries(sanitizedFieldData)) {
      if (typeof value === "string" && (value.includes("<") || value.includes(">"))) {
        sanitizedFieldData[key] = sanitizeHtml(value);
      }
    }

    const item = await webflowCall(
      (client) => client.collections.items.createItem(parsed.data.collection_id, {
        fieldData: sanitizedFieldData as any,
        isDraft: parsed.data.is_draft,
        isArchived: parsed.data.is_archived,
      }),
      "item"
    );

    await logDecision("create", "item", item.id!, "success", {
      contentPreview: JSON.stringify(sanitizedFieldData).substring(0, 100),
    });

    return success({
      item: {
        id: item.id!,
        isDraft: item.isDraft!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getCmsItem(input: unknown): Promise<Result<{ item: Types.WebflowItem }>> {
  const parsed = Types.GetCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const item = await webflowCall(
      (client) => client.collections.items.getItem(
        parsed.data.collection_id,
        parsed.data.item_id
      ),
      "item"
    );

    return success({
      item: {
        id: item.id!,
        cmsLocaleId: item.cmsLocaleId || undefined,
        lastPublished: item.lastPublished || undefined,
        lastUpdated: item.lastUpdated!,
        createdOn: item.createdOn!,
        isArchived: item.isArchived!,
        isDraft: item.isDraft!,
        fieldData: item.fieldData as Record<string, unknown>,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function updateCmsItem(input: unknown): Promise<Result<{ item: { id: string; isDraft: boolean } }>> {
  const parsed = Types.UpdateCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Sanitize any HTML content
    const sanitizedFieldData = { ...parsed.data.field_data };
    for (const [key, value] of Object.entries(sanitizedFieldData)) {
      if (typeof value === "string" && (value.includes("<") || value.includes(">"))) {
        sanitizedFieldData[key] = sanitizeHtml(value);
      }
    }

    const item = await webflowCall(
      (client) => client.collections.items.updateItem(
        parsed.data.collection_id,
        parsed.data.item_id,
        {
          fieldData: sanitizedFieldData as any,
          isDraft: parsed.data.is_draft,
          isArchived: parsed.data.is_archived,
        }
      ),
      "item"
    );

    await logDecision("update", "item", item.id!, "success");

    return success({
      item: {
        id: item.id!,
        isDraft: item.isDraft!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function deleteCmsItem(input: unknown): Promise<Result<{ deleted: boolean }>> {
  const parsed = Types.DeleteCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.collections.items.deleteItem(
        parsed.data.collection_id,
        parsed.data.item_id
      ),
      "item"
    );

    await logDecision("delete", "item", parsed.data.item_id, "success");

    return success({ deleted: true });
  } catch (error) {
    await logDecision("delete", "item", parsed.data.item_id, "error", {
      errorMessage: error instanceof Error ? error.message : String(error),
    });
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function publishCmsItem(input: unknown): Promise<Result<{ published: boolean }>> {
  const parsed = Types.PublishCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => (client.collections.items as any).publishItem(
        parsed.data.collection_id,
        { itemIds: [parsed.data.item_id] }
      ),
      "publish"
    );

    await logDecision("publish", "item", parsed.data.item_id, "success");

    return success({ published: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function listCmsItems(input: unknown): Promise<Result<{ items: Array<{ id: string; isDraft: boolean; fieldData: Record<string, unknown> }>; pagination: { limit: number; offset: number; total: number } }>> {
  const parsed = Types.ListCmsItemsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.collections.items.listItems(parsed.data.collection_id, {
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      }),
      "items"
    );

    const items = (response.items || []).map((item) => ({
      id: item.id!,
      isDraft: item.isDraft!,
      fieldData: item.fieldData as Record<string, unknown>,
    }));

    return success({
      items,
      pagination: {
        limit: parsed.data.limit,
        offset: parsed.data.offset,
        total: response.pagination?.total || items.length,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- CMS ITEMS - BULK ----------

async function bulkCreateCmsItems(input: unknown): Promise<Result<{ created: number; items: Array<{ id: string }> }>> {
  const parsed = Types.BulkCreateCmsItemsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Sanitize HTML in all items
    const sanitizedItems = parsed.data.items.map((item) => {
      const sanitized = { ...item.field_data };
      for (const [key, value] of Object.entries(sanitized)) {
        if (typeof value === "string" && (value.includes("<") || value.includes(">"))) {
          sanitized[key] = sanitizeHtml(value);
        }
      }
      return {
        fieldData: sanitized,
        isDraft: item.is_draft,
        isArchived: item.is_archived,
      };
    });

    const response: any = await webflowCall(
      (client) => (client.collections.items as any).createItems(parsed.data.collection_id, {
        items: sanitizedItems,
      }),
      "bulk-create"
    );

    const createdItems = (response.items || []).map((item: any) => ({
      id: item.id!,
    }));

    await logDecision("bulk_create", "items", parsed.data.collection_id, "success", {
      contentPreview: `${createdItems.length} items created`,
    });

    return success({
      created: createdItems.length,
      items: createdItems,
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function bulkUpdateCmsItems(input: unknown): Promise<Result<{ updated: number }>> {
  const parsed = Types.BulkUpdateCmsItemsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Sanitize HTML in all items
    const sanitizedItems = parsed.data.items.map((item) => {
      const sanitized = { ...item.field_data };
      for (const [key, value] of Object.entries(sanitized)) {
        if (typeof value === "string" && (value.includes("<") || value.includes(">"))) {
          sanitized[key] = sanitizeHtml(value);
        }
      }
      return {
        id: item.id,
        fieldData: sanitized,
        isDraft: item.is_draft,
        isArchived: item.is_archived,
      };
    });

    await webflowCall(
      (client) => client.collections.items.updateItemsLive(parsed.data.collection_id, {
        items: sanitizedItems as any,
      }),
      "bulk-update"
    );

    await logDecision("bulk_update", "items", parsed.data.collection_id, "success", {
      contentPreview: `${parsed.data.items.length} items updated`,
    });

    return success({ updated: parsed.data.items.length });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function bulkDeleteCmsItems(input: unknown): Promise<Result<{ deleted: number }>> {
  const parsed = Types.BulkDeleteCmsItemsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => (client.collections.items as any).deleteItems(parsed.data.collection_id, {
        items: parsed.data.item_ids.map((id) => ({ id })),
      }),
      "bulk-delete"
    );

    await logDecision("bulk_delete", "items", parsed.data.collection_id, "success", {
      contentPreview: `${parsed.data.item_ids.length} items deleted`,
    });

    return success({ deleted: parsed.data.item_ids.length });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function bulkPublishCmsItems(input: unknown): Promise<Result<{ published: number }>> {
  const parsed = Types.BulkPublishCmsItemsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => (client.collections.items as any).publishItem(parsed.data.collection_id, {
        itemIds: parsed.data.item_ids,
      }),
      "bulk-publish"
    );

    await logDecision("bulk_publish", "items", parsed.data.collection_id, "success", {
      contentPreview: `${parsed.data.item_ids.length} items published`,
    });

    return success({ published: parsed.data.item_ids.length });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- CMS ITEMS - LIVE ----------

async function createLiveCmsItem(input: unknown): Promise<Result<{ item: { id: string } }>> {
  const parsed = Types.CreateLiveCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Sanitize HTML content
    const sanitizedFieldData = { ...parsed.data.field_data };
    for (const [key, value] of Object.entries(sanitizedFieldData)) {
      if (typeof value === "string" && (value.includes("<") || value.includes(">"))) {
        sanitizedFieldData[key] = sanitizeHtml(value);
      }
    }

    const item = await webflowCall(
      (client) => client.collections.items.createItemLive(parsed.data.collection_id, {
        fieldData: sanitizedFieldData as any,
      }),
      "live-item"
    );

    await logDecision("create_live", "item", item.id!, "success");

    return success({
      item: { id: item.id! },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function updateLiveCmsItem(input: unknown): Promise<Result<{ item: { id: string } }>> {
  const parsed = Types.UpdateLiveCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Sanitize HTML content
    const sanitizedFieldData = { ...parsed.data.field_data };
    for (const [key, value] of Object.entries(sanitizedFieldData)) {
      if (typeof value === "string" && (value.includes("<") || value.includes(">"))) {
        sanitizedFieldData[key] = sanitizeHtml(value);
      }
    }

    const item = await webflowCall(
      (client) => client.collections.items.updateItemLive(
        parsed.data.collection_id,
        parsed.data.item_id,
        {
          fieldData: sanitizedFieldData as any,
        }
      ),
      "live-item"
    );

    await logDecision("update_live", "item", item.id!, "success");

    return success({
      item: { id: item.id! },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function deleteLiveCmsItem(input: unknown): Promise<Result<{ deleted: boolean }>> {
  const parsed = Types.DeleteLiveCmsItemSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.collections.items.deleteItemLive(
        parsed.data.collection_id,
        parsed.data.item_id
      ),
      "live-item"
    );

    await logDecision("delete_live", "item", parsed.data.item_id, "success");

    return success({ deleted: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- ASSETS ----------

async function listAssets(input: unknown): Promise<Result<{ assets: Array<{ id: string; fileName: string; url: string; contentType: string }> }>> {
  const parsed = Types.ListAssetsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.assets.list(parsed.data.site_id),
      "assets"
    );

    const assets = (response.assets || []).map((a) => ({
      id: a.id!,
      fileName: a.originalFileName!,
      url: a.hostedUrl!,
      contentType: a.contentType!,
    }));

    return success({ assets });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getAsset(input: unknown): Promise<Result<Types.WebflowAsset>> {
  const parsed = Types.GetAssetSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const asset = await webflowCall(
      (client) => client.assets.get(parsed.data.asset_id),
      "asset"
    );

    return success({
      id: asset.id!,
      contentType: asset.contentType!,
      size: asset.size!,
      siteId: asset.siteId!,
      hostedUrl: asset.hostedUrl!,
      originalFileName: asset.originalFileName!,
      displayName: asset.displayName!,
      createdOn: asset.createdOn!,
      lastUpdated: asset.lastUpdated!,
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function uploadAsset(input: unknown): Promise<Result<{ asset: { id: string; url: string } }>> {
  const parsed = Types.UploadAssetSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Validate file path (security check)
    const validatedPath = validateFilePath(parsed.data.file_path);

    // Read file
    const fileBuffer = await fs.readFile(validatedPath);
    const fileStats = await fs.stat(validatedPath);

    // Step 1: Create asset metadata (get upload URL)
    const metadata = await webflowCall(
      (client) => client.assets.create(parsed.data.site_id, {
        fileName: parsed.data.file_name,
        fileHash: "", // Will be computed
        parentFolder: parsed.data.parent_folder_id,
      }),
      "asset-create"
    );

    // Step 2: Upload to S3
    if (metadata.uploadUrl) {
      const uploadResponse = await fetch(metadata.uploadUrl, {
        method: "PUT",
        body: fileBuffer,
        headers: {
          "Content-Type": "application/octet-stream",
          "Content-Length": fileStats.size.toString(),
        },
      });

      if (!uploadResponse.ok) {
        throw new Error(`S3 upload failed: ${uploadResponse.statusText}`);
      }
    }

    await logDecision("upload", "asset", metadata.id!, "success", {
      contentPreview: parsed.data.file_name,
    });

    return success({
      asset: {
        id: metadata.id!,
        url: metadata.hostedUrl!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function deleteAsset(input: unknown): Promise<Result<{ deleted: boolean }>> {
  const parsed = Types.DeleteAssetSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.assets.delete(parsed.data.asset_id),
      "asset"
    );

    await logDecision("delete", "asset", parsed.data.asset_id, "success");

    return success({ deleted: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function listAssetFolders(input: unknown): Promise<Result<{ folders: Array<{ id: string; name: string }> }>> {
  const parsed = Types.ListAssetFoldersSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.assets.listFolders(parsed.data.site_id),
      "asset-folders"
    );

    const folders = (response.assetFolders || []).map((f) => ({
      id: f.id!,
      name: f.displayName!,
    }));

    return success({ folders });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function createAssetFolder(input: unknown): Promise<Result<{ folder: { id: string; name: string } }>> {
  const parsed = Types.CreateAssetFolderSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const folder = await webflowCall(
      (client) => client.assets.createFolder(parsed.data.site_id, {
        displayName: parsed.data.display_name,
      }),
      "asset-folder"
    );

    await logDecision("create", "asset-folder", folder.id!, "success", {
      contentPreview: parsed.data.display_name,
    });

    return success({
      folder: {
        id: folder.id!,
        name: folder.displayName!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- PAGES ----------

async function listPages(input: unknown): Promise<Result<{ pages: Array<{ id: string; title: string; slug: string; isDraft: boolean }> }>> {
  const parsed = Types.ListPagesSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.pages.list(parsed.data.site_id),
      "pages"
    );

    const pages = (response.pages || []).map((p) => ({
      id: p.id!,
      title: p.title!,
      slug: p.slug!,
      isDraft: p.draft!,
    }));

    return success({ pages });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getPage(input: unknown): Promise<Result<Types.WebflowPage>> {
  const parsed = Types.GetPageSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const page = await webflowCall(
      (client) => client.pages.getMetadata(parsed.data.page_id),
      "page"
    );

    return success({
      id: page.id!,
      siteId: page.siteId!,
      title: page.title!,
      slug: page.slug!,
      parentId: page.parentId || undefined,
      collectionId: page.collectionId || undefined,
      createdOn: page.createdOn!,
      lastUpdated: page.lastUpdated!,
      archived: page.archived!,
      draft: page.draft!,
      seo: page.seo ? {
        title: (page.seo as any).title || undefined,
        description: (page.seo as any).description || undefined,
      } : undefined,
      openGraph: page.openGraph ? {
        title: (page.openGraph as any).title || undefined,
        description: (page.openGraph as any).description || undefined,
      } : undefined,
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function updatePageSeo(input: unknown): Promise<Result<{ updated: boolean }>> {
  const parsed = Types.UpdatePageSeoSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.pages.updatePageSettings(parsed.data.page_id, {
        seo: {
          title: parsed.data.title,
          description: parsed.data.description,
        },
        openGraph: {
          title: parsed.data.og_title,
          description: parsed.data.og_description,
        },
      }),
      "page-seo"
    );

    await logDecision("update_seo", "page", parsed.data.page_id, "success");

    return success({ updated: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getPageContent(input: unknown): Promise<Result<{ content: string }>> {
  const parsed = Types.GetPageContentSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const content = await webflowCall(
      (client) => client.pages.getContent(parsed.data.page_id),
      "page-content"
    );

    return success({
      content: JSON.stringify(content, null, 2),
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- CUSTOM CODE ----------

async function registerInlineScript(input: unknown): Promise<Result<{ script: { id: string; displayName: string } }>> {
  const parsed = Types.RegisterInlineScriptSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const script = await webflowCall(
      (client) => client.scripts.registerInline(parsed.data.site_id, {
        displayName: parsed.data.display_name,
        sourceCode: parsed.data.source_code,
        version: parsed.data.version,
      }),
      "inline-script"
    );

    await logDecision("register", "inline-script", script.id!, "success", {
      contentPreview: parsed.data.display_name,
    });

    return success({
      script: {
        id: script.id!,
        displayName: script.displayName!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function registerHostedScript(input: unknown): Promise<Result<{ script: { id: string; displayName: string } }>> {
  const parsed = Types.RegisterHostedScriptSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Validate URL (SSRF prevention)
    validateRemoteUrl(parsed.data.hosted_location);

    const script = await webflowCall(
      (client) => client.scripts.registerHosted(parsed.data.site_id, {
        displayName: parsed.data.display_name,
        hostedLocation: parsed.data.hosted_location,
        integrityHash: parsed.data.integrity_hash || "",
        version: parsed.data.version,
        canCopy: parsed.data.can_copy,
      }),
      "hosted-script"
    );

    await logDecision("register", "hosted-script", script.id!, "success", {
      contentPreview: parsed.data.display_name,
    });

    return success({
      script: {
        id: script.id!,
        displayName: script.displayName!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function listRegisteredScripts(input: unknown): Promise<Result<{ scripts: Array<{ id: string; displayName: string; version: string }> }>> {
  const parsed = Types.ListRegisteredScriptsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.scripts.list(parsed.data.site_id),
      "scripts"
    );

    const scripts = (response.registeredScripts || []).map((s) => ({
      id: s.id!,
      displayName: s.displayName!,
      version: s.version!,
    }));

    return success({ scripts });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function addSiteCustomCode(input: unknown): Promise<Result<{ applied: boolean }>> {
  const parsed = Types.AddSiteCustomCodeSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.sites.scripts.upsertCustomCode(parsed.data.site_id, {
        scripts: parsed.data.scripts.map((s) => ({
          id: s.id,
          location: s.location.toUpperCase() as "HEADER" | "FOOTER",
          version: "1.0.0",
        })),
      } as any),
      "site-custom-code"
    );

    await logDecision("add_custom_code", "site", parsed.data.site_id, "success", {
      contentPreview: `${parsed.data.scripts.length} scripts applied`,
    });

    return success({ applied: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function addPageCustomCode(input: unknown): Promise<Result<{ applied: boolean }>> {
  const parsed = Types.AddPageCustomCodeSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.pages.scripts.upsertCustomCode(parsed.data.page_id, {
        scripts: parsed.data.scripts.map((s) => ({
          id: s.id,
          location: s.location.toUpperCase() as "HEADER" | "FOOTER",
          version: "1.0.0",
        })),
      } as any),
      "page-custom-code"
    );

    await logDecision("add_custom_code", "page", parsed.data.page_id, "success", {
      contentPreview: `${parsed.data.scripts.length} scripts applied`,
    });

    return success({ applied: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- FORMS ----------

async function listForms(input: unknown): Promise<Result<{ forms: Array<{ id: string; name: string; pageId: string }> }>> {
  const parsed = Types.ListFormsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.forms.list(parsed.data.site_id),
      "forms"
    );

    const forms = (response.forms || []).map((f) => ({
      id: f.id!,
      name: f.displayName!,
      pageId: f.pageId!,
    }));

    return success({ forms });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getFormSchema(input: unknown): Promise<Result<Types.WebflowForm>> {
  const parsed = Types.GetFormSchemaInputSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const form = await webflowCall(
      (client) => client.forms.get(parsed.data.form_id),
      "form"
    );

    return success({
      id: form.id!,
      displayName: form.displayName!,
      siteId: form.siteId!,
      siteDomainId: form.siteDomainId!,
      pageId: form.pageId!,
      pageName: form.pageName!,
      fields: ((form.fields as unknown as any[]) || []).map((f: any) => ({
        displayName: f.displayName!,
        type: f.type!,
        placeholder: f.placeholder || undefined,
        userVisible: f.userVisible!,
      })),
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function listFormSubmissions(input: unknown): Promise<Result<{ submissions: Array<{ id: string; formId: string; data: Record<string, string>; submittedAt: string }> }>> {
  const parsed = Types.ListFormSubmissionsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.forms.listSubmissions(parsed.data.form_id, {
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      }),
      "form-submissions"
    );

    const submissions = (response.formSubmissions || []).map((s: any) => ({
      id: s.id!,
      formId: s.formId || (s as any).id!,
      data: s.formResponse as Record<string, string>,
      submittedAt: (s.submittedAt || s.dateSubmitted || new Date().toISOString()) as string,
    }));

    return success({ submissions });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getFormSubmission(input: unknown): Promise<Result<Types.WebflowFormSubmission>> {
  const parsed = Types.GetFormSubmissionSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const submission = await webflowCall(
      (client) => client.forms.getSubmission(parsed.data.form_submission_id),
      "form-submission"
    );

    return success({
      id: submission.id!,
      displayName: submission.displayName!,
      siteId: submission.siteId!,
      formId: (submission as any).formId || submission.id!,
      formResponse: submission.formResponse as Record<string, string>,
      submittedAt: ((submission as any).submittedAt || (submission as any).dateSubmitted || new Date().toISOString()) as string,
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- USERS ----------

async function listUsers(input: unknown): Promise<Result<{ users: Array<{ id: string; email: string; status: string }> }>> {
  const parsed = Types.ListUsersSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.users.list(parsed.data.site_id, {
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      }),
      "users"
    );

    const users = (response.users || []).map((u) => ({
      id: u.id!,
      email: (u.data as any)?.email || "",
      status: u.status!,
    }));

    return success({ users });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getUser(input: unknown): Promise<Result<{ user: { id: string; email: string; status: string; createdOn: string } }>> {
  const parsed = Types.GetUserSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const user = await webflowCall(
      (client) => client.users.get(parsed.data.site_id, parsed.data.user_id),
      "user"
    );

    return success({
      user: {
        id: user.id!,
        email: (user.data as any)?.email || "",
        status: String(user.status!),
        createdOn: String(user.createdOn!),
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function inviteUser(input: unknown): Promise<Result<{ user: { id: string; email: string } }>> {
  const parsed = Types.InviteUserSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const user = await webflowCall(
      (client) => client.users.invite(parsed.data.site_id, {
        email: parsed.data.email,
        accessGroups: parsed.data.access_groups,
      }),
      "user-invite"
    );

    await logDecision("invite", "user", user.id!, "success", {
      contentPreview: parsed.data.email,
    });

    return success({
      user: {
        id: user.id!,
        email: parsed.data.email,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function updateUser(input: unknown): Promise<Result<{ updated: boolean }>> {
  const parsed = Types.UpdateUserSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.users.update(parsed.data.site_id, parsed.data.user_id, {
        accessGroups: parsed.data.access_groups as any,
      }),
      "user"
    );

    await logDecision("update", "user", parsed.data.user_id, "success");

    return success({ updated: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function deleteUser(input: unknown): Promise<Result<{ deleted: boolean }>> {
  const parsed = Types.DeleteUserSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.users.delete(parsed.data.site_id, parsed.data.user_id),
      "user"
    );

    await logDecision("delete", "user", parsed.data.user_id, "success");

    return success({ deleted: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- ACCESS GROUPS ----------

async function listAccessGroups(input: unknown): Promise<Result<{ groups: Array<{ id: string; name: string; type: string }> }>> {
  const parsed = Types.ListAccessGroupsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.accessGroups.list(parsed.data.site_id),
      "access-groups"
    );

    const groups = ((response as any).accessGroups || []).map((g: any) => ({
      id: g.id!,
      name: g.name!,
      type: g.type!,
    }));

    return success({ groups });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getAccessGroup(input: unknown): Promise<Result<Types.WebflowAccessGroup>> {
  const parsed = Types.GetAccessGroupSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const group = await webflowCall(
      (client) => (client.accessGroups as any).get(parsed.data.access_group_id),
      "access-group"
    ) as any;

    return success({
      id: group.id!,
      name: group.name!,
      slug: group.slug!,
      type: group.type!,
      createdOn: String(group.createdOn!),
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function addUserToAccessGroup(input: unknown): Promise<Result<{ added: boolean }>> {
  const parsed = Types.AddUserToAccessGroupSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  // Note: The Webflow SDK may not have a direct method for this
  // This would need to be implemented via raw API call or user update
  return failure("Adding user to access group requires updating the user's access groups via update_user tool");
}

// ---------- ECOMMERCE - PRODUCTS ----------

async function listProducts(input: unknown): Promise<Result<{ products: Array<{ id: string; name: string; slug: string }> }>> {
  const parsed = Types.ListProductsSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.products.list(parsed.data.site_id, {
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      }),
      "products"
    );

    const products = (response.items || []).map((p: any) => ({
      id: p.id!,
      name: p.fieldData?.name || "",
      slug: p.fieldData?.slug || "",
    }));

    return success({ products });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getProduct(input: unknown): Promise<Result<{ product: { id: string; name: string; slug: string; description: string | undefined; skus: Array<{ id: string; name: string; price: number }> } }>> {
  const parsed = Types.GetProductSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const product = await webflowCall(
      (client) => client.products.get(parsed.data.site_id, parsed.data.product_id),
      "product"
    ) as any;

    return success({
      product: {
        id: product.id!,
        name: product.fieldData?.name || "",
        slug: product.fieldData?.slug || "",
        description: product.fieldData?.description,
        skus: (product.skus || []).map((s: any) => ({
          id: s.id!,
          name: s.fieldData?.name || "",
          price: s.fieldData?.price?.value || 0,
        })),
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function createProduct(input: unknown): Promise<Result<{ product: { id: string; name: string } }>> {
  const parsed = Types.CreateProductSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const product = await webflowCall(
      (client) => client.products.create(parsed.data.site_id, {
        product: {
          fieldData: {
            name: parsed.data.field_data.name,
            slug: parsed.data.field_data.slug,
            description: parsed.data.field_data.description,
          },
        },
        sku: {
          fieldData: {
            name: `${parsed.data.field_data.name} - Default`,
            slug: `${parsed.data.field_data.slug}-default`,
            price: {
              value: parsed.data.sku_data.price,
              unit: parsed.data.sku_data.currency,
            },
            quantity: parsed.data.sku_data.quantity,
          },
        },
      } as any),
      "product"
    ) as any;

    await logDecision("create", "product", product.id!, "success", {
      contentPreview: parsed.data.field_data.name,
    });

    return success({
      product: {
        id: product.id!,
        name: parsed.data.field_data.name,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function updateProduct(input: unknown): Promise<Result<{ updated: boolean }>> {
  const parsed = Types.UpdateProductSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.products.update(
        parsed.data.site_id,
        parsed.data.product_id,
        {
          product: {
            fieldData: parsed.data.field_data,
          },
        } as any
      ),
      "product"
    );

    await logDecision("update", "product", parsed.data.product_id, "success");

    return success({ updated: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function createSku(input: unknown): Promise<Result<{ sku: { id: string; name: string } }>> {
  const parsed = Types.CreateSkuSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const sku = await webflowCall(
      (client) => client.products.createSku(
        parsed.data.site_id,
        parsed.data.product_id,
        {
          skus: [{
            fieldData: {
              name: parsed.data.field_data.name,
              slug: parsed.data.field_data.slug,
              price: {
                value: parsed.data.field_data.price,
                unit: parsed.data.field_data.currency,
              },
              sku: parsed.data.field_data.sku,
            },
          }],
        } as any
      ),
      "sku"
    ) as any;

    await logDecision("create", "sku", sku.skus?.[0]?.id || "unknown", "success", {
      contentPreview: parsed.data.field_data.name,
    });

    return success({
      sku: {
        id: sku.skus?.[0]?.id || "",
        name: parsed.data.field_data.name,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- ECOMMERCE - ORDERS ----------

async function listOrders(input: unknown): Promise<Result<{ orders: Array<{ id: string; status: string; total: number; email: string }> }>> {
  const parsed = Types.ListOrdersSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.orders.list(parsed.data.site_id, {
        status: parsed.data.status as any,
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      }),
      "orders"
    );

    const orders = (response.orders || []).map((o: any) => ({
      id: o.orderId!,
      status: o.status!,
      total: o.customerPaid?.value || 0,
      email: o.customerInfo?.email || "",
    }));

    return success({ orders });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getOrder(input: unknown): Promise<Result<Types.WebflowOrder>> {
  const parsed = Types.GetOrderSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const order = await webflowCall(
      (client) => client.orders.get(parsed.data.site_id, parsed.data.order_id),
      "order"
    ) as any;

    return success({
      orderId: order.orderId!,
      status: order.status!,
      customerPaid: order.customerPaid!,
      netAmount: order.netAmount!,
      purchasedAt: order.purchasedAt!,
      stripeDetails: order.stripeDetails,
      customerInfo: order.customerInfo!,
      purchasedItems: order.purchasedItems || [],
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function updateOrder(input: unknown): Promise<Result<{ updated: boolean }>> {
  const parsed = Types.UpdateOrderSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.orders.update(
        parsed.data.site_id,
        parsed.data.order_id,
        {
          comment: parsed.data.comment,
        } as any
      ),
      "order"
    );

    await logDecision("update", "order", parsed.data.order_id, "success", {
      contentPreview: `Status: ${parsed.data.status}`,
    });

    return success({ updated: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function refundOrder(input: unknown): Promise<Result<{ refunded: boolean }>> {
  const parsed = Types.RefundOrderSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.orders.refund(
        parsed.data.site_id,
        parsed.data.order_id,
        {
          reason: parsed.data.reason as any,
        }
      ),
      "order-refund"
    );

    await logDecision("refund", "order", parsed.data.order_id, "success", {
      contentPreview: parsed.data.reason || "No reason provided",
    });

    return success({ refunded: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- ECOMMERCE - INVENTORY ----------

async function listInventory(input: unknown): Promise<Result<{ items: Array<{ id: string; quantity: number }> }>> {
  const parsed = Types.ListInventorySchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => (client.inventory as any).list(parsed.data.collection_id, {}),
      "inventory"
    ) as any;

    const items = ((response.inventoryItems || response.items || []) as any[]).map((i: any) => ({
      id: i.id!,
      quantity: i.quantity!,
    }));

    return success({ items });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function updateInventory(input: unknown): Promise<Result<{ updated: boolean }>> {
  const parsed = Types.UpdateInventorySchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.inventory.update(
        parsed.data.collection_id,
        parsed.data.inventory_item_id,
        {
          inventoryType: "finite",
          updateQuantity: parsed.data.quantity,
        }
      ),
      "inventory"
    );

    await logDecision("update", "inventory", parsed.data.inventory_item_id, "success", {
      contentPreview: `Quantity: ${parsed.data.quantity}`,
    });

    return success({ updated: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ---------- WEBHOOKS ----------

async function listWebhooks(input: unknown): Promise<Result<{ webhooks: Array<{ id: string; triggerType: string; url: string }> }>> {
  const parsed = Types.ListWebhooksSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const response = await webflowCall(
      (client) => client.webhooks.list(parsed.data.site_id),
      "webhooks"
    );

    const webhooks = (response.webhooks || []).map((w) => ({
      id: w.id!,
      triggerType: w.triggerType!,
      url: w.url!,
    }));

    return success({ webhooks });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function createWebhook(input: unknown): Promise<Result<{ webhook: { id: string; triggerType: string } }>> {
  const parsed = Types.CreateWebhookSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    // Validate webhook URL (SSRF prevention)
    validateRemoteUrl(parsed.data.url);

    const webhook = await webflowCall(
      (client) => client.webhooks.create(parsed.data.site_id, {
        triggerType: parsed.data.trigger_type as any,
        url: parsed.data.url,
        filter: parsed.data.filter,
      }),
      "webhook"
    );

    await logDecision("create", "webhook", webhook.id!, "success", {
      contentPreview: `${parsed.data.trigger_type} -> ${parsed.data.url}`,
    });

    return success({
      webhook: {
        id: webhook.id!,
        triggerType: webhook.triggerType!,
      },
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function getWebhook(input: unknown): Promise<Result<Types.WebflowWebhook>> {
  const parsed = Types.GetWebhookSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    const webhook = await webflowCall(
      (client) => client.webhooks.get(parsed.data.webhook_id),
      "webhook"
    );

    return success({
      id: webhook.id!,
      triggerType: webhook.triggerType!,
      url: webhook.url!,
      createdOn: webhook.createdOn!,
      lastTriggered: webhook.lastTriggered || undefined,
      filter: webhook.filter as Record<string, string> | undefined,
    });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

async function deleteWebhook(input: unknown): Promise<Result<{ deleted: boolean }>> {
  const parsed = Types.DeleteWebhookSchema.safeParse(input);
  if (!parsed.success) return failure(`Invalid input: ${parsed.error.message}`);

  try {
    await webflowCall(
      (client) => client.webhooks.delete(parsed.data.webhook_id),
      "webhook"
    );

    await logDecision("delete", "webhook", parsed.data.webhook_id, "success");

    return success({ deleted: true });
  } catch (error) {
    return failure(error instanceof Error ? error.message : String(error));
  }
}

// ============================================================
// TOOL DEFINITIONS
// ============================================================

// Tool definitions
interface Tool {
  name: string;
  description: string;
  inputSchema: {
    type: string;
    properties?: Record<string, unknown>;
    required?: string[];
  };
}

const tools: Tool[] = [
  // Sites (4)
  {
    name: "list_sites",
    description: "List all Webflow sites accessible with your API token",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "get_site",
    description: "Get details of a specific Webflow site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "publish_site",
    description: "Publish a Webflow site to make changes live",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        domains: { type: "array", items: { type: "string" }, description: "Specific domains to publish to (optional)" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_domains",
    description: "Get custom domains configured for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },

  // Collections (4)
  {
    name: "list_collections",
    description: "List all CMS collections for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_collection",
    description: "Get collection details including field schema",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
      },
      required: ["collection_id"],
    },
  },
  {
    name: "create_collection",
    description: "Create a new CMS collection",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        display_name: { type: "string", description: "Collection display name" },
        singular_name: { type: "string", description: "Singular name (e.g., 'Post' for 'Posts')" },
        slug: { type: "string", description: "URL slug (optional)" },
      },
      required: ["site_id", "display_name", "singular_name"],
    },
  },
  {
    name: "create_collection_field",
    description: "Add a field to a CMS collection",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        display_name: { type: "string", description: "Field display name" },
        slug: { type: "string", description: "Field slug (optional)" },
        type: { type: "string", enum: ["PlainText", "RichText", "Image", "MultiImage", "Video", "Link", "Email", "Phone", "Number", "DateTime", "Switch", "Color", "Option", "File", "Reference", "MultiReference", "User"], description: "Field type" },
        is_required: { type: "boolean", description: "Whether field is required" },
      },
      required: ["collection_id", "display_name", "type"],
    },
  },

  // CMS Items - Single (6)
  {
    name: "create_cms_item",
    description: "Create a new CMS item in a collection",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        field_data: { type: "object", description: "Field values matching collection schema" },
        is_draft: { type: "boolean", description: "Create as draft (default: true)" },
        is_archived: { type: "boolean", description: "Create as archived (default: false)" },
      },
      required: ["collection_id", "field_data"],
    },
  },
  {
    name: "get_cms_item",
    description: "Get a CMS item by ID",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_id: { type: "string", description: "Item ID" },
      },
      required: ["collection_id", "item_id"],
    },
  },
  {
    name: "update_cms_item",
    description: "Update an existing CMS item",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_id: { type: "string", description: "Item ID" },
        field_data: { type: "object", description: "Field values to update" },
        is_draft: { type: "boolean", description: "Set draft status" },
        is_archived: { type: "boolean", description: "Set archived status" },
      },
      required: ["collection_id", "item_id", "field_data"],
    },
  },
  {
    name: "delete_cms_item",
    description: "Delete a CMS item",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_id: { type: "string", description: "Item ID" },
      },
      required: ["collection_id", "item_id"],
    },
  },
  {
    name: "publish_cms_item",
    description: "Publish a single CMS item to the live site",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_id: { type: "string", description: "Item ID" },
      },
      required: ["collection_id", "item_id"],
    },
  },
  {
    name: "list_cms_items",
    description: "List CMS items in a collection with pagination",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        limit: { type: "number", description: "Max items to return (1-100, default: 20)" },
        offset: { type: "number", description: "Pagination offset (default: 0)" },
      },
      required: ["collection_id"],
    },
  },

  // CMS Items - Bulk (4)
  {
    name: "bulk_create_cms_items",
    description: "Create up to 100 CMS items in a single request",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        items: { type: "array", description: "Array of items with field_data, is_draft, is_archived" },
      },
      required: ["collection_id", "items"],
    },
  },
  {
    name: "bulk_update_cms_items",
    description: "Update up to 100 CMS items in a single request",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        items: { type: "array", description: "Array of items with id, field_data, is_draft, is_archived" },
      },
      required: ["collection_id", "items"],
    },
  },
  {
    name: "bulk_delete_cms_items",
    description: "Delete up to 100 CMS items in a single request",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_ids: { type: "array", items: { type: "string" }, description: "Array of item IDs to delete" },
      },
      required: ["collection_id", "item_ids"],
    },
  },
  {
    name: "bulk_publish_cms_items",
    description: "Publish up to 100 CMS items in a single request",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_ids: { type: "array", items: { type: "string" }, description: "Array of item IDs to publish" },
      },
      required: ["collection_id", "item_ids"],
    },
  },

  // CMS Items - Live (3)
  {
    name: "create_live_cms_item",
    description: "Create a CMS item directly to the live site (bypasses draft)",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        field_data: { type: "object", description: "Field values matching collection schema" },
      },
      required: ["collection_id", "field_data"],
    },
  },
  {
    name: "update_live_cms_item",
    description: "Update a live CMS item directly",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_id: { type: "string", description: "Item ID" },
        field_data: { type: "object", description: "Field values to update" },
      },
      required: ["collection_id", "item_id", "field_data"],
    },
  },
  {
    name: "delete_live_cms_item",
    description: "Delete a CMS item from the live site",
    inputSchema: {
      type: "object",
      properties: {
        collection_id: { type: "string", description: "Collection ID" },
        item_id: { type: "string", description: "Item ID" },
      },
      required: ["collection_id", "item_id"],
    },
  },

  // Assets (6)
  {
    name: "list_assets",
    description: "List all assets for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_asset",
    description: "Get asset details by ID",
    inputSchema: {
      type: "object",
      properties: {
        asset_id: { type: "string", description: "Asset ID" },
      },
      required: ["asset_id"],
    },
  },
  {
    name: "upload_asset",
    description: "Upload a file to Webflow assets",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        file_name: { type: "string", description: "Name for the uploaded file" },
        file_path: { type: "string", description: "Local file path (must be in allowed directories)" },
        parent_folder_id: { type: "string", description: "Asset folder ID (optional)" },
      },
      required: ["site_id", "file_name", "file_path"],
    },
  },
  {
    name: "delete_asset",
    description: "Delete an asset",
    inputSchema: {
      type: "object",
      properties: {
        asset_id: { type: "string", description: "Asset ID" },
      },
      required: ["asset_id"],
    },
  },
  {
    name: "list_asset_folders",
    description: "List asset folders for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "create_asset_folder",
    description: "Create a new asset folder",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        display_name: { type: "string", description: "Folder name" },
      },
      required: ["site_id", "display_name"],
    },
  },

  // Pages (4)
  {
    name: "list_pages",
    description: "List all pages for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_page",
    description: "Get page metadata",
    inputSchema: {
      type: "object",
      properties: {
        page_id: { type: "string", description: "Page ID" },
      },
      required: ["page_id"],
    },
  },
  {
    name: "update_page_seo",
    description: "Update page SEO and Open Graph settings",
    inputSchema: {
      type: "object",
      properties: {
        page_id: { type: "string", description: "Page ID" },
        title: { type: "string", description: "SEO title" },
        description: { type: "string", description: "SEO description" },
        og_title: { type: "string", description: "Open Graph title" },
        og_description: { type: "string", description: "Open Graph description" },
      },
      required: ["page_id"],
    },
  },
  {
    name: "get_page_content",
    description: "Get page DOM content",
    inputSchema: {
      type: "object",
      properties: {
        page_id: { type: "string", description: "Page ID" },
      },
      required: ["page_id"],
    },
  },

  // Custom Code (5)
  {
    name: "register_inline_script",
    description: "Register an inline JavaScript script for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        display_name: { type: "string", description: "Script display name" },
        source_code: { type: "string", description: "JavaScript source code" },
        version: { type: "string", description: "Version string (default: 1.0.0)" },
      },
      required: ["site_id", "display_name", "source_code"],
    },
  },
  {
    name: "register_hosted_script",
    description: "Register a hosted JavaScript script URL for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        display_name: { type: "string", description: "Script display name" },
        hosted_location: { type: "string", description: "Script URL (must be HTTPS)" },
        integrity_hash: { type: "string", description: "Subresource Integrity hash (optional)" },
        version: { type: "string", description: "Version string (default: 1.0.0)" },
        can_copy: { type: "boolean", description: "Allow copying (default: false)" },
      },
      required: ["site_id", "display_name", "hosted_location"],
    },
  },
  {
    name: "list_registered_scripts",
    description: "List all registered scripts for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "add_site_custom_code",
    description: "Apply registered scripts to entire site (header or footer)",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        scripts: { type: "array", description: "Array of {id, location: 'header'|'footer'}" },
      },
      required: ["site_id", "scripts"],
    },
  },
  {
    name: "add_page_custom_code",
    description: "Apply registered scripts to a specific page (header or footer)",
    inputSchema: {
      type: "object",
      properties: {
        page_id: { type: "string", description: "Page ID" },
        scripts: { type: "array", description: "Array of {id, location: 'header'|'footer'}" },
      },
      required: ["page_id", "scripts"],
    },
  },

  // Forms (4)
  {
    name: "list_forms",
    description: "List all forms for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_form_schema",
    description: "Get form field schema",
    inputSchema: {
      type: "object",
      properties: {
        form_id: { type: "string", description: "Form ID" },
      },
      required: ["form_id"],
    },
  },
  {
    name: "list_form_submissions",
    description: "List form submissions with pagination",
    inputSchema: {
      type: "object",
      properties: {
        form_id: { type: "string", description: "Form ID" },
        limit: { type: "number", description: "Max submissions to return (1-100, default: 20)" },
        offset: { type: "number", description: "Pagination offset (default: 0)" },
      },
      required: ["form_id"],
    },
  },
  {
    name: "get_form_submission",
    description: "Get a specific form submission",
    inputSchema: {
      type: "object",
      properties: {
        form_submission_id: { type: "string", description: "Form submission ID" },
      },
      required: ["form_submission_id"],
    },
  },

  // Users (5)
  {
    name: "list_users",
    description: "List site users (memberships)",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        limit: { type: "number", description: "Max users to return (1-100, default: 20)" },
        offset: { type: "number", description: "Pagination offset (default: 0)" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_user",
    description: "Get user details",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        user_id: { type: "string", description: "User ID" },
      },
      required: ["site_id", "user_id"],
    },
  },
  {
    name: "invite_user",
    description: "Invite a new user to the site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        email: { type: "string", description: "User email address" },
        access_groups: { type: "array", items: { type: "string" }, description: "Access group IDs (optional)" },
      },
      required: ["site_id", "email"],
    },
  },
  {
    name: "update_user",
    description: "Update user access groups",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        user_id: { type: "string", description: "User ID" },
        access_groups: { type: "array", items: { type: "string" }, description: "New access group IDs" },
      },
      required: ["site_id", "user_id"],
    },
  },
  {
    name: "delete_user",
    description: "Delete a user from the site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        user_id: { type: "string", description: "User ID" },
      },
      required: ["site_id", "user_id"],
    },
  },

  // Access Groups (3)
  {
    name: "list_access_groups",
    description: "List access groups for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_access_group",
    description: "Get access group details",
    inputSchema: {
      type: "object",
      properties: {
        access_group_id: { type: "string", description: "Access group ID" },
      },
      required: ["access_group_id"],
    },
  },
  {
    name: "add_user_to_access_group",
    description: "Add a user to an access group (use update_user instead)",
    inputSchema: {
      type: "object",
      properties: {
        access_group_id: { type: "string", description: "Access group ID" },
        user_id: { type: "string", description: "User ID" },
      },
      required: ["access_group_id", "user_id"],
    },
  },

  // Ecommerce - Products (5)
  {
    name: "list_products",
    description: "List ecommerce products with pagination",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        limit: { type: "number", description: "Max products to return (1-100, default: 20)" },
        offset: { type: "number", description: "Pagination offset (default: 0)" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_product",
    description: "Get product details including SKUs",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        product_id: { type: "string", description: "Product ID" },
      },
      required: ["site_id", "product_id"],
    },
  },
  {
    name: "create_product",
    description: "Create a new ecommerce product with default SKU",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        field_data: { type: "object", description: "{name, slug, description}" },
        sku_data: { type: "object", description: "{price, currency, quantity}" },
      },
      required: ["site_id", "field_data", "sku_data"],
    },
  },
  {
    name: "update_product",
    description: "Update product field data",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        product_id: { type: "string", description: "Product ID" },
        field_data: { type: "object", description: "Field values to update" },
      },
      required: ["site_id", "product_id", "field_data"],
    },
  },
  {
    name: "create_sku",
    description: "Add a SKU variant to a product",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        product_id: { type: "string", description: "Product ID" },
        field_data: { type: "object", description: "{name, slug, price, currency, sku}" },
      },
      required: ["site_id", "product_id", "field_data"],
    },
  },

  // Ecommerce - Orders (4)
  {
    name: "list_orders",
    description: "List ecommerce orders with optional status filter",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        status: { type: "string", enum: ["pending", "unfulfilled", "fulfilled", "refunded", "disputed", "dispute-lost"], description: "Filter by status" },
        limit: { type: "number", description: "Max orders to return (1-100, default: 20)" },
        offset: { type: "number", description: "Pagination offset (default: 0)" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "get_order",
    description: "Get order details including items and customer info",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        order_id: { type: "string", description: "Order ID" },
      },
      required: ["site_id", "order_id"],
    },
  },
  {
    name: "update_order",
    description: "Update order status",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        order_id: { type: "string", description: "Order ID" },
        status: { type: "string", enum: ["pending", "unfulfilled", "fulfilled", "refunded", "disputed", "dispute-lost"], description: "New status" },
        comment: { type: "string", description: "Status change comment (optional)" },
      },
      required: ["site_id", "order_id", "status"],
    },
  },
  {
    name: "refund_order",
    description: "Process a refund for an order",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        order_id: { type: "string", description: "Order ID" },
        reason: { type: "string", description: "Refund reason (optional)" },
      },
      required: ["site_id", "order_id"],
    },
  },

  // Ecommerce - Inventory (2)
  {
    name: "list_inventory",
    description: "List inventory levels for a collection",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        collection_id: { type: "string", description: "Product collection ID" },
      },
      required: ["site_id", "collection_id"],
    },
  },
  {
    name: "update_inventory",
    description: "Update inventory quantity for an item",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        collection_id: { type: "string", description: "Product collection ID" },
        inventory_item_id: { type: "string", description: "Inventory item ID" },
        quantity: { type: "number", description: "New quantity" },
      },
      required: ["site_id", "collection_id", "inventory_item_id", "quantity"],
    },
  },

  // Webhooks (4)
  {
    name: "list_webhooks",
    description: "List webhooks for a site",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
      },
      required: ["site_id"],
    },
  },
  {
    name: "create_webhook",
    description: "Create a webhook for site events",
    inputSchema: {
      type: "object",
      properties: {
        site_id: { type: "string", description: "Webflow site ID" },
        trigger_type: { type: "string", enum: ["form_submission", "site_publish", "ecomm_new_order", "ecomm_order_changed", "ecomm_inventory_changed"], description: "Event type to trigger on" },
        url: { type: "string", description: "Webhook endpoint URL (must be HTTPS)" },
        filter: { type: "object", description: "Optional filter (e.g., form name for form_submission)" },
      },
      required: ["site_id", "trigger_type", "url"],
    },
  },
  {
    name: "get_webhook",
    description: "Get webhook details",
    inputSchema: {
      type: "object",
      properties: {
        webhook_id: { type: "string", description: "Webhook ID" },
      },
      required: ["webhook_id"],
    },
  },
  {
    name: "delete_webhook",
    description: "Delete a webhook",
    inputSchema: {
      type: "object",
      properties: {
        webhook_id: { type: "string", description: "Webhook ID" },
      },
      required: ["webhook_id"],
    },
  },
];

// ============================================================
// MCP SERVER SETUP
// ============================================================

const server = new Server(
  { name: "updike-webflow", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools,
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  let result: Result<unknown>;

  switch (name) {
    // Sites
    case "list_sites": result = await listSites(); break;
    case "get_site": result = await getSite(args); break;
    case "publish_site": result = await publishSite(args); break;
    case "get_domains": result = await getDomains(args); break;

    // Collections
    case "list_collections": result = await listCollections(args); break;
    case "get_collection": result = await getCollection(args); break;
    case "create_collection": result = await createCollection(args); break;
    case "create_collection_field": result = await createCollectionField(args); break;

    // CMS Items - Single
    case "create_cms_item": result = await createCmsItem(args); break;
    case "get_cms_item": result = await getCmsItem(args); break;
    case "update_cms_item": result = await updateCmsItem(args); break;
    case "delete_cms_item": result = await deleteCmsItem(args); break;
    case "publish_cms_item": result = await publishCmsItem(args); break;
    case "list_cms_items": result = await listCmsItems(args); break;

    // CMS Items - Bulk
    case "bulk_create_cms_items": result = await bulkCreateCmsItems(args); break;
    case "bulk_update_cms_items": result = await bulkUpdateCmsItems(args); break;
    case "bulk_delete_cms_items": result = await bulkDeleteCmsItems(args); break;
    case "bulk_publish_cms_items": result = await bulkPublishCmsItems(args); break;

    // CMS Items - Live
    case "create_live_cms_item": result = await createLiveCmsItem(args); break;
    case "update_live_cms_item": result = await updateLiveCmsItem(args); break;
    case "delete_live_cms_item": result = await deleteLiveCmsItem(args); break;

    // Assets
    case "list_assets": result = await listAssets(args); break;
    case "get_asset": result = await getAsset(args); break;
    case "upload_asset": result = await uploadAsset(args); break;
    case "delete_asset": result = await deleteAsset(args); break;
    case "list_asset_folders": result = await listAssetFolders(args); break;
    case "create_asset_folder": result = await createAssetFolder(args); break;

    // Pages
    case "list_pages": result = await listPages(args); break;
    case "get_page": result = await getPage(args); break;
    case "update_page_seo": result = await updatePageSeo(args); break;
    case "get_page_content": result = await getPageContent(args); break;

    // Custom Code
    case "register_inline_script": result = await registerInlineScript(args); break;
    case "register_hosted_script": result = await registerHostedScript(args); break;
    case "list_registered_scripts": result = await listRegisteredScripts(args); break;
    case "add_site_custom_code": result = await addSiteCustomCode(args); break;
    case "add_page_custom_code": result = await addPageCustomCode(args); break;

    // Forms
    case "list_forms": result = await listForms(args); break;
    case "get_form_schema": result = await getFormSchema(args); break;
    case "list_form_submissions": result = await listFormSubmissions(args); break;
    case "get_form_submission": result = await getFormSubmission(args); break;

    // Users
    case "list_users": result = await listUsers(args); break;
    case "get_user": result = await getUser(args); break;
    case "invite_user": result = await inviteUser(args); break;
    case "update_user": result = await updateUser(args); break;
    case "delete_user": result = await deleteUser(args); break;

    // Access Groups
    case "list_access_groups": result = await listAccessGroups(args); break;
    case "get_access_group": result = await getAccessGroup(args); break;
    case "add_user_to_access_group": result = await addUserToAccessGroup(args); break;

    // Ecommerce - Products
    case "list_products": result = await listProducts(args); break;
    case "get_product": result = await getProduct(args); break;
    case "create_product": result = await createProduct(args); break;
    case "update_product": result = await updateProduct(args); break;
    case "create_sku": result = await createSku(args); break;

    // Ecommerce - Orders
    case "list_orders": result = await listOrders(args); break;
    case "get_order": result = await getOrder(args); break;
    case "update_order": result = await updateOrder(args); break;
    case "refund_order": result = await refundOrder(args); break;

    // Ecommerce - Inventory
    case "list_inventory": result = await listInventory(args); break;
    case "update_inventory": result = await updateInventory(args); break;

    // Webhooks
    case "list_webhooks": result = await listWebhooks(args); break;
    case "create_webhook": result = await createWebhook(args); break;
    case "get_webhook": result = await getWebhook(args); break;
    case "delete_webhook": result = await deleteWebhook(args); break;

    default:
      result = failure(`Unknown tool: ${name}`);
  }

  return {
    content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
  };
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Updike Webflow MCP server running (63 tools)");
}

main().catch(console.error);
