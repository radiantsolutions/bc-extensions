// =============================================================================
//  RSG API Access  (PermissionSet 50210)
// -----------------------------------------------------------------------------
//  Grants access to the custom API pages and the table data they read/write.
//  Assign this to the Application (M2M) user that the agents authenticate as,
//  or the custom endpoints return 401 even when the standard API works — the
//  base permissions the app already holds do NOT automatically cover a custom
//  page object.
//
//  Least-privilege: read+modify on the two header tables (modify is needed for
//  the PATCH on Vendor Invoice No. and the sales shipping fields), execute on
//  the two pages. No insert/delete granted.
// =============================================================================
permissionset 50210 "RSG API Access"
{
    Access = Public;
    Assignable = true;
    Caption = 'RSG API Access';

    Permissions =
        tabledata "Sales Header" = RM,
        tabledata "Purchase Header" = RM,
        page "RSG Sales Order Shipping API" = X,
        page "RSG Purchase Order API" = X;
}
