namespace DefaultPublisher.Sticky_Notes;

page 70028 "LAB Sticky Note Setup Card"
{
    Caption = 'Sticky Note Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "LAB Sticky Note Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Enable Note Encryption"; Rec."Enable Note Encryption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether sticky note text is stored encrypted. Can only be enabled before any sticky notes exist, and requires data encryption to be enabled on this server.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
