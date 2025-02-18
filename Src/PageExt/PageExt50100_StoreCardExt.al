pageextension 50100 "StoreCardExtLS" extends "LSC Store Card"
{
    layout
    {
        addafter(Numbering)
        {
            group("Ezetap Integration")
            {
                field("Ezetap Enable"; Rec."Ezetap Enable")
                {
                    ApplicationArea = All;
                }
                field("Ezetap appKey"; Rec."Ezetap appKey")
                {
                    ApplicationArea = All;
                }
                field("Ezetap username"; Rec."Ezetap username")
                {
                    ApplicationArea = All;
                }
                field("Ezetap Password"; Rec."Ezetap Password")
                {
                    ApplicationArea = All;
                }
                // field("Ezetap EDC Account Label"; "Ezetap EDC Account Label")
                // {
                //     ApplicationArea = All;
                // }
                field("Ezetap DQR appKey"; "Ezetap DQR appKey")
                {
                    ApplicationArea = All;
                }
                field("Ezetap DQR username"; "Ezetap DQR username")
                {
                    ApplicationArea = All;
                }
                field("Ezetap DQR Password"; "Ezetap DQR Password")
                {
                    ApplicationArea = All;
                }
                // field("Ezetap DQR Account Label"; "Ezetap DQR Account Label")
                // {
                //     ApplicationArea = All;
                // }
                field("Ezetap Base URL"; Rec."Ezetap Base URL")
                {
                    ApplicationArea = All;
                }
                field("Ezetap Logs Path"; Rec."Ezetap Logs Path")
                {
                    ApplicationArea = All;
                }

            }
        }
    }
}
