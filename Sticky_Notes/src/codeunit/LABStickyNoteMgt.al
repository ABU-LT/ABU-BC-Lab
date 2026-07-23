namespace DefaultPublisher.Sticky_Notes;

using Microsoft.Foundation.Task;
using System.Security.Encryption;

codeunit 70022 "LAB Sticky Note Mgt"
{
    procedure BuildNotesJson(): Text
    var
        StickyNote: Record "LAB Sticky Note";
        StickyNoteShare: Record "LAB Sticky Note Share";
        SeenNoteIds: Dictionary of [Guid, Boolean];
        Notes: JsonArray;
        Payload: JsonArray;
        OutText: Text;
    begin
        StickyNote.SetRange("User ID", CopyStr(UserId(), 1, 50));
        if StickyNote.FindSet() then
            repeat
                AddNoteToJson(Notes, StickyNote, StickyNote."Position Left", StickyNote."Position Top", StickyNote."Width", StickyNote."Height");
                SeenNoteIds.Add(StickyNote."Note ID", true);
            until StickyNote.Next() = 0;

        StickyNoteShare.SetRange("User ID", CopyStr(UserId(), 1, 50));
        if StickyNoteShare.FindSet() then
            repeat
                if not SeenNoteIds.ContainsKey(StickyNoteShare."Note ID") then
                    if StickyNote.Get(StickyNoteShare."Note ID") then begin
                        AddNoteToJson(Notes, StickyNote, StickyNoteShare."Position Left", StickyNoteShare."Position Top", StickyNoteShare."Width", StickyNoteShare."Height");
                        SeenNoteIds.Add(StickyNoteShare."Note ID", true);
                    end;
            until StickyNoteShare.Next() = 0;

        Payload := Notes;
        Payload.WriteTo(OutText);
        exit(OutText);
    end;

    procedure CreateBlankNote(): Text
    var
        StickyNote: Record "LAB Sticky Note";
    begin
        StickyNote.Init();
        StickyNote."User ID" := CopyStr(UserId(), 1, 50);
        StickyNote."Position Left" := 20;
        StickyNote."Position Top" := 20;
        StickyNote.Insert(true);
        exit(Format(StickyNote."Note ID"));
    end;

    procedure ApplyNotesJson(JsonData: Text)
    var
        StickyNote: Record "LAB Sticky Note";
        StickyNoteShare: Record "LAB Sticky Note Share";
        NotesArray: JsonArray;
        NoteToken: JsonToken;
        NoteObj: JsonObject;
        NoteIndex: Integer;
        NoteIdGuid: Guid;
        DueDateText: Text;
        NewDueDate: Date;
        NewLeft: Integer;
        NewTop: Integer;
        NewWidth: Integer;
        NewHeight: Integer;
    begin
        if JsonData = '' then
            exit;
        if not NotesArray.ReadFrom(JsonData) then
            exit;

        for NoteIndex := 0 to NotesArray.Count - 1 do begin
            NotesArray.Get(NoteIndex, NoteToken);
            NoteObj := NoteToken.AsObject();

            if Evaluate(NoteIdGuid, GetJsonText(NoteObj, 'id')) then
                if StickyNote.Get(NoteIdGuid) then begin
                    NewLeft := GetJsonInteger(NoteObj, 'left');
                    NewTop := GetJsonInteger(NoteObj, 'top');
                    NewWidth := GetJsonInteger(NoteObj, 'width');
                    NewHeight := GetJsonInteger(NoteObj, 'height');

                    if StickyNote."User ID" = CopyStr(UserId(), 1, 50) then begin
                        StickyNote."Position Left" := NewLeft;
                        StickyNote."Position Top" := NewTop;
                        StickyNote."Width" := NewWidth;
                        StickyNote."Height" := NewHeight;
                    end else
                        if StickyNoteShare.Get(NoteIdGuid, CopyStr(UserId(), 1, 50)) then begin
                            StickyNoteShare."Position Left" := NewLeft;
                            StickyNoteShare."Position Top" := NewTop;
                            StickyNoteShare."Width" := NewWidth;
                            StickyNoteShare."Height" := NewHeight;
                            StickyNoteShare.Modify();
                        end;

                    StickyNote.SetNoteText(GetJsonText(NoteObj, 'text'));
                    StickyNote."Color" := CopyStr(GetJsonText(NoteObj, 'color'), 1, MaxStrLen(StickyNote."Color"));

                    DueDateText := GetJsonText(NoteObj, 'dueDate');
                    if (DueDateText <> '') and Evaluate(NewDueDate, DueDateText, 9) then
                        StickyNote."Due Date" := NewDueDate
                    else
                        StickyNote."Due Date" := 0D;

                    StickyNote."Last Modified At" := CurrentDateTime();
                    StickyNote.Modify();
                end;
        end;
    end;

    procedure DeleteNote(NoteIdText: Text)
    var
        StickyNote: Record "LAB Sticky Note";
        StickyNoteShare: Record "LAB Sticky Note Share";
        NoteIdGuid: Guid;
    begin
        if not Evaluate(NoteIdGuid, NoteIdText) then
            exit;
        if StickyNote.Get(NoteIdGuid) then
            if StickyNote."User ID" = CopyStr(UserId(), 1, 50) then
                StickyNote.Delete(true)
            else
                if StickyNoteShare.Get(NoteIdGuid, CopyStr(UserId(), 1, 50)) then
                    StickyNoteShare.Delete();
    end;

    procedure CreateUserTaskFromNote(TaskTitle: Text; NoteText: Text)
    var
        UserTask: Record "User Task";
    begin
        if not Confirm(CreateUserTaskQst) then
            exit;

        if TaskTitle = '' then
            TaskTitle := DefaultTaskTitleTxt;

        UserTask.Init();
        UserTask.Validate(Title, CopyStr(TaskTitle, 1, MaxStrLen(UserTask.Title)));
        UserTask.Insert(true);
        UserTask.SetDescription(NoteText);

        Page.Run(Page::"User Task Card", UserTask);
    end;

    procedure OpenDataEncryptionManagement(ErrInfo: ErrorInfo)
    begin
        Page.Run(Page::"Data Encryption Management");
    end;

    local procedure AddNoteToJson(var Notes: JsonArray; var StickyNote: Record "LAB Sticky Note"; NoteLeft: Integer; NoteTop: Integer; NoteWidth: Integer; NoteHeight: Integer)
    var
        NoteObj: JsonObject;
        DueDateText: Text;
    begin
        Clear(NoteObj);
        NoteObj.Add('id', Format(StickyNote."Note ID"));
        NoteObj.Add('text', StickyNote.GetNoteText());
        NoteObj.Add('left', NoteLeft);
        NoteObj.Add('top', NoteTop);
        NoteObj.Add('width', NoteWidth);
        NoteObj.Add('height', NoteHeight);
        NoteObj.Add('color', StickyNote."Color");

        if StickyNote."Due Date" <> 0D then
            DueDateText := Format(StickyNote."Due Date", 0, 9)
        else
            DueDateText := '';
        NoteObj.Add('dueDate', DueDateText);
        NoteObj.Add('shared', StickyNote.IsShared());

        Notes.Add(NoteObj);
    end;

    local procedure GetJsonText(NoteObj: JsonObject; FieldKey: Text): Text
    var
        FieldToken: JsonToken;
    begin
        if not NoteObj.Get(FieldKey, FieldToken) then
            exit('');
        if FieldToken.AsValue().IsNull then
            exit('');
        exit(FieldToken.AsValue().AsText());
    end;

    local procedure GetJsonInteger(NoteObj: JsonObject; FieldKey: Text): Integer
    var
        FieldToken: JsonToken;
    begin
        if not NoteObj.Get(FieldKey, FieldToken) then
            exit(0);
        if FieldToken.AsValue().IsNull then
            exit(0);
        exit(FieldToken.AsValue().AsInteger());
    end;

    var
        CreateUserTaskQst: Label 'Do you want to create user task?';
        DefaultTaskTitleTxt: Label 'Sticky note task';
}
