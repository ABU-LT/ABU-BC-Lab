namespace ABU_BC_Lab.Apps.LuckySheet;

page 70006 "LAB LuckySheet Tbl. Setup Card"
{
    Caption = 'LuckySheet Table Setup Card';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LAB LuckySheet Table Setup";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
            part(FieldSetupSubform; "LAB LuckySheet Field Setup Sub")
            {
                ApplicationArea = All;
                Caption = 'Fields';
                SubPageLink = "Table ID" = field("Table ID");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateFieldList)
            {
                ApplicationArea = All;
                Caption = 'Update Field List';
                ToolTip = 'Adds any fields of the selected table that are not yet listed below.';
                Image = RefreshLines;

                trigger OnAction()
                var
                    FieldSetup: Record "LAB LuckySheet Field Setup";
                begin
                    if Rec."Table ID" = 0 then
                        Error('Select a table first.');
                    FieldSetup.PopulateFields(Rec."Table ID");
                    CurrPage.FieldSetupSubform.Page.Update(false);
                end;
            }
        }
    }
}
