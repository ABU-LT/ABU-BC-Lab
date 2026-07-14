namespace ABU_BC_Lab.Apps.LuckySheet;

page 70003 "LAB LuckySheet Setup"
{
    Caption = 'LuckySheet Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "LAB LuckySheet Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Show System Fields"; Rec."Show System Fields")
                {
                    ApplicationArea = All;
                }
            }
            group("Interface")
            {
                Caption = 'Interface';

                field("Show Toolbar"; Rec."Show Toolbar")
                {
                    ApplicationArea = All;
                }
                field("Show Formula Bar"; Rec."Show Formula Bar")
                {
                    ApplicationArea = All;
                }
                field("Show Sheet Tabs Bar"; Rec."Show Sheet Tabs Bar")
                {
                    ApplicationArea = All;
                }
                field("Show Info Bar"; Rec."Show Info Bar")
                {
                    ApplicationArea = All;
                }
                field("Show Statistic Bar"; Rec."Show Statistic Bar")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec := Rec.GetSetup();
    end;
}
