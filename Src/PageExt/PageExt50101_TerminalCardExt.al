pageextension 50101 TerminalExt extends "LSC POS Terminal Card"
{
    layout
    {
        addafter(Omni)
        {
            group("Extra Information")
            {
                field("Ezetap EDC TID"; Rec."Ezetap EDC TID")
                {
                    ApplicationArea = all;
                }
                field("Ezetap DQR TID"; Rec."Ezetap DQR TID")
                {
                    ApplicationArea = all;
                }
                field(Phi_aggregatorId; Rec.Phi_aggregatorId)
                {
                    ApplicationArea = All;
                }
                field(Phi_posAppId; Rec.Phi_posAppId)
                {
                    ApplicationArea = All;
                }
                field(Phi_posTillNo; Phi_posTillNo)
                {
                    ApplicationArea = all;
                }
            }
        }
    }


}

