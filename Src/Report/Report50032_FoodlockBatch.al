report 50032 FoodlockBatch
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where("Assembly BOM" = filter(true),
            "Gen. Prod. Posting Group" = filter('FG'), FoodLockStatus = filter(true));
            trigger OnAfterGetRecord()
            var
                FoodLock: Record FoodLock;
                RetUser: Record "LSC Retail User";
            begin
                IF RetUser.Get(UserId) then;
                // ItemRec.Get(Item."No.");
                // if ItemRec.FoodLockStatus = true then
                Item.Validate(FoodLockStatus, false);
                Item.Modify();

                FoodLock.Init();
                FoodLock.POSItemId := Item."No.";
                FoodLock.FoodLockStatus := false;
                FoodLock.StoreCode := RetUser."Store No.";
                FoodLock.Insert(True);
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

    var
        ItemRec: Record Item;
}