var LSN_board = null;
var LSN_activeDrag = null;
var LSN_activeResize = null;
var LSN_openPalette = null;
var LSN_openPaletteButton = null;
var LSN_saveInFlight = false;
var LSN_savePending = false;
var LSN_saveTimeoutId = null;
var LSN_SAVE_TIMEOUT_MS = 8000;
var LSN_colors = [
    '#fff799', '#ffe6a7', '#ffdfba', '#ffb3ba', '#f7c6d9',
    '#f4a6c6', '#e2baff', '#d9c6f7', '#b6a6f7', '#c9c9ff',
    '#bae1ff', '#c6e0f7', '#a6c6f7', '#a6e6e6', '#baffc9',
    '#b6e6b6', '#8fd98f', '#d9d9d9', '#a6a6a6', '#4a4a4a'
];
var LSN_fonts = ['Calibri', 'Arial', 'Georgia', 'Courier New', 'Comic Sans MS'];
var LSN_fontSizes = [10, 12, 14, 16, 18, 20, 24, 28, 32, 36];
var LSN_quickColors = ['#fff799', '#baffc9', '#f7c6d9', '#bae1ff', '#e2baff'];
var LSN_pendingNoteColors = [];

function InitializeControl(controlId) {
    var controlElement = document.getElementById(controlId);
    if (!controlElement) {
        console.error('Control element not found: ' + controlId);
        return;
    }
    ControlAddInReady(controlElement);
}

function LSN_injectStyles() {
    var style = document.createElement('style');
    style.textContent =
        '.lsn-fmt-btn{box-sizing:border-box;min-width:24px;height:22px;padding:0 5px;' +
        'display:flex;align-items:center;justify-content:center;background:#3a3a3b;' +
        'color:#eee;border:1px solid #4a4a4b;border-radius:4px;cursor:pointer;font-size:12px;}' +
        '.lsn-fmt-btn:hover{background:#4a4a4b;}' +
        '.lsn-fmt-btn.lsn-active{background:#0d6efd;border-color:#4dabf7;color:#fff;}' +
        '.lsn-fmt-select{height:22px;background:#3a3a3b;color:#eee;border:1px solid #4a4a4b;' +
        'border-radius:4px;font-size:11px;padding:0 2px;cursor:pointer;}' +
        '.lsn-align-icon{width:14px;height:12px;display:flex;flex-direction:column;justify-content:space-between;}' +
        '.lsn-align-icon span{display:block;height:2px;background:currentColor;}' +
        '@keyframes lsn-pulse{0%,100%{opacity:1;}50%{opacity:.55;}}' +
        '.lsn-overdue{animation:lsn-pulse 2.2s ease-in-out infinite;}';
    document.head.appendChild(style);
}

function ControlAddInReady(element) {
    LSN_injectStyles();

    element.style.height = '100%';
    element.style.width = '100%';
    element.style.display = 'flex';
    element.style.flexDirection = 'column';

    var toolbar = document.createElement('div');
    toolbar.style.padding = '6px';

    var addButton = document.createElement('button');
    addButton.type = 'button';
    addButton.title = 'Add New Note';
    addButton.style.height = '36px';
    addButton.style.borderRadius = '18px';
    addButton.style.border = 'none';
    addButton.style.background = '#fff';
    addButton.style.color = '#201f1e';
    addButton.style.fontSize = '14px';
    addButton.style.fontWeight = 'normal';
    addButton.style.lineHeight = '1';
    addButton.style.cursor = 'pointer';
    addButton.style.display = 'flex';
    addButton.style.alignItems = 'center';
    addButton.style.justifyContent = 'center';
    addButton.style.gap = '6px';
    addButton.style.padding = '0 16px';
    addButton.style.boxShadow = '0 1px 3px rgba(0,0,0,.25)';

    var addButtonIcon = document.createElement('span');
    addButtonIcon.innerText = '+';
    addButtonIcon.style.fontSize = '18px';
    addButtonIcon.style.lineHeight = '1';
    addButton.appendChild(addButtonIcon);

    var addButtonLabel = document.createElement('span');
    addButtonLabel.innerText = 'New Note';
    addButton.appendChild(addButtonLabel);

    addButton.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    addButton.addEventListener('click', function (e) {
        e.stopPropagation();
        LSN_toggleAddPalette(addButton);
    });
    toolbar.appendChild(addButton);
    element.appendChild(toolbar);

    LSN_board = document.createElement('div');
    LSN_board.id = 'lsnBoard';
    LSN_board.style.position = 'relative';
    LSN_board.style.flex = '1 1 auto';
    LSN_board.style.width = '100%';
    LSN_board.style.background = '#f0f0f0';
    LSN_board.style.overflow = 'auto';
    element.appendChild(LSN_board);

    document.addEventListener('mousemove', function (e) {
        if (LSN_activeDrag) {
            LSN_activeDrag.note.style.left = (e.clientX - LSN_activeDrag.offsetX) + 'px';
            LSN_activeDrag.note.style.top = (e.clientY - LSN_activeDrag.offsetY) + 'px';
        } else if (LSN_activeResize) {
            var dx = e.clientX - LSN_activeResize.startX;
            var dy = e.clientY - LSN_activeResize.startY;
            LSN_activeResize.note.style.width = Math.max(80, LSN_activeResize.startWidth + dx) + 'px';
            LSN_activeResize.note.style.height = Math.max(60, LSN_activeResize.startHeight + dy) + 'px';
        }
    });

    document.addEventListener('mouseup', function () {
        if (LSN_activeDrag) {
            LSN_activeDrag = null;
            LSN_saveBoard();
        }
        if (LSN_activeResize) {
            LSN_activeResize = null;
            LSN_saveBoard();
        }
    });

    document.addEventListener('mousedown', function (e) {
        if (LSN_openPalette && !LSN_openPalette.contains(e.target)) {
            LSN_openPalette.remove();
            LSN_openPalette = null;
            LSN_openPaletteButton = null;
        }
    });

    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', null);
}

function LoadData(jsonData) {
    var notes = JSON.parse(jsonData || '[]');
    LSN_board.innerHTML = '';
    notes.forEach(function (note) {
        LSN_createNote(note.id, note.text, note.left, note.top, note.width, note.height, note.color, note.dueDate, note.shared);
    });

    clearTimeout(LSN_saveTimeoutId);
    LSN_saveInFlight = false;
    if (LSN_savePending) {
        LSN_savePending = false;
        LSN_saveBoard();
    }
}

function NoteCreated(noteId) {
    var color = LSN_pendingNoteColors.length ? LSN_pendingNoteColors.shift() : '#fff799';
    LSN_createNote(noteId, '', 20, 20, 150, 150, color, '', false);
    LSN_saveBoard();
}

function LSN_toggleAddPalette(button) {
    var reopening = LSN_openPaletteButton === button;
    if (LSN_openPalette) {
        LSN_openPalette.remove();
        LSN_openPalette = null;
        LSN_openPaletteButton = null;
        if (reopening) return;
    }

    var palette = document.createElement('div');
    var buttonRect = button.getBoundingClientRect();
    palette.style.position = 'fixed';
    palette.style.top = (buttonRect.bottom + 4) + 'px';
    palette.style.left = buttonRect.left + 'px';
    palette.style.display = 'flex';
    palette.style.gap = '4px';
    palette.style.background = '#fff';
    palette.style.boxShadow = '2px 2px 8px rgba(0,0,0,.4)';
    palette.style.padding = '6px';
    palette.style.borderRadius = '6px';
    palette.style.zIndex = 2000;

    LSN_quickColors.forEach(function (color) {
        var swatch = document.createElement('div');
        swatch.style.width = '28px';
        swatch.style.height = '28px';
        swatch.style.borderRadius = '4px';
        swatch.style.background = color;
        swatch.style.cursor = 'pointer';
        swatch.style.border = '1px solid rgba(0,0,0,.3)';
        swatch.addEventListener('mousedown', function (e) {
            e.stopPropagation();
        });
        swatch.addEventListener('click', function (e) {
            e.stopPropagation();
            palette.remove();
            LSN_openPalette = null;
            LSN_openPaletteButton = null;
            LSN_pendingNoteColors.push(color);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('CreateNote', null);
        });
        palette.appendChild(swatch);
    });

    document.body.appendChild(palette);
    LSN_openPalette = palette;
    LSN_openPaletteButton = button;
}

function LSN_todayIso() {
    var now = new Date();
    var month = String(now.getMonth() + 1).padStart(2, '0');
    var day = String(now.getDate()).padStart(2, '0');
    return now.getFullYear() + '-' + month + '-' + day;
}

function LSN_updateOverdueState(note) {
    var dueDate = note.dataset.dueDate;
    var isOverdue = !!dueDate && dueDate <= LSN_todayIso();
    note.classList.toggle('lsn-overdue', isOverdue);
}

function LSN_createNote(noteId, text, left, top, width, height, color, dueDate, shared) {
    color = color || '#fff799';

    var note = document.createElement('div');
    note.dataset.noteId = noteId || '';
    note.dataset.color = color;
    note.dataset.dueDate = dueDate || '';
    note.style.width = (width || 150) + 'px';
    note.style.height = (height || 150) + 'px';
    note.style.background = color;
    note.style.position = 'absolute';
    note.style.left = (left || 0) + 'px';
    note.style.top = (top || 0) + 'px';
    note.style.boxShadow = '5px 5px 7px rgba(33,33,33,.7)';
    note.style.borderRadius = '4px';
    note.style.overflow = 'hidden';
    note.style.display = 'flex';
    note.style.flexDirection = 'column';

    var header = document.createElement('div');
    header.style.height = '28px';
    header.style.cursor = 'move';
    header.style.display = 'flex';
    header.style.justifyContent = 'space-between';
    header.style.alignItems = 'center';
    header.style.flex = '0 0 auto';
    header.style.padding = '0 6px';
    header.style.position = 'relative';

    var headerLeft = document.createElement('div');
    headerLeft.style.display = 'flex';
    headerLeft.style.alignItems = 'center';
    headerLeft.style.gap = '6px';
    header.appendChild(headerLeft);

    var colorButton = document.createElement('span');
    colorButton.title = 'Color';
    colorButton.innerText = '🎨';
    colorButton.style.width = '22px';
    colorButton.style.height = '22px';
    colorButton.style.display = 'flex';
    colorButton.style.alignItems = 'center';
    colorButton.style.justifyContent = 'center';
    colorButton.style.fontSize = '18px';
    colorButton.style.lineHeight = '1';
    colorButton.style.cursor = 'pointer';
    colorButton.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    colorButton.addEventListener('click', function (e) {
        e.stopPropagation();
        LSN_toggleColorPalette(note, colorButton);
    });
    headerLeft.appendChild(colorButton);

    var taskButton = document.createElement('span');
    taskButton.title = 'Create Task';
    taskButton.innerText = '📝';
    taskButton.style.width = '22px';
    taskButton.style.height = '22px';
    taskButton.style.display = 'flex';
    taskButton.style.alignItems = 'center';
    taskButton.style.justifyContent = 'center';
    taskButton.style.fontSize = '18px';
    taskButton.style.lineHeight = '1';
    taskButton.style.cursor = 'pointer';
    taskButton.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    taskButton.addEventListener('click', function (e) {
        e.stopPropagation();
        var plainText = content.innerText || '';
        var firstLine = (plainText.split('\n')[0] || '').trim();
        var taskTitle = firstLine ? firstLine.substring(0, 100) : '';
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('CreateUserTask', [taskTitle, plainText]);
    });
    headerLeft.appendChild(taskButton);

    var shareButton = document.createElement('span');
    shareButton.title = shared ? 'Shared' : 'Share with another user';
    shareButton.innerHTML =
        '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" xmlns="http://www.w3.org/2000/svg">' +
        '<circle cx="18" cy="5" r="2.5" fill="currentColor"/>' +
        '<circle cx="6" cy="12" r="2.5" fill="currentColor"/>' +
        '<circle cx="18" cy="19" r="2.5" fill="currentColor"/>' +
        '<line x1="8.2" y1="10.8" x2="15.8" y2="6.2" stroke="currentColor" stroke-width="1.6"/>' +
        '<line x1="8.2" y1="13.2" x2="15.8" y2="17.8" stroke="currentColor" stroke-width="1.6"/>' +
        '</svg>';
    shareButton.style.color = shared ? '#d40000' : '#333';
    shareButton.style.width = '22px';
    shareButton.style.height = '22px';
    shareButton.style.display = 'flex';
    shareButton.style.alignItems = 'center';
    shareButton.style.justifyContent = 'center';
    shareButton.style.cursor = 'pointer';
    shareButton.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    shareButton.addEventListener('click', function (e) {
        e.stopPropagation();
        var noteIdValue = note.dataset.noteId || '';
        if (!noteIdValue) return;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ShareNote', [noteIdValue]);
    });
    headerLeft.appendChild(shareButton);

    var reminderButton = document.createElement('span');
    reminderButton.title = 'Reminder';
    reminderButton.innerText = '🔔';
    reminderButton.style.width = '22px';
    reminderButton.style.height = '22px';
    reminderButton.style.display = 'flex';
    reminderButton.style.alignItems = 'center';
    reminderButton.style.justifyContent = 'center';
    reminderButton.style.fontSize = '16px';
    reminderButton.style.lineHeight = '1';
    reminderButton.style.cursor = 'pointer';
    reminderButton.style.position = 'relative';

    var reminderInput = document.createElement('input');
    reminderInput.type = 'date';
    reminderInput.value = dueDate || '';
    reminderInput.style.position = 'absolute';
    reminderInput.style.left = '0';
    reminderInput.style.top = '100%';
    reminderInput.style.width = '1px';
    reminderInput.style.height = '1px';
    reminderInput.style.opacity = '0';
    reminderInput.style.border = 'none';
    reminderInput.style.pointerEvents = 'none';
    reminderInput.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    reminderInput.addEventListener('change', function () {
        note.dataset.dueDate = reminderInput.value || '';
        reminderDateLabel.innerText = note.dataset.dueDate;
        LSN_updateOverdueState(note);
        LSN_saveBoard();
    });
    reminderButton.appendChild(reminderInput);

    reminderButton.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    reminderButton.addEventListener('click', function (e) {
        e.stopPropagation();
        if (typeof reminderInput.showPicker === 'function') {
            try {
                reminderInput.showPicker();
                return;
            } catch (err) {
                // fall through to focus-based fallback
            }
        }
        reminderInput.focus();
    });
    headerLeft.appendChild(reminderButton);

    var reminderDateLabel = document.createElement('span');
    reminderDateLabel.style.fontSize = '11px';
    reminderDateLabel.style.color = '#333';
    reminderDateLabel.style.whiteSpace = 'nowrap';
    reminderDateLabel.innerText = dueDate || '';
    headerLeft.appendChild(reminderDateLabel);

    var deleteButton = document.createElement('span');
    deleteButton.innerText = '×';
    deleteButton.title = 'Delete';
    deleteButton.style.width = '22px';
    deleteButton.style.height = '22px';
    deleteButton.style.display = 'flex';
    deleteButton.style.alignItems = 'center';
    deleteButton.style.justifyContent = 'center';
    deleteButton.style.fontSize = '20px';
    deleteButton.style.lineHeight = '1';
    deleteButton.style.cursor = 'pointer';
    deleteButton.style.fontWeight = 'bold';
    deleteButton.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    deleteButton.addEventListener('click', function (e) {
        e.stopPropagation();
        var noteIdValue = note.dataset.noteId || '';
        note.remove();
        if (noteIdValue) {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DeleteNote', [noteIdValue]);
        }
    });
    header.appendChild(deleteButton);

    header.addEventListener('mousedown', function (e) {
        if (e.target !== header) return;
        LSN_activeDrag = { note: note, offsetX: e.clientX - note.offsetLeft, offsetY: e.clientY - note.offsetTop };
        note.style.zIndex = 1000;
    });
    note.appendChild(header);

    var content = document.createElement('div');
    content.contentEditable = true;
    if (text && text.indexOf('<') !== -1) {
        content.innerHTML = text;
    } else {
        content.innerText = text || '';
    }
    content.style.flex = '1 1 auto';
    content.style.padding = '0 10px 10px';
    content.style.overflow = 'auto';
    content.style.outline = 'none';

    var savedRange = null;
    function restoreContentSelection() {
        content.focus();
        if (savedRange) {
            var sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(savedRange);
        }
    }

    content.addEventListener('focus', function () {
        formatToolbar.style.display = 'flex';
        LSN_updateFormatButtonStates(formatButtons);
    });
    content.addEventListener('blur', function (e) {
        if (formatToolbar.contains(e.relatedTarget)) {
            var sel = window.getSelection();
            if (sel.rangeCount > 0) savedRange = sel.getRangeAt(0).cloneRange();
            return;
        }
        formatToolbar.style.display = 'none';
        LSN_saveBoard();
    });
    content.addEventListener('keyup', function () {
        LSN_updateFormatButtonStates(formatButtons);
    });
    content.addEventListener('mouseup', function () {
        LSN_updateFormatButtonStates(formatButtons);
    });
    note.appendChild(content);

    var formatToolbar = document.createElement('div');
    formatToolbar.style.display = 'none';
    formatToolbar.style.flex = '0 0 auto';
    formatToolbar.style.flexWrap = 'wrap';
    formatToolbar.style.alignItems = 'center';
    formatToolbar.style.gap = '4px';
    formatToolbar.style.padding = '4px 6px';
    formatToolbar.style.overflowX = 'auto';
    formatToolbar.style.background = '#2b2b2c';
    formatToolbar.style.boxShadow = '0 -2px 6px rgba(0,0,0,.3)';
    formatToolbar.style.borderRadius = '0 0 4px 4px';

    var formatButtons = {};

    function addToolbarButton(container, title, buildContent, onActivate) {
        var button = document.createElement('button');
        button.type = 'button';
        button.title = title;
        button.className = 'lsn-fmt-btn';
        buildContent(button);
        button.addEventListener('mousedown', function (e) {
            e.preventDefault();
            onActivate();
            LSN_updateFormatButtonStates(formatButtons);
        });
        container.appendChild(button);
        return button;
    }

    var fontSelect = document.createElement('select');
    fontSelect.className = 'lsn-fmt-select';
    fontSelect.title = 'Font';
    LSN_fonts.forEach(function (font) {
        var option = document.createElement('option');
        option.value = font;
        option.innerText = font;
        fontSelect.appendChild(option);
    });
    fontSelect.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    fontSelect.addEventListener('change', function () {
        restoreContentSelection();
        document.execCommand('fontName', false, fontSelect.value);
        LSN_saveBoard();
    });
    formatToolbar.appendChild(fontSelect);

    var fontSizeSelect = document.createElement('select');
    fontSizeSelect.className = 'lsn-fmt-select';
    fontSizeSelect.title = 'Font Size';
    LSN_fontSizes.forEach(function (size) {
        var option = document.createElement('option');
        option.value = size;
        option.innerText = size;
        fontSizeSelect.appendChild(option);
    });
    fontSizeSelect.addEventListener('mousedown', function (e) {
        e.stopPropagation();
    });
    fontSizeSelect.addEventListener('change', function () {
        restoreContentSelection();
        LSN_applyFontSize(content, fontSizeSelect.value);
        LSN_saveBoard();
    });
    formatToolbar.appendChild(fontSizeSelect);

    function addCommandButton(title, command, labelStyle, label) {
        formatButtons[command] = addToolbarButton(formatToolbar, title, function (button) {
            button.innerText = label;
            if (labelStyle) {
                for (var key in labelStyle) button.style[key] = labelStyle[key];
            }
        }, function () {
            document.execCommand(command, false, null);
        });
    }

    addCommandButton('Bold', 'bold', { fontWeight: 'bold' }, 'B');
    addCommandButton('Italic', 'italic', { fontStyle: 'italic' }, 'I');
    addCommandButton('Underline', 'underline', { textDecoration: 'underline' }, 'U');
    addCommandButton('Strikethrough', 'strikeThrough', { textDecoration: 'line-through' }, 'S');

    function addAlignButton(title, command, align) {
        formatButtons[command] = addToolbarButton(formatToolbar, title, function (button) {
            var icon = document.createElement('span');
            icon.className = 'lsn-align-icon';
            icon.style.alignItems = align;
            [1, 0.65, 1].forEach(function (widthFraction) {
                var bar = document.createElement('span');
                bar.style.width = (widthFraction * 100) + '%';
                icon.appendChild(bar);
            });
            button.appendChild(icon);
        }, function () {
            document.execCommand(command, false, null);
        });
    }

    addAlignButton('Align Left', 'justifyLeft', 'flex-start');
    addAlignButton('Align Center', 'justifyCenter', 'center');
    addAlignButton('Align Right', 'justifyRight', 'flex-end');

    note.appendChild(formatToolbar);

    var resizeHandle = document.createElement('div');
    resizeHandle.style.position = 'absolute';
    resizeHandle.style.width = '12px';
    resizeHandle.style.height = '12px';
    resizeHandle.style.right = '2px';
    resizeHandle.style.bottom = '2px';
    resizeHandle.style.cursor = 'nwse-resize';
    resizeHandle.style.background = 'linear-gradient(135deg, transparent 50%, rgba(0,0,0,.4) 50%)';
    resizeHandle.addEventListener('mousedown', function (e) {
        e.stopPropagation();
        LSN_activeResize = { note: note, startX: e.clientX, startY: e.clientY, startWidth: note.offsetWidth, startHeight: note.offsetHeight };
        note.style.zIndex = 1000;
    });
    note.appendChild(resizeHandle);

    LSN_updateOverdueState(note);

    LSN_board.appendChild(note);
    return note;
}

function LSN_updateFormatButtonStates(formatButtons) {
    for (var command in formatButtons) {
        var isActive = false;
        try {
            isActive = document.queryCommandState(command);
        } catch (e) {
            isActive = false;
        }
        formatButtons[command].classList.toggle('lsn-active', isActive);
    }
}

function LSN_applyFontSize(content, pxValue) {
    document.execCommand('fontSize', false, '7');
    var fontElements = content.querySelectorAll('font[size="7"]');
    fontElements.forEach(function (el) {
        el.removeAttribute('size');
        el.style.fontSize = pxValue + 'px';
    });
}

function LSN_toggleColorPalette(note, colorButton) {
    var reopening = LSN_openPaletteButton === colorButton;
    if (LSN_openPalette) {
        LSN_openPalette.remove();
        LSN_openPalette = null;
        LSN_openPaletteButton = null;
        if (reopening) return;
    }

    var palette = document.createElement('div');
    var buttonRect = colorButton.getBoundingClientRect();
    palette.style.position = 'fixed';
    palette.style.top = (buttonRect.bottom + 4) + 'px';
    palette.style.left = buttonRect.left + 'px';
    palette.style.display = 'grid';
    palette.style.gridTemplateColumns = 'repeat(5, 28px)';
    palette.style.gap = '4px';
    palette.style.background = '#fff';
    palette.style.boxShadow = '2px 2px 8px rgba(0,0,0,.4)';
    palette.style.padding = '6px';
    palette.style.zIndex = 2000;

    LSN_colors.forEach(function (color) {
        var swatch = document.createElement('div');
        swatch.style.position = 'relative';
        swatch.style.width = '28px';
        swatch.style.height = '28px';
        swatch.style.background = color;
        swatch.style.cursor = 'pointer';
        swatch.style.border = '1px solid rgba(0,0,0,.3)';
        swatch.style.display = 'flex';
        swatch.style.alignItems = 'center';
        swatch.style.justifyContent = 'center';

        if (color === note.dataset.color) {
            var check = document.createElement('span');
            check.innerText = '✓';
            check.style.color = '#fff';
            check.style.fontWeight = 'bold';
            check.style.fontSize = '16px';
            check.style.textShadow = '0 0 2px rgba(0,0,0,.9), 0 0 2px rgba(0,0,0,.9)';
            swatch.appendChild(check);
        }

        swatch.addEventListener('mousedown', function (e) {
            e.stopPropagation();
        });
        swatch.addEventListener('click', function (e) {
            e.stopPropagation();
            note.style.background = color;
            note.dataset.color = color;
            palette.remove();
            LSN_openPalette = null;
            LSN_openPaletteButton = null;
            LSN_saveBoard();
        });
        palette.appendChild(swatch);
    });

    document.body.appendChild(palette);
    LSN_openPalette = palette;
    LSN_openPaletteButton = colorButton;
}

function LSN_saveBoard() {
    if (LSN_saveInFlight) {
        LSN_savePending = true;
        return;
    }
    LSN_saveInFlight = true;

    var notes = [];
    LSN_board.childNodes.forEach(function (note) {
        var content = note.childNodes[1];
        notes.push({
            id: note.dataset.noteId || '',
            text: content.innerHTML,
            left: parseInt(note.style.left, 10) || 0,
            top: parseInt(note.style.top, 10) || 0,
            width: parseInt(note.style.width, 10) || 150,
            height: parseInt(note.style.height, 10) || 150,
            color: note.dataset.color || '#fff799',
            dueDate: note.dataset.dueDate || ''
        });
    });
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('SaveNotes', [JSON.stringify(notes)]);

    clearTimeout(LSN_saveTimeoutId);
    LSN_saveTimeoutId = setTimeout(function () {
        LSN_saveInFlight = false;
        if (LSN_savePending) {
            LSN_savePending = false;
            LSN_saveBoard();
        }
    }, LSN_SAVE_TIMEOUT_MS);
}
