codeunit 50101 "EzetapEDCIntegration"
{
    trigger OnRun()
    begin

    end;

    var
        p2pRequestId: Text;
        RequestAmount: Text;
        RequestUserName: Text;
        RequestcustomerMobileNumber: Text;
        RequestExternalRefNumber: Text;
        RequestDeviceId: Text;
        RequestMode: Text;

    procedure SendTransEzetapEDC(lOrderID: Code[20]; lDateTime: Text; TerminalID: Code[20]; StoreID: Code[20];
                lAmt: Decimal; lResend: Boolean; lSalesType: Code[20]; DQR: Boolean)
    var
        lBody: Text;
        // RetailSetup: Record "LSC Retail Setup";
        StoreSetup: Record "LSC Store";
        POSTerminal: Record "LSC POS Terminal";
        FinalOrderNo: Code[30];
        ResponseText: Text;
        WalletLogEntry: Record "Wallet Log Entry";
        POSTransaction: Codeunit "LSC POS Transaction";
        Cnt: Integer;
        CheckSumStr: Text;
        lChecksum: Text;
        WinHttpService: HttpClient;
        gHttpClient: HttpClient;
        gContent: HttpContent;
        gHttpResponseMsg: HttpResponseMessage;
        gHttpRequestMsg: HttpRequestMessage;
        gContentHeaders: HttpHeaders;
        gResponseMsg: Text;
        EntryNo: Integer;
        WalletLogEntry1: Record "Wallet Log Entry";
        SuccessFlag: Text;
    begin
        StoreSetup.GET(StoreID);
        if not StoreSetup."Ezetap Enable" then
            Exit;

        StoreSetup.TESTFIELD("Ezetap appKey");
        StoreSetup.TESTFIELD("Ezetap username");
        StoreSetup.TestField("Ezetap Base URL");

        POSTerminal.GET(TerminalID);
        POSTerminal.TESTFIELD("Ezetap EDC TID");

        IF NOT lResend THEN BEGIN
            WalletLogEntry.RESET;
            WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
            WalletLogEntry.SETRANGE("Store No.", StoreID);
            WalletLogEntry.SETRANGE("Receipt No.", lOrderID);
            WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
            WalletLogEntry.SETRANGE(voided, FALSE);
            // IF NOT WalletLogEntry.ISEMPTY THEN
            //     ERROR('Only one Payment can be accepted, void Previous Payment First');
        END;

        IF lSalesType IN ['ODRBOOKING'] THEN BEGIN
            WalletLogEntry.RESET;
            WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
            WalletLogEntry.SETRANGE("Receipt No.", lOrderID);
            WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
            WalletLogEntry.SETRANGE(voided, FALSE);
            WalletLogEntry.SETRANGE("Payment Validated", FALSE);
            IF WalletLogEntry.FINDFIRST THEN BEGIN
                POSTransaction.ScreenDisplay('');
                ERROR('Please click on Check Status, or call IT team');
            END;
        END;
        FinalOrderNo := lOrderID + FORMAT(TIME, 0, '<Hours><Minutes><Seconds>');

        if not DQR then begin

            lBody := '{' +
            '"appKey"' + ':' + '"' + StoreSetup."Ezetap appKey" + '"' + ',' +
            '"username"' + ':' + '"' + StoreSetup."Ezetap username" + '"' + ',' +
            '"amount"' + ':' + '"' + FORMAT(lAmt, 0, '<Integer>') + '"' + ',' +
            '"customerMobileNumber"' + ':' + '""' + ',' +
            //'"accountLabel"' + ':"' + StoreSetup."Ezetap EDC Account Label" + '",' +
            '"externalRefNumber"' + ':' + '"' + FinalOrderNo + '"' + ',' +
            '"externalRefNumber2"' + ':' + '" "' + ',' +
            '"customerEmail"' + ':' + '"Testmail@gmail.com"' + ',' +
                '"pushTo"' + ': {' +
                    '"deviceId"' + ':' + '"' + POSTerminal."Ezetap EDC TID" + '|ezetap_android"'
                + '}' + ',' +
                '"mode"' + ':' + '"CARD"' +
            '}';

        end else
            lBody := '{' +
            '"appKey"' + ':' + '"' + StoreSetup."Ezetap DQR appKey" + '"' + ',' +
            '"username"' + ':' + '"' + StoreSetup."Ezetap DQR username" + '"' + ',' +
            '"amount"' + ':' + '"' + FORMAT(lAmt, 0, '<Integer>') + '"' + ',' +
            '"customerMobileNumber"' + ':' + '""' + ',' +
            //'"accountLabel"' + ':"' + StoreSetup."Ezetap DQR Account Label" + '",' +
            '"externalRefNumber"' + ':' + '"' + FinalOrderNo + '"' + ',' +
            '"externalRefNumber2"' + ':' + '" "' + ',' +
            '"customerEmail"' + ':' + '"Testmail@gmail.com"' + ',' +
                '"pushTo"' + ': {' +
                    '"deviceId"' + ':' + '"' + POSTerminal."Ezetap DQR TID" + '|razorpay_pos_soundbox"'
                + '}' + ',' +
                '"mode"' + ':' + '"UPI"' +
            '}';

        ClearLastError();
        Clear(gResponseMsg);
        gContent.WriteFrom(lBody);
        gContent.GetHeaders(gContentHeaders);
        gContentHeaders.Clear();
        gContentHeaders.Add('Content-Type', 'application/json');
        gContentHeaders.Add('Username', StoreSetup."Ezetap username");
        gContentHeaders.Add('Password', StoreSetup."Ezetap Password");
        if gHttpClient.Post(StoreSetup."Ezetap Base URL" + 'p2padapter/pay', gContent, gHttpResponseMsg) then begin
            gHttpResponseMsg.Content.ReadAs(gResponseMsg);

            //Logs Generate
            EDCAPILog(lBody, gResponseMsg, 'SENDTOEDC', StoreID);
            if not DQR then begin

                RequestDeviceId := POSTerminal."Ezetap EDC TID";
                RequestMode := 'ALL';

            end else begin
                RequestDeviceId := POSTerminal."Ezetap Dqr TID";
                RequestMode := 'UPI';

            end;
            RequestExternalRefNumber := FinalOrderNo;

            //Logs Generate
            // Message(gResponseMsg);
            if gHttpResponseMsg.IsSuccessStatusCode then begin
                // Message(CaptureRsponse('success', gResponseMsg, gHttpResponseMsg));
                if CaptureRsponse('success', lBody, gHttpResponseMsg) = 'true' then begin
                    //Insert Data
                    p2pRequestId := CaptureRsponse('p2pRequestId', lBody, gHttpResponseMsg);
                    EDCLsLog(2, '', 0, 0, StoreID, FinalOrderNo, lAmt, lOrderID, 0, '', '', lSalesType, gResponseMsg, gHttpResponseMsg);

                end
                ELSE
                    ERROR(CaptureRsponse('errorMessage', lBody, gHttpResponseMsg));
            END ELSE
                IF gResponseMsg <> '' THEN BEGIN
                    ERROR(gResponseMsg);
                end;
        end;
    End;


    procedure CancelNotificationEzetap(lOrdID: Text; Loop: Boolean; VAR VCnt: Integer; TerminalID: Code[20];
              lSalesType: Code[20]; SkipError: Boolean; lStore: code[20]; lDateTime: Text; DQR: Boolean): Decimal
    var
        // RetailSetup: Record "LSC Retail Setup";
        StoreSetup: Record "LSC Store";
        POSTerminal: Record "LSC POS Terminal";
        WalletLogEntry: Record "Wallet Log Entry";
        FinalOrderNo: Code[30];
        WinHttpService: HttpClient;
        gHttpClient: HttpClient;
        gContent: HttpContent;
        gHttpResponseMsg: HttpResponseMessage;
        gHttpRequestMsg: HttpRequestMessage;
        gContentHeaders: HttpHeaders;
        lBody: Text;
        lAmtTxt: Text;
        gResponseMsg: Text;
        ChkStatusURL: Text;
        POSTransaction: Codeunit "LSC POS Transaction";
        TtemScanGroupJsonToken: JsonToken;
        TTaxJsonObjct: JsonObject;
        TTaxJsonArray: JsonArray;
        TTaxJsonToken: JsonToken;
        TJsonObject: JsonObject;
        TJsonToken: JsonToken;
        TGroupJsonObjct: JsonObject;
        TGroupJsonArray: JsonArray;
        Ti: Integer;
        TID: Text;
        MID: text;
        Amount: Text;
        AmountDec: Decimal;
        BatchNumber: Text;
        RRN: Text;
        ApprovalCode: Text;
        InvoiceNumber: Text;
        CardType: Text;
        TransactionLogId: text;
        FinalAmount: Text;
        lTime: Time;
        lDate: Date;
        TransactionTime: Text;
        TransactionDate: text;
        CardNumber: text;
        AcquirerId: text;
        AcquirerName: text;
        CheckSumStr: Text;
        // gResponseMsg: Text;
        lChecksum: Text;
        SAmt: Text;
        LAmt: Decimal;
        MsgCode: Text;
        StatusCode: Text;
        SuccessFlag: Text;
    begin

        StoreSetup.GET(lStore);
        StoreSetup.TESTFIELD("Ezetap appKey");
        StoreSetup.TESTFIELD("Ezetap username");
        StoreSetup.TestField("Ezetap Base URL");

        POSTerminal.GET(TerminalID);
        POSTerminal.TESTFIELD("Ezetap EDC TID");


        WalletLogEntry.RESET;
        WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
        WalletLogEntry.SETRANGE("Receipt No.", lOrdID);
        WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
        WalletLogEntry.SETRANGE(voided, FALSE);
        //WalletLogEntry.SETRANGE("Payment Validated",FALSE);
        IF WalletLogEntry.ISEMPTY THEN BEGIN
            POSTransaction.ScreenDisplay('');
            Exit(0);
            //ERROR('Network Issue or You need to Please Press Card/Upi Button')
        END ELSE
            WalletLogEntry.FINDLAST;

        if not DQR then
            lBody := '{' +
                '"username"' + ':' + '"' + StoreSetup."Ezetap username" + '"' + ',' +
                '"appKey"' + ':' + '"' + StoreSetup."Ezetap appKey" + '"' + ',' +
                '"origP2pRequestId"' + ':' + '"' + walletlogentry.p2pRequestId + '"' + ',' +
                '"pushTo": {"deviceId": "' + POSTerminal."Ezetap EDC TID" + '"}}'
        else
            lBody := '{' +
                   '"username"' + ':' + '"' + StoreSetup."Ezetap DQR username" + '"' + ',' +
                   '"appKey"' + ':' + '"' + StoreSetup."Ezetap DQR appKey" + '"' + ',' +
                    '"origP2pRequestId"' + ':' + '"' + walletlogentry.p2pRequestId + '"' + ',' +
                    '"pushTo": {"deviceId": "' + POSTerminal."Ezetap EDC TID" + '"}}';


        Clear(gResponseMsg);
        gContent.WriteFrom(lBody);
        gContent.GetHeaders(gContentHeaders);
        gContentHeaders.Clear();
        gContentHeaders.Add('Content-Type', 'application/json');
        if not DQR then begin
            gContentHeaders.Add('Username', StoreSetup."Ezetap username");
            gContentHeaders.Add('Password', StoreSetup."Ezetap Password");
        end
        else begin
            gContentHeaders.Add('Username', StoreSetup."Ezetap DQR username");
            gContentHeaders.Add('Password', StoreSetup."Ezetap DQR Password");
        end;
        if gHttpClient.Post(StoreSetup."Ezetap Base URL" + 'p2p/cancel', gContent, gHttpResponseMsg) then begin

            gHttpResponseMsg.Content.ReadAs(gResponseMsg);
            if gHttpResponseMsg.IsSuccessStatusCode then begin
                //Logs Generate
                EdcAPILog(lBody, gResponseMsg, 'SALECANCELEDC', lStore);
                //Logs Generate
                SuccessFlag := CaptureRsponse('success', gResponseMsg, gHttpResponseMsg);
                // if SuccessFlag <> 'true' then begin
                //     WalletLogEntry.voided := true;
                //     WalletLogEntry.VoidDateTime := CurrentDateTime;
                //     WalletLogEntry.Modify();
                //     exit(-1)//Means Transaction not found in Machine
                // end else begin
                WalletLogEntry.voided := true;
                WalletLogEntry.VoidDateTime := CurrentDateTime;
                WalletLogEntry.Modify();
                exit(-1);//Means successfull Transaction cancel from machine
                // end;
            End;
        End;
    End;

    procedure ChkStatusEzetapTransEDC(lOrdID: Text; Loop: Boolean; VAR VCnt: Integer; TerminalID: Code[20];
              lSalesType: Code[20]; SkipError: Boolean; lStore: code[20]; lDateTime: Text; DQR: Boolean): Decimal
    var
        // RetailSetup: Record "LSC Retail Setup";
        StoreSetup: Record "LSC Store";
        POSTerminal: Record "LSC POS Terminal";
        WalletLogEntry: Record "Wallet Log Entry";
        FinalOrderNo: Code[30];
        WinHttpService: HttpClient;
        gHttpClient: HttpClient;
        gContent: HttpContent;
        gHttpResponseMsg: HttpResponseMessage;
        gHttpRequestMsg: HttpRequestMessage;
        gContentHeaders: HttpHeaders;
        lBody: Text;
        lAmtTxt: Text;
        gResponseMsg: Text;
        ChkStatusURL: Text;
        POSTransaction: Codeunit "LSC POS Transaction";
        TtemScanGroupJsonToken: JsonToken;
        TTaxJsonObjct: JsonObject;
        TTaxJsonArray: JsonArray;
        TTaxJsonToken: JsonToken;
        TJsonObject: JsonObject;
        TJsonToken: JsonToken;
        TGroupJsonObjct: JsonObject;
        TGroupJsonArray: JsonArray;
        Ti: Integer;
        TID: Text;
        MID: text;
        Amount: Text;
        AmountDec: Decimal;
        BatchNumber: Text;
        RRN: Text;
        ApprovalCode: Text;
        InvoiceNumber: Text;
        CardType: Text;
        TransactionLogId: text;
        FinalAmount: Text;
        lTime: Time;
        lDate: Date;
        TransactionTime: Text;
        TransactionDate: text;
        CardNumber: text;
        AcquirerId: text;
        AcquirerName: text;
        CheckSumStr: Text;
        // gResponseMsg: Text;
        lChecksum: Text;
        SAmt: Text;
        LAmt: Decimal;
        MsgCode: Text;
        StatusCode: Text;
        SuccessFlag: Text;
    begin

        StoreSetup.GET(lStore);
        StoreSetup.TESTFIELD("Ezetap appKey");
        StoreSetup.TESTFIELD("Ezetap username");
        StoreSetup.TestField("Ezetap Base URL");

        POSTerminal.GET(TerminalID);
        POSTerminal.TESTFIELD("Ezetap EDC TID");


        WalletLogEntry.RESET;
        WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
        WalletLogEntry.SETRANGE("Receipt No.", lOrdID);
        WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
        // WalletLogEntry.SETRANGE(voided, FALSE);
        //WalletLogEntry.SETRANGE("Payment Validated",FALSE);
        IF WalletLogEntry.ISEMPTY THEN BEGIN
            POSTransaction.ScreenDisplay('');
            Exit(0);
            //ERROR('Network Issue or You need to Please Press Card/Upi Button')
        END ELSE
            WalletLogEntry.FINDLAST;

        IF VCnt > 3 THEN
            EXIT(0);

        // CheckSumStr := WalletLogEntry.Reference + '|' + StoreSetup."Paytm QR Merchant ID" + '|' + lDateTime;
        // lChecksum := Checksum.generateSignature(CheckSumStr, StoreSetup."Paytm QR Merchant Key");

        // lBody := '{"head":{"version":"3.1","requestTimeStamp":"' + lDateTime + '","channelId":"EDC","checksum":"' + lChecksum + '"},' +
        // '"body":{"merchantTransactionId":"' + WalletLogEntry.Reference + '","paytmMid":"' + StoreSetup."Paytm QR Merchant ID" + '","transactionDateTime":"' + lDateTime + '"}}';

        if not DQR then
            lBody := '{' +
                '"username"' + ':' + '"' + StoreSetup."Ezetap username" + '"' + ',' +
                '"appKey"' + ':' + '"' + StoreSetup."Ezetap appKey" + '"' + ',' +
                '"origP2pRequestId"' + ':' + '"' + walletlogentry.p2pRequestId + '"' +
                '}'
        else
            lBody := '{' +
                '"username"' + ':' + '"' + StoreSetup."Ezetap DQR username" + '"' + ',' +
                '"appKey"' + ':' + '"' + StoreSetup."Ezetap DQR appKey" + '"' + ',' +
                '"origP2pRequestId"' + ':' + '"' + walletlogentry.p2pRequestId + '"' +
                '}';


        Clear(gResponseMsg);
        gContent.WriteFrom(lBody);
        gContent.GetHeaders(gContentHeaders);
        gContentHeaders.Clear();
        gContentHeaders.Add('Content-Type', 'application/json');
        if not DQR then begin
            gContentHeaders.Add('Username', StoreSetup."Ezetap username");
            gContentHeaders.Add('Password', StoreSetup."Ezetap Password");
        end else begin
            gContentHeaders.Add('Username', StoreSetup."Ezetap DQR username");
            gContentHeaders.Add('Password', StoreSetup."Ezetap DQR Password");

        end;
        if gHttpClient.Post(StoreSetup."Ezetap Base URL" + 'p2padapter/status', gContent, gHttpResponseMsg) then begin

            gHttpResponseMsg.Content.ReadAs(gResponseMsg);
            if gHttpResponseMsg.IsSuccessStatusCode then begin
                //Logs Generate
                EdcAPILog(lBody, gResponseMsg, 'SALESTATUSEDC', lStore);
                //Logs Generate
                SuccessFlag := CaptureRsponse('success', gResponseMsg, gHttpResponseMsg);
                if SuccessFlag = 'true' then begin
                    MsgCode := CaptureRsponse('messageCode', gResponseMsg, gHttpResponseMsg);
                    if CaptureRsponse('abstractPaymentStatus', gResponseMsg, gHttpResponseMsg) = 'SUCCESS' then
                        StatusCode := CaptureRsponse('status', gResponseMsg, gHttpResponseMsg)
                    else
                        StatusCode := 'PROCESSING';//Fix in case not working because status code is not coming
                end;
                if (MsgCode = 'P2P_DEVICE_TXN_DONE') and (StatusCode = 'AUTHORIZED') then begin
                    SAmt := '';
                    LAmt := 0;
                    WalletLogEntry."Wallet TXN No." := CaptureRsponse('txnId', gResponseMsg, gHttpResponseMsg);
                    SAmt := CaptureRsponse('amount', gResponseMsg, gHttpResponseMsg);
                    // WalletLogEntry."Bank Name" := CaptureRsponse('$.body.issuingBankName', gResponseMsg, gHttpResponseMsg);
                    WalletLogEntry."Payment Mode" := CaptureRsponse('paymentMode', gResponseMsg, gHttpResponseMsg);
                    // WalletLogEntry."Mobile No" := CaptureRsponse('customerMobile', gResponseMsg, gHttpResponseMsg);
                    // WalletLogEntry.retrievalReferenceNo := CaptureRsponse('$.body.retrievalReferenceNo', gResponseMsg, gHttpResponseMsg);
                    // WalletLogEntry.authCode := CaptureRsponse('authCode', gResponseMsg, gHttpResponseMsg);
                    // WalletLogEntry.bankResponseMessage := CaptureRsponse('$.body.bankResponseMessage', gResponseMsg, gHttpResponseMsg);
                    WalletLogEntry.bankResponseCode := CaptureRsponse('acquirerCode', gResponseMsg, gHttpResponseMsg);
                    WalletLogEntry.bankMid := CaptureRsponse('mid', gResponseMsg, gHttpResponseMsg);
                    WalletLogEntry.bankTid := CaptureRsponse('tid', gResponseMsg, gHttpResponseMsg);
                    // WalletLogEntry.aid := CaptureRsponse('$.body.aid', gResponseMsg, gHttpResponseMsg);
                    if WalletLogEntry."Payment Mode" = 'CARD' then begin
                        WalletLogEntry.issuerMaskCardNo := CaptureRsponse('formattedPan', gResponseMsg, gHttpResponseMsg);
                        WalletLogEntry.cardType := CaptureRsponse('cardType', gResponseMsg, gHttpResponseMsg);
                        WalletLogEntry."Wallet Type" := WalletLogEntry."Wallet Type"::Card;
                        WalletLogEntry.MachineInvoiceNo := CaptureRsponse('invoiceNumber', gResponseMsg, gHttpResponseMsg);
                    end else begin
                        // WalletLogEntry."Wallet TXN No." := CaptureRsponse('orderNumber', gResponseMsg, gHttpResponseMsg);
                        WalletLogEntry.MachineRRN := CaptureRsponse('reverseReferenceNumber', gResponseMsg, gHttpResponseMsg)
                    end;
                    WalletLogEntry.MachineRRN := CaptureRsponse('rrNumber', gResponseMsg, gHttpResponseMsg);
                    IF SAmt <> '' THEN
                        EVALUATE(LAmt, SAmt);
                    IF WalletLogEntry."Wallet TXN No." = '' THEN
                        ERROR('Transaction not completed try Again');
                    WalletLogEntry."Payment Validated" := TRUE;
                    WalletLogEntry.Amount := LAmt;
                    AmountDec := WalletLogEntry.Amount;
                    WalletLogEntry.ErrorCodeDevice := '';
                    // WalletLogEntry.UPIPayment := UPIPayment;//FBTS YM UPIPayment
                    WalletLogEntry.Modify(true);
                End else begin
                    if (StatusCode <> 'AUTHORIZED') then begin
                        WalletLogEntry.ErrorCodeDevice := MsgCode;
                        WalletLogEntry.Modify();
                    end;
                End;
                Exit(AmountDec);
            End else begin
                if not SkipError then begin
                    IF NOT Loop THEN
                        ERROR(gResponseMsg)
                    ELSE BEGIN
                        SLEEP(5000);
                        VCnt += 1;
                        EXIT(ChkStatusEzetapTransEDC(lOrdID, TRUE, VCnt, TerminalID, lSalesType, false, lstore, lDateTime, DQR)); //FBTS YM UPI Payment
                    END;
                End else
                    Exit(0);
            END;
        end
        ELSE BEGIN  //Status not OK
            IF NOT Loop THEN BEGIN
                ERROR(gResponseMsg);
            END
            ELSE BEGIN
                SLEEP(5000);
                VCnt += 1;
                EXIT(ChkStatusEzetapTransEDC(lOrdID, TRUE, VCnt, TerminalID, lSalesType, false, lstore, lDateTime, DQR));//FBTS YM UPI Payment
            END;
        END;
        Exit(0);
    end;


    // procedure ChkStatusEzetapTransEDC(lOrdID: Text; Loop: Boolean; VAR VCnt: Integer; TerminalID: Code[20];
    //           lSalesType: Code[20]; SkipError: Boolean; lStore: code[20]; lDateTime: Text): Decimal
    // var
    //     // RetailSetup: Record "LSC Retail Setup";
    //     StoreSetup: Record "LSC Store";
    //     POSTerminal: Record "LSC POS Terminal";
    //     WalletLogEntry: Record EzetapReqLog;
    //     FinalOrderNo: Code[30];
    //     WinHttpService: HttpClient;
    //     gHttpClient: HttpClient;
    //     gContent: HttpContent;
    //     gHttpResponseMsg: HttpResponseMessage;
    //     gHttpRequestMsg: HttpRequestMessage;
    //     gContentHeaders: HttpHeaders;
    //     lBody: Text;
    //     lAmtTxt: Text;
    //     gResponseMsg: Text;
    //     ChkStatusURL: Text;
    //     POSTransaction: Codeunit "LSC POS Transaction";
    //     TtemScanGroupJsonToken: JsonToken;
    //     TTaxJsonObjct: JsonObject;
    //     TTaxJsonArray: JsonArray;
    //     TTaxJsonToken: JsonToken;
    //     TJsonObject: JsonObject;
    //     TJsonToken: JsonToken;
    //     TGroupJsonObjct: JsonObject;
    //     TGroupJsonArray: JsonArray;
    //     Ti: Integer;
    //     TID: Text;
    //     MID: text;
    //     Amount: Text;
    //     AmountDec: Decimal;
    //     BatchNumber: Text;
    //     RRN: Text;
    //     ApprovalCode: Text;
    //     InvoiceNumber: Text;
    //     CardType: Text;
    //     TransactionLogId: text;
    //     FinalAmount: Text;
    //     lTime: Time;
    //     lDate: Date;
    //     TransactionTime: Text;
    //     TransactionDate: text;
    //     CardNumber: text;
    //     AcquirerId: text;
    //     AcquirerName: text;
    //     Checksum: DotNet Checksum;
    //     CheckSumStr: Text;
    //     // gResponseMsg: Text;
    //     lChecksum: Text;
    //     SAmt: Text;
    //     LAmt: Decimal;
    //     razorPayResp: Record "Ezetap Log Entry";
    //     RespLastNo: Decimal;
    // begin

    //     StoreSetup.GET(lStore);
    //     StoreSetup.TESTFIELD("Ezetap appKey");
    //     StoreSetup.TESTFIELD("Ezetap username");
    //     StoreSetup.TestField("Ezetap Base URL");

    //     POSTerminal.GET(TerminalID);
    //     POSTerminal.TESTFIELD("Ezetap EDC TID");

    //     WalletLogEntry.RESET;
    //     WalletLogEntry.SETRANGE(externalRefNumber, lOrdID);
    //     // WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
    //     // WalletLogEntry.SETRANGE(voided, FALSE);
    //     //WalletLogEntry.SETRANGE("Payment Validated",FALSE);
    //     IF WalletLogEntry.ISEMPTY THEN BEGIN
    //         POSTransaction.ScreenDisplay('');
    //         Exit(0);
    //         //ERROR('Network Issue or You need to Please Press Card/Upi Button')
    //     END ELSE
    //         WalletLogEntry.FINDLAST;

    //     IF VCnt > 3 THEN
    //         EXIT(0);

    //     lBody := '{' +
    //         '"username"' + ':' + '"' + StoreSetup."Ezetap username" + '"' + ',' +
    //         '"appKey"' + ':' + '"' + StoreSetup."Ezetap appKey" + '"' + ',' +
    //         '"origP2pRequestId"' + ':' + '"' + walletlogentry."PHP Value" + '"' +
    //         '}';

    //     // lBody := '{"head":{"version":"3.1","requestTimeStamp":"' + lDateTime + '","channelId":"EDC","checksum":"' + lChecksum + '"},' +
    //     // '"body":{"merchantTransactionId":"' + WalletLogEntry.Reference + '","paytmMid":"' + StoreSetup."Paytm QR Merchant ID" + '","transactionDateTime":"' + lDateTime + '"}}';

    //     // ClearLastError();
    //     Clear(gResponseMsg);
    //     gContent.WriteFrom(lBody);
    //     gContent.GetHeaders(gContentHeaders);
    //     gContentHeaders.Clear();
    //     gContentHeaders.Add('Content-Type', 'application/json');
    //     gContentHeaders.Add('Username', StoreSetup."Ezetap username");
    //     gContentHeaders.Add('Password', StoreSetup."Ezetap Password");
    //     if gHttpClient.Post(StoreSetup."Ezetap Base URL" + 'p2padapter/status', gContent, gHttpResponseMsg) then begin

    //         gHttpResponseMsg.Content.ReadAs(gResponseMsg);
    //         if gHttpResponseMsg.IsSuccessStatusCode then begin
    //             //Logs Generate
    //             EdcAPILog(lBody, gResponseMsg, 'SALESTATUSEDC', lStore);
    //             //Logs Generate
    //             if GetResponsesValue(gResponseMsg, '"messageCode":', ',', 1) = 'P2P_DEVICE_TXN_DONE' then begin
    //                 Clear(RespLastNo);
    //                 razorPayResp.Reset();
    //                 if razorPayResp.FindLast() then
    //                     RespLastNo := razorPayResp."Increment ID" + 1
    //                 else
    //                     RespLastNo := 1;
    //                 Evaluate(AmountDec, GetResponsesValue(gResponseMsg, '"amount":', ',', 1));
    //                 razorPayResp.Init();
    //                 razorPayResp."Increment ID" := RespLastNo;
    //                 razorPayResp.p2pRequestId := GetResponsesValue(gResponseMsg, '"p2pRequestId":', ',', 1);
    //                 razorPayResp."Card No" := GetResponsesValue(gResponseMsg, '"success":', ',', 1);
    //                 razorPayResp.cardLastFourDigit := GetResponsesValue(gResponseMsg, '"cardLastFourDigit":', ',', 1);
    //                 razorPayResp.AMount := Format(GetResponsesValue(gResponseMsg, '"amount":', ',', 1));
    //                 razorpayresp.customerName := GetResponsesValue(gResponseMsg, '"customerName":', ',', 1);
    //                 razorpayresp.Mode := GetResponsesValue(gResponseMsg, '"mode":', ',', 1);
    //                 razorpayresp.status := GetResponsesValue(gResponseMsg, '"status":', ',', 1);
    //                 razorpayresp.merchantName := GetResponsesValue(gResponseMsg, '"merchantName":', ',', 1);
    //                 razorpayresp.message := GetResponsesValue(gResponseMsg, '"message":', ',', 1);
    //                 razorpayresp.messageCode := GetResponsesValue(gResponseMsg, '"messageCode":', ',', 1);
    //                 razorpayresp.orgCode := GetResponsesValue(gResponseMsg, '"orgcode":', ',', 1);
    //                 razorpayresp.paymentCardBin := GetResponsesValue(gResponseMsg, '"paymentCardBin":', ',', 1);
    //                 razorpayresp.paymentCardBrand := GetResponsesValue(gResponseMsg, '"paymentCardBrand":', ',', 1);
    //                 razorpayresp.paymentCardType := GetResponsesValue(gResponseMsg, '"paymentCardType":', ',', 1);
    //                 razorpayresp.paymentMode := GetResponsesValue(gResponseMsg, '"paymentMode":', ',', 1);
    //                 razorpayresp.externalRefNumber := GetResponsesValue(gResponseMsg, '"externalRefNumber":', ',', 1);
    //                 razorPayResp.txnId := GetResponsesValue(gResponseMsg, '"txnId":', ',', 1);
    //                 razorpayresp.Insert();

    //             End;
    //             Exit(AmountDec);
    //         End else begin
    //             if not SkipError then begin
    //                 IF NOT Loop THEN
    //                     ERROR(gResponseMsg)
    //                 ELSE BEGIN
    //                     SLEEP(5000);
    //                     VCnt += 1;
    //                     EXIT(ChkStatusEzetapTransEDC(lOrdID, TRUE, VCnt, TerminalID, lSalesType, false, lstore, lDateTime)); //FBTS YM UPI Payment
    //                 END;
    //             End else
    //                 Exit(0);
    //         END;
    //     end
    //     ELSE BEGIN  //Status not OK
    //         IF NOT Loop THEN BEGIN
    //             ERROR(gResponseMsg);
    //         END
    //         ELSE BEGIN
    //             SLEEP(5000);
    //             VCnt += 1;
    //             EXIT(ChkStatusEzetapTransEDC(lOrdID, TRUE, VCnt, TerminalID, lSalesType, false, lstore, lDateTime));//FBTS YM UPI Payment
    //         END;
    //     END;
    //     Exit(0);
    // end;

    // procedure RefundAPIPaytm(lOrderID: Code[20]; lDateTime: Text; TerminalID: Code[20]; StoreID: Code[20]; lAmt: Decimal; lCurrOrdID: Code[20]; lSalesType: Code[20]): Boolean
    // var
    //     lBody: Text;
    //     StoreSetup: Record "LSC Store";
    //     POSTerminal: Record "LSC POS Terminal";
    //     FinalOrderNo: Code[30];
    //     ResponseText: Text;
    //     WalletLogEntry: Record "Wallet Log Entry";
    //     POSTransaction: Codeunit "LSC POS Transaction";
    //     Cnt: Integer;
    //     Checksum: DotNet Checksum;
    //     CheckSumStr: Text;
    //     lChecksum: Text;
    //     WinHttpService: HttpClient;
    //     gHttpClient: HttpClient;
    //     gContent: HttpContent;
    //     gHttpResponseMsg: HttpResponseMessage;
    //     gHttpRequestMsg: HttpRequestMessage;
    //     gContentHeaders: HttpHeaders;
    //     gResponseMsg: Text;
    // begin

    //     StoreSetup.GET(StoreID);
    //     StoreSetup.TESTFIELD("Paytm QR Merchant ID");
    //     StoreSetup.TESTFIELD("Paytm QR Merchant Key");

    //     POSTerminal.GET(TerminalID);
    //     POSTerminal.TESTFIELD("Paytm EDC TID");

    //     WalletLogEntry.RESET;
    //     WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
    //     WalletLogEntry.SETRANGE("Store No.", StoreID);
    //     WalletLogEntry.SETRANGE("Receipt No.", lCurrOrdID);
    //     WalletLogEntry.SETRANGE(voided, FALSE);
    //     IF WalletLogEntry.FINDFIRST THEN
    //         EXIT(TRUE);

    //     WalletLogEntry.RESET;
    //     WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
    //     WalletLogEntry.SETRANGE("Store No.", StoreID);
    //     WalletLogEntry.SETRANGE("Receipt No.", lOrderID);
    //     WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
    //     WalletLogEntry.SETRANGE(voided, FALSE);
    //     // IF NOT WalletLogEntry.ISEMPTY THEN
    //     //  ERROR('Only one Paytm Payment can be accepted , void Previous Payment First');
    //     WalletLogEntry.FINDLAST;

    //     FinalOrderNo := lCurrOrdID + FORMAT(TIME, 0, '<Hours><Minutes><Seconds>');

    //     CheckSumStr := '{"orderId":"' + WalletLogEntry.Reference + '","txnType":"REFUND","mid":"' + StoreSetup."Paytm QR Merchant ID" + '","refId":"' + WalletLogEntry.retrievalReferenceNo +
    //     '","txnId":"' + WalletLogEntry."Wallet TXN No." + '","refundAmount":"' + DELCHR(FORMAT(WalletLogEntry.Amount), '<=>', ',') + '"}';
    //     lChecksum := Checksum.generateSignature(CheckSumStr, StoreSetup."Paytm QR Merchant Key");

    //     lBody := '{"head":{"clientId":"C11","signature":"' + lChecksum + '"},"body":' + CheckSumStr + '}';

    //     ClearLastError();
    //     Clear(gResponseMsg);
    //     gContent.WriteFrom(lBody);
    //     gContent.GetHeaders(gContentHeaders);
    //     gContentHeaders.Clear();
    //     gContentHeaders.Add('Content-Type', 'application/json');
    //     if gHttpClient.Post(StoreSetup."Paytm EDC Refund URL", gContent, gHttpResponseMsg) then begin
    //         gHttpResponseMsg.Content.ReadAs(gResponseMsg);
    //         //Logs Generate
    //         EDCAPILog(lBody, gResponseMsg, 'REFUNDEDC', StoreID);
    //         //Logs Generate

    //         // Message(gResponseMsg);
    //         if gHttpResponseMsg.IsSuccessStatusCode then begin
    //             if (CaptureRsponse('$.body.resultInfo.resultCode', gResponseMsg, gHttpResponseMsg)) IN ['601', '617', '629'] then begin
    //                 EDCLsLog(1, '', 0, 0, StoreID, FinalOrderNo, lAmt, lOrderID, 0, '', '', lSalesType, gResponseMsg, gHttpResponseMsg);
    //                 Exit(true);
    //             End ELSE
    //                 ERROR(gResponseMsg);
    //         END ELSE
    //             IF gResponseMsg <> '' THEN BEGIN
    //                 if STRPOS(gResponseMsg, '"resultMsg"') <> 0 then
    //                     Message(CaptureRsponse('$.body.resultInfo.resultMsg', gResponseMsg, gHttpResponseMsg) + '\Order ID:' + lOrderID)
    //                 else
    //                     Message(gResponseMsg);
    //             end;
    //     End;
    //     EXIT(FALSE);
    // End;

    // procedure ChkStatusRefund(lDateTime: Text; lOrdID: Text; Loop: Boolean; VAR VCnt: Integer; TerminalID: Code[20]; lCurrOrdID: Text): Boolean
    // var
    //     lBody: Text;
    //     StoreSetup: Record "LSC Store";
    //     POSTerminal: Record "LSC POS Terminal";
    //     FinalOrderNo: Code[30];
    //     ResponseText: Text;
    //     WalletLogEntry: Record "Wallet Log Entry";
    //     POSTransaction: Codeunit "LSC POS Transaction";
    //     Cnt: Integer;
    //     Checksum: DotNet Checksum;
    //     CheckSumStr: Text;
    //     lChecksum: Text;
    //     WinHttpService: HttpClient;
    //     gHttpClient: HttpClient;
    //     gContent: HttpContent;
    //     gHttpResponseMsg: HttpResponseMessage;
    //     gHttpRequestMsg: HttpRequestMessage;
    //     gContentHeaders: HttpHeaders;
    //     gResponseMsg: Text;
    //     SAmt: Text;
    //     LAmt: Decimal;
    // begin


    //     POSTerminal.GET(TerminalID);
    //     StoreSetup.Get(POSTerminal."Store No.");
    //     StoreSetup.TESTFIELD("Paytm QR Merchant ID");
    //     StoreSetup.TESTFIELD("Paytm QR Merchant Key");
    //     POSTerminal.TESTFIELD("Paytm EDC TID");
    //     IF VCnt > 3 THEN
    //         EXIT(FALSE);


    //     WalletLogEntry.RESET;
    //     WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
    //     WalletLogEntry.SETRANGE("Receipt No.", lOrdID);
    //     WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
    //     WalletLogEntry.SETRANGE(voided, FALSE);
    //     IF WalletLogEntry.FINDFIRST THEN BEGIN
    //         CheckSumStr := '{"orderId":"' + WalletLogEntry.Reference + '","mid":"' + StoreSetup."Paytm QR Merchant ID" +
    //                      '","refId":"' + WalletLogEntry.retrievalReferenceNo + '"}';
    //     END ELSE
    //         EXIT(FALSE);

    //     lChecksum := Checksum.generateSignature(CheckSumStr, StoreSetup."Paytm QR Merchant Key");
    //     // MESSAGE(CheckSumStr);
    //     // MESSAGE(lChecksum);

    //     lBody := '{"head":{"clientId":"C11","signature":"' + lChecksum + '"},"body":' + CheckSumStr + '}';
    //     // MESSAGE(lBody);
    //     ClearLastError();
    //     Clear(gResponseMsg);
    //     gContent.WriteFrom(lBody);
    //     gContent.GetHeaders(gContentHeaders);
    //     gContentHeaders.Clear();
    //     gContentHeaders.Add('Content-Type', 'application/json');
    //     if gHttpClient.Post(StoreSetup."Paytm EDC Refund Status URL", gContent, gHttpResponseMsg) then begin

    //         gHttpResponseMsg.Content.ReadAs(gResponseMsg);
    //         if gHttpResponseMsg.IsSuccessStatusCode then begin
    //             //Logs Generate
    //             EdcAPILog(lBody, gResponseMsg, 'REFUNDSTATUSEDC', '');
    //             //Logs Generate
    //             if CaptureRsponse('$.body.resultInfo.resultStatus', gResponseMsg, gHttpResponseMsg) = 'TXN_SUCCESS' then begin
    //                 SAmt := '';
    //                 LAmt := 0;
    //                 WalletLogEntry.RESET;
    //                 WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
    //                 WalletLogEntry.SETRANGE("Receipt No.", lCurrOrdID);
    //                 WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Refund);
    //                 WalletLogEntry.SETRANGE(voided, FALSE);
    //                 IF WalletLogEntry.FINDFIRST THEN BEGIN

    //                     WalletLogEntry."Wallet TXN No." := CaptureRsponse('$.body.acquirementId', gResponseMsg, gHttpResponseMsg);
    //                     // WalletLogEntry."Wallet TXN No." := PaytmResp('"acquirementId":"', '"', 0, ResponseText);
    //                     SAmt := CaptureRsponse('$.body.totalRefundAmount', gResponseMsg, gHttpResponseMsg);
    //                     // PaytmResp('"totalRefundAmount":"', '"', 0, ResponseText);
    //                     WalletLogEntry."Bank Name" := CaptureRsponse('$.body.issuingBankName', gResponseMsg, gHttpResponseMsg);
    //                     // PaytmResp('"issuingBankName":"', '"', 0, ResponseText);
    //                     WalletLogEntry."Payment Mode" := CaptureRsponse('$.body.payMethod', gResponseMsg, gHttpResponseMsg);
    //                     // PaytmResp('"payMethod":"', '"', 0, ResponseText);
    //                     WalletLogEntry."Wallet TXN No." := CaptureRsponse('$.body.txnId', gResponseMsg, gHttpResponseMsg);
    //                     // PaytmResp('"txnId":"', '"', 0, ResponseText);
    //                     WalletLogEntry.RefundID := CaptureRsponse('$.body.refundId', gResponseMsg, gHttpResponseMsg);
    //                     // PaytmResp('"refundId":"', '"', 0, ResponseText);

    //                     IF SAmt <> '' THEN
    //                         EVALUATE(LAmt, SAmt);
    //                     IF WalletLogEntry."Wallet TXN No." = '' THEN
    //                         ERROR('Transaction not completed try Again');
    //                     WalletLogEntry."Payment Validated" := TRUE;
    //                     WalletLogEntry.Amount := LAmt;
    //                     WalletLogEntry.MODIFY(TRUE);
    //                     EXIT(TRUE);
    //                 END;
    //             END
    //             ELSE BEGIN
    //                 IF Loop = FALSE THEN
    //                     ERROR(CaptureRsponse('$.body.resultInfo.resultStatus', gResponseMsg, gHttpResponseMsg) +
    //                      ':' + CaptureRsponse('$.body.resultInfo.resultMsg', gResponseMsg, gHttpResponseMsg))
    //                 ELSE BEGIN
    //                     SLEEP(5000);
    //                     VCnt += 1;
    //                     EXIT(ChkStatusRefund(lDateTime, lOrdID, TRUE, VCnt, TerminalID, lCurrOrdID));
    //                 END;
    //             END;
    //         END ELSE BEGIN  //Status not OK
    //             IF Loop = FALSE THEN BEGIN
    //                 ERROR(gResponseMsg);
    //             END
    //             ELSE BEGIN
    //                 SLEEP(5000);
    //                 VCnt += 1;
    //                 EXIT(ChkStatusRefund(lDateTime, lOrdID, TRUE, VCnt, TerminalID, lCurrOrdID));
    //             END;
    //         END;
    //         EXIT(FALSE);
    //     End;
    // End;

    // procedure ChkStatusTransEDCResend(lDateTime: Text; lOrdID: Text; Loop: Boolean; VAR VCnt: Integer; TerminalID: Code[20]; lSalesType: Code[20]): Decimal
    // var
    //     lBody: Text;
    //     RetailSetup: Record "LSC Retail Setup";
    //     POSTerminal: Record "LSC POS Terminal";
    //     FinalOrderNo: Code[30];
    //     ResponseText: Text;
    //     WalletLogEntry: Record "Wallet Log Entry";
    //     POSTransaction: Codeunit "LSC POS Transaction";
    //     Cnt: Integer;
    //     Checksum: DotNet Checksum;
    //     CheckSumStr: Text;
    //     lChecksum: Text;
    //     WinHttpService: HttpClient;
    //     gHttpClient: HttpClient;
    //     gContent: HttpContent;
    //     gHttpResponseMsg: HttpResponseMessage;
    //     gHttpRequestMsg: HttpRequestMessage;
    //     gContentHeaders: HttpHeaders;
    //     gResponseMsg: Text;
    //     SAmt: Text;
    //     LAmt: Decimal;
    // begin

    //     RetailSetup.GET;
    //     RetailSetup.TESTFIELD("Paytm QR Merchant ID");
    //     RetailSetup.TESTFIELD("Paytm QR Merchant Key");

    //     POSTerminal.GET(TerminalID);
    //     POSTerminal.TESTFIELD("Paytm EDC TID");

    //     WalletLogEntry.RESET;
    //     WalletLogEntry.SETCURRENTKEY("Store No.", "Receipt No.", "Function Type", voided);
    //     WalletLogEntry.SETRANGE("Receipt No.", lOrdID);
    //     WalletLogEntry.SETRANGE("Function Type", WalletLogEntry."Function Type"::Payment);
    //     WalletLogEntry.SETRANGE(voided, FALSE);
    //     WalletLogEntry.SETRANGE("Payment Validated", FALSE);
    //     IF WalletLogEntry.ISEMPTY THEN
    //         ERROR('Please Press PayTM Button')
    //     ELSE
    //         WalletLogEntry.FINDFIRST;

    //     IF VCnt > 3 THEN
    //         EXIT(0);

    //     CheckSumStr := WalletLogEntry.Reference + '|' + RetailSetup."Paytm QR Merchant ID" + '|' + lDateTime;
    //     lChecksum := Checksum.generateSignature(CheckSumStr, RetailSetup."Paytm QR Merchant Key");

    //     lBody := '{"head":{"version":"3.1","requestTimeStamp":"' + lDateTime + '","channelId":"EDC","checksum":"' + lChecksum + '"},' +
    //     '"body":{"merchantTransactionId":"' + WalletLogEntry.Reference + '","paytmMid":"' + RetailSetup."Paytm QR Merchant ID" + '","transactionDateTime":"' + lDateTime + '"}}';

    //     // MESSAGE(lBody);
    //     locautXmlHttp.open('POST', 'https://securegw-edc.paytm.in/ecr/V2/payment/status');
    //     locautXmlHttp.setRequestHeader('Content-Type', 'application/json');
    //     locautXmlHttp.send(lBody);
    //     // MESSAGE(locautXmlHttp.responseText);
    //     APILog(lBody, locautXmlHttp.responseText, 'SALESTATUSEDC');

    //     IF UPPERCASE(locautXmlHttp.statusText) = 'OK' THEN BEGIN
    //         ResponseText := locautXmlHttp.responseText;
    //         SAmt := '';
    //         LAmt := 0;
    //         IF UPPERCASE(PaytmResp('"resultStatus":"', '"', 0, ResponseText)) = 'SUCCESS' THEN BEGIN
    //             WalletLogEntry."Wallet TXN No." := PaytmResp('"acquirementId":"', '"', 0, ResponseText);
    //             SAmt := PaytmResp('"transactionAmount":"', '"', 0, ResponseText);
    //             WalletLogEntry."Bank Name" := PaytmResp('"issuingBankName":"', '"', 0, ResponseText);
    //             WalletLogEntry."Payment Mode" := PaytmResp('"payMethod":"', '"', 0, ResponseText);

    //             WalletLogEntry.retrievalReferenceNo := PaytmResp('"retrievalReferenceNo":"', '"', 0, ResponseText);
    //             WalletLogEntry.authCode := PaytmResp('"authCode":"', '"', 0, ResponseText);
    //             WalletLogEntry.issuerMaskCardNo := PaytmResp('"issuerMaskCardNo":"', '"', 0, ResponseText);
    //             WalletLogEntry.bankResponseMessage := PaytmResp('"bankResponseMessage":"', '"', 0, ResponseText);
    //             WalletLogEntry.bankResponseCode := PaytmResp('"bankResponseCode":"', '"', 0, ResponseText);
    //             WalletLogEntry.bankMid := PaytmResp('"bankMid":"', '"', 0, ResponseText);
    //             WalletLogEntry.bankTid := PaytmResp('"bankTid":"', '"', 0, ResponseText);
    //             WalletLogEntry.aid := PaytmResp('"aid":"', '"', 0, ResponseText);
    //             WalletLogEntry.cardType := PaytmResp('"cardType":"', '"', 0, ResponseText);

    //             IF SAmt <> '' THEN
    //                 EVALUATE(LAmt, SAmt);
    //             IF WalletLogEntry."Wallet TXN No." = '' THEN
    //                 ERROR('Transaction not completed try Again');
    //             WalletLogEntry."Payment Validated" := TRUE;
    //             WalletLogEntry.Amount := LAmt / 100;
    //             WalletLogEntry.MODIFY(TRUE);
    //             EXIT(LAmt / 100);

    //         END ELSE BEGIN
    //             //    WalletLogEntry.ErrorCode:=PaytmResp('"resultCodeId":"','"',0,ResponseText);
    //             //    WalletLogEntry.MODIFY;
    //             //    COMMIT;
    //             IF NOT Loop THEN
    //                 MESSAGE(PaytmResp('"resultStatus":"', '"', 0, ResponseText) + ':' + PaytmResp('"resultMsg":"', '"', 0, ResponseText))
    //             ELSE BEGIN
    //                 SLEEP(5000);
    //                 VCnt += 1;
    //                 EXIT(ChkStatusTransEDC(lDateTime, lOrdID, TRUE, VCnt, TerminalID, lSalesType));
    //             END;
    //         END;
    //     END ELSE BEGIN  //Status not OK
    //         IF NOT Loop THEN BEGIN
    //             ERROR(locautXmlHttp.statusText);
    //         END
    //         ELSE BEGIN
    //             SLEEP(5000);
    //             VCnt += 1;
    //             EXIT(ChkStatusTransEDC(lDateTime, lOrdID, TRUE, VCnt, TerminalID, lSalesType));
    //         END;
    //     END;
    //     EXIT(0);
    // End;

    procedure CaptureRsponse(lResp: Text[100]; ActualResponse: Text; gHttpResponseMsg: HttpResponseMessage) ResponseText2: Text
    var
        JObject: JsonObject;
        StringBuilder: DotNet StringBuilder;
        StringWriter: DotNet StringWriter;
        JSON: DotNet String;
        Jtoken: JsonToken;
        JToken_1: JsonToken;
    begin

        gHttpResponseMsg.Content().ReadAs(ActualResponse);
        JObject.ReadFrom(ActualResponse);
        Jtoken.ReadFrom(ActualResponse);

        JObject.SelectToken(lResp, JToken_1);

        if not JToken_1.AsValue().IsNull then
            exit(JToken_1.AsValue().AsText());

    End;

    procedure GetJsonToken(Jsonobject: JsonObject; TokenKey: text) Jsontoken: JsonToken
    begin
        IF not Jsonobject.get(TokenKey, Jsontoken) THEN
            exit;
    end;


    procedure GetResponsesValue(resp3: Text; Lstr: Text; Strng: Text; Cnt: Integer): Text
    var
        mstr: Text;
        IntPos: Integer;
        i: Integer;
        Resp1: Text;
    begin
        IF STRPOS(resp3, Lstr) = 0 THEN
            EXIT('');

        FOR i := 1 TO Cnt DO BEGIN
            IntPos := STRPOS(resp3, Lstr) + STRLEN(Lstr);
            Resp1 := DELSTR(resp3, 1, IntPos);
            resp3 := Resp1;
        END;

        IF Lstr <> 'error' THEN BEGIN
            IF STRPOS(Resp1, Strng) <> 0 THEN
                Resp1 := COPYSTR(Resp1, 1, STRPOS(Resp1, Strng) - 1)
            ELSE
                Resp1 := COPYSTR(Resp1, 1, STRLEN(Resp1) - 1);

            Resp1 := SELECTSTR(1, Resp1);
        END;

        IF NOT (Lstr = 'StatusDate') THEN
            Resp1 := DELCHR(Resp1, '=', ' ');

        Resp1 := DELCHR(Resp1, '=', '"');
        Resp1 := DELCHR(Resp1, '<', ':');

        EXIT(Resp1);
    end;



    procedure EDCAPILog(RequestJSON: Text; ResponseJSON: Text; LogFileName: Text; StoreID: Code[20])
    var
        FileName: Text;
        MyFile: File;
        Data: BigText;
        ins: InStream;
        outs: OutStream;
        StoreSetup: Record "LSC Store";
    begin
        //Create API Logs Detailing  
        StoreSetup.GET(StoreID);
        StoreSetup.TESTFIELD("Ezetap Logs Path");
        FileName := StoreSetup."Ezetap Logs Path" + LogFileName + FORMAT(Today, 0, 6) + FORMAT(TIME, 0, '<Hours><Minutes><Seconds>') + '.txt';

        IF NOT EXISTS(FileName) THEN BEGIN
            MyFile.CREATE(FileName);
            MyFile.CLOSE;
        END;

        MyFile.TEXTMODE(TRUE);
        MyFile.WRITEMODE(TRUE);
        MyFile.OPEN(FileName);
        REPEAT
            MyFile.READ(FileName);
        UNTIL MyFile.POS = MyFile.LEN;
        MyFile.WRITE('');
        MyFile.WRITE(CURRENTDATETIME);
        MyFile.WRITE(RequestJSON);
        MyFile.WRITE('');
        MyFile.WRITE('RESPONSE:  ');
        MyFile.WRITE(ResponseJSON);
        MyFile.CLOSE;

    End;

    procedure EDCLsLog(EDCMachine: option PineLabs,Paytm,Ezetap; PayTransactionID: Text[64]; TransactionType: Option Payment,Refund,QR;
                         WalletType: Option Payment,Wallet,"SMS Link"; "LstoreNo.": Code[20]; WalletOrdNo: Code[30];
                         LAmt: Decimal; LrecNo: Code[30]; LRecLineNo: Integer; LQRCheckSUm: Text[500];
                         LinkIDPaytm: Code[20]; lSalesType: Code[20]; gRespMsg: Text; gHttpResponseMsg: HttpResponseMessage)
    var
        WalletLogEntry: Record "Wallet Log Entry";
        PosCode: Integer;
        EntryNo: Integer;
        WalletLogEntry1: Record "Wallet Log Entry";
    begin
        PosCode := 0;
        WalletLogEntry.RESET;
        IF WalletLogEntry.FINDLAST THEN
            EntryNo := WalletLogEntry."Entry No." + 1
        ELSE
            EntryNo := 1;

        WalletLogEntry1.INIT;
        WalletLogEntry1.p2pRequestId := p2pRequestId;
        WalletLogEntry1."Device ID" := RequestDeviceId;
        WalletLogEntry1.Mode := RequestMode;
        WalletLogEntry1."Entry No." := EntryNo;
        WalletLogEntry1."EDC Machine" := EDCMachine;
        WalletLogEntry1."Function Type" := TransactionType;
        WalletLogEntry1."Wallet Type" := 0;
        IF WalletType = WalletType::"SMS Link" THEN
            WalletLogEntry1."Wallet Type" := WalletLogEntry1."Wallet Type"::"SMS Link";
        IF WalletLogEntry1."Function Type" <> 1 THEN
            WalletLogEntry1.Amount := LAmt
        ELSE
            WalletLogEntry1.Amount := -1 * LAmt;
        WalletLogEntry1."Receipt No." := LrecNo;

        //WalletLogEntry1."Org. Rcpt No." := LrecNo;
        WalletLogEntry1."POS Code Merger" := PosCode;
        WalletLogEntry1."Store No." := "LstoreNo.";
        WalletLogEntry1."Trans Date" := TODAY;
        WalletLogEntry1."Trans Time" := TIME;
        if LrecNo = 'VOID' then begin
            WalletLogEntry1.voided := true;
            WalletLogEntry1."Wallet TXN No." := LrecNo;
        end;

        WalletLogEntry1.Reference := WalletOrdNo;
        WalletLogEntry1."Receipt Line No" := LRecLineNo;
        WalletLogEntry1.INSERT(TRUE);
    end;

}
//FBTS SP
