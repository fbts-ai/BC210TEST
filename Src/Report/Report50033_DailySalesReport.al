report 50033 "Daily Sales Report"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Daily Sales Report';
    DefaultLayout = RDLC;
    RDLCLayout = 'Src/Report/Daily Sales.rdl';
    dataset
    {
        dataitem("LSC Transaction Header"; "LSC Transaction Header")
        {
            column(Store_No_; "Store No.")
            {
            }
            column(StoreName; StoreName)
            {
            }
            column(Dates; Date)
            {
            }

            dataitem("LSC Trans. Payment Entry"; "LSC Trans. Payment Entry")
            {
                DataItemLinkReference = "LSC Transaction Header";
                DataItemLink = "Store No." = field("Store No."), Date = field(Date), "Receipt No." = field("Receipt No."), "Transaction No." = field("Transaction No.");
                column(cash; (cash))
                { }
                column(CardOffline_12; CardOffline_12)
                { }
                column(offlineUP_33; offlineUP_33)
                { }
                column(PinelabCardPaymnet_53; PinelabCardPaymnet_53)
                { }
                column(PineLabUPI_52; PineLabUPI_52)
                { }
                column(Swiggi_22; Swiggi_22)
                { }
                column(TenderRemovedflot_9; TenderRemovedflot_9)
                { }
                column(TWC_Wallet_16; TWC_Wallet_16)
                { }
                column(TWCApp21; TWCApp21)
                { }
                column(Zomato_23; Zomato_23)
                { }

                column(CustomerAccount; CustomerAccount)
                { }

                column(UPI; UPI)
                { }
                column(AmountD; AmountD)
                {
                }
                column(TenderTypeDesc; TenderTypeDesc)
                {
                }
                column(Transaction_No_; "Transaction No.")
                { }
                column(NetAmount; NetAmount)
                { }
                trigger OnAfterGetRecord()
                var
                    myInt: Integer;
                begin
                    Clear(cash);
                    Clear(Cards);
                    Clear(UPI);
                    Clear(CustomerAccount);
                    Clear(TWCApp21);
                    Clear(TWC_Wallet_16);
                    Clear(TenderRemovedflot_9);
                    Clear(CardOffline_12);
                    Clear(offlineUP_33);
                    Clear(PinelabCardPaymnet_53);
                    Clear(PineLabUPI_52);
                    Clear(Swiggi_22);
                    Clear(Zomato_23);
                    if "LSC Trans. Payment Entry"."Tender Type" = '1' then
                        if "LSC Trans. Payment Entry"."Safe type" = "LSC Trans. Payment Entry"."Safe type"::" " then begin
                            cash += "LSC Trans. Payment Entry"."Amount Tendered";
                        end;
                    //  Message('%1', cash);
                    // Message('%1', cash);
                    if "LSC Trans. Payment Entry"."Tender Type" = '16' then
                        TWC_Wallet_16 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '21' then
                        TWCApp21 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '33' then
                        offlineUP_33 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '12' then
                        CardOffline_12 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '53' then
                        PinelabCardPaymnet_53 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '52' then
                        PineLabUPI_52 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '22' then
                        Swiggi_22 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '23' then
                        Zomato_23 := "LSC Trans. Payment Entry"."Amount Tendered";
                    if "LSC Trans. Payment Entry"."Tender Type" = '9' then
                        TenderRemovedflot_9 := "LSC Trans. Payment Entry"."Amount Tendered";
                    LSCTenderType.Reset();
                    LSCTenderType.SetRange(Code, "LSC Trans. Payment Entry"."Tender Type");
                    // LSCTenderType.SetFilter(Description, '<>%1', 'Tender Remove/Float');
                    if LSCTenderType.FindFirst() then;
                    TenderTypeDesc := LSCTenderType.Description;

                    ///////////////////////////////////////////////////////////////////

                    // UNTIL LSCStoreList.Next() = 0;
                    //Message('%1', StoreName);
                    /////////////////////


                    Clear(NetAmount);
                    LSCTransIncomeExp.Reset();
                    LSCTransIncomeExp.SetRange("Receipt  No.", "LSC Trans. Payment Entry"."Receipt No.");
                    LSCTransIncomeExp.SetRange("Account Type", LSCTransIncomeExp."Account Type"::Expense);
                    If LSCTransIncomeExp.FindFirst() then begin
                        repeat
                            NetAmount += LSCTransIncomeExp."Net Amount";
                            StoreNo := LSCTransIncomeExp."Store No.";
                        until LSCTransIncomeExp.Next() = 0;
                        // Message('%1', NetAmount);
                    end;
                end;

                trigger OnPostDataItem()
                var
                    myInt: Integer;
                begin
                    // "LSC Trans. Payment Entry".SetFilter(Date, '%1..%2', StartDate, endDate);
                end;
            }
            dataitem("LSC Trans. Tender Declar. Entr"; "LSC Trans. Tender Declar. Entr")
            {
                DataItemLinkReference = "LSC Transaction Header";
                DataItemLink = "Store No." = field("Store No."), Date = field(Date), "Slip No." = field("Receipt No.");
                column(Amount_Tendered; "Amount Tendered")
                { }
            }
            trigger OnAfterGetRecord()
            var
                myInt: Integer;
            begin
                Clear(TenderDeclarAmt);
                if "LSC Transaction Header"."Transaction Type" = "LSC Transaction Header"."Transaction Type"::"Tender Decl." then begin
                    TransDecEntry.Reset();///PT fbts
                    TransDecEntry.SetRange("Store No.", "LSC Transaction Header"."Store No.");
                    TransDecEntry.SetRange(Date, "LSC Transaction Header".Date);
                    if TransDecEntry.FindFirst() then
                        repeat
                            TenderDeclarAmt := TransDecEntry."Amount Tendered";
                        until TransDecEntry.Next() = 0;
                end;
                Clear(StoreName);
                LSCStoreList.Reset();
                LSCStoreList.SetRange("No.", "LSC Transaction Header"."Store No.");
                if LSCStoreList.FindFirst() then
                    // repeat
                    StoreName := LSCStoreList.Name;
            end;

            trigger OnPreDataItem()
            var
                usersetup: Record "User Setup";
                userName: Text[50];
                DSR: Report "Daily sales Report";
            begin

                DateRange1 := "LSC Trans. Payment Entry".GetFilter("LSC Trans. Payment Entry".Date);
                // Clear(usersetup);
                // IF usersetup.Get(UserId) then
                //     if not usersetup.DSR then
                //         Error('You do not have Permission this Report Please Contact Administrator');

                "LSC Transaction Header".SetRange(Date, StartDate, endDate);
                IF store <> '' then
                    "LSC Transaction Header".SetRange("Store No.", store);


            end;

        }

    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = all;
                        Caption = 'Start Date';
                    }
                    field(endDate; endDate)
                    {
                        ApplicationArea = all;
                        Caption = 'End Date';
                    }
                    field(store; store)
                    {
                        ApplicationArea = all;
                        Caption = 'Store';
                        TableRelation = "LSC Store";
                        // Editable = false;

                    }
                }
            }
        }

        actions
        {
            area(processing)
            {
                action(ActionName)
                {
                    ApplicationArea = All;

                }
            }
        }
    }



    var
        LSCTenderType: Record "LSC Tender Type";
        TenderTypeDesc: Text;
        TransactionHeader: Record "LSC Transaction Header";
        LSCStoreList: Record "LSC Store";
        LSCTransSalesEntry: Record "LSC Trans. Sales Entry";
        StoreName: Text[100];
        "storeNo_": Code[20];
        AmountD: Decimal;
        StoreNo: Code[20];
        TransDecEntry: Record "LSC Trans. Tender Declar. Entr";
        TenderDeclarAmt: Decimal;
        StartDate: Date;
        endDate: Date;
        LSCTransIncomeExp: Record "LSC Trans. Inc./Exp. Entry";
        NetAmount: Decimal;
        NoofRow: Integer;
        ReceiptNo: Text[50];
        DateRange1: Text;
        Date_: Date;
        LSCTransPayemtEntry: Record "LSC Trans. Payment Entry";
        Cards: Decimal;

        UPI: Decimal;
        /////////////////// TWC TenderVar
        cash: Decimal;
        TWCApp21: Decimal;
        TWC_Wallet_16: Decimal;
        Swiggi_22: Decimal;
        Zomato_23: Decimal;
        CardOffline_12: Decimal;
        TenderRemovedflot_9: Decimal;
        PinelabCardPaymnet_53: Decimal;
        offlineUP_33: Decimal;
        PineLabUPI_52: Decimal;

        ///////////////////////////////// 
        CustomerAccount: Decimal;
        //SendByEmail_gBln: Boolean;
        RetailUser: Record "LSC Retail User";
        store: Code[40];


    trigger OnInitReport()
    var
        lFilterGroup: Integer;
    begin
        // lFilterGroup := "LSC Transaction Header".FilterGroup;//PT FBTS
        // "LSC Transaction Header".FilterGroup(10);
        // if RetailUser.Get(UserId) then
        //     if RetailUser."Store No." <> '' then
        //         store := RetailUser."Store No.";
        // Message('%1', store);
        // "LSC Transaction Header".SetRange("Store No.", RetailUser."Store No.")
        // else
        //     "LSC Transaction Header".SetRange("Store No.");
        // "LSC Transaction Header".FilterGroup(lFilterGroup);

    end;
}