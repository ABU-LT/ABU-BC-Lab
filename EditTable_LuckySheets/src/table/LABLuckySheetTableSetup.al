namespace ABU_BC_Lab.Apps.LuckySheet;

using System.Reflection;

table 70004 "LAB LuckySheet Table Setup"
{
    Caption = 'LuckySheet Table Setup';
    DataClassification = SystemMetadata;
    LookupPageId = "LAB LuckySheet Tbl. Setup List";
    DrillDownPageId = "LAB LuckySheet Tbl. Setup List";

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            var
                FieldSetup: Record "LAB LuckySheet Field Setup";
            begin
                FieldSetup.PopulateFields("Table ID");
            end;
        }
        field(2; "Table Name"; Text[30])
        {
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
        }
        field(3; "Activate Modify Trigger"; Boolean)
        {
            Caption = 'Activate Modify Trigger';
            ToolTip = 'Specifies whether saving changes from the sheet runs the table''s OnModify trigger (field validation, table triggers). When not set, changes are written directly without running the trigger.';
        }
        field(4; "Activate Insert Trigger"; Boolean)
        {
            Caption = 'Activate Insert Trigger';
            ToolTip = 'Specifies whether inserting new rows from the sheet runs the table''s OnInsert trigger (field validation, table triggers). When not set, new records are written directly without running the trigger.';
        }
    }

    keys
    {
        key(PK; "Table ID")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        FieldSetup: Record "LAB LuckySheet Field Setup";
    begin
        FieldSetup.SetRange("Table ID", "Table ID");
        FieldSetup.DeleteAll(true);
    end;
}
