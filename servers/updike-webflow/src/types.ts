import { z } from "zod";

// Result type - matches other Updike MCP servers
export type Result<T> = { success: true; data: T } | { success: false; error: string };

// Webflow API types
export interface WebflowSite {
  id: string;
  workspaceId: string;
  displayName: string;
  shortName: string;
  previewUrl?: string;
  timeZone: string;
  createdOn: string | Date;
  lastUpdated: string | Date;
  lastPublished?: string | Date;
}

export interface WebflowDomain {
  id: string;
  url: string;
}

export interface WebflowCollection {
  id: string;
  displayName: string;
  singularName: string;
  slug: string;
  createdOn: string;
  lastUpdated: string;
}

export interface WebflowCollectionField {
  id: string;
  isEditable: boolean;
  isRequired: boolean;
  type: string;
  slug: string;
  displayName: string;
}

export interface WebflowItem {
  id: string;
  cmsLocaleId?: string;
  lastPublished?: string;
  lastUpdated: string;
  createdOn: string;
  isArchived: boolean;
  isDraft: boolean;
  fieldData: Record<string, unknown>;
}

export interface WebflowAsset {
  id: string;
  contentType: string;
  size: number;
  siteId: string;
  hostedUrl: string;
  originalFileName: string;
  displayName: string;
  createdOn: string | Date;
  lastUpdated: string | Date;
}

export interface WebflowAssetFolder {
  id: string;
  displayName: string;
  createdOn: string;
  lastUpdated: string;
}

export interface WebflowPage {
  id: string;
  siteId: string;
  title: string;
  slug: string;
  parentId?: string;
  collectionId?: string;
  createdOn: string | Date;
  lastUpdated: string | Date;
  archived: boolean;
  draft: boolean;
  seo?: {
    title?: string;
    description?: string;
  };
  openGraph?: {
    title?: string;
    description?: string;
    titleCopied?: boolean;
    descriptionCopied?: boolean;
  };
}

export interface WebflowForm {
  id: string;
  displayName: string;
  siteId: string;
  siteDomainId: string;
  pageId: string;
  pageName: string;
  fields: WebflowFormField[];
}

export interface WebflowFormField {
  displayName: string;
  type: string;
  placeholder?: string;
  userVisible: boolean;
}

export interface WebflowFormSubmission {
  id: string;
  displayName: string;
  siteId: string;
  formId: string;
  formResponse: Record<string, string>;
  submittedAt: string;
}

export interface WebflowUser {
  id: string;
  email: string;
  status: string;
  createdOn: string;
  lastUpdated: string;
  accessGroups?: string[];
}

export interface WebflowAccessGroup {
  id: string;
  name: string;
  slug: string;
  type: string;
  createdOn: string | Date;
}

export interface WebflowProduct {
  id: string;
  cmsLocaleId?: string;
  lastPublished?: string;
  lastUpdated: string;
  createdOn: string;
  isArchived: boolean;
  isDraft: boolean;
  fieldData: {
    name: string;
    slug: string;
    description?: string;
    price?: { value: number; unit: string };
  };
  product: {
    id: string;
    defaultSku: WebflowSku;
    skus: WebflowSku[];
  };
}

export interface WebflowSku {
  id: string;
  cmsLocaleId?: string;
  fieldData: {
    name: string;
    slug: string;
    price: { value: number; unit: string };
    "compare-at-price"?: { value: number; unit: string };
    sku?: string;
    quantity?: number;
  };
}

export interface WebflowOrder {
  orderId: string;
  status: string;
  customerPaid: { value: number; unit: string };
  netAmount: { value: number; unit: string };
  purchasedAt: string;
  stripeDetails?: {
    customerId: string;
    paymentIntentId: string;
  };
  customerInfo: {
    fullName: string;
    email: string;
  };
  purchasedItems: Array<{
    productId: string;
    productName: string;
    variantId: string;
    variantName: string;
    variantPrice: { value: number; unit: string };
    count: number;
  }>;
}

export interface WebflowInventoryItem {
  id: string;
  quantity: number;
  inventoryType: string;
}

export interface WebflowWebhook {
  id: string;
  triggerType: string;
  url: string;
  createdOn: string | Date;
  lastTriggered?: string | Date;
  filter?: Record<string, string>;
}

export interface WebflowScript {
  id: string;
  displayName: string;
  hostedLocation?: string;
  integrityHash?: string;
  canCopy: boolean;
  version: string;
  createdOn: string;
  lastUpdated: string;
}

// Zod Schemas for tool inputs

// Sites
export const ListSitesSchema = z.object({});

export const GetSiteSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const PublishSiteSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  domains: z.array(z.string()).optional(),
});

export const GetDomainsSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

// Collections
export const ListCollectionsSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const GetCollectionSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
});

export const CreateCollectionSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  display_name: z.string().min(1, "Display name is required"),
  singular_name: z.string().min(1, "Singular name is required"),
  slug: z.string().optional(),
});

export const CreateCollectionFieldSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  display_name: z.string().min(1, "Display name is required"),
  slug: z.string().optional(),
  type: z.enum([
    "PlainText", "RichText", "Image", "MultiImage", "Video", "Link",
    "Email", "Phone", "Number", "DateTime", "Switch", "Color",
    "Option", "File", "Reference", "MultiReference", "User",
  ]),
  is_required: z.boolean().default(false),
});

// CMS Items - Single
export const CreateCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  field_data: z.record(z.unknown()),
  is_draft: z.boolean().default(true),
  is_archived: z.boolean().default(false),
});

export const GetCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_id: z.string().min(1, "Item ID is required"),
});

export const UpdateCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_id: z.string().min(1, "Item ID is required"),
  field_data: z.record(z.unknown()),
  is_draft: z.boolean().optional(),
  is_archived: z.boolean().optional(),
});

export const DeleteCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_id: z.string().min(1, "Item ID is required"),
});

export const PublishCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_id: z.string().min(1, "Item ID is required"),
});

export const ListCmsItemsSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  limit: z.number().int().min(1).max(100).default(20),
  offset: z.number().int().min(0).default(0),
});

// CMS Items - Bulk
export const BulkCreateCmsItemsSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  items: z.array(z.object({
    field_data: z.record(z.unknown()),
    is_draft: z.boolean().default(true),
    is_archived: z.boolean().default(false),
  })).min(1).max(100),
});

export const BulkUpdateCmsItemsSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  items: z.array(z.object({
    id: z.string().min(1),
    field_data: z.record(z.unknown()),
    is_draft: z.boolean().optional(),
    is_archived: z.boolean().optional(),
  })).min(1).max(100),
});

export const BulkDeleteCmsItemsSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_ids: z.array(z.string().min(1)).min(1).max(100),
});

export const BulkPublishCmsItemsSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_ids: z.array(z.string().min(1)).min(1).max(100),
});

// CMS Items - Live
export const CreateLiveCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  field_data: z.record(z.unknown()),
});

export const UpdateLiveCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_id: z.string().min(1, "Item ID is required"),
  field_data: z.record(z.unknown()),
});

export const DeleteLiveCmsItemSchema = z.object({
  collection_id: z.string().min(1, "Collection ID is required"),
  item_id: z.string().min(1, "Item ID is required"),
});

// Assets
export const ListAssetsSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const GetAssetSchema = z.object({
  asset_id: z.string().min(1, "Asset ID is required"),
});

export const UploadAssetSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  file_name: z.string().min(1, "File name is required"),
  file_path: z.string().min(1, "File path is required"),
  parent_folder_id: z.string().optional(),
});

export const DeleteAssetSchema = z.object({
  asset_id: z.string().min(1, "Asset ID is required"),
});

export const ListAssetFoldersSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const CreateAssetFolderSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  display_name: z.string().min(1, "Display name is required"),
});

// Pages
export const ListPagesSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const GetPageSchema = z.object({
  page_id: z.string().min(1, "Page ID is required"),
});

export const UpdatePageSeoSchema = z.object({
  page_id: z.string().min(1, "Page ID is required"),
  title: z.string().optional(),
  description: z.string().optional(),
  og_title: z.string().optional(),
  og_description: z.string().optional(),
});

export const GetPageContentSchema = z.object({
  page_id: z.string().min(1, "Page ID is required"),
});

// Custom Code
export const RegisterInlineScriptSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  display_name: z.string().min(1, "Display name is required"),
  source_code: z.string().min(1, "Source code is required"),
  version: z.string().default("1.0.0"),
});

export const RegisterHostedScriptSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  display_name: z.string().min(1, "Display name is required"),
  hosted_location: z.string().url("Must be a valid URL"),
  integrity_hash: z.string().optional(),
  version: z.string().default("1.0.0"),
  can_copy: z.boolean().default(false),
});

export const ListRegisteredScriptsSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const AddSiteCustomCodeSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  scripts: z.array(z.object({
    id: z.string().min(1),
    location: z.enum(["header", "footer"]),
  })),
});

export const AddPageCustomCodeSchema = z.object({
  page_id: z.string().min(1, "Page ID is required"),
  scripts: z.array(z.object({
    id: z.string().min(1),
    location: z.enum(["header", "footer"]),
  })),
});

// Forms
export const ListFormsSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const GetFormSchemaInputSchema = z.object({
  form_id: z.string().min(1, "Form ID is required"),
});

export const ListFormSubmissionsSchema = z.object({
  form_id: z.string().min(1, "Form ID is required"),
  limit: z.number().int().min(1).max(100).default(20),
  offset: z.number().int().min(0).default(0),
});

export const GetFormSubmissionSchema = z.object({
  form_submission_id: z.string().min(1, "Form submission ID is required"),
});

// Users
export const ListUsersSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  limit: z.number().int().min(1).max(100).default(20),
  offset: z.number().int().min(0).default(0),
});

export const GetUserSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  user_id: z.string().min(1, "User ID is required"),
});

export const InviteUserSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  email: z.string().email("Must be a valid email"),
  access_groups: z.array(z.string()).optional(),
});

export const UpdateUserSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  user_id: z.string().min(1, "User ID is required"),
  access_groups: z.array(z.string()).optional(),
});

export const DeleteUserSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  user_id: z.string().min(1, "User ID is required"),
});

// Access Groups
export const ListAccessGroupsSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const GetAccessGroupSchema = z.object({
  access_group_id: z.string().min(1, "Access group ID is required"),
});

export const AddUserToAccessGroupSchema = z.object({
  access_group_id: z.string().min(1, "Access group ID is required"),
  user_id: z.string().min(1, "User ID is required"),
});

// Ecommerce - Products
export const ListProductsSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  limit: z.number().int().min(1).max(100).default(20),
  offset: z.number().int().min(0).default(0),
});

export const GetProductSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  product_id: z.string().min(1, "Product ID is required"),
});

export const CreateProductSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  field_data: z.object({
    name: z.string().min(1),
    slug: z.string().min(1),
    description: z.string().optional(),
  }),
  sku_data: z.object({
    price: z.number().min(0),
    currency: z.string().default("USD"),
    quantity: z.number().int().min(0).optional(),
  }),
});

export const UpdateProductSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  product_id: z.string().min(1, "Product ID is required"),
  field_data: z.record(z.unknown()),
});

export const CreateSkuSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  product_id: z.string().min(1, "Product ID is required"),
  field_data: z.object({
    name: z.string().min(1),
    slug: z.string().min(1),
    price: z.number().min(0),
    currency: z.string().default("USD"),
    sku: z.string().optional(),
  }),
});

// Ecommerce - Orders
export const ListOrdersSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  status: z.enum(["pending", "unfulfilled", "fulfilled", "refunded", "disputed", "dispute-lost"]).optional(),
  limit: z.number().int().min(1).max(100).default(20),
  offset: z.number().int().min(0).default(0),
});

export const GetOrderSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  order_id: z.string().min(1, "Order ID is required"),
});

export const UpdateOrderSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  order_id: z.string().min(1, "Order ID is required"),
  status: z.enum(["pending", "unfulfilled", "fulfilled", "refunded", "disputed", "dispute-lost"]),
  comment: z.string().optional(),
});

export const RefundOrderSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  order_id: z.string().min(1, "Order ID is required"),
  reason: z.string().optional(),
});

// Ecommerce - Inventory
export const ListInventorySchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  collection_id: z.string().min(1, "Collection ID is required"),
});

export const UpdateInventorySchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  collection_id: z.string().min(1, "Collection ID is required"),
  inventory_item_id: z.string().min(1, "Inventory item ID is required"),
  quantity: z.number().int().min(0),
});

// Webhooks
export const ListWebhooksSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
});

export const CreateWebhookSchema = z.object({
  site_id: z.string().min(1, "Site ID is required"),
  trigger_type: z.enum([
    "form_submission",
    "site_publish",
    "ecomm_new_order",
    "ecomm_order_changed",
    "ecomm_inventory_changed",
  ]),
  url: z.string().url("Must be a valid URL"),
  filter: z.record(z.string()).optional(),
});

export const GetWebhookSchema = z.object({
  webhook_id: z.string().min(1, "Webhook ID is required"),
});

export const DeleteWebhookSchema = z.object({
  webhook_id: z.string().min(1, "Webhook ID is required"),
});
