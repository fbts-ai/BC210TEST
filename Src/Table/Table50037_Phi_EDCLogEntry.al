Table 50037 "Phi_EDC Log Entry"
{

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(2; aggregatorId; Text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Function Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = 'Payment,Refund,QR';
            OptionMembers = Payment,Refund,QR;
        }
        field(4; Amount; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(5; invoiceNo; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(6; invoiceStatus; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Receipt No."; Code[30])
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Trans Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(15; "Trans Time"; Time)
        {
            DataClassification = ToBeClassified;
        }
        field(16; Reference; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(33; "Mobile No"; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(36; voided; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(37; "Receipt Line No"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(39; "Staff Id"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(41; "Store No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(51; responseCode; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(52; respDescription; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(53; "Payment Validated"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(101; "Replication Counter"; Integer)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                WalletLog.SetCurrentkey("Replication Counter");
                if WalletLog.FindLast then
                    "Replication Counter" := WalletLog."Replication Counter" + 1
                else
                    "Replication Counter" := 1;
            end;
        }
        field(102; merchantId; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(103; paymentDateTime; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(104; paymentInstrumentId; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(105; paymentMode; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(106; posAppId; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(107; posTillNo; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(108; txnAuthID; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(109; txnID; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(110; "Pos Terminal No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(111; txnRespDescription; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(112; txnResponseCode; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(113; txnStatus; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(114; RefundInvoiceNo; Text[30])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Receipt No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        //ERROR('You can not delete');
    end;

    trigger OnInsert()
    begin
        Validate("Replication Counter");
    end;

    trigger OnModify()
    begin
        Validate("Replication Counter");
        //ERROR('You can not modify');
    end;

    var
        WalletLog: Record "Phi_EDC Log Entry";
}

