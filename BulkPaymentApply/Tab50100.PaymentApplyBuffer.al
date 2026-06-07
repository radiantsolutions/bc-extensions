table 50100 "Payment Apply Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Customer No."; Code[20])
        {
            TableRelation = Customer;
        }
        field(3; "Payment Document No."; Code[20]) { }
        field(4; "Invoice Document No."; Code[20]) { }
        field(5; Processed; Boolean) { }
        field(6; "Error Text"; Text[250]) { }

        // --- v1.2.0.0 additions ---
        field(10; "Payment Entry No."; Integer)
        {
            Caption = 'Payment Entry No.';
            DataClassification = CustomerContent;
        }
        field(11; "Payment Amount"; Decimal)
        {
            Caption = 'Payment Amount';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            BlankZero = false;  // $0 is meaningful (would be a flag), don't hide it
        }
        field(20; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
            DataClassification = CustomerContent;
        }
        field(21; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            DataClassification = CustomerContent;
        }
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(60; "Action Type"; Option)
        {
            Caption = 'Action Type';
            DataClassification = CustomerContent;
            OptionMembers = "Apply Existing","Create Invoice + Apply";
            OptionCaption = 'Apply Existing,Create Invoice + Apply';
            InitValue = "Apply Existing";
        }
        field(61; "Invoice Posting Date"; Date)
        {
            Caption = 'Invoice Posting Date';
            DataClassification = CustomerContent;
        }
        field(62; "Invoice Line Description"; Text[100])
        {
            Caption = 'Invoice Line Description';
            DataClassification = CustomerContent;
        }
        field(63; "Revenue G/L Account"; Code[20])
        {
            Caption = 'Revenue G/L Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No." where("Direct Posting" = const(true));
        }
        field(64; "Tax Treatment"; Option)
        {
            Caption = 'Tax Treatment';
            DataClassification = CustomerContent;
            OptionMembers = "Exempt","Liable";
            OptionCaption = 'Exempt,Liable';
            InitValue = "Exempt";
        }
        field(65; "Created Invoice No."; Code[20])
        {
            Caption = 'Created Invoice No.';
            DataClassification = CustomerContent;
            Editable = false; // populated by codeunit, audit trail
            TableRelation = "Sales Invoice Header"."No.";
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}
