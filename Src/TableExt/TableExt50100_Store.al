tableextension 50100 "StoreSetup.Ext" extends "LSC Store"
{
    fields
    {

        //Ezetap Integration
        field(70000; "Ezetap Enable"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(70001; "Ezetap appKey"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(70002; "Ezetap username"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        // field(70003; "Ezetap EDC Account Label"; Text[50])
        // {
        //     DataClassification = ToBeClassified;
        // }
        field(70004; "Ezetap Base URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(70005; "Ezetap Logs Path"; Text[80])
        {
            DataClassification = ToBeClassified;
        }
        field(70006; "Ezetap Password"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(70007; "Ezetap DQR appKey"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(70008; "Ezetap DQR username"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(70009; "Ezetap DQR Password"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        // field(70010; "Ezetap DQR Account Label"; Text[50])
        // {
        //     DataClassification = ToBeClassified;
        // }

    }
}