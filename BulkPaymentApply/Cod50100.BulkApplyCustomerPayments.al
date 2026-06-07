codeunit 50100 "Bulk Apply Customer Payments"
{
    procedure RunApply()
    var
        Buffer: Record "Payment Apply Buffer";
        Applied: Integer;
        Errors: Integer;
    begin
        Buffer.SetRange(Processed, false);
        if Buffer.IsEmpty() then
            Error('No unprocessed lines found.');

        if not Confirm('Apply %1 entries. Continue?', false, Buffer.Count()) then
            exit;

        Buffer.FindSet();
        repeat
            Commit();
            case Buffer."Action Type" of
                Buffer."Action Type"::"Apply Existing":
                    if ApplySingle(Buffer) then
                        Applied += 1
                    else
                        Errors += 1;
                Buffer."Action Type"::"Create Invoice + Apply":
                    if CreateInvoiceAndApply(Buffer) then
                        Applied += 1
                    else
                        Errors += 1;
            end;
        until Buffer.Next() = 0;

        Message('Done.\Applied: %1\Errors: %2', Applied, Errors);
    end;

    local procedure ApplySingle(var Buffer: Record "Payment Apply Buffer"): Boolean
    var
        PaymentCLE: Record "Cust. Ledger Entry";
        InvoiceCLE: Record "Cust. Ledger Entry";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        CustEntryApply: Codeunit "CustEntry-Apply Posted Entries";
        ApplyUnapplyParams: Record "Apply Unapply Parameters";
        AppliestoID: Code[50];
    begin
        // Find the open payment entry
        PaymentCLE.Reset();
        PaymentCLE.SetRange("Customer No.", Buffer."Customer No.");
        PaymentCLE.SetRange("Document Type", PaymentCLE."Document Type"::Payment);  // v1.2: narrow to payments only
        PaymentCLE.SetRange("Document No.", Buffer."Payment Document No.");
        PaymentCLE.SetRange(Open, true);
        if Buffer."Payment Entry No." <> 0 then                                      // v1.2: optional tiebreaker
            PaymentCLE.SetRange("Entry No.", Buffer."Payment Entry No.");
        if not PaymentCLE.FindFirst() then begin
            MarkError(Buffer, 'Payment entry not found or already closed.');
            exit(false);
        end;

        // Find the open invoice entry
        InvoiceCLE.Reset();
        InvoiceCLE.SetRange("Customer No.", Buffer."Customer No.");
        InvoiceCLE.SetRange("Document Type", InvoiceCLE."Document Type"::Invoice);   // v1.2: narrow to invoices only
        InvoiceCLE.SetRange("Document No.", Buffer."Invoice Document No.");
        InvoiceCLE.SetRange(Open, true);
        if not InvoiceCLE.FindFirst() then begin
            MarkError(Buffer, 'Invoice entry not found or already closed.');
            exit(false);
        end;

        // Build an Applies-to ID
        AppliestoID := Format(PaymentCLE."Entry No.");

        // Tag the invoice
        InvoiceCLE.CalcFields("Remaining Amount");
        InvoiceCLE."Applies-to ID" := AppliestoID;
        InvoiceCLE."Amount to Apply" := InvoiceCLE."Remaining Amount";
        CustEntryEdit.Run(InvoiceCLE);

        // Tag the payment
        PaymentCLE.CalcFields("Remaining Amount");
        PaymentCLE."Applies-to ID" := AppliestoID;
        PaymentCLE."Amount to Apply" := PaymentCLE."Remaining Amount";
        CustEntryEdit.Run(PaymentCLE);

        // Post the application
        PaymentCLE.FindFirst();
        ApplyUnapplyParams."Document No." := PaymentCLE."Document No.";
        if InvoiceCLE."Posting Date" > PaymentCLE."Posting Date" then
            ApplyUnapplyParams."Posting Date" := InvoiceCLE."Posting Date"
        else
            ApplyUnapplyParams."Posting Date" := PaymentCLE."Posting Date";
        CustEntryApply.Apply(PaymentCLE, ApplyUnapplyParams);

        // Mark success
        Buffer.Processed := true;
        Buffer."Error Text" := '';
        Buffer.Modify();
        exit(true);
    end;

    local procedure CreateInvoiceAndApply(var Buffer: Record "Payment Apply Buffer"): Boolean
    var
        PaymentCLE: Record "Cust. Ledger Entry";
        InvoiceCLE: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        SalesInvHeader: Record "Sales Invoice Header";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        CustEntryApply: Codeunit "CustEntry-Apply Posted Entries";
        ApplyUnapplyParams: Record "Apply Unapply Parameters";
        AppliestoID: Code[50];
        LedgerRemaining: Decimal;
        PreAssignedNo: Code[20];
    begin
        // === Step 1: Sanity check the payment ===
        PaymentCLE.Reset();
        PaymentCLE.SetRange("Customer No.", Buffer."Customer No.");
        PaymentCLE.SetRange("Document Type", PaymentCLE."Document Type"::Payment);
        PaymentCLE.SetRange("Document No.", Buffer."Payment Document No.");
        PaymentCLE.SetRange(Open, true);
        if Buffer."Payment Entry No." <> 0 then
            PaymentCLE.SetRange("Entry No.", Buffer."Payment Entry No.");
        if not PaymentCLE.FindFirst() then begin
            MarkError(Buffer, 'Payment entry not found or already closed.');
            exit(false);
        end;

        PaymentCLE.CalcFields("Remaining Amount");
        LedgerRemaining := Abs(PaymentCLE."Remaining Amount");

        if LedgerRemaining < 0.01 then begin
            MarkError(Buffer, StrSubstNo('Payment already closed (Remaining=%1).', PaymentCLE."Remaining Amount"));
            exit(false);
        end;

        if Abs(LedgerRemaining - Buffer."Payment Amount") > 0.01 then begin
            MarkError(Buffer, StrSubstNo(
                'Amount mismatch: staging=%1, ledger remaining=%2.',
                Buffer."Payment Amount", LedgerRemaining));
            exit(false);
        end;

        // === Step 2: Build the sales invoice header ===
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := '';  // let No. Series assign
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Buffer."Customer No.");
        SalesHeader.Validate("Posting Date", Buffer."Invoice Posting Date");
        SalesHeader.Validate("Document Date", Buffer."Invoice Posting Date");
        if Buffer."External Document No." <> '' then
            SalesHeader.Validate("External Document No.", Buffer."External Document No.")
        else
            SalesHeader.Validate("External Document No.", Buffer."Payment Document No.");
        if Buffer."Tax Treatment" = Buffer."Tax Treatment"::Exempt then
            SalesHeader.Validate("Tax Liable", false);
        SalesHeader.Modify(true);

        PreAssignedNo := SalesHeader."No.";  // capture for post-Sales-Post lookup

        // === Step 3: Build the single G/L revenue line ===
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", Buffer."Revenue G/L Account");
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", Buffer."Payment Amount");
        if Buffer."Invoice Line Description" <> '' then
            SalesLine.Validate(Description, Buffer."Invoice Line Description")
        else
            SalesLine.Validate(Description,
                StrSubstNo('Cleanup invoice for payment %1', Buffer."Payment Document No."));
        if Buffer."Tax Treatment" = Buffer."Tax Treatment"::Exempt then
            SalesLine.Validate("Tax Group Code", 'NONTAXABLE');  // override any customer default
        SalesLine.Modify(true);

        // === Step 4: Post (Ship=false, Invoice=true) ===
        SalesHeader.Validate(Ship, false);
        SalesHeader.Validate(Invoice, true);
        SalesHeader.Modify(true);
        Commit();  // close write transaction so SalesPost.Run can use return value
        if not SalesPost.Run(SalesHeader) then begin
            MarkError(Buffer, StrSubstNo('Sales-Post failed: %1', GetLastErrorText()));
            exit(false);
        end;

        // === Step 5: Locate the posted invoice via Pre-Assigned No. ===
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        if not SalesInvHeader.FindFirst() then begin
            MarkError(Buffer, StrSubstNo('Posted invoice not found for Pre-Assigned No. %1', PreAssignedNo));
            exit(false);
        end;

        // Persist for audit trail
        Buffer."Created Invoice No." := SalesInvHeader."No.";
        Buffer.Modify();

        // === Step 6: Find the new invoice CLE ===
        InvoiceCLE.Reset();
        InvoiceCLE.SetRange("Customer No.", Buffer."Customer No.");
        InvoiceCLE.SetRange("Document Type", InvoiceCLE."Document Type"::Invoice);
        InvoiceCLE.SetRange("Document No.", SalesInvHeader."No.");
        InvoiceCLE.SetRange(Open, true);
        if not InvoiceCLE.FindFirst() then begin
            MarkError(Buffer, 'Posted invoice CLE not found after Sales-Post.');
            exit(false);
        end;

        // === Step 7: Apply payment to new invoice (same pattern as ApplySingle) ===
        AppliestoID := Format(PaymentCLE."Entry No.");

        InvoiceCLE.CalcFields("Remaining Amount");
        InvoiceCLE."Applies-to ID" := AppliestoID;
        InvoiceCLE."Amount to Apply" := InvoiceCLE."Remaining Amount";
        CustEntryEdit.Run(InvoiceCLE);

        PaymentCLE.CalcFields("Remaining Amount");
        PaymentCLE."Applies-to ID" := AppliestoID;
        PaymentCLE."Amount to Apply" := PaymentCLE."Remaining Amount";
        CustEntryEdit.Run(PaymentCLE);

        PaymentCLE.FindFirst();
        ApplyUnapplyParams."Document No." := PaymentCLE."Document No.";
        if InvoiceCLE."Posting Date" > PaymentCLE."Posting Date" then
            ApplyUnapplyParams."Posting Date" := InvoiceCLE."Posting Date"
        else
            ApplyUnapplyParams."Posting Date" := PaymentCLE."Posting Date";
        CustEntryApply.Apply(PaymentCLE, ApplyUnapplyParams);

        // === Step 8: Mark success ===
        Buffer.Processed := true;
        Buffer."Error Text" := '';
        Buffer.Modify();
        exit(true);
    end;

    local procedure MarkError(var Buffer: Record "Payment Apply Buffer"; ErrorMsg: Text[250])
    begin
        Buffer.Processed := true;
        Buffer."Error Text" := ErrorMsg;
        Buffer.Modify();
    end;
}
