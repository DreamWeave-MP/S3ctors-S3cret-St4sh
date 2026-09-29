// The St4sh's own script: the command palette that searches the whole wiki, and the portal's
// project filters. Without it every page still works: the palette's buttons do nothing, and the
// portal lists every project.
//
// The palette opens with Ctrl+K or Cmd+K anywhere, or from any [data-st4sh-palette-open]
// button. It fetches Zola's search index on first use, ranks pages by where each word matches
// (title first, then description, then body), groups them under the project they belong to,
// and keeps the last pages opened from it in localStorage.

(() => {
  'use strict';

  const script = document.currentScript;
  const RECENT_KEY = 'st4sh.palette.recent';
  const RECENT_LIMIT = 8;
  const RESULT_LIMIT = 40;

  const escapeHtml = (text) => text.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const escapeRegExp = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  function readRecent() {
    try {
      const value = JSON.parse(localStorage.getItem(RECENT_KEY) || '[]');
      return Array.isArray(value) ? value : [];
    } catch {
      return [];
    }
  }

  function remember(entry) {
    try {
      const recent = readRecent().filter((item) => item.url !== entry.url);
      recent.unshift({ url: entry.url, title: entry.title, trail: entry.trail, group: entry.group });
      localStorage.setItem(RECENT_KEY, JSON.stringify(recent.slice(0, RECENT_LIMIT)));
    } catch { /* storage may be unavailable; the palette works without it */ }
  }

  // The palette ---------------------------------------------------------------------------------

  // The template's dreamweave.js carries the search index's URL; the St4sh loads this script on
  // every page through [extra] scripts.
  const indexScript = document.querySelector('script[data-search-index]');
  const indexUrl = (script && script.dataset.searchIndex) || (indexScript && indexScript.dataset.searchIndex);
  let entries = null;
  let loading = null;
  let dialog = null;
  let input = null;
  let results = null;
  let items = [];
  let selected = -1;

  function siteRoot() {
    const url = new URL(indexUrl, window.location.href);
    return url.pathname.replace(/[^/]*$/, '');
  }

  function prettify(segment) {
    return decodeURIComponent(segment).replace(/[-_]+/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  }

  // Turns the index into entries that know their project and where they sit in it.
  function prepare(raw) {
    const root = siteRoot();
    const titles = new Map();
    const parsed = raw.map((item) => {
      const path = new URL(item.url, window.location.href).pathname;
      const rest = path.startsWith(root) ? path.slice(root.length) : path.replace(/^\//, '');
      const segments = rest.split('/').filter(Boolean);
      return { item, segments };
    });
    for (const { item, segments } of parsed) {
      if (segments.length === 1) titles.set(segments[0], item.title);
    }
    return parsed.map(({ item, segments }) => {
      const group = segments[0] || '';
      const trail = segments.slice(1, -1).map(prettify).join(' › ');
      return {
        url: item.url,
        title: item.title || prettify(segments[segments.length - 1] || 'Home'),
        description: item.description || '',
        body: item.body || '',
        group: titles.get(group) || prettify(group || 'St4sh'),
        trail,
        titleLower: (item.title || '').toLocaleLowerCase(),
        descriptionLower: (item.description || '').toLocaleLowerCase(),
        bodyLower: (item.body || '').toLocaleLowerCase(),
      };
    });
  }

  function load() {
    if (!indexUrl) return Promise.resolve([]);
    loading ??= fetch(indexUrl)
      .then((response) => {
        if (!response.ok) throw new Error(`the search index returned ${response.status}`);
        return response.json();
      })
      .then((raw) => {
        entries = prepare(Array.isArray(raw) ? raw : []);
        return entries;
      });
    return loading;
  }

  function score(entry, terms) {
    let total = 0;
    for (const term of terms) {
      let best = 0;
      const at = entry.titleLower.indexOf(term);
      if (at === 0) best = 40;
      else if (at > 0) best = /\W/.test(entry.titleLower[at - 1]) ? 26 : 14;
      if (!best && entry.descriptionLower.includes(term)) best = 7;
      if (!best) {
        const inBody = entry.bodyLower.indexOf(term);
        if (inBody < 0) return 0;
        best = 2 + Math.min(3, entry.bodyLower.split(term).length - 2);
      }
      total += best;
    }
    if (entry.titleLower === terms.join(' ')) total += 60;
    return total - entry.titleLower.length * 0.02;
  }

  function highlight(text, terms) {
    let html = escapeHtml(text);
    for (const term of terms) {
      if (!term) continue;
      html = html.replace(new RegExp(`(${escapeRegExp(escapeHtml(term))})`, 'gi'), '<mark>$1</mark>');
    }
    return html;
  }

  function snippet(entry, terms) {
    const source = entry.body || entry.description;
    if (!source) return '';
    const lower = source.toLocaleLowerCase();
    let at = -1;
    for (const term of terms) {
      at = lower.indexOf(term);
      if (at >= 0) break;
    }
    if (at < 0) return entry.description ? highlight(entry.description, terms) : '';
    const start = Math.max(0, at - 50);
    const end = Math.min(source.length, at + 110);
    return (start > 0 ? '… ' : '') + highlight(source.slice(start, end).replace(/\s+/g, ' '), terms) + (end < source.length ? ' …' : '');
  }

  function row(entry, terms, index) {
    const trail = [entry.group, entry.trail].filter(Boolean).join(' › ');
    const text = terms ? snippet(entry, terms) : '';
    return `<a class="st4sh-palette__item" role="option" id="st4sh-palette-${index}" aria-selected="false" href="${escapeHtml(entry.url)}">`
      + `<strong>${terms ? highlight(entry.title, terms) : escapeHtml(entry.title)}</strong>`
      + (trail ? `<small>${escapeHtml(trail)}</small>` : '')
      + (text ? `<span>${text}</span>` : '')
      + '</a>';
  }

  function render(query) {
    const terms = query.toLocaleLowerCase().split(/\s+/).filter(Boolean);
    let html = '';
    let shown = [];
    if (!terms.length) {
      const recent = readRecent();
      if (recent.length) {
        html += '<p class="st4sh-palette__group">Recently opened</p>';
        html += recent.map((entry, i) => row(entry, null, i)).join('');
        shown = recent;
      } else {
        html = '<p class="st4sh-palette__status">Type to search every project and every page of the wiki.</p>';
      }
    } else if (!entries) {
      html = '<p class="st4sh-palette__status">Loading the index…</p>';
    } else {
      const ranked = entries
        .map((entry) => ({ entry, value: score(entry, terms) }))
        .filter((hit) => hit.value > 0)
        .sort((a, b) => b.value - a.value)
        .slice(0, RESULT_LIMIT);
      if (!ranked.length) {
        html = `<p class="st4sh-palette__status">Nothing matches “${escapeHtml(query)}”.</p>`;
      } else {
        // Groups in the order of their best result; results in rank order inside each.
        const groups = new Map();
        for (const hit of ranked) {
          if (!groups.has(hit.entry.group)) groups.set(hit.entry.group, []);
          groups.get(hit.entry.group).push(hit.entry);
        }
        for (const [group, list] of groups) {
          html += `<p class="st4sh-palette__group">${escapeHtml(group)}</p>`;
          for (const entry of list) {
            html += row(entry, terms, shown.length);
            shown.push(entry);
          }
        }
      }
    }
    results.innerHTML = html;
    items = [...results.querySelectorAll('.st4sh-palette__item')];
    items.forEach((element, i) => {
      element.addEventListener('click', () => remember(shown[i]));
      element.addEventListener('mousemove', () => select(i, false));
    });
    select(items.length ? 0 : -1, false);
  }

  function select(index, scroll = true) {
    if (selected >= 0 && items[selected]) items[selected].setAttribute('aria-selected', 'false');
    selected = index;
    if (selected >= 0 && items[selected]) {
      items[selected].setAttribute('aria-selected', 'true');
      input.setAttribute('aria-activedescendant', items[selected].id);
      if (scroll) items[selected].scrollIntoView({ block: 'nearest' });
    } else {
      input.removeAttribute('aria-activedescendant');
    }
  }

  function build() {
    dialog = document.createElement('dialog');
    dialog.className = 'st4sh-palette';
    dialog.setAttribute('aria-label', 'Search the St4sh');
    dialog.innerHTML = `
      <div class="st4sh-palette__field">
        <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m15.5 15.5 5 5"/></svg>
        <input type="search" placeholder="Search projects and the wiki…" autocomplete="off" spellcheck="false"
          role="combobox" aria-expanded="true" aria-controls="st4sh-palette-results" aria-autocomplete="list">
        <kbd>Esc</kbd>
      </div>
      <div class="st4sh-palette__results" id="st4sh-palette-results" role="listbox" aria-label="Results"></div>
      <div class="st4sh-palette__foot" aria-hidden="true"><span>↑ ↓ to move</span><span>Enter to open</span><span>Ctrl+Enter for a new tab</span></div>`;
    document.body.append(dialog);
    input = dialog.querySelector('input');
    results = dialog.querySelector('.st4sh-palette__results');

    input.addEventListener('input', () => render(input.value));
    input.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault();
        if (!items.length) return;
        const step = event.key === 'ArrowDown' ? 1 : -1;
        select((selected + step + items.length) % items.length);
      } else if (event.key === 'Enter' && selected >= 0 && items[selected]) {
        event.preventDefault();
        const target = items[selected];
        target.dispatchEvent(new MouseEvent('click', { bubbles: false }));
        if (event.ctrlKey || event.metaKey) window.open(target.href, '_blank', 'noopener');
        else window.location.href = target.href;
      }
    });
    // A click on the backdrop, outside the panel, closes it.
    dialog.addEventListener('click', (event) => {
      if (event.target === dialog) dialog.close();
    });
  }

  function open() {
    if (!dialog) build();
    if (dialog.open) return;
    dialog.showModal();
    input.value = '';
    render('');
    input.focus();
    load().then(() => {
      if (dialog.open && input.value) render(input.value);
    }).catch(() => {
      results.innerHTML = '<p class="st4sh-palette__status">The search index could not be loaded.</p>';
    });
  }

  if (indexUrl) {
    document.addEventListener('keydown', (event) => {
      if ((event.ctrlKey || event.metaKey) && !event.altKey && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        open();
      }
    });
    for (const button of document.querySelectorAll('[data-st4sh-palette-open]')) {
      button.addEventListener('click', open);
      // Typing on a focused search button starts the search with that letter.
      button.addEventListener('keydown', (event) => {
        if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
          event.preventDefault();
          open();
          input.value = event.key;
          render(input.value);
        }
      });
    }
    const mac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
    if (mac) {
      for (const kbd of document.querySelectorAll('[data-st4sh-palette-open] kbd')) kbd.textContent = '⌘ K';
    }
  }

  // The portal's filters --------------------------------------------------------------------------

  const filters = document.querySelector('[data-st4sh-filters]');
  const grid = document.querySelector('[data-st4sh-grid]');
  if (filters && grid) {
    const chips = [...filters.querySelectorAll('[data-st4sh-filter]')];
    const text = filters.querySelector('[data-st4sh-filter-text]');
    const empty = document.querySelector('[data-st4sh-empty]');
    const cards = [...grid.querySelectorAll('.st4sh-card')];
    let category = '';

    const apply = () => {
      const wanted = category.split(/\s+/).filter(Boolean);
      const terms = text.value.toLocaleLowerCase().split(/\s+/).filter(Boolean);
      let visible = 0;
      for (const card of cards) {
        const tags = (card.dataset.tags || '').split(/\s+/);
        const haystack = card.dataset.text || '';
        const show = (!wanted.length || wanted.some((tag) => tags.includes(tag)))
          && terms.every((term) => haystack.includes(term));
        card.hidden = !show;
        if (show) visible++;
      }
      if (empty) empty.hidden = visible > 0;
    };

    for (const chip of chips) {
      chip.addEventListener('click', () => {
        category = chip.dataset.st4shFilter;
        for (const other of chips) other.setAttribute('aria-pressed', String(other === chip));
        apply();
      });
    }
    text.addEventListener('input', apply);
    const reset = document.querySelector('[data-st4sh-filter-reset]');
    if (reset) {
      reset.addEventListener('click', () => {
        category = '';
        text.value = '';
        for (const chip of chips) chip.setAttribute('aria-pressed', String(chip.dataset.st4shFilter === ''));
        apply();
      });
    }
  }
})();
