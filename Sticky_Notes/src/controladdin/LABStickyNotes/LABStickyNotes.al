namespace DefaultPublisher.Sticky_Notes;

controladdin "LAB Sticky Notes"
{
    Scripts = 'src/controladdin/LABStickyNotes/script.js';
    StartupScript = 'src/controladdin/LABStickyNotes/startup.js';
    HorizontalStretch = true;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalShrink = true;
    RequestedHeight = 500;
    RequestedWidth = 900;

    event ControlAddInReady();
    event SaveNotes(jsonData: Text);
    event DeleteNote(noteId: Text);
    event CreateNote();
    event CreateUserTask(title: Text; noteText: Text);
    event ShareNote(noteId: Text);

    procedure LoadData(jsonData: Text);
    procedure NoteCreated(noteId: Text);
}
