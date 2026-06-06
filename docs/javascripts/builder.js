// Web command builder (docs/builder.md) — browser twin of bin/mc-tui.
// Browse the command catalog, fill <placeholders> with the same pickers
// (items, enchantments, effects, ... with official pt-BR names), then
// copy the result for the game chat or server console. Player names are
// kept in localStorage; data comes from builder-data.js (generated from
// bin/mc-tui by scripts/builder-data.py).
(function () {
  const app = document.getElementById("cb-app");
  if (!app) return;
  if (!window.MC_DATA) {
    app.innerHTML = "<p>Command data failed to load — try a hard refresh.</p>";
    return;
  }
  const D = window.MC_DATA;

  // which picker fills which <token>; anything else is a free input
  const KIND = {
    player: "players", target: "players",
    item: "items", block: "items", block2: "items",
    enchantment: "enchantments", effect: "effects", entity: "entities",
    structure: "structures", biome: "biomes",
  };
  const SELECTORS = [
    ["@s", "yourself — você (not from the console)"],
    ["@p", "nearest player — jogador mais próximo"],
    ["@a", "all players — todos os jogadores"],
    ["@r", "random player — jogador aleatório"],
    ["@e", "all entities — todas as entidades"],
  ];
  const FREE_HINTS = {
    x: "~ ok", y: "~ ok", z: "~ ok",
    x2: "~ ok", y2: "~ ok", z2: "~ ok",
    x3: "~ ok", y3: "~ ok", z3: "~ ok",
    seconds: "in seconds", ticks: "24000 = one day",
    message: "text", reason: "text", level: "number", amount: "number",
  };

  // accent-insensitive search (bússola === bussola)
  const norm = (s) =>
    s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
  const matches = (q, hay) => {
    const h = norm(hay);
    return q.split(/\s+/).every((term) => !term || h.includes(term));
  };
  const esc = (s) =>
    s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

  // --- persisted state ------------------------------------------------------
  let players = [];
  try { players = JSON.parse(localStorage.getItem("cb-players") || "[]"); } catch {}
  const savePlayers = () => localStorage.setItem("cb-players", JSON.stringify(players));
  let slash = localStorage.getItem("cb-slash") !== "0";

  // --- skeleton --------------------------------------------------------------
  const cats = [...new Set(D.catalog.map((e) => e.c))];
  app.innerHTML = `
    <div class="cb-controls">
      <input id="cb-search" type="search"
        placeholder="search commands… (give, teleport, keepinventory…)">
      <select id="cb-cat">
        <option value="">all categories</option>
        ${cats.map((c) => `<option>${esc(c)}</option>`).join("")}
      </select>
      <label class="cb-toggle" title="prefix the command with / for the in-game chat">
        <input type="checkbox" id="cb-slash"> <code>/</code> for game chat
      </label>
    </div>
    <details class="cb-players">
      <summary>Saved players (<span id="cb-pcount"></span>)</summary>
      <div class="cb-chiprow" id="cb-chips"></div>
      <div class="cb-addrow">
        <input id="cb-pname" placeholder="player name" autocomplete="off">
        <button type="button" id="cb-padd" class="cb-btn">add</button>
      </div>
      <p class="cb-hint">Stored only in this browser — offered wherever a
        command needs a <code>&lt;player&gt;</code>.</p>
    </details>
    <div id="cb-panel" class="cb-panel" hidden></div>
    <div id="cb-list" class="cb-list"></div>`;
  const $ = (id) => document.getElementById(id);
  $("cb-slash").checked = slash;

  // --- players ----------------------------------------------------------------
  function renderPlayers() {
    $("cb-pcount").textContent = players.length;
    $("cb-chips").innerHTML = players
      .map((p, i) =>
        `<span class="cb-chip">${esc(p)}<button type="button" data-i="${i}"
          aria-label="remove ${esc(p)}">&times;</button></span>`)
      .join("");
  }
  $("cb-chips").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-i]");
    if (!b) return;
    players.splice(+b.dataset.i, 1);
    savePlayers();
    renderPlayers();
  });
  function addPlayer() {
    const name = $("cb-pname").value.trim();
    if (name && !players.includes(name)) {
      players.push(name);
      players.sort();
      savePlayers();
      renderPlayers();
    }
    $("cb-pname").value = "";
  }
  $("cb-padd").addEventListener("click", addPlayer);
  $("cb-pname").addEventListener("keydown", (e) => {
    if (e.key === "Enter") { e.preventDefault(); addPlayer(); }
  });
  renderPlayers();

  // --- autocomplete -------------------------------------------------------------
  // getOpts() -> [[value, note], ...]; the note carries the pt-BR names so
  // both languages match.
  function autocomplete(input, getOpts) {
    const box = document.createElement("div");
    box.className = "cb-ac";
    box.hidden = true;
    input.parentNode.appendChild(box);
    let idx = -1;
    const close = () => { box.hidden = true; idx = -1; };
    const open = () => {
      const q = norm(input.value.trim());
      const opts = getOpts()
        .filter((o) => matches(q, o[0] + " " + (o[1] || "")))
        .slice(0, 40);
      if (!opts.length) return close();
      idx = -1;
      box.innerHTML = opts
        .map((o) =>
          `<button type="button" class="cb-ac-item" data-v="${esc(o[0])}">
            <code>${esc(o[0])}</code>${o[1] ? ` <span>${esc(o[1])}</span>` : ""}
          </button>`)
        .join("");
      box.hidden = false;
    };
    box.addEventListener("mousedown", (e) => {
      const b = e.target.closest(".cb-ac-item");
      if (!b) return;
      e.preventDefault();
      input.value = b.dataset.v;
      close();
      input.dispatchEvent(new Event("input"));
    });
    input.addEventListener("focus", open);
    input.addEventListener("input", open);
    input.addEventListener("blur", () => setTimeout(close, 150));
    input.addEventListener("keydown", (e) => {
      if (box.hidden) return;
      const els = box.children;
      if (e.key === "ArrowDown") idx = Math.min(idx + 1, els.length - 1);
      else if (e.key === "ArrowUp") idx = Math.max(idx - 1, 0);
      else if (e.key === "Enter" && idx >= 0) { els[idx].dispatchEvent(new Event("mousedown", { bubbles: true })); return e.preventDefault(); }
      else if (e.key === "Escape") return close();
      else return;
      e.preventDefault();
      [...els].forEach((el, i) => el.classList.toggle("active", i === idx));
      els[idx] && els[idx].scrollIntoView({ block: "nearest" });
    });
  }
  function pickerOpts(kind) {
    if (kind === "players")
      return players.map((p) => [p, "saved player"]).concat(SELECTORS);
    if (kind === "items")
      return D.items.map((i) => [i.id, [i.pt, i.n, i.g].filter(Boolean).join(" · ")]);
    return D[kind].map((e) => [e.id, e.n]);
  }

  // --- builder panel ---------------------------------------------------------------
  let current = null; // {entry, tokens, inputs}
  function buildCmd() {
    if (!current) return "";
    let cmd = current.entry.t;
    for (const tok of current.tokens) {
      const v = current.inputs[tok].value.trim();
      if (v) cmd = cmd.split(`<${tok}>`).join(v);
      else if (tok.endsWith("?"))
        cmd = cmd.replace(` <${tok}>`, "").replace(`<${tok}>`, "");
    }
    return (slash ? "/" : "") + cmd;
  }
  function updatePreview() {
    const prev = $("cb-prev");
    if (prev) prev.textContent = buildCmd();
  }
  function selectCommand(entry) {
    const tokens = [...new Set([...entry.t.matchAll(/<([a-z0-9_]+\??)>/g)].map((m) => m[1]))];
    const panel = $("cb-panel");
    panel.hidden = false;
    panel.innerHTML = `
      <span class="cb-cat-tag">${esc(entry.c)}</span>
      <code class="cb-tmpl">${esc(entry.t)}</code>
      <p class="cb-hint">${esc(entry.d)}</p>
      <div class="cb-fields"></div>
      <div class="cb-prevrow">
        <pre class="cb-preview"><code id="cb-prev"></code></pre>
        <button type="button" id="cb-copy" class="cb-btn cb-primary">copy</button>
      </div>`;
    const fields = panel.querySelector(".cb-fields");
    const inputs = {};
    for (const tok of tokens) {
      const name = tok.replace(/\?$/, "");
      const optional = tok.endsWith("?");
      const field = document.createElement("div");
      field.className = "cb-field";
      field.innerHTML = `<label>${esc(name)}${optional ? " <em>(optional)</em>" : ""}</label>`;
      const input = document.createElement("input");
      input.autocomplete = "off";
      input.spellcheck = false;
      input.placeholder = KIND[name] ? "pick or type…" : (FREE_HINTS[name] || "");
      field.appendChild(input);
      fields.appendChild(field);
      inputs[tok] = input;
      input.addEventListener("input", updatePreview);
      if (KIND[name]) autocomplete(input, () => pickerOpts(KIND[name]));
    }
    current = { entry, tokens, inputs };
    updatePreview();
    $("cb-copy").addEventListener("click", () => copy(buildCmd(), $("cb-copy")));
    panel.scrollIntoView({ behavior: "smooth", block: "start" });
    const first = fields.querySelector("input");
    if (first && matchMedia("(hover: hover)").matches) first.focus();
  }
  function copy(text, btn) {
    const done = () => {
      btn.textContent = "copied!";
      setTimeout(() => (btn.textContent = "copy"), 1200);
    };
    if (navigator.clipboard && navigator.clipboard.writeText)
      navigator.clipboard.writeText(text).then(done);
    else {
      const ta = document.createElement("textarea");
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      ta.remove();
      done();
    }
  }

  // --- command list -------------------------------------------------------------------
  function renderList() {
    const q = norm($("cb-search").value.trim());
    const cat = $("cb-cat").value;
    let html = "", lastCat = null, n = 0;
    for (const e of D.catalog) {
      if (cat && e.c !== cat) continue;
      if (q && !matches(q, e.c + " " + e.t + " " + e.d)) continue;
      if (e.c !== lastCat) {
        html += `<div class="cb-cathead">${esc(e.c)}</div>`;
        lastCat = e.c;
      }
      html += `<button type="button" class="cb-row" data-i="${D.catalog.indexOf(e)}">
        <code>${esc(e.t)}</code><span class="desc">${esc(e.d)}</span></button>`;
      n++;
    }
    $("cb-list").innerHTML =
      html || `<div class="cb-cathead">no commands match — try fewer words</div>`;
  }
  $("cb-list").addEventListener("click", (e) => {
    const row = e.target.closest(".cb-row");
    if (row) selectCommand(D.catalog[+row.dataset.i]);
  });
  $("cb-search").addEventListener("input", renderList);
  $("cb-cat").addEventListener("change", renderList);
  $("cb-slash").addEventListener("change", (e) => {
    slash = e.target.checked;
    localStorage.setItem("cb-slash", slash ? "1" : "0");
    updatePreview();
  });
  renderList();
})();
