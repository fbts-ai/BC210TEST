tableextension 50104 "PosTransactionExt" extends "LSC POS Transaction"
{
    fields
    {
        field(70000; "Custom Sales Type"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "LSC Sales Type";
        }

    }
}