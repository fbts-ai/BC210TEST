tableextension 50101 "PosTerminalExt.al" extends "LSC POS Terminal"
{
    fields
    {
        field(70000; "Ezetap EDC TID"; Code[15])
        {
            DataClassification = ToBeClassified;
        }
        field(70001; "Ezetap DQR TID"; Code[15])
        {
            DataClassification = ToBeClassified;
        }
        field(70002; "Phi_aggregatorId"; Text[20])
        {
            DataClassification = ToBeClassified;

        }
        field(70003; "Phi_posAppId"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(70004; "Phi_posTillNo"; Text[20])
        {
            DataClassification = ToBeClassified;
        }


    }
}