namespace ABU_BC_Lab.Apps.LuckySheet;

page 70007 "LAB LuckySheet Tbl. Setup List"
{
    Caption = 'LuckySheet Table Setup List';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "LAB LuckySheet Table Setup";
    CardPageId = "LAB LuckySheet Tbl. Setup Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                }
                field("Activate Modify Trigger"; Rec."Activate Modify Trigger")
                {
                    ApplicationArea = All;
                }
                field("Activate Insert Trigger"; Rec."Activate Insert Trigger")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
