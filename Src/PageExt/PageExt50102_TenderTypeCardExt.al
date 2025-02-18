pageextension 50102 TenderTypeCardExt extends "LSC Tender Type Card"
{
    layout
    {
        addafter("Valid on Mobile POS")
        {
            field("Ezetap EDC"; Rec."Ezetap EDC")
            {
                ApplicationArea = all;
            }
            field("Ezetap DQR"; Rec."Ezetap DQR")
            {
                ApplicationArea = all;
            }
            field("Phi_EDC Enable"; "Phi_EDC Enable")
            {
                ApplicationArea = all;
            }

        }


    }
}
