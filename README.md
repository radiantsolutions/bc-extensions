# BC Extensions

Business Central (AL) per-tenant extensions for BulbsDepot, built by Radiant Solutions Group. This is a monorepo: each extension is its own AL project (its own `app.json` / `.app`), and a multi-root VS Code workspace ties them together.

## Projects

| Folder | Extension | Object ID range | What it does |
|---|---|---|---|
| `BulkPaymentApply/` | Bulk Payment Apply | 50100–501xx | Bulk application of customer payments (codeunit + buffer table + page + permission set). |
| `RSG-BC-API/` | RSG BC API | 50200–50249 | Custom API pages exposing BC fields to external automation agents — sales-order shipping (Copilot Order Status) and the purchase-order Vendor Invoice No. (AP automation). |

## Layout

```
bc-extensions/
├── .gitignore                  # shared; AL build artifacts ignored
├── BulbsDepot.code-workspace   # multi-root workspace — open THIS, not the folders
├── BulkPaymentApply/
│   ├── app.json
│   └── *.al
└── RSG-BC-API/
    ├── app.json
    ├── .vscode/launch.json     # sandbox target
    └── src/
        ├── RSGSalesOrderShippingAPI.Page.al   # page 50200
        ├── RSGPurchaseOrderAPI.Page.al        # page 50201
        └── RSGAPIAccess.PermissionSet.al      # permissionset 50210
```

## Conventions

- **Object name prefix:** `RSG` (e.g. `RSG Purchase Order API`).
- **File naming:** `<ObjectName without spaces>.<ObjectType>.al` (e.g. `RSGPurchaseOrderAPI.Page.al`).
- **API publisher:** `radiant` everywhere; **API group** by functional domain (`apProcessing`, `salesFulfillment`).
- **Object IDs:** each extension owns a non-overlapping slice of the 50000–99999 PTE range — partition up front to avoid publish conflicts.
- **One extension per bounded context.** Don't merge unrelated functionality into one app, and don't mix non-AL code (e.g. Magento/PHP) into this repo.

## Custom API endpoints

```
.../api/radiant/salesFulfillment/v1.0/companies({id})/salesOrderShipping
.../api/radiant/apProcessing/v1.0/companies({id})/purchaseOrders
```

Both API pages are keyed on `SystemId`, so their `id` matches the corresponding standard BC API entity — read via the standard API, then GET/PATCH the custom page at the same id.

## Getting started

1. **Clone to a clean local path** — e.g. `C:\dev\bc-extensions`. Do **not** work out of a OneDrive-synced or redirected-profile folder; that injects `desktop.ini` into `.git` and corrupts operations.
2. Open `BulbsDepot.code-workspace` (File → Open Workspace from File) — not the individual folders — so AL treats each project as its own root.
3. Click into a file in the project you're working on, then run **AL: Download Symbols** (per project; needs an active AL file + a `launch.json` env config).
4. Build: **Ctrl+Shift+B** (creates the `.app` locally; "Success: The package is created").
5. Publish: **AL: Publish without debugging** (Command Palette) or **Ctrl+F5**. This is the step that uploads to BC — a clean build alone does not deploy.

## Environments

- **Sandbox:** `Sandbox-2026-06-07` (dev work).
- **Production:** `Production` (exact casing).

## Deployment notes

- VS Code **dev-publishes** are ephemeral — BC removes them on environment update/relocation. For production, install the built `.app` through Extension Management or the admin center.
- Custom API pages require a **permission set** assigned to the calling app/user (the "Microsoft Entra Applications" page in BC), or the endpoint returns 401 even when the standard API works. Permission sets are per-environment — assign in Production separately.

## Ignored by git

`.alpackages/` (regenerable symbols), `*.app` (build output), `.snapshots/`, `.altestrunner/`, `rad.json`, plus OS junk (`desktop.ini`). See `.gitignore`.
