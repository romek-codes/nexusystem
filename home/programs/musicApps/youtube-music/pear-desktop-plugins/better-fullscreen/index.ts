import style from './style.css?inline';

import { jaroWinkler } from '@skyra/jaro-winkler';
import { createBackend, createPlugin, createRenderer } from '@/utils';
import { YTMusic } from '@/plugins/synced-lyrics/providers/YTMusic';
import { LRC } from '@/plugins/synced-lyrics/parsers/lrc';

import type { MenuContext } from '@/types/contexts';
import type { MenuItemConstructorOptions } from 'electron';
import type { SongInfo } from '@/providers/song-info';
import type { MusicPlayer } from '@/types/music-player';
import type {
  LyricResult,
  SearchSongInfo,
} from '@/plugins/synced-lyrics/types';

type BetterFullscreenPluginConfig = {
  enabled: boolean;
};

type WindowState = {
  fullscreen: boolean;
  width: number;
  height: number;
};

type LayoutMode = 'portrait' | 'landscape';

const pluginId = 'better-fullscreen';
const activeClass = 'pear-better-fullscreen-active';
const layoutAttribute = 'data-better-fullscreen-layout';
const backdropId = 'pear-bf-backdrop';
const backdropImageId = 'pear-bf-backdrop-image';
const backdropVideoId = 'pear-bf-backdrop-video';
const shellId = 'pear-bf-shell';
const mediaSlotId = 'pear-bf-media-slot';
const lyricsSlotId = 'pear-bf-lyrics-slot';
const lyricsHostId = 'pear-bf-lyrics-host';
const titleTextId = 'pear-bf-title';
const bylineTextId = 'pear-bf-byline';
const progressId = 'pear-bf-progress';

const defaultConfig: BetterFullscreenPluginConfig = {
  enabled: false,
};

const getWindowState = (window: Electron.BrowserWindow): WindowState => {
  const { width, height } = window.getBounds();

  return {
    fullscreen: window.isFullScreen(),
    width,
    height,
  };
};

const clamp = (value: number, min: number, max: number): number =>
  Math.min(max, Math.max(min, value));

const formatTime = (seconds: number): string => {
  if (!Number.isFinite(seconds) || seconds < 0) {
    return '0:00';
  }

  const wholeSeconds = Math.floor(seconds);
  const hours = Math.floor(wholeSeconds / 3600);
  const minutes = Math.floor((wholeSeconds % 3600) / 60);
  const secs = wholeSeconds % 60;

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }

  return `${minutes}:${String(secs).padStart(2, '0')}`;
};

type LRCLibSearchItem = {
  trackName: string;
  artistName: string;
  albumName: string;
  duration: number;
  instrumental: boolean;
  plainLyrics: string;
  syncedLyrics: string;
};

const searchLRCLibFallback = async ({
  title,
  alternativeTitle,
  artist,
  album,
  songDuration,
  tags,
}: SearchSongInfo): Promise<LyricResult | null> => {
  const baseUrl = 'https://lrclib.net';

  let query = new URLSearchParams({
    artist_name: artist,
    track_name: title,
  });

  if (album) {
    query.set('album_name', album);
  }

  let response = await fetch(`${baseUrl}/api/search?${query.toString()}`);
  if (!response.ok) {
    throw new Error(`bad HTTPStatus(${response.statusText})`);
  }

  let data = (await response.json()) as LRCLibSearchItem[];
  if (!Array.isArray(data)) {
    throw new Error(`Expected LRCLib array, got ${typeof data}`);
  }

  if (data.length === 0) {
    const trackName = alternativeTitle || title;
    query = new URLSearchParams({ q: trackName });
    response = await fetch(`${baseUrl}/api/search?${query.toString()}`);
    if (!response.ok) {
      throw new Error(`bad HTTPStatus(${response.statusText})`);
    }

    data = (await response.json()) as LRCLibSearchItem[];
    if (!Array.isArray(data)) {
      throw new Error(`Expected LRCLib array, got ${typeof data}`);
    }

    if (data.length === 0 && alternativeTitle) {
      query = new URLSearchParams({ q: title });
      response = await fetch(`${baseUrl}/api/search?${query.toString()}`);
      if (!response.ok) {
        throw new Error(`bad HTTPStatus(${response.statusText})`);
      }

      data = (await response.json()) as LRCLibSearchItem[];
      if (!Array.isArray(data)) {
        throw new Error(`Expected LRCLib array, got ${typeof data}`);
      }
    }
  }

  const filteredResults = data.filter((item) => {
    const artists = artist.split(/[&,]/g).map((value) => value.trim());
    const itemArtists = item.artistName.split(/[&,]/g).map((value) => value.trim());

    const permutations: Array<[string, string]> = [];
    for (const artistA of artists) {
      for (const artistB of itemArtists) {
        permutations.push([artistA.toLowerCase(), artistB.toLowerCase()]);
      }
    }

    for (const artistA of itemArtists) {
      for (const artistB of artists) {
        permutations.push([artistA.toLowerCase(), artistB.toLowerCase()]);
      }
    }

    let ratio = Math.max(
      0,
      ...permutations.map(([left, right]) => jaroWinkler(left, right)),
    );

    if (ratio <= 0.9 && tags?.length) {
      const filteredTags = tags.filter(
        (tag) => tag.toLowerCase() !== artist.toLowerCase(),
      );

      const tagPermutations: Array<[string, string]> = [];
      for (const tag of filteredTags) {
        for (const itemArtist of itemArtists) {
          tagPermutations.push([tag.toLowerCase(), itemArtist.toLowerCase()]);
          tagPermutations.push([itemArtist.toLowerCase(), tag.toLowerCase()]);
        }
      }

      if (tagPermutations.length > 0) {
        ratio = Math.max(
          ratio,
          ...tagPermutations.map(([left, right]) => jaroWinkler(left, right)),
        );
      }
    }

    return ratio > 0.9;
  });

  filteredResults.sort((left, right) => {
    return Math.abs(left.duration - songDuration) - Math.abs(right.duration - songDuration);
  });

  const closestResult = filteredResults[0];
  if (!closestResult) {
    return null;
  }

  if (Math.abs(closestResult.duration - songDuration) > 15) {
    return null;
  }

  if (closestResult.instrumental) {
    return null;
  }

  const raw = closestResult.syncedLyrics;
  const plain = closestResult.plainLyrics;
  if (!raw && !plain) {
    return null;
  }

  return {
    title: closestResult.trackName,
    artists: closestResult.artistName.split(/[&,]/g),
    lines: raw
      ? LRC.parse(raw).lines.map((line) => ({
          ...line,
          status: 'upcoming' as const,
        }))
      : undefined,
    lyrics: plain || undefined,
  };
};

const menu = async (
  _ctx: MenuContext<BetterFullscreenPluginConfig>,
): Promise<MenuItemConstructorOptions[]> => {
  return [];
};

const backend = createBackend<
  {
    emitWindowState: () => void;
    onWindowStateChange: () => void;
  },
  BetterFullscreenPluginConfig
>({
  emitWindowState() {},
  onWindowStateChange() {},

  start(ctx) {
    this.emitWindowState = () => {
      ctx.window.webContents.send(
        `${pluginId}:window-state`,
        getWindowState(ctx.window),
      );
    };

    this.onWindowStateChange = () => {
      this.emitWindowState();
    };

    ctx.ipc.handle(`${pluginId}:get-window-state`, () =>
      getWindowState(ctx.window),
    );
    ctx.ipc.handle(`${pluginId}:set-fullscreen`, (_event, fullscreen: boolean) => {
      ctx.window.setFullScreen(fullscreen);
      this.emitWindowState();
    });

    for (const event of [
      'enter-full-screen',
      'leave-full-screen',
      'maximize',
      'unmaximize',
      'resize',
    ] as const) {
      ctx.window.on(event, this.onWindowStateChange);
    }

    this.emitWindowState();
  },

  stop(ctx) {
    ctx.ipc.removeHandler(`${pluginId}:get-window-state`);
    ctx.ipc.removeHandler(`${pluginId}:set-fullscreen`);

    for (const event of [
      'enter-full-screen',
      'leave-full-screen',
      'maximize',
      'unmaximize',
      'resize',
    ] as const) {
      ctx.window.removeListener(event, this.onWindowStateChange);
    }
  },
});

const renderer = createRenderer<
  {
    config: BetterFullscreenPluginConfig;
    windowState: WindowState;
    customFullscreenRequested: boolean;
    suspendCustomForCurrentFullscreen: boolean;
    isActive: boolean;
    openedPlayerPageForActivation: boolean;
    previousSelectedTabIndex: number | null;
    resizeHandler: () => void;
    videoDataChangeHandler: EventListener;
    observer: MutationObserver | null;
    syncQueued: boolean;
    keydownHandler: (event: KeyboardEvent) => void;
    fullscreenChangeHandler: () => void;
    progressIntervalId: number | null;
    metadataIntervalId: number | null;
    backgroundIntervalId: number | null;
    backdropVideoFrameId: number | null;
    backdropVideoLastFrameAt: number;
    lastBackgroundImageUrl: string | null;
    preferredSyncedLyrics: boolean;
    latestSongInfo: SongInfo | null;
    playerApi: MusicPlayer | null;
    lyricsProvider: YTMusic | null;
    lyricsResult: LyricResult | null;
    lyricsFetchKey: string | null;
    lyricsFetchNonce: number;
    lyricsCurrentIndex: number;
    lyricsFetchInFlight: boolean;
    scheduleSync: () => void;
    syncState: () => Promise<void>;
    shouldActivate: () => boolean;
    isEditableTarget: (target: EventTarget | null) => boolean;
    isPortraitWindow: () => boolean;
    getLayoutMode: () => LayoutMode;
    getLayout: () => HTMLElement | null;
    getActivePlayerPageRoot: () => HTMLElement | null;
    isVisibleElement: (element: Element | null) => boolean;
    getShell: () => HTMLElement | null;
    getTogglePlayerPageButton: () => HTMLButtonElement | null;
    getLyricsTab: () => HTMLElement | null;
    getAllLyricsTabs: () => HTMLElement[];
    getLyricsRenderer: () => HTMLElement | null;
    getSyncedLyricsContainer: () => HTMLElement | null;
    ensureLyricsHost: () => HTMLElement | null;
    ensureShell: () => HTMLElement;
    removeShell: () => void;
    restoreMovedNodes: () => void;
    mountMediaIntoShell: () => void;
    mountLyricsIntoShell: () => void;
    fetchFullscreenLyrics: () => Promise<boolean>;
    renderFullscreenLyrics: () => void;
    updateFullscreenLyricsState: () => void;
    clearFullscreenLyrics: () => void;
    updateShellMetadata: () => void;
    ensureShellMetadataReady: () => void;
    refreshLatestSongInfoFromDom: () => void;
    buildSongInfoFromPlayerApi: () => SongInfo | null;
    updateMediaFrameVariables: () => void;
    updateLyricsFrameVariables: () => void;
    getSelectedTabIndex: () => number | null;
    getSongImage: () => HTMLImageElement | null;
    getSongVideo: () => HTMLVideoElement | null;
    isSongImageVisible: () => boolean;
    isSongVideoVisible: () => boolean;
    getMediaElementForProgress: () => HTMLMediaElement | null;
    isNativePlayerFullscreen: () => boolean;
    isPlayerPageOpen: () => boolean;
    isPlayerPageReady: () => boolean;
    waitForPlayerPageReady: () => Promise<boolean>;
    waitForLyricsTab: () => Promise<HTMLElement | null>;
    waitForLyricsContentReady: () => Promise<boolean>;
    openPlayerPageIfNeeded: () => void;
    closePlayerPageIfNeeded: () => void;
    ensureLyricsViewReady: () => Promise<boolean>;
    preferSyncedLyricsSource: () => void;
    restoreSelectedTab: () => void;
    setActiveClass: (active: boolean) => void;
    setLayoutAttribute: (active: boolean) => void;
    ensureBackdrop: () => void;
    clearBackdrop: () => void;
    updateBackgroundVisuals: () => void;
    updateBackgroundImage: () => void;
    updateBackdropVideoFrame: () => void;
    tickBackdropVideoFrame: (timestamp: number) => void;
    setLyricsVariables: (active: boolean) => void;
    ensureCustomProgress: () => HTMLElement | null;
    removeCustomProgress: () => void;
    updateProgressDisplay: () => void;
    startVisualLoops: () => void;
    stopVisualLoops: () => void;
    observeLayout: () => void;
    disconnectObserver: () => void;
  },
  BetterFullscreenPluginConfig
>({
  config: defaultConfig,
  windowState: {
    fullscreen: false,
    width: 0,
    height: 0,
  },
  customFullscreenRequested: false,
  suspendCustomForCurrentFullscreen: false,
  isActive: false,
  openedPlayerPageForActivation: false,
  previousSelectedTabIndex: null,
  resizeHandler() {},
  videoDataChangeHandler: () => {},
  observer: null,
  syncQueued: false,
  keydownHandler: () => {},
  fullscreenChangeHandler: () => {},
  progressIntervalId: null,
  metadataIntervalId: null,
  backgroundIntervalId: null,
  backdropVideoFrameId: null,
  backdropVideoLastFrameAt: 0,
  lastBackgroundImageUrl: null,
  preferredSyncedLyrics: false,
  latestSongInfo: null,
  playerApi: null,
  lyricsProvider: null,
  lyricsResult: null,
  lyricsFetchKey: null,
  lyricsFetchNonce: 0,
  lyricsCurrentIndex: -1,
  lyricsFetchInFlight: false,

  scheduleSync() {
    if (this.syncQueued) {
      return;
    }

    this.syncQueued = true;

    window.setTimeout(() => {
      this.syncQueued = false;
      void this.syncState();
    }, 32);
  },

  shouldActivate() {
    if (!this.config.enabled || this.suspendCustomForCurrentFullscreen) {
      return false;
    }

    return this.isNativePlayerFullscreen();
  },

  isEditableTarget(target) {
    if (!(target instanceof HTMLElement)) {
      return false;
    }

    return (
      target.isContentEditable ||
      target instanceof HTMLInputElement ||
      target instanceof HTMLTextAreaElement ||
      target instanceof HTMLSelectElement
    );
  },

  isPortraitWindow() {
    const width = this.windowState.width || window.innerWidth;
    const height = this.windowState.height || window.innerHeight;

    return height > width * 1.06;
  },

  getLayoutMode() {
    return this.isPortraitWindow() ? 'portrait' : 'landscape';
  },

  getLayout() {
    return document.querySelector<HTMLElement>('ytmusic-app-layout');
  },

  getActivePlayerPageRoot() {
    const candidates = Array.from(
      document.querySelectorAll<HTMLElement>(
        'ytmusic-player-page[player-page-open][role="dialog"], ytmusic-player-page[player-page-open]',
      ),
    );

    return (
      candidates.find((candidate) => this.isVisibleElement(candidate)) ?? null
    );
  },

  isVisibleElement(element) {
    if (!(element instanceof HTMLElement)) {
      return false;
    }

    const style = getComputedStyle(element);
    const rect = element.getBoundingClientRect();

    return (
      style.display !== 'none' &&
      style.visibility !== 'hidden' &&
      rect.width > 0 &&
      rect.height > 0
    );
  },

  getShell() {
    return document.getElementById(shellId) as HTMLElement | null;
  },

  getTogglePlayerPageButton() {
    return document.querySelector<HTMLButtonElement>(
      '.toggle-player-page-button',
    );
  },

  getLyricsTab() {
    const root = this.getActivePlayerPageRoot();
    const searchRoots = [root, document].filter(Boolean) as ParentNode[];

    for (const searchRoot of searchRoots) {
      const exact = searchRoot.querySelector<HTMLElement>(
        '#tabsContent > .tab-header:nth-of-type(2)',
      );

      if (this.isVisibleElement(exact)) {
        return exact;
      }

      const explicit =
        searchRoot.querySelector<HTMLElement>('#lyrics-tab') ??
        searchRoot.querySelector<HTMLElement>('[tab-id="lyrics"]') ??
        searchRoot.querySelector<HTMLElement>('[data-tab-id="lyrics"]');

      if (this.isVisibleElement(explicit)) {
        return explicit;
      }

      const headers = Array.from(
        searchRoot.querySelectorAll<HTMLElement>(
          '#tabsContent > .tab-header, tp-yt-paper-tab, [role="tab"]',
        ),
      );

      const visibleHeaders = headers.filter((header) =>
        this.isVisibleElement(header),
      );

      const matchingHeader = visibleHeaders.find((header) =>
        header.textContent?.trim().toLowerCase().includes('lyric'),
      );

      if (matchingHeader) {
        return matchingHeader;
      }
    }

    return null;
  },

  getAllLyricsTabs() {
    const roots = [
      ...document.querySelectorAll<HTMLElement>(
        'ytmusic-player-page[player-page-open][role="dialog"], ytmusic-player-page[player-page-open], ytmusic-player-page',
      ),
      document.documentElement,
    ];

    const seen = new Set<HTMLElement>();
    const tabs: HTMLElement[] = [];

    for (const root of roots) {
      const exact = Array.from(
        root.querySelectorAll<HTMLElement>('#tabsContent > .tab-header:nth-of-type(2)'),
      );
      const explicit = Array.from(
        root.querySelectorAll<HTMLElement>(
          '#lyrics-tab, [tab-id="lyrics"], [data-tab-id="lyrics"]',
        ),
      );
      const fuzzy = Array.from(
        root.querySelectorAll<HTMLElement>(
          '#tabsContent > .tab-header, tp-yt-paper-tab, [role="tab"]',
        ),
      ).filter((header) =>
        header.textContent?.trim().toLowerCase().includes('lyric'),
      );

      for (const tab of [...exact, ...explicit, ...fuzzy]) {
        if (!seen.has(tab)) {
          seen.add(tab);
          tabs.push(tab);
        }
      }
    }

    return tabs;
  },

  getSelectedTabIndex() {
    const root = this.getActivePlayerPageRoot() ?? document;
    const headers = Array.from(
      root.querySelectorAll<HTMLElement>('#tabsContent > .tab-header'),
    ).filter((header) => this.isVisibleElement(header));
    const selected = headers.findIndex(
      (header) => header.getAttribute('aria-selected') === 'true',
    );

    return selected >= 0 ? selected : null;
  },

  getLyricsRenderer() {
    const root = this.getActivePlayerPageRoot();
    const searchRoots = [root, document].filter(Boolean) as ParentNode[];

    for (const searchRoot of searchRoots) {
      const renderers = Array.from(
        searchRoot.querySelectorAll<HTMLElement>(
          "#tab-renderer[page-type='MUSIC_PAGE_TYPE_TRACK_LYRICS']",
        ),
      );
      const visibleRenderer = renderers.find((renderer) =>
        this.isVisibleElement(renderer),
      );

      if (visibleRenderer) {
        return visibleRenderer;
      }
    }

    return null;
  },

  getSyncedLyricsContainer() {
    const renderer = this.getLyricsRenderer();
    if (renderer) {
      const scopedContainer =
        renderer.querySelector<HTMLElement>('#synced-lyrics-container');
      if (scopedContainer) {
        return scopedContainer;
      }
    }

    const containers = Array.from(
      document.querySelectorAll<HTMLElement>('#synced-lyrics-container'),
    );

    return (
      containers.find((container) =>
        this.isVisibleElement(container.closest('#tab-renderer') ?? container),
      ) ?? null
    );
  },

  ensureShell() {
    const existing = this.getShell();
    if (existing) {
      return existing;
    }

    const shell = document.createElement('div');
    shell.id = shellId;
    shell.innerHTML = `
      <div id="pear-bf-main">
        <section id="pear-bf-left">
          <div id="${mediaSlotId}"></div>
          <div id="pear-bf-meta">
            <h1 id="${titleTextId}"></h1>
            <p id="${bylineTextId}"></p>
          </div>
          <div id="${progressId}">
            <div id="pear-bf-progress-track">
              <div id="pear-bf-progress-fill"></div>
            </div>
            <div id="pear-bf-progress-times">
              <span id="pear-bf-current">0:00</span>
              <span id="pear-bf-duration">0:00</span>
            </div>
          </div>
        </section>
        <section id="pear-bf-right">
          <div id="${lyricsSlotId}">
            <div id="${lyricsHostId}"></div>
          </div>
        </section>
      </div>
    `;

    document.body.append(shell);
    return shell;
  },

  removeShell() {
    this.getShell()?.remove();
  },

  restoreMovedNodes() {
    return;
  },

  mountMediaIntoShell() {
    this.restoreMovedNodes();
    this.updateMediaFrameVariables();
  },

  mountLyricsIntoShell() {
    this.updateLyricsFrameVariables();
    this.renderFullscreenLyrics();
    this.updateFullscreenLyricsState();
    window.requestAnimationFrame(() => {
      this.updateFullscreenLyricsState();
      window.requestAnimationFrame(() => {
        this.updateFullscreenLyricsState();
      });
    });
    window.setTimeout(() => {
      if (this.isActive) {
        this.updateFullscreenLyricsState();
      }
    }, 120);
  },

  ensureLyricsHost() {
    return document.getElementById(lyricsHostId) as HTMLElement | null;
  },

  async fetchFullscreenLyrics() {
    if (this.lyricsFetchInFlight) {
      return Boolean(this.lyricsResult);
    }

    const source =
      this.buildSongInfoFromPlayerApi() ??
      this.latestSongInfo;

    if (!source?.videoId || !source.title || !source.artist) {
      this.lyricsResult = null;
      this.lyricsFetchKey = null;
      this.renderFullscreenLyrics();
      return false;
    }

    const info: SearchSongInfo = {
      title: source.title,
      alternativeTitle: source.alternativeTitle ?? '',
      artist: source.artist,
      album: source.album,
      songDuration: Number(source.songDuration ?? 0),
      videoId: source.videoId,
      tags: Array.isArray(source.tags) ? source.tags : [],
    };

    const fetchKey = `${info.videoId}:${info.title}:${info.artist}:${info.songDuration}`;
    if (this.lyricsFetchKey === fetchKey && this.lyricsResult) {
      this.renderFullscreenLyrics();
      return true;
    }

    this.lyricsFetchKey = fetchKey;
    const currentNonce = ++this.lyricsFetchNonce;
    this.lyricsResult = null;
    this.lyricsCurrentIndex = -1;
    this.lyricsFetchInFlight = true;
    this.renderFullscreenLyrics();

    try {
      this.lyricsProvider ??= new YTMusic();

      const result =
        await searchLRCLibFallback(info) ??
        await this.lyricsProvider.search(info);

      if (currentNonce !== this.lyricsFetchNonce) {
        return false;
      }

      this.lyricsResult = result;
      this.lyricsCurrentIndex = -1;
      this.renderFullscreenLyrics();
      this.updateFullscreenLyricsState();

      return Boolean(result);
    } catch (error) {
      console.error(error);

      if (currentNonce === this.lyricsFetchNonce) {
        this.lyricsResult = null;
        this.lyricsCurrentIndex = -1;
        this.renderFullscreenLyrics();
      }

      return false;
    } finally {
      this.lyricsFetchInFlight = false;

      if (!this.lyricsResult) {
        this.renderFullscreenLyrics();
      }
    }
  },

  renderFullscreenLyrics() {
    const host = this.ensureLyricsHost();
    if (!host) {
      return;
    }

    host.replaceChildren();
    host.classList.remove('pear-bf-lyrics-host-empty');

    const result = this.lyricsResult;
    if (!result) {
      const empty = document.createElement('div');
      empty.className = this.lyricsFetchInFlight
        ? 'pear-bf-lyrics-empty pear-bf-lyrics-empty-loading'
        : 'pear-bf-lyrics-empty';
      empty.textContent = 'd(-_-)b';
      host.classList.add('pear-bf-lyrics-host-empty');
      host.append(empty);
      return;
    }

    const scroller = document.createElement('div');
    scroller.className = 'pear-bf-lyrics-scroller';

    if (Array.isArray(result.lines) && result.lines.length > 0) {
      for (const [index, line] of result.lines.entries()) {
        const row = document.createElement('div');
        row.className = 'pear-bf-lyrics-line upcoming';
        row.dataset.index = String(index);

        const text = document.createElement('div');
        text.className = 'pear-bf-lyrics-text';
        text.textContent = line.text || ' ';

        row.append(text);
        scroller.append(row);
      }
    } else if (typeof result.lyrics === 'string' && result.lyrics.trim()) {
      scroller.classList.add('pear-bf-lyrics-scroller-plain');
      const plainLines = result.lyrics.split('\n').filter((line) => line.trim());
      for (const [index, line] of plainLines.entries()) {
        const row = document.createElement('div');
        row.className = 'pear-bf-lyrics-line pear-bf-lyrics-line-plain current';
        row.dataset.index = String(index);

        const text = document.createElement('div');
        text.className = 'pear-bf-lyrics-text';
        text.textContent = line;

        row.append(text);
        scroller.append(row);
      }
    } else {
      const empty = document.createElement('div');
      empty.className = 'pear-bf-lyrics-empty';
      empty.textContent = 'd(-_-)b';
      host.classList.add('pear-bf-lyrics-host-empty');
      host.append(empty);
      return;
    }

    host.append(scroller);
  },

  updateFullscreenLyricsState() {
    const result = this.lyricsResult;
    const host = this.ensureLyricsHost();
    const scroller = host?.querySelector<HTMLElement>('.pear-bf-lyrics-scroller');

    if (!host || !scroller || !result?.lines?.length) {
      return;
    }

    const media = this.getMediaElementForProgress();
    const time = Math.max(
      0,
      Math.round((Number.isFinite(media?.currentTime) ? media?.currentTime ?? 0 : 0) * 1000),
    );

    const statuses = result.lines.map((line) => {
      if (line.timeInMs >= time) return 'upcoming';
      if (time - line.timeInMs >= line.duration) return 'previous';
      return 'current';
    });

    let currentIndex = statuses.findIndex((status) => status === 'current');
    if (currentIndex === -1) {
      currentIndex = statuses.findIndex((status) => status === 'upcoming');
    }

    const rows = Array.from(
      scroller.querySelectorAll<HTMLElement>('.pear-bf-lyrics-line'),
    );

    for (const [index, row] of rows.entries()) {
      row.classList.remove('previous', 'current', 'upcoming');
      row.classList.add(statuses[index] ?? 'upcoming');
    }

    if (currentIndex < 0) {
      return;
    }

    const isRenderableRow = (row: HTMLElement | undefined) => {
      const text = row?.querySelector<HTMLElement>('.pear-bf-lyrics-text')?.textContent ?? '';
      return text.trim().length > 0;
    };

    let targetIndex = currentIndex;
    if (!isRenderableRow(rows[targetIndex])) {
      for (let offset = 1; offset < rows.length; offset++) {
        const previousIndex = targetIndex - offset;
        if (previousIndex >= 0 && isRenderableRow(rows[previousIndex])) {
          targetIndex = previousIndex;
          break;
        }

        const nextIndex = targetIndex + offset;
        if (nextIndex < rows.length && isRenderableRow(rows[nextIndex])) {
          targetIndex = nextIndex;
          break;
        }
      }
    }

    const currentRow = rows[targetIndex];
    if (!currentRow || !isRenderableRow(currentRow)) {
      return;
    }

    const previousRenderableCount = rows
      .slice(0, targetIndex)
      .filter((row) => row.classList.contains('previous') && isRenderableRow(row))
      .length;
    const anchorRatio = Math.min(0.5, 0.34 + previousRenderableCount * 0.02);
    const verticalLift = 100;
    const anchorOffset = Math.max(
      0,
      scroller.clientHeight * anchorRatio - currentRow.clientHeight / 2 - verticalLift,
    );
    const centerOffset =
      currentRow.offsetTop - scroller.scrollTop - anchorOffset;
    const shouldRecenter =
      this.lyricsCurrentIndex !== targetIndex || Math.abs(centerOffset) > 8;

    if (shouldRecenter) {
      const isInitialPosition = this.lyricsCurrentIndex === -1;
      this.lyricsCurrentIndex = targetIndex;
      scroller.scrollTo({
        top: Math.max(0, currentRow.offsetTop - anchorOffset),
        behavior: isInitialPosition ? 'auto' : 'smooth',
      });
    }
  },

  clearFullscreenLyrics() {
    this.lyricsResult = null;
    this.lyricsFetchKey = null;
    this.lyricsCurrentIndex = -1;
    this.lyricsFetchInFlight = false;
    this.ensureLyricsHost()?.replaceChildren();
  },

  updateShellMetadata() {
    this.refreshLatestSongInfoFromDom();

    const titleTarget = document.getElementById(titleTextId);
    const bylineTarget = document.getElementById(bylineTextId);
    const titleSource =
      document.querySelector<HTMLElement>('#main-panel .title') ??
      document.querySelector<HTMLElement>(
        'ytmusic-player-bar .content-info-wrapper .title',
      ) ??
      document.querySelector<HTMLElement>('ytmusic-player-bar .title');
    const bylineSource =
      document.querySelector<HTMLElement>('#main-panel .byline') ??
      document.querySelector<HTMLElement>('#main-panel .subtitle') ??
      document.querySelector<HTMLElement>(
        'ytmusic-player-bar .content-info-wrapper .byline',
      ) ??
      document.querySelector<HTMLElement>(
        'ytmusic-player-bar .content-info-wrapper .subtitle',
      ) ??
      document.querySelector<HTMLElement>('ytmusic-player-bar .byline');

    const titleText = titleSource?.textContent?.trim();
    const bylineText = bylineSource?.textContent?.trim();

    if (titleTarget) {
      titleTarget.textContent = titleText || this.latestSongInfo?.title || '';
    }

    if (bylineTarget) {
      bylineTarget.textContent = bylineText || this.latestSongInfo?.artist || '';
    }
  },

  ensureShellMetadataReady() {
    void (async () => {
      for (let attempt = 0; attempt < 20; attempt++) {
        if (!this.isActive || !this.getShell()) {
          return;
        }

        this.updateShellMetadata();

        const titleTarget = document.getElementById(titleTextId);
        const bylineTarget = document.getElementById(bylineTextId);
        const hasTitle = Boolean(titleTarget?.textContent?.trim());
        const hasByline = Boolean(bylineTarget?.textContent?.trim());

        if (hasTitle || hasByline) {
          return;
        }

        await new Promise<void>((resolve) => {
          window.setTimeout(resolve, 100);
        });
      }
    })();
  },

  refreshLatestSongInfoFromDom() {
    const mediaMetadata = navigator.mediaSession?.metadata;
    const mediaArtwork = mediaMetadata?.artwork;
    const mediaArtworkSrc =
      mediaArtwork && mediaArtwork.length > 0
        ? mediaArtwork[mediaArtwork.length - 1]?.src || mediaArtwork[0]?.src || ''
        : '';
    const titleSource =
      document.querySelector<HTMLElement>('#main-panel .title') ??
      document.querySelector<HTMLElement>(
        'ytmusic-player-bar .content-info-wrapper .title',
      ) ??
      document.querySelector<HTMLElement>('ytmusic-player-bar .title');
    const bylineSource =
      document.querySelector<HTMLElement>('#main-panel .byline') ??
      document.querySelector<HTMLElement>('#main-panel .subtitle') ??
      document.querySelector<HTMLElement>(
        'ytmusic-player-bar .content-info-wrapper .byline',
      ) ??
      document.querySelector<HTMLElement>(
        'ytmusic-player-bar .content-info-wrapper .subtitle',
      ) ??
      document.querySelector<HTMLElement>('ytmusic-player-bar .byline');
    const songImage = document.querySelector<HTMLImageElement>('#song-image img');
    const titleText =
      titleSource?.textContent?.trim() ||
      mediaMetadata?.title?.trim() ||
      '';
    const bylineText =
      bylineSource?.textContent?.trim() ||
      mediaMetadata?.artist?.trim() ||
      '';
    const imageSrc =
      songImage?.currentSrc ||
      songImage?.src ||
      mediaArtworkSrc ||
      '';

    if (!titleText && !bylineText && !imageSrc) {
      return;
    }

    this.latestSongInfo = {
      title: titleText || this.latestSongInfo?.title || '',
      artist: bylineText || this.latestSongInfo?.artist || '',
      imageSrc: imageSrc || this.latestSongInfo?.imageSrc || '',
      videoId: this.latestSongInfo?.videoId || '',
      views: this.latestSongInfo?.views || '',
      id: this.latestSongInfo?.id || '',
      liked: this.latestSongInfo?.liked || false,
      inLibrary: this.latestSongInfo?.inLibrary || false,
    };
  },

  buildSongInfoFromPlayerApi() {
    const response = this.playerApi?.getPlayerResponse();
    const details = response?.videoDetails;

    if (!details?.videoId) {
      return null;
    }

    const canonical = response?.microformat?.microformatDataRenderer?.urlCanonical;
    const thumbnails = details.thumbnail?.thumbnails ?? [];
    const imageSrc =
      thumbnails.at(-1)?.url?.split('?')?.at(0) ?? thumbnails.at(-1)?.url ?? '';

    return {
      title: details.title ?? '',
      alternativeTitle:
        response?.microformat?.microformatDataRenderer?.linkAlternates?.find(
          (link) => link.title,
        )?.title ?? '',
      artist: details.author ?? '',
      views: Number(details.viewCount ?? 0),
      imageSrc,
      songDuration: Number(details.lengthSeconds ?? 0),
      elapsedSeconds: details.elapsedSeconds,
      url: canonical?.split('&')[0] ?? '',
      album: details.album ?? undefined,
      videoId: details.videoId,
      playlistId: canonical ? new URL(canonical).searchParams.get('list') ?? '' : '',
      mediaType: 'AUDIO' as SongInfo['mediaType'],
      tags: Array.isArray(response?.microformat?.microformatDataRenderer?.tags)
        ? response.microformat.microformatDataRenderer.tags
        : [],
    };
  },

  updateMediaFrameVariables() {
    const slot = document.getElementById(mediaSlotId);
    if (!slot) {
      return;
    }

    const applyRect = () => {
      const rect = slot.getBoundingClientRect();
      const root = document.documentElement;

      root.style.setProperty('--bf-media-left', `${rect.left}px`);
      root.style.setProperty('--bf-media-top', `${rect.top}px`);
      root.style.setProperty('--bf-media-width', `${rect.width}px`);
      root.style.setProperty('--bf-media-height', `${rect.height}px`);
      root.style.setProperty('--bf-media-radius', '18px');
    };

    applyRect();
    window.requestAnimationFrame(applyRect);
  },

  updateLyricsFrameVariables() {
    const slot = document.getElementById(lyricsSlotId);
    if (!slot) {
      return;
    }

    const applyRect = () => {
      const rect = slot.getBoundingClientRect();
      const root = document.documentElement;

      root.style.setProperty('--bf-lyrics-left', `${rect.left}px`);
      root.style.setProperty('--bf-lyrics-top', `${rect.top}px`);
      root.style.setProperty('--bf-lyrics-width', `${rect.width}px`);
      root.style.setProperty('--bf-lyrics-height', `${rect.height}px`);
    };

    applyRect();
    window.requestAnimationFrame(applyRect);
  },

  getSongImage() {
    return document.querySelector<HTMLImageElement>(
      `#${mediaSlotId} img, #song-image img`,
    );
  },

  getSongVideo() {
    return document.querySelector<HTMLVideoElement>(
      `#${mediaSlotId} video, #song-video video`,
    );
  },

  isSongImageVisible() {
    const container = document.querySelector<HTMLElement>('#song-image');
    if (!container) {
      return false;
    }

    const style = getComputedStyle(container);
    return style.display !== 'none' && style.visibility !== 'hidden';
  },

  isSongVideoVisible() {
    const container = document.querySelector<HTMLElement>('#song-video');
    if (!container) {
      return false;
    }

    const style = getComputedStyle(container);
    return style.display !== 'none' && style.visibility !== 'hidden';
  },

  getMediaElementForProgress() {
    return (
      this.getSongVideo() ??
      document.querySelector<HTMLMediaElement>('video, audio')
    );
  },

  isNativePlayerFullscreen() {
    return Boolean(
      document
        .querySelector<HTMLElement>('ytmusic-player-bar')
        ?.attributes.getNamedItem('player-fullscreened'),
    );
  },

  isPlayerPageOpen() {
    return Boolean(this.getLayout()?.hasAttribute('player-page-open'));
  },

  isPlayerPageReady() {
    const mainPanel = document.querySelector<HTMLElement>('#main-panel');
    const contentInfo = document.querySelector<HTMLElement>(
      '#main-panel .content-info-wrapper',
    );
    const player = document.querySelector<HTMLElement>('#player');
    const media = this.getSongVideo() ?? this.getSongImage();

    return Boolean(
      this.isPlayerPageOpen() &&
        mainPanel &&
        contentInfo &&
        player &&
        media,
    );
  },

  async waitForPlayerPageReady() {
    for (let attempt = 0; attempt < 40; attempt++) {
      if (this.isPlayerPageReady()) {
        return true;
      }

      await new Promise<void>((resolve) => {
        window.setTimeout(resolve, 50);
      });
    }

    return this.isPlayerPageReady();
  },

  async waitForLyricsTab() {
    for (let attempt = 0; attempt < 50; attempt++) {
      const tab = this.getLyricsTab();
      if (tab) {
        return tab;
      }

      await new Promise<void>((resolve) => {
        window.setTimeout(resolve, 100);
      });
    }

    return null;
  },

  async waitForLyricsContentReady() {
    for (let attempt = 0; attempt < 40; attempt++) {
      const renderer = this.getLyricsRenderer();
      const syncedContainer = this.getSyncedLyricsContainer();
      const hasPlainLyrics = Boolean(
        renderer?.querySelector('.description, .text-lyrics'),
      );

      if (
        renderer &&
        renderer.getAttribute('page-type') === 'MUSIC_PAGE_TYPE_TRACK_LYRICS' &&
        (syncedContainer || hasPlainLyrics)
      ) {
        return true;
      }

      await new Promise<void>((resolve) => {
        window.setTimeout(resolve, 75);
      });
    }

    return Boolean(
      this.getLyricsRenderer() &&
        (this.getSyncedLyricsContainer() ||
          this.getLyricsRenderer()?.querySelector('.description, .text-lyrics')),
    );
  },

  openPlayerPageIfNeeded() {
    const layout = this.getLayout();
    if (!layout || layout.hasAttribute('player-page-open')) {
      return;
    }

    this.getTogglePlayerPageButton()?.click();
    this.openedPlayerPageForActivation = true;
  },

  closePlayerPageIfNeeded() {
    if (!this.openedPlayerPageForActivation) {
      return;
    }

    const layout = this.getLayout();
    if (layout?.hasAttribute('player-page-open')) {
      this.getTogglePlayerPageButton()?.click();
    }

    this.openedPlayerPageForActivation = false;
  },

  async ensureLyricsViewReady() {
    return await this.fetchFullscreenLyrics();
  },

  preferSyncedLyricsSource() {
    const picker =
      this.getSyncedLyricsContainer()?.querySelector<HTMLElement>(
        '.lyrics-picker',
      ) ??
      this.getLyricsRenderer()?.querySelector<HTMLElement>('.lyrics-picker') ??
      document.querySelector<HTMLElement>('.lyrics-picker');
    if (!picker) {
      return;
    }

    const options = Array.from(
      picker.querySelectorAll<HTMLElement>(
        'button, [role="button"], tp-yt-paper-item, .ytmusic-menu-navigation-item-renderer',
      ),
    );

    const syncedOption = options.find((option) =>
      option.textContent?.toLowerCase().includes('sync'),
    );

    if (!syncedOption) {
      return;
    }

    const selected =
      syncedOption.getAttribute('aria-selected') === 'true' ||
      syncedOption.getAttribute('aria-pressed') === 'true' ||
      syncedOption.classList.contains('selected') ||
      syncedOption.classList.contains('active');

    if (!selected) {
      syncedOption.click();
    }
    this.preferredSyncedLyrics = true;
  },

  restoreSelectedTab() {
    if (this.previousSelectedTabIndex === null) {
      return;
    }

    const root = this.getActivePlayerPageRoot() ?? document;
    const headers = Array.from(
      root.querySelectorAll<HTMLElement>('#tabsContent > .tab-header'),
    );
    const target = headers[this.previousSelectedTabIndex];

    if (target && target.getAttribute('aria-selected') !== 'true') {
      target.click();
    }

    this.previousSelectedTabIndex = null;
  },

  setActiveClass(active) {
    document.documentElement.classList.toggle(activeClass, active);
    document.body.classList.toggle(activeClass, active);
    this.getLayout()?.classList.toggle(activeClass, active);
  },

  setLayoutAttribute(active) {
    if (!active) {
      document.documentElement.removeAttribute(layoutAttribute);
      return;
    }

    document.documentElement.setAttribute(layoutAttribute, this.getLayoutMode());
  },

  ensureBackdrop() {
    if (document.getElementById(backdropId)) {
      return;
    }

    const backdrop = document.createElement('div');
    backdrop.id = backdropId;
    backdrop.innerHTML = `
      <div id="${backdropImageId}"></div>
      <canvas id="${backdropVideoId}"></canvas>
    `;
    document.body.prepend(backdrop);
  },

  clearBackdrop() {
    const canvas = document.getElementById(backdropVideoId) as HTMLCanvasElement | null;
    canvas?.getContext('2d')?.clearRect(0, 0, canvas.width, canvas.height);
    document.getElementById(backdropId)?.remove();
    this.lastBackgroundImageUrl = null;
  },

  updateBackgroundVisuals() {
    this.ensureBackdrop();
    this.updateBackgroundImage();
    this.updateBackdropVideoFrame();
  },

  updateBackgroundImage() {
    const backdrop = document.getElementById(backdropId);
    const backdropImage = document.getElementById(backdropImageId);
    if (!backdrop || !backdropImage) {
      return;
    }

    if (!this.isSongImageVisible() && this.isSongVideoVisible()) {
      if (backdrop.getAttribute('data-bf-backdrop-mode') !== 'video') {
        backdropImage.setAttribute('style', 'background-image: none;');
      }
      return;
    }

    const songImage = this.getSongImage();
    const imageUrl =
      songImage?.currentSrc || songImage?.src || this.latestSongInfo?.imageSrc || null;

    if (!imageUrl) {
      backdrop.setAttribute('data-bf-backdrop-mode', 'none');
      backdropImage.setAttribute('style', 'background-image: none;');
      return;
    }

    if (imageUrl === this.lastBackgroundImageUrl) {
      if (backdrop.getAttribute('data-bf-backdrop-mode') !== 'video') {
        backdrop.setAttribute('data-bf-backdrop-mode', 'image');
      }
      return;
    }

    this.lastBackgroundImageUrl = imageUrl;
    if (backdrop.getAttribute('data-bf-backdrop-mode') !== 'video') {
      backdrop.setAttribute('data-bf-backdrop-mode', 'image');
    }
    backdropImage.setAttribute('style', `background-image: url("${imageUrl}");`);
  },

  updateBackdropVideoFrame() {
    const backdrop = document.getElementById(backdropId);
    const canvas = document.getElementById(backdropVideoId) as HTMLCanvasElement | null;
    const backdropImage = document.getElementById(backdropImageId) as HTMLElement | null;
    const video = this.getSongVideo();
    const visibleVideo =
      video &&
      video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA &&
      this.isSongVideoVisible() &&
      getComputedStyle(video).display !== 'none'
        ? video
        : null;

    if (!backdrop || !canvas) {
      return;
    }

    if (!visibleVideo) {
      const context = canvas.getContext('2d');
      context?.clearRect(0, 0, canvas.width, canvas.height);
      const hasImage =
        Boolean(backdropImage) &&
        backdropImage?.style.backgroundImage &&
        backdropImage.style.backgroundImage !== 'none';
      backdrop.setAttribute('data-bf-backdrop-mode', hasImage ? 'image' : 'none');
      return;
    }

    const targetWidth = 320;
    const aspectRatio = visibleVideo.videoWidth / visibleVideo.videoHeight || 16 / 9;
    const targetHeight = Math.max(180, Math.round(targetWidth / aspectRatio));

    if (canvas.width !== targetWidth || canvas.height !== targetHeight) {
      canvas.width = targetWidth;
      canvas.height = targetHeight;
    }

    const context = canvas.getContext('2d', { willReadFrequently: true });
    if (!context) {
      return;
    }

    try {
      context.drawImage(visibleVideo, 0, 0, canvas.width, canvas.height);
      backdrop.setAttribute('data-bf-backdrop-mode', 'video');
    } catch {
      // Ignore draw failures.
    }
  },

  tickBackdropVideoFrame(timestamp) {
    if (!this.isActive) {
      this.backdropVideoFrameId = null;
      return;
    }

    if (timestamp - this.backdropVideoLastFrameAt >= 1000 / 12) {
      this.backdropVideoLastFrameAt = timestamp;
      this.updateBackdropVideoFrame();
    }

    this.backdropVideoFrameId = window.requestAnimationFrame((nextTimestamp) => {
      this.tickBackdropVideoFrame(nextTimestamp);
    });
  },

  setLyricsVariables(active) {
    const root = document.documentElement;

    if (active) {
      root.style.setProperty('--lyrics-font-size', 'clamp(1.6rem, 2.4vw, 2.8rem)');
      root.style.setProperty('--lyrics-line-height', '1.46');
      root.style.setProperty('--lyrics-width', 'min(92vw, 52rem)');
      root.style.setProperty('--lyrics-padding', '0');
      root.style.setProperty('--lyrics-inactive-opacity', '0.34');
      root.style.setProperty('--lyrics-active-scale', '1.05');
      root.style.setProperty('--lyrics-active-offset', '0');
      root.style.setProperty('--lyrics-inactive-offset', '0');
      return;
    }

    for (const property of [
      '--lyrics-font-size',
      '--lyrics-line-height',
      '--lyrics-width',
      '--lyrics-padding',
      '--lyrics-inactive-opacity',
      '--lyrics-active-scale',
      '--lyrics-active-offset',
      '--lyrics-inactive-offset',
    ]) {
      root.style.removeProperty(property);
    }
  },

  ensureCustomProgress() {
    const existing = document.getElementById(progressId);
    if (existing) {
      return existing;
    }

    return document.querySelector<HTMLElement>(`#${shellId} #${progressId}`);
  },

  removeCustomProgress() {
    document.getElementById(progressId)?.remove();
  },

  updateProgressDisplay() {
    const progress = this.ensureCustomProgress();
    if (!progress) {
      return;
    }

    const media = this.getMediaElementForProgress();
    const fill = progress.querySelector<HTMLElement>('#pear-bf-progress-fill');
    const current = progress.querySelector<HTMLElement>('#pear-bf-current');
    const duration = progress.querySelector<HTMLElement>('#pear-bf-duration');

    if (!media || !fill || !current || !duration) {
      fill?.style.setProperty('width', '0%');
      if (current) {
        current.textContent = '0:00';
      }
      if (duration) {
        duration.textContent = '0:00';
      }
      return;
    }

    const safeDuration = Number.isFinite(media.duration) && media.duration > 0
      ? media.duration
      : 0;
    const safeCurrent = Number.isFinite(media.currentTime) ? media.currentTime : 0;
    const ratio = safeDuration > 0 ? clamp((safeCurrent / safeDuration) * 100, 0, 100) : 0;

    fill.style.width = `${ratio}%`;
    current.textContent = formatTime(safeCurrent);
    duration.textContent = formatTime(safeDuration);
    this.updateFullscreenLyricsState();
  },

  startVisualLoops() {
    if (this.progressIntervalId === null) {
      this.progressIntervalId = window.setInterval(() => {
        this.updateProgressDisplay();
      }, 250);
    }

    if (this.metadataIntervalId === null) {
      this.metadataIntervalId = window.setInterval(() => {
        this.updateShellMetadata();
        if (this.isActive && !this.lyricsResult && !this.lyricsFetchInFlight) {
          void this.fetchFullscreenLyrics().then((ready) => {
            if (ready && this.isActive) {
              this.mountLyricsIntoShell();
            }
          });
        }
      }, 250);
    }

    if (this.backgroundIntervalId === null) {
      this.backgroundIntervalId = window.setInterval(() => {
        this.updateBackgroundImage();
      }, 1000);
    }

    if (this.backdropVideoFrameId === null) {
      this.backdropVideoLastFrameAt = 0;
      this.backdropVideoFrameId = window.requestAnimationFrame((timestamp) => {
        this.tickBackdropVideoFrame(timestamp);
      });
    }
  },

  stopVisualLoops() {
    if (this.progressIntervalId !== null) {
      window.clearInterval(this.progressIntervalId);
      this.progressIntervalId = null;
    }

    if (this.metadataIntervalId !== null) {
      window.clearInterval(this.metadataIntervalId);
      this.metadataIntervalId = null;
    }

    if (this.backgroundIntervalId !== null) {
      window.clearInterval(this.backgroundIntervalId);
      this.backgroundIntervalId = null;
    }

    if (this.backdropVideoFrameId !== null) {
      window.cancelAnimationFrame(this.backdropVideoFrameId);
      this.backdropVideoFrameId = null;
    }
  },

  observeLayout() {
    if (this.observer) {
      return;
    }

    this.observer = new MutationObserver((mutations) => {
      const shouldIgnore = mutations.every((mutation) => {
        const target =
          mutation.target instanceof Element ? mutation.target : null;

        return Boolean(
          target?.closest(
            `#${shellId}, #${lyricsSlotId}, #synced-lyrics-container, #${backdropId}`,
          ),
        );
      });

      if (!shouldIgnore) {
        this.scheduleSync();
      }
    });

    this.observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: [
        'player-fullscreened',
        'player-page-open',
        'aria-selected',
        'disabled',
      ],
    });
  },

  disconnectObserver() {
    this.observer?.disconnect();
    this.observer = null;
  },

  async syncState() {
    const shouldActivate = this.shouldActivate();

    if (!shouldActivate) {
      if (!this.isActive) {
        this.closePlayerPageIfNeeded();
        return;
      }

      this.isActive = false;
      this.preferredSyncedLyrics = false;
      this.stopVisualLoops();
      this.setActiveClass(false);
      this.setLayoutAttribute(false);
      this.setLyricsVariables(false);
      this.removeCustomProgress();
      this.clearBackdrop();
      this.clearFullscreenLyrics();
      this.restoreMovedNodes();
      this.removeShell();
      this.restoreSelectedTab();
      this.closePlayerPageIfNeeded();
      return;
    }

    if (!this.isActive) {
      this.previousSelectedTabIndex = this.getSelectedTabIndex();
    }

    this.isActive = true;
    this.setActiveClass(true);
    this.setLayoutAttribute(true);
    this.setLyricsVariables(true);
    this.ensureBackdrop();
    this.updateBackgroundVisuals();
    this.ensureShell();
    this.updateMediaFrameVariables();
    this.updateLyricsFrameVariables();
    this.ensureCustomProgress();
    this.updateProgressDisplay();
    this.startVisualLoops();

    this.openPlayerPageIfNeeded();

    const playerPageReady = await this.waitForPlayerPageReady();
    if (!playerPageReady) {
      if (this.isNativePlayerFullscreen()) {
        window.setTimeout(() => {
          this.scheduleSync();
        }, 100);
      }
      return;
    }

    this.updateShellMetadata();
    this.ensureShellMetadataReady();
    this.mountMediaIntoShell();

    const activeSongInfo = this.buildSongInfoFromPlayerApi();
    if (activeSongInfo) {
      this.latestSongInfo = {
        ...this.latestSongInfo,
        ...activeSongInfo,
      };
      this.updateShellMetadata();
    }

    if (this.latestSongInfo && window.ipcRenderer?.emit) {
      window.ipcRenderer.emit(
        'peard:update-song-info',
        {} as never,
        this.latestSongInfo,
      );
    }

    const lyricsReady = await this.ensureLyricsViewReady();
    if (lyricsReady) {
      this.mountLyricsIntoShell();
    }
    this.updateBackgroundVisuals();

    if (!lyricsReady && this.isNativePlayerFullscreen()) {
      window.setTimeout(() => {
        this.scheduleSync();
      }, 100);
    }
  },

  async start(ctx) {
    this.config = await ctx.getConfig();
    this.windowState = (await ctx.ipc.invoke(
      `${pluginId}:get-window-state`,
    )) as WindowState;

    this.resizeHandler = () => {
      this.updateMediaFrameVariables();
      this.updateLyricsFrameVariables();
      this.scheduleSync();
    };
    this.videoDataChangeHandler = () => {
      const activeSongInfo = this.buildSongInfoFromPlayerApi();
      if (activeSongInfo) {
        this.latestSongInfo = {
          ...this.latestSongInfo,
          ...activeSongInfo,
        };
      }
      this.updateShellMetadata();
      this.mountMediaIntoShell();
      void this.fetchFullscreenLyrics().then((ready) => {
        if (ready) {
          this.mountLyricsIntoShell();
        }
      });
      this.updateMediaFrameVariables();
      this.updateLyricsFrameVariables();
      this.updateBackgroundVisuals();
      this.updateProgressDisplay();
      this.scheduleSync();
    };
    this.fullscreenChangeHandler = () => {
      this.scheduleSync();
    };
    this.keydownHandler = (event) => {
      if (event.defaultPrevented || event.repeat) {
        return;
      }

      if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
        return;
      }

      if (this.isEditableTarget(event.target)) {
        return;
      }

      const key = event.key.toLowerCase();
      if (key !== 'escape' && key !== 'f') {
        return;
      }

      if (key === 'f' && !this.isNativePlayerFullscreen()) {
        this.customFullscreenRequested = true;
        this.suspendCustomForCurrentFullscreen = false;
        return;
      }

      if (!this.isNativePlayerFullscreen()) {
        return;
      }

      if (key === 'f' && this.isActive) {
        event.preventDefault();
        event.stopPropagation();
        this.customFullscreenRequested = false;
        this.suspendCustomForCurrentFullscreen = true;
        this.scheduleSync();
        return;
      }

      if (key === 'escape') {
        this.customFullscreenRequested = false;
        this.suspendCustomForCurrentFullscreen = false;
      }
    };

    ctx.ipc.on(`${pluginId}:window-state`, (state: WindowState) => {
      this.windowState = state;
      this.scheduleSync();
    });
    ctx.ipc.on('peard:update-song-info', (info: SongInfo) => {
      this.latestSongInfo = info;
      this.updateShellMetadata();
      this.updateBackgroundImage();
      this.updateBackdropVideoFrame();
      if (this.isActive) {
        void this.fetchFullscreenLyrics().then((ready) => {
          if (ready) {
            this.mountLyricsIntoShell();
          }
        });
      }
    });

    if (!this.isNativePlayerFullscreen()) {
      this.suspendCustomForCurrentFullscreen = false;
    }
    this.observeLayout();
    window.addEventListener('resize', this.resizeHandler);
    window.addEventListener('keydown', this.keydownHandler, true);
    document.addEventListener('fullscreenchange', this.fullscreenChangeHandler);
    document.addEventListener(
      'videodatachange',
      this.videoDataChangeHandler,
    );

    this.scheduleSync();
  },

  onPlayerApiReady(api) {
    this.playerApi = api;
    const activeSongInfo = this.buildSongInfoFromPlayerApi();

    if (activeSongInfo) {
      this.latestSongInfo = {
        ...this.latestSongInfo,
        ...activeSongInfo,
      };
    }
  },

  onConfigChange(newConfig) {
    this.config = newConfig;
    this.scheduleSync();
  },

  stop(ctx) {
    window.removeEventListener('resize', this.resizeHandler);
    window.removeEventListener('keydown', this.keydownHandler, true);
    document.removeEventListener('fullscreenchange', this.fullscreenChangeHandler);
    document.removeEventListener(
      'videodatachange',
      this.videoDataChangeHandler,
    );
    ctx.ipc.removeAllListeners(`${pluginId}:window-state`);

    this.stopVisualLoops();
    this.preferredSyncedLyrics = false;
    this.latestSongInfo = null;
    this.playerApi = null;
    this.clearFullscreenLyrics();
    this.customFullscreenRequested = false;
    this.suspendCustomForCurrentFullscreen = false;
    this.isActive = false;
    this.setActiveClass(false);
    this.setLayoutAttribute(false);
    this.setLyricsVariables(false);
    this.removeCustomProgress();
    this.clearBackdrop();
    this.restoreMovedNodes();
    this.removeShell();
    this.restoreSelectedTab();
    this.closePlayerPageIfNeeded();
    this.disconnectObserver();
  },
});

export default createPlugin({
  name: () => 'Better Fullscreen',
  description: () =>
    'Cinematic fullscreen layout with synced lyrics, adaptive media framing, and dynamic background.',
  restartNeeded: false,
  config: defaultConfig,
  stylesheets: [style],
  menu,
  backend,
  renderer,
});
