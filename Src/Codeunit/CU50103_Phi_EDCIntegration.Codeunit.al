Codeunit 50103 "Phi_EDC Integration"
{
    trigger OnRun()

    var
        Body: Text;
        Stateposition: Integer;
        ILevel: Text;
    begin
        //    Body:='{"aggregatorId": "J_00038",'+
        //    '"invoiceNo": "301415","merchantId": "T_00230",'+
        //    '"posAppId": "pos123qwg","posTillNo": "Bial123",'+
        //    '"referenceNo": "301415","respDescription": "Invoice created successfully",'+
        //    '"responseCode": "0000","storeCode": "BIALT001","txnID": "301415"}';
        //  Stateposition:=STRPOS(Body,'"responseCode":');
        //  ILevel:=COPYSTR(Body,Stateposition,50);
        //  MESSAGE(SELECTSTR(1,CONVERTSTR(ILevel,'"',',')));
        //  MESSAGE(SELECTSTR(2,CONVERTSTR(ILevel,'"',',')));
        //  MESSAGE(SELECTSTR(3,CONVERTSTR(ILevel,'"',',')));
        //  MESSAGE(SELECTSTR(4,CONVERTSTR(ILevel,'"',',')));
    end;


    procedure CreateInvoice(RcptNo: Code[30]; StoreNo: Code[20]; TerminalNo: Code[20]; lAmt: Text; ReceiptNo: Code[20]): Boolean
    var
        WinHttpService: HttpClient;
        gHttpClient: HttpClient;
        gContent: HttpContent;
        gHttpResponseMsg: HttpResponseMessage;
        gHttpRequestMsg: HttpRequestMessage;
        gContentHeaders: HttpHeaders;
        lBody: Text;
        lAmtTxt: Text;
        JsonBody: Text;
        RetailSetup: Record TwcApiSetupUrl;
        lTerminal: Record 99001471;
        AmtDec: Decimal;
        Stateposition: Integer;
        ILevel: Text;
        ResponseCode: Text;
        ErrorLevel: Text;
        ErrorResponseMsg: Text;
        Resposition: Integer;
        ILevelResp: Text;
        gResponseMsg: Text;
        lResponseTxt: Text;
    begin
        RetailSetup.Get;
        RetailSetup.TestField("Phi_EDCInvoice URL");

        lTerminal.Get(TerminalNo);
        Evaluate(AmtDec, lAmt);
        if AmtDec < 0 then
            Error('Amount cannot be Negative');

        JsonBody := '{"aggregatorId":"' + lTerminal.Phi_aggregatorId + '","callbackURL":"https://qa.phicommerce.com/pg/api/merchant",' +
        '"chargeAmount":"' + Format(AmtDec, 0, '<Precision,2:2><Standard Format,2>') + '","currencyCode":"356","desc":"Invoice ' + RcptNo + '","posAppId":"' + lTerminal.Phi_posAppId + '",' +
        '"posTillNo":"' + lTerminal.Phi_posTillNo + '","referenceNo":"' + RcptNo + '","storeCode":"BIAL0003"}';

        Message(JsonBody);
        ClearLastError();
        Clear(gResponseMsg);
        gContent.WriteFrom(JsonBody);
        gContent.GetHeaders(gContentHeaders);
        gContentHeaders.Clear();
        gContentHeaders.Add('Content-Type', 'application/json');
        gHttpClient.DefaultRequestHeaders().Add('secureHash', secureHash(JsonBody));
        if gHttpClient.Post(RetailSetup."Phi_EDCInvoice URL", gContent, gHttpResponseMsg) then begin
            gHttpResponseMsg.Content.ReadAs(gResponseMsg);
            Message(gResponseMsg);

            //Logs Generate
            EdcAPILog(JsonBody, gResponseMsg, 'SENDTOEDC', StoreNo);
            //Logs Generate
            if gHttpResponseMsg.IsSuccessStatusCode then begin
                Stateposition := StrPos(gResponseMsg, '"responseCode":');
                if Stateposition = 0 then begin
                    Message(gResponseMsg);
                    exit(false);

                end else begin
                    //RespDesc
                    lResponseTxt := '';
                    Resposition := StrPos(gResponseMsg, '"respDescription":');
                    if Resposition <> 0 then begin
                        ILevelResp := CopyStr(gResponseMsg, Resposition, 200);
                        lResponseTxt := SelectStr(4, ConvertStr(ILevelResp, '"', ','));
                    end;
                    //RespDesc
                    ResponseCode := '';
                    if Stateposition <> 0 then begin
                        ILevel := CopyStr(gResponseMsg, Stateposition, 50);
                        ResponseCode := SelectStr(4, ConvertStr(ILevel, '"', ','));
                    end;
                    if ResponseCode <> '0000' then begin
                        //      ErrorLevel:=COPYSTR(LocalXmlVar.responseText,Stateposition,50);
                        //      ErrorResponseMsg:=SELECTSTR(4,CONVERTSTR(ErrorLevel,'"',','));
                        InsertTransactionLog(RcptNo, StoreNo, TerminalNo, AmtDec, ResponseCode, lResponseTxt, ReceiptNo, false);
                        Error('Error Response ' + ResponseCode + ':' + lResponseTxt);
                    end else begin
                        InsertTransactionLog(RcptNo, StoreNo, TerminalNo, AmtDec, ResponseCode, lResponseTxt, ReceiptNo, false);
                        exit(true);
                    end;
                end;
            end else
                Error('Network/Connection Error ' + Format(gHttpResponseMsg.HttpStatusCode) + ':' + format(gHttpResponseMsg.IsSuccessStatusCode));

        End;
    end;


    procedure RefundInvoice(RcptNo: Code[30]; StoreNo: Code[20]; TerminalNo: Code[20]; lAmt: Text; RefReceiptNo: Code[50]; TranType: Code[10]): Boolean
    var
        WinHttpService: HttpClient;
        gHttpClient: HttpClient;
        gContent: HttpContent;
        gHttpResponseMsg: HttpResponseMessage;
        gHttpRequestMsg: HttpRequestMessage;
        gContentHeaders: HttpHeaders;
        JsonBody: Text;
        RetailSetup: Record TwcApiSetupUrl;
        lTerminal: Record 99001471;
        AmtDec: Decimal;
        Stateposition: Integer;
        ILevel: Text;
        ResponseCode: Text;
        ErrorLevel: Text;
        ErrorResponseMsg: Text;
        Resposition: Integer;
        ILevelResp: Text;
        lResponseTxt: Text;
        POSTransaction: Codeunit "LSC POS Transaction";
        gResponseMsg: Text;
    begin
        RetailSetup.Get;
        RetailSetup.TestField("Phi_EDCRefund URL");


        lTerminal.Get(TerminalNo);
        Evaluate(AmtDec, lAmt);
        if AmtDec < 0 then
            Error('Amount cannot be Negative');

        JsonBody := '{"aggregatorId":"' + lTerminal.Phi_aggregatorId + '",' +
        '"amount":"' + Format(AmtDec, 0, '<Precision,2:2><Standard Format,2>') + '","invoiceNo":"' + RefReceiptNo + '","posAppId":"' + lTerminal.Phi_posAppId + '","posTillNo":"' + lTerminal.Phi_posTillNo + '",' +
        '"referenceNo":"' + RcptNo + '","storeCode":"BIAL0003","transactionType":"' + TranType + '"}';

        ClearLastError();
        Clear(gResponseMsg);
        gContent.WriteFrom(JsonBody);
        gContent.GetHeaders(gContentHeaders);
        gContentHeaders.Clear();
        gContentHeaders.Add('Content-Type', 'application/json');
        gHttpClient.DefaultRequestHeaders().Add('secureHash', secureHash(JsonBody));
        if gHttpClient.Post(RetailSetup."Phi_EDCRefund URL", gContent, gHttpResponseMsg) then begin
            gHttpResponseMsg.Content.ReadAs(gResponseMsg);
            //Logs Generate
            EdcAPILog(JsonBody, gResponseMsg, 'SENDTOEDCrefund', StoreNo);
            //Logs Generate
            if gHttpResponseMsg.IsSuccessStatusCode then begin
                Stateposition := StrPos(gResponseMsg, '"responseCode":');
                if Stateposition = 0 then begin
                    Message(gResponseMsg);
                    exit(false);
                end else begin
                    //RespDesc
                    lResponseTxt := '';
                    Resposition := StrPos(gResponseMsg, '"respDescription":');
                    if Resposition <> 0 then begin
                        ILevelResp := CopyStr(gResponseMsg, Resposition, 200);
                        lResponseTxt := SelectStr(4, ConvertStr(ILevelResp, '"', ','));
                    end;
                    //RespDesc
                    ResponseCode := '';
                    InsertTransactionLog(RefReceiptNo, StoreNo, TerminalNo, AmtDec, ResponseCode, lResponseTxt, RcptNo, true);
                    //   if POSTransaction.Phi_CheckStatusPressed('') then  //Rinku  Will use this function later
                    exit;
                    if Stateposition <> 0 then begin
                        ILevel := CopyStr(gResponseMsg, Stateposition, 50);
                        ResponseCode := SelectStr(4, ConvertStr(ILevel, '"', ','));
                    end;
                    if ResponseCode <> 'P1000' then begin
                        //      ErrorLevel:=COPYSTR(LocalXmlVar.responseText,Stateposition,50);
                        //      ErrorResponseMsg:=SELECTSTR(4,CONVERTSTR(ErrorLevel,'"',','));
                        InsertTransactionLog(RefReceiptNo, StoreNo, TerminalNo, AmtDec, ResponseCode, lResponseTxt, RcptNo, true);
                        Error('Error Response ' + ResponseCode + ':' + lResponseTxt);
                    end else begin
                        InsertTransactionLog(RefReceiptNo, StoreNo, TerminalNo, AmtDec, ResponseCode, lResponseTxt, RcptNo, true);
                        //   POSTransaction.Phi_CheckStatusPressed('');  //Rinku  Will use this function later
                        exit(true);
                    end;
                End;
            end else
                Error('Network/Connection Error ' + Format(gHttpResponseMsg.HttpStatusCode) + ':' + format(gHttpResponseMsg.IsSuccessStatusCode));
        end;
    End;

    procedure CheckStatus(OrgRcptNo: Code[30]; StoreNo: Code[20]; TerminalNo: Code[20]; lAmt: Text; var ResponseTxt: Text; ReceiptNo: Code[20]; ErrorFlag: Text[1]): Boolean
    var
        WinHttpService: HttpClient;
        gHttpClient: HttpClient;
        gContent: HttpContent;
        gHttpResponseMsg: HttpResponseMessage;
        gHttpRequestMsg: HttpRequestMessage;
        gContentHeaders: HttpHeaders;
        JsonBody: Text;
        RetailSetup: Record TwcApiSetupUrl;
        lTerminal: Record "LSC POS Terminal";
        AmtDec: Decimal;
        Stateposition: Integer;
        ILevel: Text;
        ResponseCode: Text;
        ErrorLevel: Text;
        ErrorResponseMsg: Text;
        Resposition: Integer;
        ILevelResp: Text;
        lResponseTxt: Text;
        gResponseMsg: Text;
    begin
        RetailSetup.Get;
        RetailSetup.TestField("Phi_EDCStatus URL");


        lTerminal.Get(TerminalNo);
        Evaluate(AmtDec, lAmt);
        if AmtDec < 0 then
            Error('Amount cannot be Negative');

        JsonBody := '{"aggregatorId":"' + lTerminal.Phi_aggregatorId + '","invoiceNo":"' + OrgRcptNo + '",' +
            '"posAppId":"' + lTerminal.Phi_posAppId + '","referenceNo":"' + OrgRcptNo + '",' +
            '"storeCode":"BIAL0003","transactionType":"STATUS"}';

        ClearLastError();
        Clear(gResponseMsg);
        gContent.WriteFrom(JsonBody);
        gContent.GetHeaders(gContentHeaders);
        gContentHeaders.Clear();
        gContentHeaders.Add('Content-Type', 'application/json');
        gHttpClient.DefaultRequestHeaders().Add('secureHash', secureHash(JsonBody));
        if gHttpClient.Post(RetailSetup."Phi_EDCStatus URL", gContent, gHttpResponseMsg) then begin
            gHttpResponseMsg.Content.ReadAs(gResponseMsg);
            //Logs Generate
            EdcAPILog(JsonBody, gResponseMsg, 'SENDTOEDCstatus', StoreNo);
            //Logs Generate
            if gHttpResponseMsg.IsSuccessStatusCode then begin
                Stateposition := StrPos(gResponseMsg, '"txnResponseCode":');
                ResponseTxt := gResponseMsg;
                if Stateposition = 0 then begin
                    Message(gResponseMsg);
                    exit(false);
                end else begin
                    //RespDesc
                    lResponseTxt := '';
                    Resposition := StrPos(gResponseMsg, '"txnRespDescription":');
                    if Resposition <> 0 then begin
                        ILevelResp := CopyStr(gResponseMsg, Resposition, 200);
                        lResponseTxt := SelectStr(4, ConvertStr(ILevelResp, '"', ','));
                    end;
                    //RespDesc

                    ResponseCode := '';
                    if Stateposition <> 0 then begin
                        ILevel := CopyStr(gResponseMsg, Stateposition, 50);
                        ResponseCode := SelectStr(4, ConvertStr(ILevel, '"', ','));
                    end;
                    if ResponseCode <> '0000' then begin
                        //      ErrorLevel:=COPYSTR(LocalXmlVar.responseText,Stateposition,50);
                        //      ErrorResponseMsg:=SELECTSTR(4,CONVERTSTR(ErrorLevel,'"',','));
                        InsertTransactionLog(OrgRcptNo, StoreNo, TerminalNo, AmtDec, ResponseCode, lResponseTxt, ReceiptNo, false);
                        if ErrorFlag = '1' then
                            Message('Error Response ' + ResponseCode + ':' + lResponseTxt)
                        else
                            Error('Error Response ' + ResponseCode + ':' + lResponseTxt);
                        exit(false);
                    end else begin
                        //      InsertTransactionLog(OrgRcptNo,StoreNo,TerminalNo,AmtDec,ResponseCode,lResponseTxt,ReceiptNo);
                        exit(true);
                    end;
                end;
            end else
                Error('Network/Connection Error ' + Format(gHttpResponseMsg.HttpStatusCode) + ':' + format(gHttpResponseMsg.IsSuccessStatusCode));
        end;
    End;

    local procedure secureHash(JsonMinify: Text): Text
    var
        HMACSHA256: dotnet HMACSHA256;
        KeyBytes: dotnet Array;
        JsonBytes: dotnet Array;
        Encoding: dotnet UTF8Encoding;
        HmacSH1Signature: Text;
        Convert: dotnet BitConverter;
        SysString: dotnet String;
        RetailSetup: Record TwcApiSetupUrl;
    begin
        RetailSetup.Get;
        RetailSetup.TestField("Phi_EDC SecretKey");

        KeyBytes := Encoding.UTF8.GetBytes(RetailSetup."Phi_EDC SecretKey");
        JsonBytes := Encoding.UTF8.GetBytes(JsonMinify);

        HMACSHA256 := HMACSHA256.HMACSHA256(KeyBytes);
        // Crypto.Key:=BytesK;
        SysString := Convert.ToString(HMACSHA256.ComputeHash(JsonBytes));
        SysString := SysString.Replace('-', '');
        HmacSH1Signature := SysString.ToLower;

        // MESSAGE(HmacSH1Signature);
        exit(HmacSH1Signature);
    end;

    local procedure InsertTransactionLog(OrderID: Code[30]; StoreNo: Code[20]; TerminalNo: Code[20]; lAmt: Decimal; RespCode: Text; RespTxt: Text; RcptNo: Code[20]; RefundFlag: Boolean)
    var
        Phi_EDCLogEntry: Record "Phi_EDC Log Entry";
        EDCLogEntry: Record "Phi_EDC Log Entry";
    begin
        Phi_EDCLogEntry.Reset;

        if RefundFlag then
            Phi_EDCLogEntry.SetRange(invoiceNo, RcptNo)
        else
            Phi_EDCLogEntry.SetRange(invoiceNo, OrderID);
        if Phi_EDCLogEntry.FindFirst then begin
            Phi_EDCLogEntry."Store No." := StoreNo;
            Phi_EDCLogEntry."Trans Date" := Today;
            Phi_EDCLogEntry."Trans Time" := Time;
            Phi_EDCLogEntry.Amount := lAmt;
            Phi_EDCLogEntry.responseCode := RespCode;
            Phi_EDCLogEntry.respDescription := RespTxt;
            if RefundFlag then
                Phi_EDCLogEntry."Function Type" := Phi_EDCLogEntry."function type"::Refund;
            Phi_EDCLogEntry.Modify(true);
        end else begin
            Phi_EDCLogEntry.Init;
            //  Phi_EDCLogEntry."Receipt No.":=RcptNo;
            Phi_EDCLogEntry.invoiceNo := OrderID;
            EDCLogEntry.Reset;
            if EDCLogEntry.FindLast then begin
                Phi_EDCLogEntry."Entry No." := EDCLogEntry."Entry No." + 1;
                Phi_EDCLogEntry."Receipt Line No" := EDCLogEntry."Receipt Line No" + 1;
            end else begin
                Phi_EDCLogEntry."Entry No." := 1;
                Phi_EDCLogEntry."Receipt Line No" := 1;
            end;
            Phi_EDCLogEntry."Receipt No." := RcptNo;
            Phi_EDCLogEntry."Store No." := StoreNo;
            Phi_EDCLogEntry."Trans Date" := Today;
            Phi_EDCLogEntry."Trans Time" := Time;
            Phi_EDCLogEntry.Amount := lAmt;
            Phi_EDCLogEntry.responseCode := RespCode;
            Phi_EDCLogEntry.respDescription := RespTxt;
            if RefundFlag then
                Phi_EDCLogEntry."Function Type" := Phi_EDCLogEntry."function type"::Refund;
            Phi_EDCLogEntry.Insert(true);
        end;
        Commit;
    end;

    local procedure EDCAPILog(RequestJSON: Text; ResponseJSON: Text; LogFileName: Text; StoreID: Code[20])
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
        MyFile: File;
        RetailSetup: Record "LSC Retail Setup";
        Data: BigText;
        ins: InStream;
        outs: OutStream;
        TempBLOB: codeunit "Temp Blob";
        StoreSetup: Record "Lsc Store";
    begin
        //Create API Logs Detailing  
        StoreSetup.GET(StoreID);
        if StoreSetup."Ezetap Logs Path" = '' then
            Exit;
        // StoreSetup.TESTFIELD("EDC Logs Path");
        // IF NOT FileManagement.ClientDirectoryExists(RetailSetup."EDC Logs Path") THEN
        //     FileManagement.CreateClientDirectory(RetailSetup."EDC Logs Path");

        FileName := StoreSetup."Ezetap Logs Path" + 'Phi_' + LogFileName + FORMAT(Today, 0, 6) + FORMAT(TIME, 0, '<Hours><Minutes><Seconds>') + '.txt';
        RetailSetup.GET;

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

        // Data.AddText(RequestJSON);
        // Data.AddText('  ');
        // Data.AddText('RESPONSE:  ');
        // Data.AddText(ResponseJSON);
        // TempBLOB.CreateOutStream(outs);
        // Data.Write(outs);
        // TempBLOB.CreateInStream(ins);
        // DownloadFromStream(
        //     ins,  // InStream to save
        //     '',   // Not used in cloud
        //     StoreSetup."EDC Logs Path",   // Not used in cloud
        //     '',   // Not used in cloud
        //     filename); // Filename is browser download folder

    End;

}

