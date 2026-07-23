namespace DefaultPublisher.Sticky_Notes;

using System.Security.AccessControl;
using System.Security.User;


table 70025 "LAB Sticky Note Share"
{
    Caption = 'Sticky Note Share';
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "Note ID"; Guid)
        {
            Caption = 'Note ID';
            TableRelation = "LAB Sticky Note"."Note ID";
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(3; "Position Left"; Integer)
        {
            Caption = 'Position Left';
        }
        field(4; "Position Top"; Integer)
        {
            Caption = 'Position Top';
        }
        field(5; "Width"; Integer)
        {
            Caption = 'Width';
        }
        field(6; "Height"; Integer)
        {
            Caption = 'Height';
        }
    }

    keys
    {
        key(PK; "Note ID", "User ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        StickyNote: Record "LAB Sticky Note";
        OtherShare: Record "LAB Sticky Note Share";
    begin
        if StickyNote.Get("Note ID") then begin
            "Position Left" := StickyNote."Position Left";
            "Position Top" := StickyNote."Position Top";
            "Width" := StickyNote."Width";
            "Height" := StickyNote."Height";

            OtherShare.SetRange("Note ID", "Note ID");
            if OtherShare.IsEmpty() then
                StickyNote.MigrateNoteTextScope(true);
        end;
    end;

    trigger OnDelete()
    var
        StickyNote: Record "LAB Sticky Note";
        OtherShare: Record "LAB Sticky Note Share";
    begin
        OtherShare.SetRange("Note ID", "Note ID");
        OtherShare.SetFilter("User ID", '<>%1', "User ID");
        if OtherShare.IsEmpty() then
            if StickyNote.Get("Note ID") then
                StickyNote.MigrateNoteTextScope(false);
    end;
}
