Codeunit 50102 "POSExternalCommand"
{
    TableNo = "LSC POS Menu Line";
    SingleInstance = true;
    trigger OnRun()
    begin
        if Rec."Registration Mode" then
            Register(Rec)
        else
            case Rec.Command of
                'P_CHECKSTATUS':
                    EDCMachineCheckStatus(Rec.Parameter);
                'PHI_CREATEINVOICE':
                    Phi_CreateInvoice();
                'PHI_STATUS':
                    Phi_CheckStatusPressed(rec.Parameter);

            end;
    End;

    var
        checkStatus: Boolean;
        g_VirtualAmt: Decimal;
        POSSESSION: Codeunit "LSC POS Session";

    local procedure Register(var POSMenuLine: Record "LSC POS Menu Line")
    var
        POSCommandReg: Codeunit "LSC POS Command Registration";
        ModuleDescription: Label 'ExtraCommandModule';
        ExtCommandDesc: Label 'External Command For Some Other Work on POS';
    begin
        // Register the module:
        POSCommandReg.RegisterModule(GetModuleCode(), ModuleDescription, Codeunit::POSExternalCommand);
        // Register the command, as many lines as there are commands in the Codeunit:
        POSCommandReg.RegisterExtCommand('P_CHECKSTATUS', ExtCommandDesc,
            Codeunit::POSExternalCommand, 0, GetModuleCode(), true);
        POSCommandReg.RegisterExtCommand('PHI_CREATEINVOICE', ExtCommandDesc,
             Codeunit::POSExternalCommand, 0, GetModuleCode(), true);
        POSCommandReg.RegisterExtCommand('PHI_STATUS', ExtCommandDesc,
            Codeunit::POSExternalCommand, 0, GetModuleCode(), true);

        POSMenuLine."Registration Mode" := false;
    end;

    procedure GetModuleCode(): Code[20]
    var
        ModuleCode: Label 'EXTERNALMODULE', Locked = true;
    begin
        exit(ModuleCode);
    end;

    local procedure EDCMachineCheckStatus(lParam: Text)
    var
    begin
        checkStatus := true;
    End;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeRunCommand', '', false, false)]
    local procedure "LSPTOnBeforeRunCommand"(var POSTransaction: Record "LSC POS Transaction";
    var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var POSMenuLine: Record "LSC POS Menu Line"; var isHandled: Boolean; TenderType: Record "LSC Tender Type"; var CusomterOrCardNo: Code[20])
    var
        walletLog: Record "Wallet Log Entry";
    begin
        if POSMenuLine.Command in ['CANCEL', 'CANCEL2', 'MANAGER MENU', 'MGRKEY'] then begin
            walletLog.Reset();
            walletLog.SetRange("Receipt No.", POSTransaction."Receipt No.");
            walletLog.SetRange("Wallet TXN No.", '');
            walletLog.SetRange(ErrorCodeDevice, '');
            if walletLog.FindLast() then begin
                checkStatus := false;
                CurrInput := '';
                IsHandled := true;
                Message('Please do Check Status');
                Exit;
            end;
            //  else begin
            //     TenderType.Get(POSTransaction."Store No.", TenderTypeCode);
            //     if not (TenderType."Ezetap DQR" or TenderType."Ezetap EDC") then begin
            //         checkStatus := false;
            //         CurrInput := '';
            //         IsHandled := true;
            //         Message('Please do Check Status');
            //         Exit;
            //     End;
            // end;
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnAfterTenderKeyPressedEx', '', false, false)]
    local procedure OnAfterTenderKeyPressedEx(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line";
                var CurrInput: Text; var TenderTypeCode: Code[10]; var TenderAmountText: Text; var IsHandled: Boolean);
    var
        walletLog: Record "Wallet Log Entry";
        PosGui: Codeunit "LSC POS Transaction";
        EzetapMachine: Codeunit EzetapEDCIntegration;
        // LPosTrans: Record "LSC POS Transaction";
        LCnt: Integer;
        VirtualAmt: Decimal;
        lDateTime: Text;
        //FBTS YM SMS
        lPosTrans: Record "LSC POS Transaction";
        EposController: Codeunit "LSC POS Control Interface";
        Result: Action;
        I: Integer;
        MM_card: Record "LSC Membership Card";
        MM_Contact: Record "LSC Member Contact";
        // MMAPI: Codeunit MMAPISOAP_Consume;
        MMPoints_1: Decimal;
        CUPOSTRans: Codeunit "LSC POS Transaction";
        Possession: Codeunit "LSC POS Session";
        POSTrasLine: Record "LSC POS Trans. Line";
        ItemRec: Record Item;
        RecPosTransline: Record "LSC POS Trans. Line";
        POSTrasLine2: Record "LSC POS Trans. Line";
        ItemQty: Decimal;
        ItemQtyPck: Decimal;
        l_Item: Record Item;
        TotalQuantity: Decimal;
        Division: Record "LSC Division";
        TECTXT50000: Label 'There is no enough inventory for the Item %1 - %2.';
        TECTXT50001: Label 'Sales can be continue only after Accepting the previous day open statmenets';
        MMPoints_2: Decimal;
        EzetapEDCMachine: Codeunit EzetapEDCIntegration;
        TenderType: Record "LSC Tender Type";
        ConfigFile: Record "TWC Configuration";
    begin
        if not checkStatus then begin
            walletLog.Reset();
            walletLog.SetRange("Receipt No.", POSTransaction."Receipt No.");
            walletLog.SetRange("Wallet TXN No.", '');
            // walletLog.SetRange(voided, false);
            if walletLog.FindLast() then begin
                if walletLog.ErrorCodeDevice = '' then begin
                    checkStatus := false;
                    CurrInput := '';
                    IsHandled := true;
                    Message('Please do Check Status');
                    Exit;
                end
                else begin
                    if walletLog.errorcodedevice = '' then begin
                        TenderType.Get(POSTransaction."Store No.", TenderTypeCode);
                        if not (TenderType."Ezetap DQR" or TenderType."Ezetap EDC") then begin
                            checkStatus := false;
                            CurrInput := '';
                            IsHandled := true;
                            Message('Please do Check Status');
                            Exit;
                        End;
                    End;
                end;
            end;
        end;

        if checkStatus then begin
            TenderType.Get(POSTransaction."Store No.", TenderTypeCode);
            if TenderType."Ezetap DQR" or TenderType."Ezetap EDC" then begin
                walletLog.reset;
                if POSTransaction."Sale Is Return Sale" then
                    walletLog.SetRange("Receipt No.", POSTransaction."Retrieved from Receipt No.")
                else
                    walletLog.SetRange("Receipt No.", POSTransaction."Receipt No.");
                // if TenderTypeCode in ['3', '5'] then
                //     walletLog.SetFilter("Wallet TXN No.", '<>%1', '');
                if TenderType."Ezetap DQR" or TenderType."Ezetap EDC" then begin
                    if POSTransaction."Sale Is Return Sale" then
                        walletLog.SetFilter("Wallet TXN No.", '<>%1', '')
                    else
                        walletLog.SetFilter("Wallet TXN No.", '%1', '');
                End;
                walletLog.SetRange(TransactionID, '');
                if walletLog.findlast then begin

                    PosGui.ScreenDisplay('Transaction validating...');
                    LCnt := 0;
                    if TenderType."Ezetap DQR" or TenderType."Ezetap EDC" then begin
                        if not POSTransaction."Sale Is Return Sale" then begin
                            if TenderType."Ezetap DQR" then
                                VirtualAmt := EzetapEDCMachine.ChkStatusEzetapTransEDC(POSTransaction."Receipt No.", true, lcnt,
                                        POSTransaction."POS Terminal No.", POSTransaction."Sales Type", false, POSTransaction."Store No.", lDateTime, true);
                            if TenderType."Ezetap EDC" then
                                VirtualAmt := EzetapEDCMachine.ChkStatusEzetapTransEDC(POSTransaction."Receipt No.", true, lcnt,
                                        POSTransaction."POS Terminal No.", POSTransaction."Sales Type", false, POSTransaction."Store No.", lDateTime, false);
                        end;
                    end;
                    posgui.ScreenDisplay('');
                    CurrInput := Format(walletLog.Amount);
                    IsHandled := false;
                    TenderTypeCode := TenderTypeCode;
                    TenderAmountText := '';
                    if VirtualAmt = 0 then begin
                        IsHandled := true;
                        CurrInput := '';
                        checkStatus := false;
                    end;
                End else begin
                    IsHandled := true;
                    checkStatus := false;
                    CurrInput := '';
                    Message('Please initiate the EDC/DQR transaction first');
                end;

            end;


        end;

        //FBTS YM Zomato gold
        // if TenderTypeCode = '56' then begin
        //     ConfigFile.Reset();
        //     ConfigFile.SetRange(Key_, 'UP');
        //     ConfigFile.SetRange(Name, 'Zomato_CUSTOMER_NO');
        //     if ConfigFile.FindFirst() then begin
        //         POSTransaction."Customer No." := ConfigFile.Value_;
        //         POSTransaction.Modify();
        //     end;
        // end;
        //FBTS YM Zomato Gold
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeInsertPaymentLine', '', false, false)]
    local procedure "LSC POS Transaction Events_OnBeforeInsertPaymentLine"(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var TenderTypeCode: Code[10];
    Balance: Decimal;
    PaymentAmount: Decimal;
    STATE: Code[10]; var isHandled: Boolean)
    begin
        if g_VirtualAmt = -1 then
            isHandled := true;
        g_VirtualAmt := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeStartNewTransaction', '', false, false)]
    local procedure "LSC POS Transaction Events_OnBeforeStartNewTransaction"(var POSTransaction: Record "LSC POS Transaction")
    begin
        if POSTransaction."Custom Sales Type" = '' then
            POSTransaction."Custom Sales Type" := POSTransaction."Sales Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeRunCommand', '', false, false)]
    local procedure "LSC POS Transaction Events_OnBeforeRunCommand"(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var POSMenuLine: Record "LSC POS Menu Line"; var isHandled: Boolean; TenderType: Record "LSC Tender Type"; var CusomterOrCardNo: Code[20])
    var
        WalletLogEntry: Record "Wallet Log Entry";
        EzetapEDC: Codeunit EzetapEDCIntegration;
        LCnt: Integer;
        PosTRans: codeunit "LSC POS Transaction";
    begin
        if POSTransaction."Custom Sales Type" = '' then
            POSTransaction."Custom Sales Type" := POSTransaction."Sales Type";

        // WalletLogEntry.RESET;
        // WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
        // WalletLogEntry.SETRANGE("Receipt No.", POSTransaction."Receipt No.");
        // WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
        // WalletLogEntry.SETRANGE(voided, FALSE);
        // IF WalletLogEntry.FindLast() THEN BEGIN
        //     if WalletLogEntry."Wallet TXN No." = '' then begin
        //         LCnt := 0;

        //         if WalletLogEntry."Payment Mode" = 'UPI' then begin
        //             checkStatus := true;
        //             PosTRans.TenderKeyPressedEx('19', format(WalletLogEntry.Amount));
        //             // EzetapEDC.ChkStatusEzetapTransEDC(POSTransaction."Receipt No.", true, lcnt,
        //             //    POSTransaction."POS Terminal No.", POSTransaction."Sales Type", false,
        //             //    POSTransaction."Store No.", '', true)
        //         end else begin
        //             checkStatus := true;
        //             PosTRans.TenderKeyPressedEx('18', format(WalletLogEntry.Amount));
        //         end;

        //     end;
        // End;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnAfterInsertTransHeader', '', false, false)]
    local procedure "LSC POS Post Utility_OnAfterInsertTransHeader"(var Transaction: Record "LSC Transaction Header";
    var POSTrans: Record "LSC POS Transaction")
    var
        PosLine: Record "LSC POS Trans. Line";
    begin
        //FBTS YM 290824 Sales Type updation
        PosLine.Reset();
        PosLine.SetRange("Receipt No.", POSTrans."Receipt No.");
        PosLine.SetFilter("Sales Type", '<>%1', '');
        if PosLine.FindFirst() then;

        if Transaction."Sales Type" = '' then
            if POSTrans."Custom Sales Type" = '' then begin
                PosTrans."Custom Sales Type" := PosLine."Sales Type";
                Transaction."Sales Type" := PosTrans."Custom Sales Type";
            end;
        Transaction."Custom Sales Type" := POSTrans."Custom Sales Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeInsertPayment_TenderKeyExecutedEx', '', false, false)]
    local procedure OnBeforeInsertPayment_TenderKeyExecutedEx(var POSTransaction: Record "LSC POS Transaction";
              var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var TenderTypeCode: Code[10];
              var TenderAmountText: Text);
    var
        VAmt: Decimal;
        PosGui: Codeunit "LSC POS Transaction";
        LCnt: Integer;
        Customer: Record Customer;
        Text001: Label 'Payment Being processed...';
        CreditSalesTxt: text;
        Rsetup: Record "LSC Retail Setup";
        Storesetup: Record "LSC Store";
        EzetapEDC: Codeunit EzetapEDCIntegration;
        lDateTime: Text;
        WalletLogEntry: Record "Wallet Log Entry";
        TenderType: Record "LSC Tender Type";
        DQRFlag: Boolean;
    begin
        if POSTransaction."Custom Sales Type" = '' then
            POSTransaction."Custom Sales Type" := POSTransaction."Sales Type";

        DQRFlag := false;
        Storesetup.Get(POSTransaction."Store No.");
        if Storesetup."Ezetap Enable" then begin
            if checkStatus then
                Exit;

            TenderType.Get(Storesetup."No.", TenderTypeCode);

            if TenderType."Ezetap DQR" or TenderType."Ezetap EDC" then begin//Tender Fix for PineLab
                // if TenderAmountText = '' then begin
                //     g_VirtualAmt := -1;
                //     exit;
                // end;
                Evaluate(VAmt, TenderAmountText);
                lDateTime := FORMAT(CURRENTDATETIME, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2>');//Fix YYY-MM-DD HH:MM:SS
                if TenderType."Ezetap DQR" then
                    DQRFlag := true;
                if TenderType."Ezetap EDC" then
                    DQRFlag := false;
                if not POSTransaction."Sale Is Return Sale" then
                    EzetapEDC.SendTransEzetapEDC(POSTransaction."Receipt No.", lDateTime, POSTransaction."POS Terminal No.", POSTransaction."Store No.",
                    VAmt, FALSE, POSTransaction."Sales Type", DQRFlag)
                else begin
                    //Refund API
                    // WalletLogEntry.RESET;
                    // WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
                    // WalletLogEntry.SETRANGE("Store No.", POSTransaction."Store No.");
                    // WalletLogEntry.SETRANGE("Receipt No.", POSTransaction."Retrieved from Receipt No.");
                    // WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
                    // WalletLogEntry.SETRANGE(WalletLogEntry.voided, FALSE);
                    // IF WalletLogEntry.ISEMPTY THEN
                    //     ERROR('No Paytm Payment exist in this bill being refunded');
                    // WalletLogEntry.FINDFIRST;
                    // // ScreenDisplay('Checking Refund...');
                    // IF PaytmEDC.RefundAPIPaytm(WalletLogEntry."Receipt No.", lDateTime, POSTransaction."POS Terminal No.",
                    //     POSTransaction."Store No.", WalletLogEntry.Amount, POSTransaction."Receipt No.", POSTransaction."Sales Type") THEN BEGIN
                    //     // GlobalRefunfRcptNo := WalletLogEntry."Receipt No.";
                    //     IF PaytmEDC.ChkStatusRefund(lDateTime, WalletLogEntry."Receipt No.", FALSE, LCnt,
                    //         POSTransaction."POS Terminal No.", POSTransaction."Receipt No.") THEN BEGIN
                    //         // PaymentAmount := WalletLogEntry.Amount;
                    //         CurrInput := FORMAT(WalletLogEntry.Amount);
                    //         TenderAmountText := CurrInput;
                    //         // TenderKeyPressed(TenderTypeCode);
                    //         // MessageBeep('payment succesful');
                    //         // CurrInput := '';
                    //         WalletLogEntry.voided := TRUE;
                    //         WalletLogEntry.MODIFY;
                    //     END;
                    // END;
                END;

            end;
            SLEEP(3000);
            COMMIT;
            if TenderType."Ezetap DQR" or TenderType."Ezetap EDC" then begin
                IF NOT Dialog.Confirm('Get Ack By Customer : Payment confirmed Yes/No', FALSE) THEN begin

                    if TenderType."Ezetap EDC" then begin
                        checkStatus := true;
                        PosGui.TenderKeyPressedEx(TenderType.Code, format(WalletLogEntry.Amount));

                        VAmt := EzetapEDC.CancelNotificationEzetap(POSTransaction."Receipt No.", true, lcnt,
                                POSTransaction."POS Terminal No.", POSTransaction."Sales Type", false,
                                POSTransaction."Store No.", lDateTime, false);
                    End;
                    if TenderType."Ezetap DQR" then begin
                        checkStatus := true;
                        PosGui.TenderKeyPressedEx(TenderType.Code, format(WalletLogEntry.Amount));
                        VAmt := EzetapEDC.CancelNotificationEzetap(POSTransaction."Receipt No.", true, lcnt,
                                POSTransaction."POS Terminal No.", POSTransaction."Sales Type", false,
                                POSTransaction."Store No.", lDateTime, true);

                        // VAmt := -1;
                    End;
                    g_VirtualAmt := VAmt;
                    Message('Transaction cancelled');
                    exit;
                End ELSE
                    PosGui.ScreenDisplay(Text001);
                LCnt := 0;

                //SLEEP(5000);
                if TenderType."Ezetap DQR" then
                    VAmt := EzetapEDC.ChkStatusEzetapTransEDC(POSTransaction."Receipt No.", true, lcnt,
                            POSTransaction."POS Terminal No.", POSTransaction."Sales Type", false,
                            POSTransaction."Store No.", lDateTime, true);
                if TenderType."Ezetap EDC" then
                    VAmt := EzetapEDC.ChkStatusEzetapTransEDC(POSTransaction."Receipt No.", true, lcnt,
                            POSTransaction."POS Terminal No.", POSTransaction."Sales Type", false,
                            POSTransaction."Store No.", lDateTime, false);

                PosGui.ScreenDisplay('');
                if VAmt = 0 then begin
                    WalletLogEntry.RESET;
                    WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
                    WalletLogEntry.SETRANGE("Store No.", POSTransaction."Store No.");
                    WalletLogEntry.SETRANGE("Receipt No.", POSTransaction."Receipt No.");
                    WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
                    WalletLogEntry.SETRANGE(WalletLogEntry.voided, FALSE);
                    IF WalletLogEntry.ISEMPTY THEN
                        ERROR('No Payment exist in this bill being refunded');
                    WalletLogEntry.FINDFIRST;
                    WalletLogEntry.voided := true;
                    WalletLogEntry.Modify();
                    g_VirtualAmt := -1;
                    Message('Maximum time lapsed Please Press CheckStatus button to check payment status');
                end;
                PosGui.ScreenDisplay('');
            End;
        end;
    End;

    //Phi Integration
    local procedure Phi_CreateInvoice()
    var
        PhiEDCTenderType: Code[10];
        Phi_EDCIntegration: Codeunit "Phi_EDC Integration";
        TextDateTimeVar: Text;
        VAmt: Decimal;
        EposController: Codeunit "LSC POS Control Interface";
        LCnt: Integer;
        Phi_EDCLogEntry: Record "Phi_EDC Log Entry";
        EDCLogEntry: Record "Phi_EDC Log Entry";
        WalletLogEntry: Record "Phi_EDC Log Entry";
        l_WalletLogEntry: Record "Phi_EDC Log Entry";
        TranType: Code[10];
        lAmt: Text;
        PosTran: Codeunit "LSC POS Transaction";
        PosTransTbl: Record "LSC POS Transaction";
        PaymentAmount: Decimal;
        PosFunc: codeunit "LSC POS Functions";
        Text233: Label 'Amount';
        Result: Action;
    begin
        PosTran.GetPOSTransaction(PosTransTbl);
        IF NOT PosTransTbl."Sale Is Return Sale" THEN BEGIN
            // IF STATE <> STATE_PAYMENT THEN BEGIN
            //     ErrorBeep(Text097);
            //     EXIT;
            // END;
            // CurrInput := '';
            Phi_EDCLogEntry.RESET;
            Phi_EDCLogEntry.SETRANGE("Receipt No.", PosTransTbl."Receipt No.");
            Phi_EDCLogEntry.SETRANGE("Function Type", Phi_EDCLogEntry."Function Type"::Payment);
            Phi_EDCLogEntry.SETRANGE(voided, FALSE);
            //  Phi_EDCLogEntry.SETRANGE(txnAuthID,'');
            IF Phi_EDCLogEntry.FINDFIRST THEN BEGIN
                IF Phi_EDCLogEntry.txnAuthID = '' THEN BEGIN
                    IF Phi_CheckStatusPressed('1') THEN
                        EXIT;
                    IF EDCLogEntry.GET(Phi_EDCLogEntry."Entry No.", Phi_EDCLogEntry."Receipt No.") THEN BEGIN
                        EDCLogEntry.voided := TRUE;
                        EDCLogEntry.MODIFY;
                    END;
                END ELSE BEGIN
                    ERROR('Transaction Already Posted Kindly Press Check Status');
                END;
            END;

            PaymentAmount := PosTran.GetOutstandingBalance();

            EposController.OpenNumericKeyboard(Text233, format(PaymentAmount), '1003');
            Exit;
        end;
    End;

    local procedure Phi_CheckStatusPressed(_Param: text[1]): boolean
    var
        LAmt: Decimal;
        SAmt: Text;
        RetailSetup: Record "LSC Retail Setup";
        RetailUser: Record "LSC Retail User";
        POSTerminalRec: Record "LSC POS Terminal";
        WalletLogEntry: Record "Phi_EDC Log Entry";
        Phi_EDCIntegration: Codeunit "Phi_EDC Integration";
        PosTrans: Codeunit "LSC POS Transaction";
        PosTransTbl: Record "LSC POS Transaction";
        ResponseText: Text;
        VCnt: integer;
    begin
        //1 is for Button
        PosTrans.GetPOSTransaction(PosTransTbl);
        IF VCnt > 3 THEN
            EXIT;

        WalletLogEntry.RESET;
        WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
        WalletLogEntry.SETRANGE("Receipt No.", PosTransTbl."Receipt No.");
        IF PosTransTbl."Sale Is Return Sale" THEN
            WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Refund)
        ELSE
            WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
        WalletLogEntry.SETRANGE(voided, FALSE);
        WalletLogEntry.SETRANGE("Payment Validated", FALSE);
        IF WalletLogEntry.ISEMPTY THEN
            ERROR('Please Press EDC Button');
        WalletLogEntry.FINDFIRST;

        IF Phi_EDCIntegration.CheckStatus(WalletLogEntry.invoiceNo, PosTransTbl."Store No.", PosTransTbl."POS Terminal No.",
        FORMAT(WalletLogEntry.Amount), ResponseText, PosTransTbl."Receipt No.", _Param) THEN BEGIN
            SAmt := '';
            LAmt := 0;
            MESSAGE(ResponseText);
            IF Phi_payresp('"responseCode":"', '"', 0, ResponseText) = '0000' THEN BEGIN
                WalletLogEntry.aggregatorId := Phi_payresp('"aggregatorId":"', '"', 0, ResponseText);
                SAmt := Phi_payresp('"amount":"', '"', 0, ResponseText);
                WalletLogEntry.invoiceNo := Phi_payresp('"invoiceNo":"', '"', 0, ResponseText);
                WalletLogEntry.invoiceStatus := Phi_payresp('"invoiceStatus":"', '"', 0, ResponseText);
                IF SAmt <> '' THEN
                    EVALUATE(LAmt, SAmt);
                //    IF _Param <> '1' THEN
                //      IF WalletLogEntry.txnID='' THEN
                //        ERROR('Transaction not completed try Again');
                WalletLogEntry."Payment Validated" := TRUE;
                WalletLogEntry.Amount := LAmt;

                WalletLogEntry.merchantId := Phi_payresp('"merchantId":"', '"', 0, ResponseText);
                WalletLogEntry.paymentDateTime := Phi_payresp('"paymentDateTime":"', '"', 0, ResponseText);
                WalletLogEntry.paymentInstrumentId := Phi_payresp('"paymentInstrumentId":"', '"', 0, ResponseText);
                WalletLogEntry.paymentMode := Phi_payresp('"paymentMode":"', '"', 0, ResponseText);
                WalletLogEntry.posAppId := Phi_payresp('"posAppId":"', '"', 0, ResponseText);
                WalletLogEntry.posTillNo := Phi_payresp('"posTillNo":"', '"', 0, ResponseText);
                WalletLogEntry.Reference := Phi_payresp('"referenceNo":"', '"', 0, ResponseText);
                WalletLogEntry.responseCode := Phi_payresp('"responseCode":"', '"', 0, ResponseText);
                WalletLogEntry.txnAuthID := Phi_payresp('"txnAuthID":"', '"', 0, ResponseText);
                WalletLogEntry.txnID := Phi_payresp('"txnID":"', '"', 0, ResponseText);
                WalletLogEntry.txnStatus := Phi_payresp('"txnStatus":"', '"', 0, ResponseText);
                WalletLogEntry.txnResponseCode := Phi_payresp('"txnResponseCode":"', '"', 0, ResponseText);
                WalletLogEntry.txnRespDescription := Phi_payresp('"txnRespDescription":"', '"', 0, ResponseText);
                WalletLogEntry.MODIFY(TRUE);
                IF LAmt <> 0 THEN BEGIN
                    // CurrInput := FORMAT(LAmt);
                    PosTrans.SetCurrInput(SAmt);
                    PosTrans.TenderKeyPressed(GetPhiEDCTender());
                    Message('payment succesful');
                    // CurrInput := '';
                    EXIT(TRUE);
                END;
            END;
        END;
        EXIT(FALSE);
    end;


    local procedure DateFormatted(lDate: Date): Text
    begin
        EXIT(FORMAT(lDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure TimeFormatted(LTime: Time): Text
    begin
        EXIT(FORMAT(LTime, 0, '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2>'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction", 'OnAfterKeyboardTriggerToProcess', '', false, false)]
    local procedure OnAfterKeyboardTriggerToProcess(InputValue: Text; KeyboardTriggerToProcess: Integer;
       var Rec: Record "LSC POS Transaction"; var IsHandled: Boolean);
    var
        VAmt: Decimal;
        TextDateTimeVar: Text;
        Phi_EDCIntegration: codeunit "Phi_EDC Integration";
        ErrorResponse: Text;
        LCnt: Integer;
        PosTran: Codeunit "LSC POS Transaction";
        ResponseText: Text;
        WalletLogEntry: Record "Phi_EDC Log Entry";
        TranType: Code[10];
        lAmt: Text;
        PaymentAmount: Text;
        l_WalletLogEntry: Record "Phi_EDC Log Entry";
    begin
        //1003: Amount
        if KeyboardTriggerToProcess = 1003 then begin
            IsHandled := true;
            IF InputValue = '' THEN
                EXIT;

            EVALUATE(VAmt, InputValue);
            // CurrInput := '';
            CLEAR(TextDateTimeVar);
            TextDateTimeVar := REC."Receipt No." + TimeFormatted(DT2TIME(CURRENTDATETIME + (300 * 1000)));
            //  IF NOT Phi_EDCIntegration.CreateInvoice(TextDateTimeVar,REC."Store No.",REC."POS Terminal No.",FORMAT(VAmt),REC."Receipt No.") THEN
            //    EXIT;
            IF NOT Phi_EDCIntegration.CreateInvoice(TextDateTimeVar, REC."Store No.", REC."POS Terminal No.", FORMAT(VAmt), REC."Receipt No.") THEN
                EXIT;

            IF NOT Confirm('Get Ack By Customer : Payment confirmed Yes/No', FALSE) THEN
                ERROR('Transaction denied');

            LCnt := 0;
            ErrorResponse := '';
            VAmt := Phi_CheckStatus(REC."Receipt No.", TRUE, LCnt, ErrorResponse);
            PaymentAmount := format(VAmt);
            ResponseText := ErrorResponse;
            IF VAmt <> 0 THEN BEGIN
                // CurrInput := FORMAT(PaymentAmount);
                PosTran.SetCurrInput(PaymentAmount);
                PosTran.TenderKeyPressed(GetPhiEDCTender());
                Message('payment succesful');
                // CurrInput := '';
                PaymentAmount := '';
                PosTran.SetCurrInput(PaymentAmount);
            END ELSE BEGIN
                ErrorResponse := Phi_payresp('"responseCode":"', '"', 0, ResponseText) + ':' + Phi_payresp('"txnRespDescription":"', '"', 0, ResponseText);
                MESSAGE('Maximum time lapsed Please Press Phi EDC CheckStatus button to check payment status %1', ErrorResponse);
            END;
        END ELSE BEGIN
            WalletLogEntry.RESET;
            WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
            WalletLogEntry.SETRANGE("Store No.", REC."Store No.");
            WalletLogEntry.SETRANGE("Receipt No.", REC."Retrieved from Receipt No.");
            WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
            WalletLogEntry.SETRANGE(WalletLogEntry.voided, FALSE);
            IF WalletLogEntry.ISEMPTY THEN
                ERROR('No Payment exist in this bill being refunded');
            WalletLogEntry.FINDFIRST;
            IF WalletLogEntry.paymentMode = 'Card' THEN BEGIN
                TranType := 'VOID';
                lAmt := '0.00';
            END ELSE BEGIN
                TranType := 'REFUND';
                lAmt := FORMAT(WalletLogEntry.Amount);
            END;

            //   IF Phi_EDCIntegration.RefundInvoice(REC."Receipt No.",WalletLogEntry."Store No.",REC."POS Terminal No.",lAmt
            //     ,WalletLogEntry.Reference,TranType) THEN BEGIN
            IF Phi_EDCIntegration.RefundInvoice(REC."Receipt No.", WalletLogEntry."Store No.", REC."POS Terminal No.", lAmt
                , WalletLogEntry.Reference, TranType) THEN BEGIN
                PaymentAmount := format(WalletLogEntry.Amount);
                // CurrInput := FORMAT(WalletLogEntry.Amount);
                PosTran.SetCurrInput(PaymentAmount);
                PosTran.TenderKeyPressed(GetPhiEDCTender());
                Message('payment succesful');
                PaymentAmount := '';
                PosTran.SetCurrInput(PaymentAmount);
                // CurrInput := '';
                IF l_WalletLogEntry.GET(WalletLogEntry."Entry No.", WalletLogEntry."Receipt No.") THEN BEGIN
                    l_WalletLogEntry.voided := TRUE;
                    l_WalletLogEntry.RefundInvoiceNo := REC."Receipt No.";
                    l_WalletLogEntry.MODIFY(TRUE);
                END;
            END;
        END;
    end;

    local procedure Phi_CheckStatus(OrderID: Code[20]; Loop: Boolean; VAR VCnt: Integer; VAR ErrorResp: Text): Decimal
    var
        LAmt: Decimal;
        SAmt: Text;
        RetailSetup: Record "LSC Retail Setup";
        RetailUser: Record "LSC Retail User";
        POSTerminalRec: Record "LSC POS Terminal";
        WalletLogEntry: Record "Phi_EDC Log Entry";
        Phi_EDCIntegration: Codeunit "Phi_EDC Integration";
        ResponseText: Text;
        PosTran: Codeunit "LSC POS Transaction";
        PosTransTbl: Record "LSC POS Transaction";
    begin
        PosTran.GetPOSTransaction(PosTransTbl);
        IF VCnt > 3 THEN
            EXIT(0);

        WalletLogEntry.RESET;
        WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
        WalletLogEntry.SETRANGE("Receipt No.", OrderID);
        WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
        WalletLogEntry.SETRANGE(voided, FALSE);
        WalletLogEntry.SETRANGE("Payment Validated", FALSE);
        IF WalletLogEntry.ISEMPTY THEN
            ERROR('Please Press EDC Button');
        WalletLogEntry.FINDFIRST;

        IF Phi_EDCIntegration.CheckStatus(WalletLogEntry.invoiceNo, PosTransTbl."Store No.", PosTransTbl."POS Terminal No.",
        FORMAT(WalletLogEntry.Amount), ResponseText, PosTransTbl."Receipt No.", '') THEN BEGIN
            SAmt := '';
            LAmt := 0;
            IF Phi_payresp('"responseCode":"', '"', 0, ResponseText) = '0000' THEN BEGIN
                WalletLogEntry.aggregatorId := Phi_payresp('"aggregatorId":"', '"', 0, ResponseText);
                SAmt := Phi_payresp('"amount":"', '"', 0, ResponseText);
                WalletLogEntry.invoiceNo := Phi_payresp('"invoiceNo":"', '"', 0, ResponseText);
                WalletLogEntry.invoiceStatus := Phi_payresp('"invoiceStatus":"', '"', 0, ResponseText);
                IF SAmt <> '' THEN
                    EVALUATE(LAmt, SAmt);
                //    IF WalletLogEntry.txnID='' THEN
                //      ERROR('Transaction not completed try Again');
                WalletLogEntry."Payment Validated" := TRUE;
                WalletLogEntry.Amount := LAmt;

                WalletLogEntry.merchantId := Phi_payresp('"merchantId":"', '"', 0, ResponseText);
                WalletLogEntry.paymentDateTime := Phi_payresp('"paymentDateTime":"', '"', 0, ResponseText);
                WalletLogEntry.paymentInstrumentId := Phi_payresp('"paymentInstrumentId":"', '"', 0, ResponseText);
                WalletLogEntry.paymentMode := Phi_payresp('"paymentMode":"', '"', 0, ResponseText);
                WalletLogEntry.posAppId := Phi_payresp('"posAppId":"', '"', 0, ResponseText);
                WalletLogEntry.posTillNo := Phi_payresp('"posTillNo":"', '"', 0, ResponseText);
                WalletLogEntry.Reference := Phi_payresp('"referenceNo":"', '"', 0, ResponseText);
                WalletLogEntry.responseCode := Phi_payresp('"responseCode":"', '"', 0, ResponseText);
                WalletLogEntry.txnAuthID := Phi_payresp('"txnAuthID":"', '"', 0, ResponseText);
                WalletLogEntry.txnID := Phi_payresp('"txnID":"', '"', 0, ResponseText);
                WalletLogEntry.txnStatus := Phi_payresp('"txnStatus":"', '"', 0, ResponseText);
                WalletLogEntry.txnResponseCode := Phi_payresp('"txnResponseCode":"', '"', 0, ResponseText);
                WalletLogEntry.txnRespDescription := Phi_payresp('"txnRespDescription":"', '"', 0, ResponseText);
                WalletLogEntry.MODIFY(TRUE);
                EXIT(LAmt);
            END
            ELSE BEGIN
                IF Loop = FALSE THEN
                    ERROR(Phi_payresp('"responseCode":"', '"', 0, ResponseText) + ':' + Phi_payresp('"txnRespDescription":"', '"', 0, ResponseText))
                ELSE BEGIN
                    SLEEP(5000);
                    VCnt += 1;
                    ResponseText := '';
                    EXIT(Phi_CheckStatus(OrderID, TRUE, VCnt, ResponseText));

                END;
            END;
        END ELSE BEGIN  //Status not OK
            IF Loop = FALSE THEN BEGIN
                ERROR(ResponseText);
            END
            ELSE BEGIN
                SLEEP(5000);
                VCnt += 1;
                //    ResponseText:='';
                EXIT(Phi_CheckStatus(OrderID, TRUE, VCnt, ResponseText));
            END;
        END;
        EXIT(0);
    end;

    local procedure GetPhiEDCTender(): Code[20]
    var
        lTenderTypeForPhiEDC: Record "LSC Tender Type";
    begin
        //Get Phi EDC Tender
        lTenderTypeForPhiEDC.RESET;
        lTenderTypeForPhiEDC.SETRANGE("Store No.", POSSESSION.StoreNo);
        lTenderTypeForPhiEDC.SETRANGE("Phi_EDC Enable", TRUE);
        IF lTenderTypeForPhiEDC.FINDFIRST THEN
            EXIT(lTenderTypeForPhiEDC.Code)
        ELSE
            ERROR('Phi EDC Card Setup is missing on Tender Type Setup');

    end;

    local procedure Phi_payresp(lResp: Text[1024]; lResp2: Text[30]; GoBAck: Integer; ResponseText: Text) ResponseText2: Text
    begin
        IF (STRPOS(ResponseText, lResp2) <> 0) AND (lResp2 <> '"') THEN
            ResponseText2 := COPYSTR(ResponseText, STRPOS(ResponseText, lResp) + STRLEN(lResp) + 2, STRPOS(ResponseText, lResp2) - 2)
        ELSE
            IF lResp2 = '"' THEN BEGIN
                ResponseText2 := COPYSTR(ResponseText, STRPOS(ResponseText, lResp) + STRLEN(lResp), STRLEN(ResponseText));
                ResponseText2 := COPYSTR(ResponseText2, 1, STRPOS(ResponseText2, '"') - 1);
            END
            ELSE
                ResponseText2 := COPYSTR(ResponseText, STRPOS(ResponseText, lResp) + STRLEN(lResp) + 2, STRLEN(ResponseText) - 1);
        ResponseText2 := SELECTSTR(1, ResponseText2);
        IF (STRPOS(ResponseText, lResp2) <> 0) AND (lResp2 <> '"') THEN
            ResponseText2 := COPYSTR(ResponseText2, 1, STRLEN(ResponseText2) - GoBAck - 1);
        EXIT(ResponseText2);
        //MESSAGE(FORMAT(ResponseText2));
    end;

    //Phi INtegration

}

