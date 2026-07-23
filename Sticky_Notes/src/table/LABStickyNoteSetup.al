namespace DefaultPublisher.Sticky_Notes;

table 70027 "LAB Sticky Note Setup"
{
    Caption = 'Sticky Note Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Enable Note Encryption"; Boolean)
        {
            Caption = 'Enable Note Encryption';

            trigger OnValidate()
            var
                StickyNote: Record "LAB Sticky Note";
                ErrInfo: ErrorInfo;
            begin
                if not "Enable Note Encryption" then
                    exit;

                if not EncryptionEnabled() then begin
                    ErrInfo.Message := EncryptionModuleNotActiveErr;
                    ErrInfo.AddAction(EnableEncryptionActionTxt, Codeunit::"LAB Sticky Note Mgt", 'OpenDataEncryptionManagement');
                    Error(ErrInfo);
                end;

                if not StickyNote.IsEmpty() then
                    Error(NotesAlreadyExistErr);
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        EncryptionModuleNotActiveErr: Label 'Data encryption is not enabled on this server. Enable encryption before turning on note encryption.';
        NotesAlreadyExistErr: Label 'Note encryption cannot be enabled because sticky notes already exist. It can only be turned on before any notes are created.';
        EnableEncryptionActionTxt: Label 'Enable Encryption';
}
