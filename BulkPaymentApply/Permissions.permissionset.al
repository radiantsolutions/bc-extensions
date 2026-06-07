permissionset 50100 "Bulk Payment Apply"
{
    Assignable = true;
    Caption = 'Bulk Payment Apply';

    Permissions =
        table "Payment Apply Buffer" = X,
        tabledata "Payment Apply Buffer" = RIMD,
        codeunit "Bulk Apply Customer Payments" = X,
        page "Payment Apply Buffer" = X;
}