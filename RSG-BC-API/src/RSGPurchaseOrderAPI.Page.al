// =============================================================================
//  RSG Purchase Order API  (Page 50201)
// -----------------------------------------------------------------------------
//  Exposes "Vendor Invoice No." as a writable field on purchase orders, which
//  Microsoft's standard purchaseOrder API does not surface. The AP Automation
//  agent stamps this value so matched orders can be batch-posted as invoices.
//
//  Agent flow:
//    1. Match + read the order via the STANDARD purchaseOrders API -> get `id`.
//    2. Set Qty. to Invoice on lines via the STANDARD purchaseOrderLine API.
//    3. PATCH this page at the same `id` to stamp vendorInvoiceNumber.
//    (SystemId is identical across the standard API and this one, so the agent
//     reuses the id from step 1 with no extra lookup.)
//
//  Endpoint:
//    .../api/radiant/apProcessing/v1.0/companies({companyId})/purchaseOrders({id})
//    PATCH body: { "vendorInvoiceNumber": "INV-12345" }   (header If-Match: *)
//
//  Only vendorInvoiceNumber is writable; everything else is read-only so the
//  endpoint can't nudge anything unintended. Setting the field runs the table's
//  standard OnValidate, including BC's duplicate-vendor-invoice-no. check.
// =============================================================================
page 50201 "RSG Purchase Order API"
{
    PageType = API;
    Caption = 'RSG Purchase Order API';
    APIPublisher = 'radiant';
    APIGroup = 'apProcessing';
    APIVersion = 'v1.0';
    EntityName = 'purchaseOrder';
    EntitySetName = 'purchaseOrders';
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = const(Order));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(vendorNumber; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Vendor No.';
                    Editable = false;
                }
                field(vendorName; Rec."Buy-from Vendor Name")
                {
                    Caption = 'Vendor Name';
                    Editable = false;
                }
                field(vendorInvoiceNumber; Rec."Vendor Invoice No.")
                {
                    Caption = 'Vendor Invoice No.';
                    // The one writable field — staged by the agent before batch posting.
                }
                field(orderDate; Rec."Order Date")
                {
                    Caption = 'Order Date';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }
}
