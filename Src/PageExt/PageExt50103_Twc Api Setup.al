pageextension 50103 TWC_API_Setup extends TwcApiSetupUrl
{
    layout
    {
        addafter(Pinelab)
        {
            group("Phi EDC Integration")
            {
                field("Phi_EDCStatus URL"; Rec."Phi_EDCStatus URL")
                {
                    ApplicationArea = All;
                }
                field("Phi_EDCInvoice URL"; Rec."Phi_EDCInvoice URL")
                {
                    ApplicationArea = All;
                }
                field("Phi_EDCRefund URL"; Rec."Phi_EDCRefund URL")
                {
                    ApplicationArea = All;
                }
                field("Phi_EDC SecretKey"; Rec."Phi_EDC SecretKey")
                {
                    ApplicationArea = All;
                }

            }
        }
    }
    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}