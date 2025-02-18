report 50034 "Stock Audit Report"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = 'SRC/Report/Stock Audit.rdl';
    Caption = 'Stock Audit Report';
    dataset
    {
        dataitem(StockInsertHeader; StockInsertHeader)
        {
            column(Location_Code; "Location Code")
            { }
            column(Item_No_; "Item No.")
            { }
            column(Description; Description)
            { }
            column(UOM; UOM)
            { }
            column(Stock; Stock)
            { }
            column(Store; Store)
            { }
            column(Date_; Date_)
            { }
            column(Unposted_Sales; Unposted_Sales)
            { }
            column(SaleQty; sumQty)
            { }
            trigger OnAfterGetRecord()
            var
                myInt: Integer;
            begin



                SetRange("Location Code", Store);
                Clear(SalesQty);
                Clear(BomCom_gVar);
                Clear(QtyPer);
                Clear(sumQty);
                // TransSalesEntry.Reset();
                // TransSalesEntry.SetRange("Item No.", StockInsertHeader."Item No.");
                // TransSalesEntry.SetRange(Date, Today);
                // TransSalesEntry.CalcSums(Quantity);
                // SalesQty += TransSalesEntry.Quantity;
                BomCom_gVar.Reset();
                BomCom_gVar.SetCurrentKey("No.");
                BomCom_gVar.SetRange("No.", StockInsertHeader."Item No.");
                if BomCom_gVar.Findset() then begin

                    repeat
                        I_Uom.Reset();
                        I_Uom.SetRange("Item No.", BomCom_gVar."No.");
                        I_Uom.SetRange(Code, BomCom_gVar."Unit of Measure Code");
                        if I_Uom.FindFirst() then
                            QtyPer := I_Uom."Qty. per Unit of Measure";
                        Bomqty := BomCom_gVar."Quantity per";
                        ItemNo_gvar := BomCom_gVar."Parent Item No.";
                        // sumQty1 := 0;
                        TransSalesEntry.Reset();
                        TransSalesEntry.SetRange("Store No.", StockInsertHeader."Location Code");
                        TransSalesEntry.SetRange("Item No.", ItemNo_gvar);
                        TransSalesEntry.SetRange(Date, Today);
                        TransSalesEntry.CalcSums(Quantity);
                        SalesQty := TransSalesEntry.Quantity * BomCom_gVar."Quantity per" * QtyPer;
                        // sumQty1 := TransSaleEntry_gVar.Quantity;
                        sumQty += TransSalesEntry.Quantity * BomCom_gVar."Quantity per" * QtyPer;
                    until BomCom_gVar.Next() = 0;

                end;

            end;
        }
    }
    requestpage
    {
        AboutTitle = 'Teaching tip title';
        AboutText = 'Teaching tip content';
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(Store; Store)
                    {
                        ApplicationArea = All;
                        TableRelation = "LSC Store";

                        trigger OnValidate()
                        var
                            myInt: Integer;
                        begin
                            //StockInsertHeader.SetRange("Location Code", Store);

                        end;
                    }
                }
            }
        }

        actions
        {
            area(processing)
            {
                action(LayoutName)
                {
                    ApplicationArea = All;

                }
            }
        }
    }
    trigger OnPostReport()
    begin

    end;

    trigger OnPreReport()
    begin
        Clear(InventorySetup);
        InventorySetup.GEt;
        // BlisterHeader_lNos := '';
        // Clear(LineNo);
        // Clear(POQty);
        // Clear(Item);
        //Clear(Store);
        StockInsertHeader.DeleteAll();
        URL := 'http://10.20.0.7:1122/api/values/stockaudit?store=' + Store;
        IF HttpClient.Get(URL, HttpResponseMessage) then begin
            HttpResponseMessage.Content.ReadAs(Response);
            Response := DelChr(Response, '=', '\/');
            Response := CopyStr(Response, 2, StrLen(Response) - 2);
            // Message('%1', Response);
            if JsonArray.ReadFrom(Response) then begin
                for Index := 0 to JsonArray.Count() - 1 do begin
                    if JsonArray.Get(Index, JsonToken) then begin
                        JsonObject1 := JsonToken.AsObject();

                        if JsonObject1.Get('Location Code', JsonToken1) then begin
                            StoreNo := JsonToken1.AsValue().AsText();
                        end;
                        if JsonObject1.Get('Item Category Code', JsonToken1) then begin
                            ItemCategoryCode := JsonToken1.AsValue().AsText();
                        end;
                        if JsonObject1.Get('Item No_', JsonToken1) then begin
                            ItemNo := JsonToken1.AsValue().AsText();
                        end;
                        if JsonObject1.Get('Description', JsonToken1) then begin
                            Description := JsonToken1.AsValue().AsText();
                        end;
                        if JsonObject1.Get('UOM', JsonToken1) then begin
                            UOM := JsonToken1.AsValue().AsText();
                        end;
                        if JsonObject1.Get('Stock', JsonToken1) then begin
                            Stock := JsonToken1.AsValue().AsText();
                            Evaluate(Stock_ldec, Stock);
                        end;
                        if JsonObject1.Get('Unposted_Sales', JsonToken1) then begin
                            Sale_Quantity := JsonToken1.AsValue().AsText();
                            Evaluate(Unposted_Sales_ldec, Sale_Quantity);
                        end;
                        if JsonObject1.Get('Net_Stock', JsonToken1) then begin
                            Adj_Required := JsonToken1.AsValue().AsText();
                            Evaluate(Net_Stock_dec, Adj_Required);
                        end;
                        StockInsertHeader1.Reset();
                        StockInsertHeader1.SetRange("Location Code", StoreNo);
                        StockInsertHeader1.SetRange("Item No.", ItemNo);
                        IF Not StockInsertHeader1.FindFirst() then begin
                            StockInsertHeader.Init();
                            StockInsertHeader."Location Code" := StoreNo;
                            StockInsertHeader.Description := Description;
                            StockInsertHeader."Item No." := ItemNo;
                            StockInsertHeader.Stock := Stock_lDec;
                            StockInsertHeader.Net_Stock := Net_Stock_dec;
                            StockInsertHeader.Stock := Stock_lDec;
                            StockInsertHeader.Unposted_Sales := Unposted_Sales_ldec;
                            StockInsertHeader.UOM := uom;
                            StockInsertHeader.Insert();
                            StockInsertHeader.Modify();
                        end;
                    end;
                end;
            end;
        end;
    end;

    var
        Store: Code[20];
        // ExcelBuf: Record "Excel Buffer" temporary;
        // ReportCaption: Label 'Posted Transfer Receipts';
        // LSCBarcodes: Record "LSC Barcodes";
        // LineNo: Integer;
        // ItemQty: Decimal;
        // BlisterHeader_lNos: Code[20];
        // Transfer1_lRec: Record "Transfer Line";
        // POQty: Decimal;
        // TransferLine3: Record "Transfer Line";
        // TransferLine1: Record "Transfer Line";
        // TransferLine: Record "Transfer Line";
        // TransferLine4: Record "Transfer Line";
        // Item: Record item;
        // TaxCaseExecution: Codeunit "Use Case Execution";
        // ItemLedgerEntry: Record "Item Ledger Entry";
        // TransferShipmentLine: Record "Transfer Shipment Line";

        URL: Text;
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        Response: Text;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        JsonObject: JsonObject;
        JSONManagement: Codeunit "JSON Management";
        ArrayJSONManagement: Codeunit "JSON Management";
        ObjectJSONManagement: Codeunit "JSON Management";
        Index: Integer;
        Value: text;
        ItemJsonobject: text;
        JsonObject1: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonToken1: JsonToken;
        ItemNo: Code[20];
        ItemCategoryCode: Code[20];
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        BomCom_gVar: Record "BOM Component";
        QtyPer: Decimal;
        I_Uom: Record "Item Unit of Measure";
        ItemNo_gvar: Code[100];
        // QtyPer: Decimal;
        VariantCode: Code[20];
        StockInsertHeader_: record StockInsertHeader;
        StockInsertHeader1: record StockInsertHeader;
        StockInsertHeader2: record StockInsertHeader;
        StoreNo: Text;
        Date_: text;

        Description: Text;
        UOM: Text;
        Sale_Quantity: text;
        Stock: text;
        Stock_lDec: Decimal;

        Adj_Required: Text;
        Pending_Receiving: Text;
        Expected_Pur_Receiving:
                    Text;
        Expected_Pur_Receiving_lDec: decimal;
        Date_lDat: Date;
        Unposted_Sales_ldec: Decimal;
        Net_Stock_dec: Decimal;
        Pending_Receiving_ldec: Decimal;
        InventorySetup: Record "Inventory Setup";
        SalesQty: Decimal;
        Bomqty: Decimal;
        sumQty: Decimal;
}
