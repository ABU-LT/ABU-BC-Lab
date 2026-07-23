namespace DefaultPublisher.Sticky_Notes;

page 70026 "LAB Sticky Note Share List"
{
    Caption = 'Sticky Note Share';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LAB Sticky Note Share";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user this note is shared with.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentNoteId := Rec.GetRangeMin("Note ID");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Note ID" := CurrentNoteId;
    end;

    var
        CurrentNoteId: Guid;
}
