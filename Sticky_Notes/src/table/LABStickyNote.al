namespace DefaultPublisher.Sticky_Notes;

table 70020 "LAB Sticky Note"
{
    Caption = 'Sticky Note';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Note ID"; Guid)
        {
            Caption = 'Note ID';
            Editable = false;
        }
        field(3; "Position Left"; Integer)
        {
            Caption = 'Position Left';
        }
        field(4; "Position Top"; Integer)
        {
            Caption = 'Position Top';
        }
        field(5; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Last Modified At"; DateTime)
        {
            Caption = 'Last Modified At';
        }
        field(7; Color; Text[20])
        {
            Caption = 'Color';
        }
        field(8; Width; Integer)
        {
            Caption = 'Width';
        }
        field(9; Height; Integer)
        {
            Caption = 'Height';
        }
        field(10; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
    }

    keys
    {
        key(PK; "Note ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if IsNullGuid("Note ID") then
            "Note ID" := CreateGuid();
        if "User ID" = '' then
            "User ID" := CopyStr(UserId(), 1, 50);
        if "Last Modified At" = 0DT then
            "Last Modified At" := CurrentDateTime();
        if "Color" = '' then
            "Color" := '#fff799';
        if "Width" = 0 then
            "Width" := 150;
        if "Height" = 0 then
            "Height" := 150;
    end;

    trigger OnDelete()
    var
        StickyNoteShare: Record "LAB Sticky Note Share";
    begin
        StickyNoteShare.SetRange("Note ID", "Note ID");
        StickyNoteShare.DeleteAll(true);
        IsolatedStorage.Delete(GetStorageKey(), GetStorageScope());
    end;

    procedure GetNoteText(): Text
    var
        StoredText: Text;
    begin
        if IsolatedStorage.Get(GetStorageKey(), GetStorageScope(), StoredText) then
            exit(StoredText);
        exit('');
    end;

    procedure SetNoteText(NewText: Text)
    begin
        if NoteEncryptionEnabled() then begin
            EnsureEncryptionEnabled();
            IsolatedStorage.SetEncrypted(GetStorageKey(), NewText, GetStorageScope());
        end else
            IsolatedStorage.Set(GetStorageKey(), NewText, GetStorageScope());
    end;

    procedure IsShared(): Boolean
    var
        StickyNoteShare: Record "LAB Sticky Note Share";
    begin
        StickyNoteShare.SetRange("Note ID", "Note ID");
        exit(not StickyNoteShare.IsEmpty());
    end;

    procedure MigrateNoteTextScope(ToShared: Boolean)
    var
        OldScope: DataScope;
        NewScope: DataScope;
        StoredText: Text;
    begin
        if ToShared then begin
            OldScope := DataScope::User;
            NewScope := DataScope::Company;
        end else begin
            OldScope := DataScope::Company;
            NewScope := DataScope::User;
        end;

        if not IsolatedStorage.Get(GetStorageKey(), OldScope, StoredText) then
            exit;

        IsolatedStorage.Delete(GetStorageKey(), OldScope);
        if NoteEncryptionEnabled() then
            IsolatedStorage.SetEncrypted(GetStorageKey(), StoredText, NewScope)
        else
            IsolatedStorage.Set(GetStorageKey(), StoredText, NewScope);
    end;

    local procedure GetStorageKey(): Text
    begin
        exit(Format("Note ID"));
    end;

    local procedure GetStorageScope(): DataScope
    begin
        if IsShared() then
            exit(DataScope::Company);
        exit(DataScope::User);
    end;

    local procedure NoteEncryptionEnabled(): Boolean
    var
        StickyNoteSetup: Record "LAB Sticky Note Setup";
    begin
        if not StickyNoteSetup.Get() then
            exit(false);
        exit(StickyNoteSetup."Enable Note Encryption");
    end;

    local procedure EnsureEncryptionEnabled()
    var
        ErrInfo: ErrorInfo;
    begin
        if EncryptionEnabled() then
            exit;
        ErrInfo.Message := EncryptionRequiredErr;
        ErrInfo.AddAction(EnableEncryptionActionTxt, Codeunit::"LAB Sticky Note Mgt", 'OpenDataEncryptionManagement');
        Error(ErrInfo);
    end;

    var
        EncryptionRequiredErr: Label 'Note text is stored encrypted, but data encryption is not enabled on this server. Enable encryption to use sticky notes.';
        EnableEncryptionActionTxt: Label 'Enable Encryption';
}
