page 50150 StockInsertHeaderLists
{
    PageType = List;
    Caption = 'Stock Insert Header Lists';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = StockInsertHeader;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    var

                    begin


                        //Message('%1..%2',TransSalesEntry);
                        //Rec.Modify();
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }
                field("Item Category Code"; "Item Category Code")
                {
                    ApplicationArea = All;
                }

                field(Net_Stock; Net_Stock)
                {
                    ApplicationArea = All;
                }
                field(Stock; Stock)
                {
                    ApplicationArea = All;
                }
                field(UOM; UOM)
                {
                    ApplicationArea = All;
                }
                field(Unposted_Sales; Unposted_Sales)
                {
                    ApplicationArea = All;
                }
                field("Sales Qty"; "Sales Qty")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(GetValueData)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    LSCBarcodes: Record "LSC Barcodes";
                    LineNo: Integer;
                    ItemQty: Decimal;
                    BlisterHeader_lNos: Code[20];
                    Transfer1_lRec: Record "Transfer Line";
                    POQty: Decimal;
                    TransferLine3: Record "Transfer Line";
                    TransferLine1: Record "Transfer Line";
                    TransferLine: Record "Transfer Line";
                    TransferLine4: Record "Transfer Line";
                    Item: Record item;
                    TaxCaseExecution: Codeunit "Use Case Execution";
                    ItemLedgerEntry: Record "Item Ledger Entry";
                    TransferShipmentLine: Record "Transfer Shipment Line";

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
                    VariantCode: Code[20];
                    StockInsertHeader: record StockInsertHeader;
                    StockInsertHeader1: record StockInsertHeader;
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
                begin
                    Clear(InventorySetup);
                    InventorySetup.GEt;


                    BlisterHeader_lNos := '';
                    Clear(LineNo);
                    Clear(POQty);
                    Clear(Item);
                    URL := 'http://10.20.0.7:1122/api/values/stockaudit?store=S001';

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
                                    end;
                                end;
                            end;
                        end;

                    end;

                end;
            }
        }
    }
    var
        TransSalesEntry: Record "LSC Trans. Sales Entry";
}