tableextension 50106 TWC_API_Setup extends TwcApiSetupUrl
{
    fields
    {
        field(60001; "Phi_EDCStatus URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(60002; "Phi_EDCInvoice URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(60003; "Phi_EDCRefund URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(60004; "Phi_EDC SecretKey"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}