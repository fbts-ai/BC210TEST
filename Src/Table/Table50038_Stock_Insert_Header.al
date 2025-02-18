table 50038 StockInsertHeader
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Location Code"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Item Category Code"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;

        }
        field(4; Description; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(5; UOM; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(6; Stock; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Net_Stock"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Unposted_Sales"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Sales Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Location Code", "Item No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}