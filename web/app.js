const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ns_radialmenu';

const post = (name, data = {}) =>
    fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).then((r) => r.json()).catch(() => null);

const state = {
    settings: { theme: 'dark', blur: true, behaviour: 'hold', sound: true, colored: false, items: [] },
    locale: {},
    hour: 12,
    center: 'fa-solid fa-comment',
    open: false,
    items: [],
    depth: 1,
    hovered: -2,
    disc: null,
    settingsOpen: false,
    pool: [],
    defaults: null,
    max: 8,
    tab: 'look',
    preview: null,
    dragFrom: null
};

const $ = (id) => document.getElementById(id);

const esc = (value) =>
    String(value ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const L = (key, ...args) => {
    let text = state.locale[key] || key;
    args.forEach((a) => (text = text.replace('%s', a)));
    return text;
};

let audio;
const tone = (freq, duration, volume, type = 'sine') => {
    if (!state.settings.sound) return;
    try {
        audio = audio || new (window.AudioContext || window.webkitAudioContext)();
        const osc = audio.createOscillator();
        const gain = audio.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, audio.currentTime);
        gain.gain.setValueAtTime(volume, audio.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.0001, audio.currentTime + duration);
        osc.connect(gain).connect(audio.destination);
        osc.start();
        osc.stop(audio.currentTime + duration);
    } catch (e) {}
};

const sfx = {
    hover: () => tone(1500, 0.035, 0.025, 'triangle'),
    select: () => {
        tone(760, 0.06, 0.05);
        setTimeout(() => tone(1140, 0.07, 0.04), 45);
    },
    open: () => tone(520, 0.09, 0.04),
    back: () => tone(420, 0.07, 0.04)
};

const PALETTE = {
    light: { bg: [238, 236, 232, 0.66], border: [255, 255, 255, 0.6], hover: [255, 255, 255, 0.6], hubBg: [255, 255, 255, 0.35] },
    dark: { bg: [22, 22, 26, 0.74], border: [255, 255, 255, 0.08], hover: [255, 255, 255, 0.1], hubBg: [8, 8, 10, 0.45] }
};

const mix = (a, b, f) => a.map((v, i) => v + (b[i] - v) * f);
const rgba = (c) => `rgba(${Math.round(c[0])},${Math.round(c[1])},${Math.round(c[2])},${c[3].toFixed(3)})`;
const clamp = (v) => Math.max(0, Math.min(1, v));
const daylight = (hour) => (Math.cos(((hour - 13) / 12) * Math.PI) + 1) / 2;

const DYNAMIC_VARS = ['--disc-bg', '--disc-border', '--seg-hover', '--hub-bg', '--text', '--muted', '--hub-ring', '--hub-inner', '--hub-icon'];

function applyTheme(el, theme, hour) {
    el.classList.remove('theme-light', 'theme-dark', 'theme-dynamic');
    DYNAMIC_VARS.forEach((v) => el.style.removeProperty(v));
    if (theme !== 'dynamic') {
        el.classList.add(`theme-${theme}`);
        return;
    }
    const f = daylight(hour);
    const a = mix(PALETTE.dark.bg, PALETTE.light.bg, clamp(f + 0.35));
    const b = mix(PALETTE.dark.bg, PALETTE.light.bg, clamp(f - 0.35));
    const bright = f >= 0.5;
    el.classList.add(bright ? 'theme-light' : 'theme-dark', 'theme-dynamic');
    el.style.setProperty('--disc-bg', `linear-gradient(135deg, ${rgba(a)} 0%, ${rgba(a)} 38%, ${rgba(b)} 62%, ${rgba(b)} 100%)`);
    el.style.setProperty('--disc-border', rgba(mix(PALETTE.dark.border, PALETTE.light.border, f)));
    el.style.setProperty('--seg-hover', rgba(mix(PALETTE.dark.hover, PALETTE.light.hover, f)));
    el.style.setProperty('--hub-bg', rgba(mix(PALETTE.dark.hubBg, PALETTE.light.hubBg, f)));
}

const HUB_R = 50;
const RING_R = 148;

function wedge(index, count, r1, r2) {
    if (count <= 1) {
        return `M 0 ${-r2} A ${r2} ${r2} 0 1 1 0 ${r2} A ${r2} ${r2} 0 1 1 0 ${-r2} Z M 0 ${-r1} A ${r1} ${r1} 0 1 0 0 ${r1} A ${r1} ${r1} 0 1 0 0 ${-r1} Z`;
    }
    const step = (Math.PI * 2) / count;
    const a0 = -Math.PI / 2 - step / 2 + index * step;
    const a1 = a0 + step;
    const p = (r, a) => `${(r * Math.cos(a)).toFixed(2)} ${(r * Math.sin(a)).toFixed(2)}`;
    const large = step > Math.PI ? 1 : 0;
    return `M ${p(r2, a0)} A ${r2} ${r2} 0 ${large} 1 ${p(r2, a1)} L ${p(r1, a1)} A ${r1} ${r1} 0 ${large} 0 ${p(r1, a0)} Z`;
}

function createDisc() {
    const root = document.createElement('div');
    root.className = 'disc';
    root.innerHTML = `
        <svg viewBox="-150 -150 300 300"><path class="disc-hl" fill-rule="evenodd"></path></svg>
        <div class="disc-items"></div>
        <div class="disc-hub"><div class="hub-core"><i></i></div></div>`;
    return root;
}

function renderDisc(root, items, opts = {}) {
    applyTheme(root, opts.theme || 'dark', opts.hour ?? 12);
    root.classList.toggle('colored', !!opts.colored);
    root._items = items;
    const wrap = root.querySelector('.disc-items');
    wrap.innerHTML = '';
    const count = items.length;
    items.forEach((item, i) => {
        const angle = -Math.PI / 2 + (i * Math.PI * 2) / Math.max(count, 1);
        const radius = count === 1 ? 0 : 102;
        const x = 50 + ((radius * Math.cos(angle)) / 300) * 100;
        const y = count === 1 ? 17 : 50 + ((radius * Math.sin(angle)) / 300) * 100;
        const el = document.createElement('div');
        el.className = 'disc-item' + (item.active ? ' active' : '');
        el.style.left = `${x}%`;
        el.style.top = `${y}%`;
        if (item.color) el.style.setProperty('--c', item.color);
        el.innerHTML = `${item.submenu ? '<i class="fa-solid fa-circle sub"></i>' : ''}<i class="${esc(item.icon || 'fa-solid fa-circle')}"></i><span>${esc(item.label)}</span>`;
        wrap.appendChild(el);
    });
    root.querySelector('.hub-core i').className = opts.center || state.center;
    setHover(root, opts.hovered ?? -2);
}

function setHover(root, index) {
    const items = root._items || [];
    const path = root.querySelector('.disc-hl');
    root.querySelectorAll('.disc-item').forEach((el, i) => el.classList.toggle('hover', i === index));
    root.querySelector('.disc-hub').classList.toggle('hover', index === -1);
    if (index >= 0 && items[index]) {
        path.setAttribute('d', wedge(index, items.length, HUB_R + 2, RING_R));
        path.style.setProperty('--c', items[index].color || '#ffffff');
        path.style.opacity = 1;
    } else {
        path.style.opacity = 0;
    }
}

function pickIndex(root, count, event) {
    const rect = root.getBoundingClientRect();
    const scale = 300 / rect.width;
    const dx = (event.clientX - (rect.left + rect.width / 2)) * scale;
    const dy = (event.clientY - (rect.top + rect.height / 2)) * scale;
    if (Math.hypot(dx, dy) < HUB_R) return -1;
    if (!count) return -2;
    const step = (Math.PI * 2) / count;
    let angle = Math.atan2(dy, dx) + Math.PI / 2 + step / 2;
    angle = ((angle % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2);
    return Math.floor(angle / step) % count;
}

function radialOpts(extra = {}) {
    return {
        theme: state.settings.theme,
        hour: state.hour,
        colored: state.settings.colored,
        center: state.depth > 1 ? 'fa-solid fa-arrow-left' : state.center,
        ...extra
    };
}

function openRadial(data) {
    state.settings = data.settings || state.settings;
    state.hour = data.hour ?? state.hour;
    state.center = data.center || state.center;
    state.open = true;
    state.hovered = -2;
    state.items = [];
    const stage = $('radial-stage');
    stage.innerHTML = '';
    state.disc = createDisc();
    stage.appendChild(state.disc);
    $('radial').classList.remove('hidden', 'closing');
    sfx.open();
}

function setItems(data) {
    if (!state.open || !state.disc) return;
    const deeper = data.depth !== state.depth;
    state.items = data.items || [];
    state.depth = data.depth || 1;
    state.hovered = -2;
    renderDisc(state.disc, state.items, radialOpts());
    const title = $('radial-title');
    title.textContent = data.title || '';
    title.classList.toggle('hidden', !data.title);
    if (deeper) {
        const stage = $('radial-stage');
        stage.classList.remove('swap');
        void stage.offsetWidth;
        stage.classList.add('swap');
    }
}

function closeRadial() {
    if (!state.open) return;
    state.open = false;
    const radial = $('radial');
    radial.classList.add('closing');
    setTimeout(() => {
        if (!state.open) {
            radial.classList.add('hidden');
            radial.classList.remove('closing');
            $('radial-stage').innerHTML = '';
            state.disc = null;
        }
    }, 140);
}

function chooseHovered(release) {
    const index = state.hovered;
    if (index === -1) {
        if (release) return post('close');
        sfx.back();
        return post('back');
    }
    const item = state.items[index];
    if (!item) return release ? post('close') : null;
    sfx.select();
    post('select', { id: item.id, release: !!release });
}

document.addEventListener('mousemove', (event) => {
    if (state.open && state.disc) {
        const index = pickIndex(state.disc, state.items.length, event);
        if (index !== state.hovered) {
            state.hovered = index;
            setHover(state.disc, index);
            if (index >= 0 || index === -1) sfx.hover();
        }
    }
    if (state.settingsOpen && state.preview && !event.target.closest('.drawer')) {
        setHover(state.preview, pickLive(state.preview, event));
    }
});

function pickLive(root, event) {
    const rect = root.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) return -2;
    return pickIndex(root, (root._items || []).length, event);
}

document.addEventListener('mousedown', (event) => {
    if (!state.open) return;
    if (event.button === 0) chooseHovered(false);
    if (event.button === 2) {
        sfx.back();
        post('back');
    }
});

document.addEventListener('contextmenu', (event) => event.preventDefault());

document.addEventListener('keydown', (event) => {
    if (state.open) {
        if (event.key === 'Escape') post('close');
        if (event.key === 'Backspace') post('back');
        return;
    }
    if (state.settingsOpen && event.key === 'Escape') closeSettings(true);
});

function poolItem(id) {
    return state.pool.find((p) => p.id === id);
}

function previewItems() {
    return state.settings.items.map(poolItem).filter(Boolean);
}

function save() {
    post('saveSettings', state.settings);
}

function openSettings(data) {
    state.settings = JSON.parse(JSON.stringify(data.settings));
    state.defaults = data.defaults;
    state.pool = data.pool || [];
    state.max = data.max || 8;
    state.hour = data.hour ?? state.hour;
    state.center = data.center || state.center;
    state.locale = data.locale || state.locale;
    state.tab = 'look';
    state.settingsOpen = true;

    $('st-server').textContent = data.server || '';
    $('st-sub').textContent = L('ui_subtitle');
    $('st-name').textContent = data.profile?.name || '';
    $('st-id').textContent = `${L('ui_id')} ${data.profile?.id ?? ''}`;
    const avatar = $('st-avatar');
    if (data.profile?.avatar) {
        avatar.style.backgroundImage = `url('${data.profile.avatar}')`;
        avatar.classList.add('has-img');
    } else {
        avatar.style.backgroundImage = '';
        avatar.classList.remove('has-img');
    }
    $('st-revert-label').textContent = L('ui_revert');
    $('st-close').title = L('ui_close');
    $('st-hint').textContent = L('ui_preview_hint');
    $('settings').classList.remove('hidden');
    renderSettings();
}

function closeSettings(notify) {
    state.settingsOpen = false;
    $('settings').classList.add('hidden');
    $('st-preview').innerHTML = '';
    state.preview = null;
    if (notify) post('closeSettings');
}

const TABS = [
    { id: 'look', icon: 'fa-solid fa-palette', label: 'ui_tab_look' },
    { id: 'controls', icon: 'fa-solid fa-sliders', label: 'ui_tab_controls' },
    { id: 'layout', icon: 'fa-solid fa-circle-nodes', label: 'ui_tab_layout' }
];

const THEMES = [
    { id: 'dark', icon: 'fa-solid fa-moon', label: 'ui_dark' },
    { id: 'light', icon: 'fa-solid fa-sun', label: 'ui_light' },
    { id: 'dynamic', icon: 'fa-solid fa-circle-half-stroke', label: 'ui_dynamic' }
];

const MODES = [
    { id: 'hold', icon: 'fa-solid fa-hand-back-fist', label: 'ui_hold', desc: 'ui_hold_desc' },
    { id: 'press', icon: 'fa-solid fa-hand-pointer', label: 'ui_press', desc: 'ui_press_desc' }
];

function renderSettings() {
    $('st-tabs').innerHTML = TABS.map((t) => `<button class="${state.tab === t.id ? 'on' : ''}" data-tab="${t.id}"><i class="${t.icon}"></i><span>${esc(L(t.label))}</span></button>`).join('');
    $('st-tabs').querySelectorAll('[data-tab]').forEach((b) =>
        b.addEventListener('click', () => {
            if (state.tab === b.dataset.tab) return;
            state.tab = b.dataset.tab;
            sfx.hover();
            renderSettings();
        })
    );
    $('st-revert').classList.toggle('hidden', state.tab !== 'layout');
    renderMain();
    renderPreview();
}

function switchRow(key, label, desc) {
    const on = !!state.settings[key];
    return `<button class="opt" data-toggle="${key}" role="switch" aria-checked="${on}">
        <span class="opt-text"><strong>${esc(L(label))}</strong><small>${esc(L(desc))}</small></span>
        <span class="switch ${on ? 'on' : ''}"></span>
    </button>`;
}

function renderMain() {
    const main = $('st-main');
    const s = state.settings;
    let html = '';

    if (state.tab === 'look') {
        html += `<h2>${esc(L('ui_theme'))}</h2><p class="lead">${esc(L('ui_desc_theme'))}</p>`;
        html += `<div class="swatches">${THEMES.map((t) => `<button class="swatch ${s.theme === t.id ? 'on' : ''}" data-theme="${t.id}">
            <span class="chip chip-${t.id}"><i class="${t.icon}"></i></span>
            <span class="swatch-name">${esc(L(t.label))}</span>
            <i class="fa-solid fa-check tick"></i>
        </button>`).join('')}</div>`;
        html += `<div class="group">${switchRow('colored', 'ui_colored', 'ui_desc_colored')}</div>`;
    } else if (state.tab === 'controls') {
        html += `<h2>${esc(L('ui_open_mode'))}</h2><p class="lead">${esc(L('ui_desc_behaviour'))}</p>`;
        html += `<div class="modes">${MODES.map((m) => `<button class="mode ${s.behaviour === m.id ? 'on' : ''}" data-behaviour="${m.id}">
            <i class="${m.icon}"></i>
            <span><strong>${esc(L(m.label))}</strong><small>${esc(L(m.desc))}</small></span>
        </button>`).join('')}</div>`;
        html += `<div class="group">${switchRow('blur', 'ui_blur', 'ui_desc_blur')}${switchRow('sound', 'ui_sound', 'ui_desc_sound')}</div>`;
    } else {
        const items = s.items;
        const available = state.pool.filter((p) => !items.includes(p.id));
        const full = items.length >= state.max;
        html += `<div class="slots-head"><h2>${esc(L('ui_slots'))}</h2><span class="count ${full ? 'full' : ''}">${esc(L('ui_slots_used', items.length, state.max))}</span></div>`;
        html += `<p class="lead">${esc(L('ui_layout_desc'))}</p><ol class="slots">`;
        for (let i = 0; i < state.max; i++) {
            const id = items[i];
            const p = id && poolItem(id);
            if (id) {
                html += `<li class="slot" data-index="${i}" draggable="true" style="--c:${esc(p?.color || '#fff')}">
                    <span class="slot-n">${i + 1}</span>
                    <i class="slot-ic ${esc(p?.icon || 'fa-solid fa-circle')}"></i>
                    <span class="slot-name">${esc(p ? p.label : id)}</span>
                    <span class="slot-tools">
                        <button data-move="${i}" data-dir="-1" title="${esc(L('ui_move_up'))}" ${i === 0 ? 'disabled' : ''}><i class="fa-solid fa-chevron-up"></i></button>
                        <button data-move="${i}" data-dir="1" title="${esc(L('ui_move_down'))}" ${i === items.length - 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-down"></i></button>
                        <button data-del="${i}" title="${esc(L('ui_remove'))}"><i class="fa-solid fa-xmark"></i></button>
                    </span>
                </li>`;
            } else {
                html += `<li class="slot empty"><span class="slot-n">${i + 1}</span><span class="slot-name">${esc(L('ui_empty_slot'))}</span></li>`;
            }
        }
        html += `</ol><h3>${esc(L('ui_available'))}</h3>`;
        html += available.length
            ? `<div class="pool ${full ? 'locked' : ''}">${available.map((p) => `<button class="pill" data-add="${esc(p.id)}" style="--c:${esc(p.color || '#fff')}" ${full ? 'disabled' : ''}><i class="${esc(p.icon)}"></i><span>${esc(p.label)}</span><i class="fa-solid fa-plus plus"></i></button>`).join('')}</div>`
            : `<p class="muted-note">${esc(L('ui_all_added'))}</p>`;
    }

    main.innerHTML = html;
    bindMain(main);
}

function bindMain(main) {
    main.querySelectorAll('[data-theme]').forEach((b) => b.addEventListener('click', () => update({ theme: b.dataset.theme })));
    main.querySelectorAll('[data-behaviour]').forEach((b) => b.addEventListener('click', () => update({ behaviour: b.dataset.behaviour })));
    main.querySelectorAll('[data-toggle]').forEach((b) =>
        b.addEventListener('click', () => {
            const key = b.dataset.toggle;
            update({ [key]: !state.settings[key] });
            if (key === 'blur') post('previewBlur', { on: state.settings.blur });
        })
    );
    main.querySelectorAll('[data-add]').forEach((b) =>
        b.addEventListener('click', () => {
            if (state.settings.items.length >= state.max) return;
            state.settings.items = [...state.settings.items, b.dataset.add];
            sfx.select();
            commit();
        })
    );
    main.querySelectorAll('[data-del]').forEach((b) =>
        b.addEventListener('click', () => {
            const index = Number(b.dataset.del);
            state.settings.items = state.settings.items.filter((_, i) => i !== index);
            sfx.back();
            commit();
        })
    );
    main.querySelectorAll('[data-move]').forEach((b) =>
        b.addEventListener('click', () => {
            const from = Number(b.dataset.move);
            moveSlot(from, from + Number(b.dataset.dir));
        })
    );
    main.querySelectorAll('.slot:not(.empty)').forEach((row) => {
        const index = Number(row.dataset.index);
        row.addEventListener('mouseenter', () => state.preview && setHover(state.preview, index));
        row.addEventListener('mouseleave', () => state.preview && setHover(state.preview, -2));
        row.addEventListener('dragstart', (e) => {
            state.dragFrom = index;
            row.classList.add('dragging');
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', String(index));
        });
        row.addEventListener('dragend', () => {
            row.classList.remove('dragging');
            main.querySelectorAll('.slot').forEach((r) => r.classList.remove('over'));
            state.dragFrom = null;
        });
        row.addEventListener('dragover', (e) => {
            e.preventDefault();
            main.querySelectorAll('.slot').forEach((r) => r.classList.toggle('over', r === row));
        });
        row.addEventListener('drop', (e) => {
            e.preventDefault();
            if (state.dragFrom !== null) moveSlot(state.dragFrom, index);
        });
    });
}

function moveSlot(from, to) {
    const list = [...state.settings.items];
    if (from === to || to < 0 || to >= list.length) return;
    const [moved] = list.splice(from, 1);
    list.splice(to, 0, moved);
    state.settings.items = list;
    sfx.hover();
    commit();
}

function update(patch) {
    Object.assign(state.settings, patch);
    sfx.select();
    commit();
}

function commit() {
    save();
    renderMain();
    renderPreview();
}

function renderPreview() {
    const host = $('st-preview');
    if (!state.preview) {
        host.innerHTML = '';
        state.preview = createDisc();
        host.appendChild(state.preview);
    }
    const s = state.settings;
    renderDisc(state.preview, previewItems(), { theme: s.theme, colored: s.colored, hour: state.hour, center: state.center, hovered: -2 });
    const area = host.parentElement;
    const scale = Math.max(0.6, Math.min(1.35, (Math.min(area.clientWidth, area.clientHeight) - 160) / 300));
    host.style.setProperty('--s', scale.toFixed(3));
}

$('st-revert').addEventListener('click', () => {
    if (!state.defaults) return;
    state.settings.items = [...state.defaults.items];
    sfx.back();
    commit();
});

$('st-close').addEventListener('click', () => closeSettings(true));

window.addEventListener('resize', () => {
    if (state.settingsOpen) renderPreview();
});

window.addEventListener('message', (event) => {
    const data = event.data || {};
    switch (data.action) {
        case 'open':
            openRadial(data);
            break;
        case 'setItems':
            setItems(data);
            break;
        case 'close':
            closeRadial();
            break;
        case 'release':
            if (state.open) chooseHovered(true);
            break;
        case 'openSettings':
            openSettings(data);
            break;
        case 'closeSettings':
            closeSettings(false);
            break;
    }
});

post('ready').then((res) => {
    if (res && res.locale) state.locale = res.locale;
});
