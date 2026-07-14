namespace ABU_BC_Lab.Apps.LuckySheet;

using System.Reflection;

table 70005 "LAB LuckySheet Field Setup"
{
    Caption = 'LuckySheet Field Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = "LAB LuckySheet Table Setup"."Table ID";
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(3; "Field Name"; Text[80])
        {
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"), "No." = field("Field No.")));
        }
        field(4; "Show in LuckySheet"; Boolean)
        {
            Caption = 'Show in LuckySheet';
            InitValue = true;
            ToolTip = 'Specifies whether this field is included when the table is loaded into the sheet.';
        }
        field(5; "Activate Field Validation"; Boolean)
        {
            Caption = 'Activate Field Validation';
            InitValue = true;
            ToolTip = 'Specifies whether saving a change to this field from the sheet runs the field''s OnValidate trigger.';
        }
    }

    keys
    {
        key(PK; "Table ID", "Field No.")
        {
            Clustered = true;
        }
    }

    procedure PopulateFields(TableId: Integer)
    var
        FieldRec: Record Field;
        FieldSetup: Record "LAB LuckySheet Field Setup";
    begin
        if TableId = 0 then
            exit;

        FieldRec.SetRange(TableNo, TableId);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetFilter("No.", '<%1', 2000000000);
        if FieldRec.FindSet() then
            repeat
                if not FieldSetup.Get(TableId, FieldRec."No.") then begin
                    FieldSetup.Init();
                    FieldSetup."Table ID" := TableId;
                    FieldSetup."Field No." := FieldRec."No.";
                    FieldSetup.Insert(true);
                end;
            until FieldRec.Next() = 0;
    end;
}
