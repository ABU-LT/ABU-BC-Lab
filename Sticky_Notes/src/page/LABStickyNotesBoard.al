namespace DefaultPublisher.Sticky_Notes;
using System.Security.Encryption;

page 70023 "LAB Sticky Notes Board"
{
    Caption = 'Sticky Notes Board';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            usercontrol(StickyNotesControl; "LAB Sticky Notes")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    CurrPage.StickyNotesControl.LoadData(this.StickyNoteMgt.BuildNotesJson());
                end;

                trigger SaveNotes(jsonData: Text)
                begin
                    this.StickyNoteMgt.ApplyNotesJson(jsonData);
                    CurrPage.StickyNotesControl.LoadData(this.StickyNoteMgt.BuildNotesJson());
                end;

                trigger DeleteNote(noteId: Text)
                begin
                    this.StickyNoteMgt.DeleteNote(noteId);
                end;

                trigger CreateNote()
                var
                    NewNoteId: Text;
                begin
                    NewNoteId := this.StickyNoteMgt.CreateBlankNote();
                    CurrPage.StickyNotesControl.NoteCreated(NewNoteId);
                end;

                trigger CreateUserTask(title: Text; noteText: Text)
                begin
                    this.StickyNoteMgt.CreateUserTaskFromNote(title, noteText);
                end;

                trigger ShareNote(noteId: Text)
                var
                    StickyNoteShare: Record "LAB Sticky Note Share";
                    NoteIdGuid: Guid;
                begin
                    if not Evaluate(NoteIdGuid, noteId) then
                        exit;
                    StickyNoteShare.SetRange("Note ID", NoteIdGuid);
                    Page.RunModal(Page::"LAB Sticky Note Share List", StickyNoteShare);
                    CurrPage.StickyNotesControl.LoadData(this.StickyNoteMgt.BuildNotesJson());
                end;
            }
        }
    }

    var
        StickyNoteMgt: Codeunit "LAB Sticky Note Mgt";






}
