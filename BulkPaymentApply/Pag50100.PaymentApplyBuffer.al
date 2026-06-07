page 50100 "Payment Apply Buffer"
{
    Caption = 'Bulk Payment Apply';
    PageType = List;
    SourceTable = "Payment Apply Buffer";
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Payment Document No."; Rec."Payment Document No.")
                {
                    ApplicationArea = All;
                }
                field("Invoice Document No."; Rec."Invoice Document No.")
                {
                    ApplicationArea = All;
                }
                field(Processed; Rec.Processed)
                {
                    ApplicationArea = All;
                    StyleExpr = ProcessedStyle;
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    StyleExpr = ErrorStyle;
                }
                field("Payment Entry No."; Rec."Payment Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the exact payment Cust. Ledger Entry No. Optional — used as a tiebreaker when populated.';
                }
                field("Shipment No."; Rec."Shipment No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Reference to the posted shipment this payment corresponds to.';
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Reference to the originating sales order.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'External document number from the source system (e.g., Magento order number).';
                }
                // === v1.3.0.0 additions ===
                field("Payment Amount"; Rec."Payment Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Expected payment amount; validated against ledger remaining at apply time.';
                }
                field("Action Type"; Rec."Action Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Apply Existing = match payment to existing invoice. Create Invoice + Apply = post a cleanup invoice and apply.';
                }
                field("Invoice Posting Date"; Rec."Invoice Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posting date for the cleanup invoice (Create Invoice + Apply only).';
                }
                field("Invoice Line Description"; Rec."Invoice Line Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Optional line description for the cleanup invoice.';
                    Visible = false;
                }
                field("Revenue G/L Account"; Rec."Revenue G/L Account")
                {
                    ApplicationArea = All;
                    ToolTip = 'Revenue account for the cleanup invoice line. Usually 40100.';
                    Visible = false;
                }
                field("Tax Treatment"; Rec."Tax Treatment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Exempt = no sales tax on cleanup invoice. Liable = standard tax.';
                    Visible = false;
                }
                field("Created Invoice No."; Rec."Created Invoice No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posted invoice number created by the codeunit. Audit trail.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApplyAll)
            {
                Caption = 'Apply All';
                Image = ApplyEntries;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ApplicationArea = All;

                trigger OnAction()
                var
                    BulkApply: Codeunit "Bulk Apply Customer Payments";
                begin
                    BulkApply.RunApply();
                    CurrPage.Update(false);
                end;
            }
            action(ResetAll)
            {
                Caption = 'Reset Processed Flag';
                Image = ResetStatus;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Buffer: Record "Payment Apply Buffer";
                begin
                    if not Confirm('Reset all lines to unprocessed?') then
                        exit;
                    Buffer.ModifyAll(Processed, false);
                    Buffer.ModifyAll("Error Text", '');
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ProcessedStyle: Text;
        ErrorStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec."Error Text" <> '' then
            ErrorStyle := 'Unfavorable'
        else
            ErrorStyle := '';

        if Rec.Processed and (Rec."Error Text" = '') then
            ProcessedStyle := 'Favorable'
        else
            ProcessedStyle := '';
    end;
}
