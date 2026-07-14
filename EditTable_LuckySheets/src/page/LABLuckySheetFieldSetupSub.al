namespace ABU_BC_Lab.Apps.LuckySheet;

page 70008 "LAB LuckySheet Field Setup Sub"
{
    Caption = 'LuckySheet Field Setup';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "LAB LuckySheet Field Setup";
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                }
                field("Show in LuckySheet"; Rec."Show in LuckySheet")
                {
                    ApplicationArea = All;
                }
                field("Activate Field Validation"; Rec."Activate Field Validation")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
