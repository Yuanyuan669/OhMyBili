import webview from '@ohos.web.webview';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';

interface PageEvent {
  url: string;
}

interface ProgressEvent {
  newProgress: number;
}

interface TitleEvent {
  title: string;
}

interface ErrorEvent {
  request: WebResourceRequest;
  error: WebResourceError;
}

interface LoadInterceptEvent {
  data: WebResourceRequest;
}

interface FullScreenEvent {
  handler: FullScreenExitHandler;
}

const HOME_URL: string = 'https://m.bilibili.com/';
const SEARCH_URL: string = 'https://m.bilibili.com/search';
const UA_MOBILE: string = 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

const INJECT_JS: string = `
(function () {
  if (window.__ohmybiliSweep) {
    window.__ohmybiliSweep();
    return;
  }
  var style = document.createElement('style');
  style.textContent = '.m-download,.open-app,.launch-app,.fixed-download,.m-navbar-download,' +
    '.download-app,.m-openapp,.fixed-openapp,.app-guide{display:none!important}';
  if (document.head) { document.head.appendChild(style); }

  function hideNode(el) {
    var n = el;
    for (var i = 0; i < 7 && n && n !== document.body; i++) {
      var cs = window.getComputedStyle(n);
      var cls = typeof n.className === 'string' ? n.className : '';
      if (cs.position === 'fixed' || cs.position === 'absolute' ||
          /dialog|popup|modal|openapp|download|guide/i.test(cls)) {
        n.style.display = 'none';
        return;
      }
      n = n.parentElement;
    }
    el.style.display = 'none';
  }

  function hideByText(text) {
    var nodes = document.querySelectorAll('body *');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.children && el.children.length > 0) { continue; }
      var t = (el.textContent || '').trim();
      if (t.length === 0 || t.indexOf(text) < 0) { continue; }
      hideNode(el);
    }
  }

  function hideDownloadButtons() {
    var nodes = document.querySelectorAll('a,button,span,div');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.children && el.children.length > 0) { continue; }
      var t = (el.textContent || '').replace(/\\s+/g, '');
      if (t === '下载App' || t === '去打开') {
        hideNode(el);
      }
    }
  }

  function hidePromoContainer(needles) {
    var nodes = document.querySelectorAll('div,section,article');
    var best = null;
    var bestCount = 100000;
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var t = el.innerText || '';
      var all = true;
      for (var k = 0; k < needles.length; k++) {
        if (t.indexOf(needles[k]) < 0) { all = false; break; }
      }
      if (!all) { continue; }
      var count = el.getElementsByTagName('*').length;
      if (count < bestCount) {
        best = el;
        bestCount = count;
      }
    }
    if (best === null) { return; }
    var n = best;
    for (var j = 0; j < 3 && n.parentElement && n.parentElement !== document.body; j++) {
      var cs = window.getComputedStyle(n.parentElement);
      if (cs.position === 'fixed' || cs.position === 'absolute') {
        n = n.parentElement;
      } else {
        break;
      }
    }
    n.style.display = 'none';
  }

  function hideMasks() {
    var nodes = document.querySelectorAll('div');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var cs = window.getComputedStyle(el);
      if (cs.position !== 'fixed') { continue; }
      var r = el.getBoundingClientRect();
      if (r.width < window.innerWidth * 0.9 || r.height < window.innerHeight * 0.9) { continue; }
      if (el.querySelector && el.querySelector('video')) { continue; }
      if ((el.innerText || '').trim().length > 0) { continue; }
      var bg = cs.backgroundColor || '';
      if (bg.indexOf('rgba') === 0 && bg !== 'rgba(0, 0, 0, 0)') {
        el.style.display = 'none';
      }
    }
  }

  function requestPlayerFullscreen() {
    var v = document.querySelector('video');
    if (!v) { return; }
    window.__ohmybiliLandscape = (v.videoWidth >= v.videoHeight) ? '1' : '0';
    try {
      if (typeof v.webkitEnterFullscreen === 'function') {
        v.webkitEnterFullscreen();
      } else if (typeof v.requestFullscreen === 'function') {
        v.requestFullscreen();
      } else if (typeof v.webkitRequestFullscreen === 'function') {
        v.webkitRequestFullscreen();
      }
    } catch (e) {
    }
    if (window.__ohmybiliFsBtn) {
      window.__ohmybiliFsBtn.style.display = 'none';
    }
  }

  function ensureFullscreenButton() {
    if (!document.body) { return; }
    var v = document.querySelector('video');
    var b = window.__ohmybiliFsBtn;
    if (!v) {
      if (b) { b.style.display = 'none'; }
      return;
    }
    if (!b) {
      b = document.createElement('div');
      b.textContent = '全屏';
      b.style.cssText = 'position:fixed;right:8px;top:45%;' +
        'z-index:2147483647;width:38px;padding:10px 5px;box-sizing:border-box;' +
        'border-radius:8px;background:rgba(0,0,0,0.55);color:#fff;font-size:12px;' +
        'line-height:1.2;text-align:center;';
      b.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        requestPlayerFullscreen();
      }, true);
      document.body.appendChild(b);
      window.__ohmybiliFsBtn = b;
    }
    if (document.fullscreenElement || document.webkitFullscreenElement) {
      b.style.display = 'none';
    } else {
      var r = v.getBoundingClientRect();
      if (r.bottom < 80 || r.top > window.innerHeight - 20) {
        b.style.display = 'none';
      } else {
        var top = Math.max(70, Math.min(r.bottom - 56, window.innerHeight - 60));
        b.style.top = top + 'px';
        b.style.display = 'block';
      }
    }
  }

  function sweep() {
    try {
      hideMasks();
      ensureFullscreenButton();
      hidePromoContainer(['浏览方式', '推荐使用']);
      hidePromoContainer(['哔哩哔哩', '感兴趣的视频都在B站']);
      hidePromoContainer(['未能成功跳转客户端', '下载哔哩哔哩App']);
      hidePromoContainer(['建议安装最新版本', '下载哔哩哔哩App']);
      hidePromoContainer(['APP内尽享高清流畅视频']);
      hidePromoContainer(['打开App，流畅又高清']);
      hideByText('未能成功跳转客户端');
      hideByText('浏览方式');
      hideByText('推荐使用');
      hideByText('建议安装最新版本');
      hideByText('下载哔哩哔哩App');
      hideByText('APP内尽享高清流畅视频');
      hideByText('打开App，流畅又高清');
      hideByText('App内打开');
      hideByText('打开App，一起发弹幕看视频');
      hideByText('友情提示：为了您的体验');
      hideDownloadButtons();
    } catch (e) {
    }
  }

  window.__ohmybiliSweep = sweep;
  sweep();

  document.addEventListener('click', function (e) {
    var n = e.target;
    while (n && n.tagName !== 'A') { n = n.parentElement; }
    if (n && n.href && /^(bilibili|biliapp):/i.test(n.href)) {
      e.preventDefault();
      e.stopPropagation();
    }
  }, true);

  var rawOpen = window.open;
  window.open = function (u) {
    if (typeof u === 'string' && /^(bilibili|biliapp):/i.test(u)) { return null; }
    return rawOpen.apply(window, arguments);
  };

  var timer = 0;
  var observer = new MutationObserver(function () {
    if (timer !== 0) { return; }
    timer = setTimeout(function () {
      timer = 0;
      sweep();
    }, 200);
  });
  if (document.documentElement) {
    observer.observe(document.documentElement, { childList: true, subtree: true });
  }
  setInterval(sweep, 1500);
})();
`;

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  @State title: string = 'OhMyBili';
  @State progress: number = 0;
  @State loading: boolean = false;
  @State canBack: boolean = false;
  @State canForward: boolean = false;
  @State errText: string = '';
  @State isFullscreen: boolean = false;
  @State webShown: boolean = true;
  private fullScreenHandler: FullScreenExitHandler | null = null;
  private fullscreenExitAt: number = 0;

  aboutToAppear(): void {
    const launchUrl = AppStorage.get<string>('launchUrl');
    if (launchUrl !== undefined && launchUrl.length > 0) {
      setTimeout(() => {
        this.loadUrl(launchUrl);
      }, 300);
    }
  }

  private loadUrl(url: string): void {
    try {
      this.controller.loadUrl(url);
    } catch (e) {
      this.errText = '页面加载失败';
    }
  }

  private goHome(): void {
    this.loadUrl(HOME_URL);
  }

  private goSearch(): void {
    this.loadUrl(SEARCH_URL);
  }

  private refresh(): void {
    try {
      if (this.loading) {
        this.controller.stop();
        this.loading = false;
      } else {
        this.controller.refresh();
      }
    } catch (e) {
      this.errText = '刷新失败';
    }
  }

  private updateNav(): void {
    try {
      this.canBack = this.controller.accessBackward();
      this.canForward = this.controller.accessForward();
    } catch (e) {
      this.canBack = false;
      this.canForward = false;
    }
  }

  private blockedScheme(url: string): boolean {
    const lower = url.toLowerCase();
    return lower.startsWith('bilibili://') || lower.startsWith('biliapp://') ||
      lower.startsWith('intent://') || lower.startsWith('alipays://') ||
      lower.startsWith('weixin://') || lower.startsWith('snssdk1128://');
  }

  private setSystemBars(visible: boolean): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const names: Array<'status' | 'navigation'> = visible ? ['status', 'navigation'] : [];
      window.getLastWindow(ctx).then((win: window.Window) => {
        win.setWindowSystemBarEnable(names).catch((e: Error) => {
          console.error('system bar failed: ' + e.message);
        });
      }).catch((e: Error) => {
        console.error('get window failed: ' + e.message);
      });
    } catch (e) {
      console.error('system bar setup failed');
    }
  }

  private setOrientation(landscape: boolean): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const orientation: window.Orientation =
        landscape ? window.Orientation.LANDSCAPE : window.Orientation.PORTRAIT;
      window.getLastWindow(ctx).then((win: window.Window) => {
        win.setPreferredOrientation(orientation).catch((e: Error) => {
          console.error('orientation failed: ' + e.message);
        });
      }).catch((e: Error) => {
        console.error('get window failed: ' + e.message);
      });
    } catch (e) {
      console.error('orientation setup failed');
    }
  }

  private applyFullscreenUI(on: boolean): void {
    this.isFullscreen = on;
    this.setSystemBars(!on);
    if (on) {
      try {
        this.controller.runJavaScript(
          "window.__ohmybiliLandscape === '0' ? '0' : '1'"
        ).then((result: string) => {
          this.setOrientation(result !== '0');
        }).catch((e: Error) => {
          console.error('read orientation failed: ' + e.message);
          this.setOrientation(true);
        });
      } catch (e) {
        this.setOrientation(true);
      }
    } else {
      setTimeout(() => {
        this.setOrientation(false);
        setTimeout(() => {
          this.webShown = false;
          setTimeout(() => {
            this.webShown = true;
            try {
              this.controller.refresh();
            } catch (e) {
              console.error('repaint refresh failed');
            }
          }, 250);
        }, 700);
      }, 100);
    }
  }

  private exitFullscreen(): void {
    if (this.fullScreenHandler !== null) {
      try {
        this.fullScreenHandler.exitFullScreen();
      } catch (e) {
        this.applyFullscreenUI(false);
      }
    } else {
      this.applyFullscreenUI(false);
    }
  }

  private injectHelpers(): void {
    try {
      this.controller.runJavaScript(INJECT_JS);
    } catch (e) {
      console.error('inject failed');
    }
  }

  onBackPress(): boolean {
    if (this.isFullscreen) {
      this.exitFullscreen();
      return true;
    }
    if (Date.now() - this.fullscreenExitAt < 1000) {
      return true;
    }
    if (this.canBack) {
      try {
        this.controller.backward();
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  @Builder
  NavButton(icon: string, label: string, enabled: boolean, action: () => void) {
    Column({ space: 1 }) {
      Text(icon)
        .fontSize(20)
        .fontColor(enabled ? '#FFFFFF' : '#666666')
        .height(24)
      Text(label)
        .fontSize(10)
        .fontColor(enabled ? '#BBBBBB' : '#555555')
    }
    .width('20%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (enabled) {
        action();
      }
    })
  }

  build() {
    Column() {
      if (!this.isFullscreen && this.progress > 0 && this.progress < 100) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color('#FB7299')
          .backgroundColor('#F1F1F1')
      }

      Stack({ alignContent: Alignment.TopStart }) {
        Web({ src: HOME_URL, controller: this.controller })
          .width('100%')
          .height('100%')
          .visibility(this.webShown ? Visibility.Visible : Visibility.Hidden)
          .domStorageAccess(true)
          .fileAccess(false)
          .javaScriptAccess(true)
          .darkMode(WebDarkMode.Off)
          .forceDarkAccess(false)
          .onControllerAttached(() => {
            try {
              this.controller.setCustomUserAgent(UA_MOBILE);
            } catch (e) {
              console.error('ua failed');
            }
          })
          .onLoadIntercept((event: LoadInterceptEvent) => {
            try {
              const url = event.data.getRequestUrl();
              if (this.blockedScheme(url)) {
                return true;
              }
            } catch (e) {
              return false;
            }
            return false;
          })
          .onPageBegin((event?: PageEvent) => {
            this.loading = true;
            this.progress = 0;
            this.errText = '';
          })
          .onPageEnd((event?: PageEvent) => {
            this.loading = false;
            this.progress = 100;
            this.updateNav();
            this.injectHelpers();
          })
          .onProgressChange((event?: ProgressEvent) => {
            this.progress = event !== undefined ? event.newProgress : 0;
            if (this.progress >= 100) {
              this.loading = false;
            }
            this.updateNav();
          })
          .onTitleReceive((event?: TitleEvent) => {
            if (event !== undefined && event.title.length > 0) {
              this.title = event.title;
            }
          })
          .onErrorReceive((event?: ErrorEvent) => {
            if (event === undefined) {
              return;
            }
            try {
              if (!event.request.isMainFrame()) {
                return;
              }
              this.loading = false;
              this.errText = '加载失败：' + event.error.getErrorCode() + ' ' + event.error.getErrorInfo();
            } catch (e) {
              this.errText = '页面加载失败';
            }
          })
          .onFullScreenEnter((event: FullScreenEvent) => {
            this.fullScreenHandler = event.handler;
            this.applyFullscreenUI(true);
          })
          .onFullScreenExit(() => {
            this.fullScreenHandler = null;
            this.fullscreenExitAt = Date.now();
            this.applyFullscreenUI(false);
          })

        if (this.errText.length > 0) {
          Column({ space: 16 }) {
            Text(this.errText)
              .fontSize(14)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
              .padding({ left: 24, right: 24 })
            Button('重新加载')
              .backgroundColor('#FB7299')
              .fontColor('#FFFFFF')
              .onClick(() => {
                this.refresh();
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
        }
      }
      .layoutWeight(1)

      if (!this.isFullscreen) {
        Row() {
          this.NavButton('←', '后退', this.canBack, () => {
            try {
              this.controller.backward();
            } catch (e) {
              console.error('back failed');
            }
          })
          this.NavButton('→', '前进', this.canForward, () => {
            try {
              this.controller.forward();
            } catch (e) {
              console.error('forward failed');
            }
          })
          this.NavButton('↻', '刷新', true, () => {
            this.refresh();
          })
          this.NavButton('⌂', '首页', true, () => {
            this.goHome();
          })
          this.NavButton('⌕', '搜索', true, () => {
            this.goSearch();
          })
        }
        .width('100%')
        .height(54)
        .backgroundColor('#1A1A1A')
      }

      if (this.isFullscreen) {
        Button('退出全屏')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .height(34)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#B3000000')
          .position({ x: '85%', y: 12 })
          .zIndex(99)
          .onClick(() => {
            this.exitFullscreen();
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
