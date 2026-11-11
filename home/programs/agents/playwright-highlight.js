// Visual feedback for agent-driven browsers: cursor dot, click ripple, focus ring, key echo.
(() => {
  if (window.__pwHighlight) return;
  window.__pwHighlight = true;

  const css = `
    .pwh{position:fixed;pointer-events:none;z-index:2147483647;box-sizing:border-box}
    .pwh-cursor{width:18px;height:18px;margin:-9px 0 0 -9px;border-radius:50%;background:rgba(255,60,60,.55);border:2px solid #ff3c3c;transition:left .12s,top .12s}
    .pwh-ripple{width:14px;height:14px;margin:-7px 0 0 -7px;border-radius:50%;border:3px solid #ff3c3c;animation:pwh-r .6s ease-out forwards}
    @keyframes pwh-r{to{transform:scale(4);opacity:0}}
    .pwh-focus{border:3px solid #2b8aff;border-radius:4px;box-shadow:0 0 0 3px rgba(43,138,255,.3);transition:all .1s}
    .pwh-key{right:12px;bottom:12px;padding:4px 10px;border-radius:6px;background:rgba(0,0,0,.8);color:#fff;font:14px monospace;opacity:0;transition:opacity .3s}
  `;
  const mk = (cls) => {
    const el = document.createElement('div');
    el.className = 'pwh ' + cls;
    return el;
  };

  let cursor, focus, key, keyTimer;
  const setup = () => {
    if (cursor) return;
    const style = document.createElement('style');
    style.textContent = css;
    cursor = mk('pwh-cursor'); focus = mk('pwh-focus'); key = mk('pwh-key');
    cursor.style.display = focus.style.display = 'none';
    document.documentElement.append(style, cursor, focus, key);
  };

  const place = (el) => {
    const r = el.getBoundingClientRect();
    Object.assign(focus.style, {
      display: r.width ? 'block' : 'none',
      left: r.left - 3 + 'px', top: r.top - 3 + 'px',
      width: r.width + 6 + 'px', height: r.height + 6 + 'px',
    });
  };

  const on = (type, fn) => addEventListener(type, (e) => { setup(); fn(e); }, true);

  on('mousemove', (e) => {
    cursor.style.display = 'block';
    cursor.style.left = e.clientX + 'px';
    cursor.style.top = e.clientY + 'px';
  });
  on('mousedown', (e) => {
    const r = mk('pwh-ripple');
    r.style.left = e.clientX + 'px';
    r.style.top = e.clientY + 'px';
    document.documentElement.append(r);
    setTimeout(() => r.remove(), 700);
  });
  on('focusin', (e) => { if (e.target !== document.body) place(e.target); });
  on('focusout', () => { focus.style.display = 'none'; });
  on('keydown', (e) => {
    key.textContent = [e.ctrlKey && 'Ctrl', e.altKey && 'Alt', e.metaKey && 'Meta', e.key].filter(Boolean).join('+');
    key.style.opacity = 1;
    clearTimeout(keyTimer);
    keyTimer = setTimeout(() => (key.style.opacity = 0), 1200);
  });
  on('scroll', () => { if (document.activeElement && focus.style.display !== 'none') place(document.activeElement); });
})();
