table 50036 "Wallet Log Entry"
{
    DataClassification = ToBeClassified;
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Wallet TXN No."; Text[64])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Function Type"; Option)
        {
            OptionMembers = Payment,Refund,QR;
            DataClassification = ToBeClassified;
        }
        field(4; Amount; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Wallet Type"; Option)
        {
            OptionMembers = Card,Wallet,"SMS Link";
            DataClassification = ToBeClassified;
        }
        field(6; "Receipt No."; Code[30])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "ResponseCode"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Trans Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Trans Time"; Time)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Reference"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Mobile No"; Text[200])
        {
            DataClassification = ToBeClassified;
        }
        field(12; "voided"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Receipt Line No"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Staff Id"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "LSC Staff";
            ValidateTableRelation = false;
        }
        field(15; "Store No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "LSC Store";
            ValidateTableRelation = false;
        }
        field(16; "QR Checksum"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(17; "QR Checksum2"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(18; "Payment Validated"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(19; "Replication Counter"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                WalletLog: Record "Wallet Log Entry";
            begin

                WalletLog.SETCURRENTKEY("Replication Counter");
                IF WalletLog.FINDLAST THEN
                    "Replication Counter" := WalletLog."Replication Counter" + 1
                ELSE
                    "Replication Counter" := 1;

            end;
        }
        field(20; "Bank Name"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(21; "Payment Mode"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(22; "Payment Link ID"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(23; "EDC Order ID"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(24; "retrievalReferenceNo"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(25; "authCode"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(26; "issuerMaskCardNo"; Text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(27; "bankResponseMessage"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(28; "bankResponseCode"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(29; "bankMid"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(30; "bankTid"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(31; "aid"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(32; "cardType"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(33; "ErrorCode"; code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(34; "RefundID"; Text[64])
        {
            DataClassification = ToBeClassified;
        }
        field(35; "Resend Link Notification"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(36; "POS Code Merger"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(37; "EDC Machine"; Option)
        {
            OptionMembers = PineLabs,PayTm,Ezetap;
            DataClassification = ToBeClassified;
        }
        field(38; MachineBatchNo; text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(39; MachineRRN; text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(40; TransactionID; text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(41; MachineInvoiceNo; text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(42; VoidRespMsg; text[200])
        {
            DataClassification = ToBeClassified;
        }
        field(43; VoidDateTime; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(44; "Retry Allowed"; boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(45; UPIPayment; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(100; "Device ID"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(101; Mode; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(102; Appkey; Text[80])
        {
            DataClassification = ToBeClassified;
        }
        field(103; p2pRequestId; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(104; ErrorCodeDevice; Text[100])
        {
            DataClassification = ToBeClassified;
        }

    }
    keys
    {
        key(PK; "Entry No.", "Receipt No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        Validate("Replication Counter");
    end;

    trigger OnModify()
    begin
        Validate("Replication Counter");
    end;

}