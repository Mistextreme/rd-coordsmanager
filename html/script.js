const state = {
    coords:       [],
    filtered:     [],
    pendingCoord: null,
    copyFormats:  { vector4: 'vector4({x}, {y}, {z}, {heading})' },
    activeFmt:    'vector4',
    renameTarget: null,
    deleteTarget: null,
};

const $ = id => document.getElementById(id);
const overlay       = $('overlay');
const panel         = $('panel');
const coordsList    = $('coords-list');
const emptyState    = $('empty-state');
const saveRow       = $('save-row');
const coordName     = $('coord-name');
const searchInput   = $('search-input');
const fmtSelect     = $('fmt-select');
const coordCount    = $('coord-count');
const prevX         = $('prev-x');
const prevY         = $('prev-y');
const prevZ         = $('prev-z');
const prevH         = $('prev-h');
const toast         = $('toast');
const modalRename   = $('modal-rename');
const renameInput   = $('rename-input');
const modalDelete   = $('modal-delete');
const deleteName    = $('delete-name');

function nuiFetch(event, data = {}) {
    return fetch(`https:
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => null);
}

let toastTimer;
function showToast(msg, type = 'info') {
    clearTimeout(toastTimer);
    toast.textContent = msg;
    toast.className   = `toast ${type}`;
    toastTimer = setTimeout(() => toast.classList.add('hidden'), 2500);
}

function buildFormatSelect(formats, defaultKey) {
    state.copyFormats = formats;
    state.activeFmt   = defaultKey;
    fmtSelect.innerHTML = '';
    for (const [key, tpl] of Object.entries(formats)) {
        const opt = document.createElement('option');
        opt.value    = key;
        opt.textContent = key;
        if (key === defaultKey) opt.selected = true;
        fmtSelect.appendChild(opt);
    }
}

fmtSelect.addEventListener('change', () => { state.activeFmt = fmtSelect.value; });

function applyFormat(coord, fmtKey) {
    const tpl = state.copyFormats[fmtKey] || state.copyFormats[state.activeFmt];
    return tpl
        .replace(/{x}/g,       roundCoord(coord.x))
        .replace(/{y}/g,       roundCoord(coord.y))
        .replace(/{z}/g,       roundCoord(coord.z))
        .replace(/{heading}/g, roundCoord(coord.heading))
        .replace(/{name}/g,    coord.name || '');
}

function roundCoord(v) {
    return parseFloat(v).toFixed(4);
}

async function copyToClipboard(text) {
    try {
        await navigator.clipboard.writeText(text);
        return true;
    } catch {

        const ta = document.createElement('textarea');
        ta.value = text;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
        return true;
    }
}

function renderList() {
    const query = searchInput.value.trim().toLowerCase();
    state.filtered = query
        ? state.coords.filter(c => c.name.toLowerCase().includes(query))
        : [...state.coords];

    coordCount.textContent = `${state.coords.length} saved`;

    Array.from(coordsList.children).forEach(el => {
        if (!el.classList.contains('empty-state')) el.remove();
    });

    if (state.filtered.length === 0) {
        emptyState.style.display = '';
        return;
    }
    emptyState.style.display = 'none';

    state.filtered.forEach((coord, i) => {
        const card = buildCard(coord, i + 1);
        coordsList.appendChild(card);
    });
}

function buildCard(coord, index) {
    const card = document.createElement('div');
    card.className  = 'coord-card';
    card.dataset.id = coord.id;

    const date = coord.created_at
        ? new Date(coord.created_at).toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric' })
        : '';

    card.innerHTML = `
        <div class="card-index">#${index}</div>
        <div class="card-body">
            <div class="card-name" title="${escHtml(coord.name)}">${escHtml(coord.name)}</div>
            <div class="card-coords">
                <span class="coord-axis"><span class="axis-lbl">X</span>${roundCoord(coord.x)}</span>
                <span class="coord-axis"><span class="axis-lbl">Y</span>${roundCoord(coord.y)}</span>
                <span class="coord-axis"><span class="axis-lbl">Z</span>${roundCoord(coord.z)}</span>
                <span class="coord-axis"><span class="axis-lbl">H</span>${roundCoord(coord.heading)}</span>
            </div>
            ${date ? `<div class="card-date">${date}</div>` : ''}
        </div>
        <div class="card-actions">
            <button class="card-btn copy"     title="Copy">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
            </button>
            <button class="card-btn rename"   title="Rename">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/></svg>
            </button>
            <button class="card-btn update"   title="Update to current position">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            </button>
            <button class="card-btn teleport" title="Teleport here">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg>
            </button>
            <button class="card-btn delete"   title="Delete">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>
            </button>
        </div>
    `;

    card.querySelector('.copy').addEventListener('click', () => onCopy(coord));
    card.querySelector('.rename').addEventListener('click', () => onRename(coord));
    card.querySelector('.update').addEventListener('click', () => onUpdate(coord));
    card.querySelector('.teleport').addEventListener('click', () => onTeleport(coord));
    card.querySelector('.delete').addEventListener('click', () => onDelete(coord));

    return card;
}

async function onCopy(coord) {
    const text = applyFormat(coord, state.activeFmt);
    await copyToClipboard(text);
    showToast('Copied: ' + text.substring(0, 50), 'success');
}

function onRename(coord) {
    state.renameTarget = coord;
    renameInput.value  = coord.name;
    modalRename.classList.remove('hidden');
    setTimeout(() => renameInput.focus(), 50);
}

async function onUpdate(coord) {
    await nuiFetch('updateCoord', { id: coord.id });
    showToast('Position updated!', 'success');
}

async function onTeleport(coord) {
    await nuiFetch('teleport', { x: coord.x, y: coord.y, z: coord.z, heading: coord.heading });
    showToast(`Teleporting to "${coord.name}"…`, 'info');
}

function onDelete(coord) {
    state.deleteTarget = coord;
    deleteName.textContent = coord.name;
    modalDelete.classList.remove('hidden');
}

$('btn-take').addEventListener('click', async () => {
    const btn = $('btn-take');
    const svg = btn.querySelector('svg');
    svg.classList.add('spin');
    btn.disabled = true;

    const data = await nuiFetch('takeCoord');
    svg.classList.remove('spin');
    btn.disabled = false;

    if (!data) { showToast('Failed to get coords.', 'error'); return; }

    state.pendingCoord = data;
    prevX.textContent  = roundCoord(data.x);
    prevY.textContent  = roundCoord(data.y);
    prevZ.textContent  = roundCoord(data.z);
    prevH.textContent  = roundCoord(data.heading);

    saveRow.classList.remove('hidden');
    coordName.focus();
    showToast('Position captured! Enter a name and save.', 'info');
});

$('btn-save').addEventListener('click', async () => {
    if (!state.pendingCoord) { showToast('Take a coord first.', 'error'); return; }
    const name = coordName.value.trim() || 'Unnamed';
    await nuiFetch('saveCoord', { name, ...state.pendingCoord });
    coordName.value = '';
    saveRow.classList.add('hidden');
    state.pendingCoord = null;
    showToast(`"${name}" saved!`, 'success');
});

coordName.addEventListener('keydown', e => {
    if (e.key === 'Enter') $('btn-save').click();
});

$('rename-cancel').addEventListener('click', () => {
    modalRename.classList.add('hidden');
    state.renameTarget = null;
});

$('rename-confirm').addEventListener('click', async () => {
    if (!state.renameTarget) return;
    const name = renameInput.value.trim() || 'Unnamed';
    await nuiFetch('renameCoord', { id: state.renameTarget.id, name });
    modalRename.classList.add('hidden');
    state.renameTarget = null;
    showToast(`Renamed to "${name}"`, 'success');
});

renameInput.addEventListener('keydown', e => {
    if (e.key === 'Enter') $('rename-confirm').click();
});

$('delete-cancel').addEventListener('click', () => {
    modalDelete.classList.add('hidden');
    state.deleteTarget = null;
});

$('delete-confirm').addEventListener('click', async () => {
    if (!state.deleteTarget) return;
    const name = state.deleteTarget.name;
    await nuiFetch('deleteCoord', { id: state.deleteTarget.id });
    modalDelete.classList.add('hidden');
    state.deleteTarget = null;
    showToast(`"${name}" deleted.`, 'info');
});

$('btn-close').addEventListener('click', () => {
    closeMenu();
});

$('btn-refresh').addEventListener('click', () => {
    const svg = $('btn-refresh').querySelector('svg');
    svg.classList.add('spin');
    nuiFetch('refreshCoords').then(() => {
        setTimeout(() => svg.classList.remove('spin'), 400);
    });
});

function closeMenu() {
    overlay.classList.add('hidden');
    nuiFetch('closeMenu');
    state.pendingCoord = null;
    saveRow.classList.add('hidden');
    coordName.value   = '';
    searchInput.value = '';
    modalRename.classList.add('hidden');
    modalDelete.classList.add('hidden');
}

searchInput.addEventListener('input', renderList);

window.addEventListener('message', e => {
    const { action } = e.data;

    if (action === 'openMenu') {
        overlay.classList.remove('hidden');
        if (e.data.copyFormats) {
            buildFormatSelect(e.data.copyFormats, e.data.defaultFmt || 'vector4');
        }
    }

    if (action === 'closeMenu') {
        overlay.classList.add('hidden');
    }

    if (action === 'receiveCoords') {
        state.coords = e.data.coords || [];
        renderList();
    }

    if (action === 'actionSuccess') {

    }

    if (action === 'actionError') {
        showToast(e.data.message || 'Error occurred.', 'error');
    }
});

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        if (!modalRename.classList.contains('hidden')) {
            modalRename.classList.add('hidden'); return;
        }
        if (!modalDelete.classList.contains('hidden')) {
            modalDelete.classList.add('hidden'); return;
        }
        closeMenu();
    }
});

function escHtml(str) {
    return String(str)
        .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}