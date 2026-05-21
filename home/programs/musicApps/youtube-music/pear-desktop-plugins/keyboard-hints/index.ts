import style from './style.css?inline';

import { createBackend, createPlugin, createRenderer } from '@/utils';

type KeyboardHintsPluginConfig = {
  enabled: boolean;
};

type HintTarget = {
  element: HTMLElement;
  label: string;
  left: number;
  top: number;
  width: number;
  height: number;
};

const pluginId = 'keyboard-hints';
const toggleEvent = `${pluginId}:toggle`;
const alphabet = 'asdfghjklqwertyuiopzxcvbnm';
const clickableSelector = [
  'a[href]',
  'button',
  'input:not([type="hidden"])',
  'select',
  'textarea',
  '[role="button"]',
  '[role="link"]',
  '[tabindex]:not([tabindex="-1"])',
  'tp-yt-paper-icon-button',
  'tp-yt-paper-tab',
  'ytmusic-play-button-renderer',
  'yt-button-shape button',
].join(', ');

const defaultConfig: KeyboardHintsPluginConfig = {
  enabled: false,
};

const isShortcutInput = (input: Electron.Input): boolean => {
  if (input.type !== 'keyDown') return false;

  const key = input.key.toLowerCase();
  return input.control && !input.meta && !input.alt && key === 'f';
};

const isEditableElement = (element: Element | null): boolean => {
  if (!(element instanceof HTMLElement)) return false;
  if (element.isContentEditable) return true;

  return Boolean(
    element.closest(
      'input, textarea, select, [contenteditable=""], [contenteditable="true"]',
    ),
  );
};

const getHintLength = (count: number): number => {
  let length = 2;
  let capacity = alphabet.length ** length;

  while (capacity < count) {
    length += 1;
    capacity = alphabet.length ** length;
  }

  return length;
};

const generateHintLabel = (index: number, length: number): string => {
  let current = index;
  let label = '';

  for (let position = 0; position < length; position += 1) {
    label = alphabet[current % alphabet.length] + label;
    current = Math.floor(current / alphabet.length);
  }

  return label;
};

const compareTargets = (left: HintTarget, right: HintTarget): number => {
  const topDelta = left.top - right.top;
  if (Math.abs(topDelta) > 6) return topDelta;

  const leftDelta = left.left - right.left;
  if (Math.abs(leftDelta) > 6) return leftDelta;

  const areaDelta = right.width * right.height - left.width * left.height;
  if (Math.abs(areaDelta) > 1) return areaDelta;

  return 0;
};

const backend = createBackend<
  {
    onBeforeInputEvent: (
      event: Electron.Event,
      input: Electron.Input,
    ) => void;
  },
  KeyboardHintsPluginConfig
>({
  onBeforeInputEvent() {},

  start(ctx) {
    this.onBeforeInputEvent = (event, input) => {
      if (!isShortcutInput(input)) return;

      event.preventDefault();
      ctx.window.webContents.send(toggleEvent);
    };

    ctx.window.webContents.on(
      'before-input-event',
      this.onBeforeInputEvent,
    );
  },

  stop(ctx) {
    ctx.window.webContents.removeListener(
      'before-input-event',
      this.onBeforeInputEvent,
    );
  },
});

const renderer = createRenderer<
  {
    active: boolean;
    typed: string;
    hintTargets: HintTarget[];
    overlay: HTMLDivElement | null;
    badgeMap: Map<string, HTMLDivElement>;
    labelAssignments: Map<HTMLElement, string>;
    keyHandler: (event: KeyboardEvent) => void;
    resizeHandler: () => void;
    scrollHandler: () => void;
    mutationObserver: MutationObserver | null;
    scheduledRefresh: number | null;
    activate: () => void;
    deactivate: () => void;
    toggle: () => void;
    refreshHints: () => void;
    scheduleRefresh: () => void;
    ensureOverlay: () => HTMLDivElement;
    clearOverlay: () => void;
    collectHints: () => HintTarget[];
    renderHints: () => void;
    updateMatches: () => void;
    triggerHint: (label: string) => void;
  },
  KeyboardHintsPluginConfig
>({
  active: false,
  typed: '',
  hintTargets: [],
  overlay: null,
  badgeMap: new Map(),
  labelAssignments: new Map(),
  keyHandler() {},
  resizeHandler() {},
  scrollHandler() {},
  mutationObserver: null,
  scheduledRefresh: null,

  ensureOverlay() {
    if (this.overlay?.isConnected) return this.overlay;

    const overlay = document.createElement('div');
    overlay.id = 'pear-keyboard-hints-overlay';
    document.body.appendChild(overlay);
    this.overlay = overlay;
    return overlay;
  },

  clearOverlay() {
    this.badgeMap.clear();
    this.overlay?.replaceChildren();
  },

  collectHints() {
    const elements = Array.from(
      document.querySelectorAll<HTMLElement>(clickableSelector),
    );

    const uniqueElements = elements.filter(
      (element, index) => elements.indexOf(element) === index,
    );

    const visibleElements = uniqueElements.filter((element) => {
      if (!(element instanceof HTMLElement)) return false;
      if (element.closest('#pear-keyboard-hints-overlay')) return false;
      if (element.matches('html, body')) return false;
      if (isEditableElement(element) && element !== document.activeElement) {
        return true;
      }

      const style = window.getComputedStyle(element);
      if (
        style.display === 'none' ||
        style.visibility === 'hidden' ||
        style.pointerEvents === 'none'
      ) {
        return false;
      }

      const rect = element.getBoundingClientRect();
      if (
        rect.width < 6 ||
        rect.height < 6 ||
        rect.bottom < 0 ||
        rect.right < 0 ||
        rect.top > window.innerHeight ||
        rect.left > window.innerWidth
      ) {
        return false;
      }

      const sampleX = Math.min(
        window.innerWidth - 1,
        Math.max(0, rect.left + Math.min(rect.width / 2, 16)),
      );
      const sampleY = Math.min(
        window.innerHeight - 1,
        Math.max(0, rect.top + Math.min(rect.height / 2, 16)),
      );
      const topElement = document.elementFromPoint(sampleX, sampleY);

      return Boolean(
        topElement &&
          (topElement === element || element.contains(topElement)),
      );
    });

    return visibleElements.map((element) => {
      const rect = element.getBoundingClientRect();

      return {
        element,
        label: '',
        left: Math.max(4, rect.left + window.scrollX),
        top: Math.max(4, rect.top + window.scrollY),
        width: rect.width,
        height: rect.height,
      };
    }).sort(compareTargets);
  },

  renderHints() {
    const overlay = this.ensureOverlay();
    this.clearOverlay();

    for (const hint of this.hintTargets) {
      const badge = document.createElement('div');
      badge.className = 'pear-keyboard-hint';
      badge.dataset.label = hint.label;
      badge.textContent = hint.label;
      badge.style.left = `${hint.left}px`;
      badge.style.top = `${hint.top}px`;
      overlay.appendChild(badge);
      this.badgeMap.set(hint.label, badge);
    }

    this.updateMatches();
  },

  updateMatches() {
    const typed = this.typed;
    let visibleCount = 0;

    for (const hint of this.hintTargets) {
      const badge = this.badgeMap.get(hint.label);
      if (!badge) continue;

      const matches = typed === '' || hint.label.startsWith(typed);
      badge.hidden = !matches;
      badge.classList.toggle('pear-keyboard-hint-match', matches && typed !== '');
      badge.classList.toggle('pear-keyboard-hint-exact', matches && typed === hint.label);
      if (matches) visibleCount += 1;
    }

    if (typed === '') return;

    const exactMatch = this.hintTargets.find((hint) => hint.label === typed);
    if (exactMatch) {
      this.triggerHint(exactMatch.label);
      return;
    }

    if (visibleCount === 0) {
      this.typed = '';
      this.updateMatches();
    }
  },

  triggerHint(label) {
    const target = this.hintTargets.find((hint) => hint.label === label);
    if (!target) return;

    this.deactivate();

    const element = target.element;
    element.focus({ preventScroll: false });

    if (
      element instanceof HTMLInputElement ||
      element instanceof HTMLTextAreaElement ||
      element instanceof HTMLSelectElement
    ) {
      element.select?.();
      return;
    }

    element.click();
  },

  refreshHints() {
    if (!this.active) return;
    const nextTargets = this.collectHints();
    const nextAssignments = new Map<HTMLElement, string>();
    const usedLabels = new Set<string>();

    for (const target of nextTargets) {
      const existingLabel = this.labelAssignments.get(target.element);
      if (!existingLabel) continue;

      nextAssignments.set(target.element, existingLabel);
      usedLabels.add(existingLabel);
      target.label = existingLabel;
    }

    let nextIndex = 0;
    const hintLength = getHintLength(nextTargets.length);

    for (const target of nextTargets) {
      if (target.label !== '') continue;

      let nextLabel = '';
      do {
        nextLabel = generateHintLabel(nextIndex, hintLength);
        nextIndex += 1;
      } while (usedLabels.has(nextLabel));

      target.label = nextLabel;
      nextAssignments.set(target.element, nextLabel);
      usedLabels.add(nextLabel);
    }

    this.labelAssignments = nextAssignments;
    this.hintTargets = nextTargets;
    this.renderHints();
  },

  scheduleRefresh() {
    if (!this.active || this.scheduledRefresh !== null) return;

    this.scheduledRefresh = window.requestAnimationFrame(() => {
      this.scheduledRefresh = null;
      this.refreshHints();
    });
  },

  activate() {
    if (this.active) return;
    if (isEditableElement(document.activeElement)) return;

    this.active = true;
    this.typed = '';
    document.body.classList.add('pear-keyboard-hints-active');

    this.refreshHints();

    if (!this.mutationObserver) {
      this.mutationObserver = new MutationObserver(() => this.scheduleRefresh());
      this.mutationObserver.observe(document.body, {
        childList: true,
        subtree: true,
      });
    }
  },

  deactivate() {
    if (!this.active) return;

    this.active = false;
    this.typed = '';
    this.hintTargets = [];
    this.labelAssignments.clear();
    document.body.classList.remove('pear-keyboard-hints-active');

    if (this.scheduledRefresh !== null) {
      window.cancelAnimationFrame(this.scheduledRefresh);
      this.scheduledRefresh = null;
    }

    this.mutationObserver?.disconnect();
    this.mutationObserver = null;
    this.clearOverlay();
    this.overlay?.remove();
    this.overlay = null;
  },

  toggle() {
    if (this.active) {
      this.deactivate();
    } else {
      this.activate();
    }
  },

  async start({ ipc, getConfig }) {
    const config = await getConfig();
    if (!config.enabled) return;

    this.keyHandler = (event) => {
      if (!this.active) return;

      if (event.key === 'Escape') {
        event.preventDefault();
        this.deactivate();
        return;
      }

      if (event.key === 'Backspace') {
        event.preventDefault();
        this.typed = this.typed.slice(0, -1);
        this.updateMatches();
        return;
      }

      if (event.ctrlKey || event.metaKey || event.altKey) {
        return;
      }

      if (!/^[a-z]$/i.test(event.key)) {
        return;
      }

      event.preventDefault();
      this.typed += event.key.toLowerCase();
      this.updateMatches();
    };

    this.resizeHandler = () => this.scheduleRefresh();
    this.scrollHandler = () => this.scheduleRefresh();

    window.addEventListener('keydown', this.keyHandler, true);
    window.addEventListener('resize', this.resizeHandler);
    window.addEventListener('scroll', this.scrollHandler, true);
    ipc.on(toggleEvent, () => this.toggle());
  },

  stop({ ipc }) {
    this.deactivate();
    window.removeEventListener('keydown', this.keyHandler, true);
    window.removeEventListener('resize', this.resizeHandler);
    window.removeEventListener('scroll', this.scrollHandler, true);
    ipc.removeAllListeners(toggleEvent);
  },
});

export default createPlugin({
  name: () => 'Keyboard Hints',
  description: () => 'Show keyboard hint badges over visible controls and activate them without a mouse.',
  restartNeeded: false,
  config: defaultConfig,
  stylesheets: [style],
  backend,
  renderer,
});
