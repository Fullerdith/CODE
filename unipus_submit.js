// ==========================================
// Unipus 课程自动完成脚本
// 在课程页面 F12 → Console 粘贴运行
// 自动完成所有题目，每题间隔 20-60 秒
// ==========================================

(async function() {
  const DEBUG = true;
  const MIN_DELAY = 20000;  // 最小间隔 20 秒
  const MAX_DELAY = 50000;  // 最大间隔 50 秒

  const log = (...args) => DEBUG && console.log('[AutoSolve]', ...args);
  const delay = ms => new Promise(r => setTimeout(r, ms));
  const randomDelay = () => delay(MIN_DELAY + Math.random() * (MAX_DELAY - MIN_DELAY));

  // ============ 第一步：找到页面内的 API 实例 ============
  log('搜索页面内的 API 实例...');

  // 从 React 组件树中提取 axios/http 实例
  function findApiInstance() {
    // 检查 window 上挂载的全局实例
    const candidates = Object.keys(window).filter(k => {
      try {
        const v = window[k];
        return v && typeof v === 'object' && (v.get || v.post) && v.interceptors;
      } catch(e) { return false; }
    });
    log('可能的 HTTP 实例:', candidates);
    return candidates;
  }

  // 尝试获取 React fiber 中的 course 数据
  function getReactData() {
    const root = document.getElementById('root');
    if (!root) return null;

    const fiberKey = Object.keys(root).find(k => k.startsWith('__reactFiber') || k.startsWith('__reactInternalInstance'));
    if (!fiberKey) return null;

    let fiber = root[fiberKey];
    let depth = 0;
    while (fiber && depth < 100) {
      try {
        const state = fiber.memoizedState;
        const props = fiber.memoizedProps;

        if (state && state.course) return { source: 'state.course', data: state.course };
        if (state && state.workData) return { source: 'state.workData', data: state.workData };
        if (props && props.course) return { source: 'props.course', data: props.course };
        if (props && props.questions) return { source: 'props.questions', data: props.questions };

        // Check hooks chain
        let hookState = state;
        while (hookState) {
          const val = hookState.memoizedState;
          if (val && typeof val === 'object' && (val.course || val.questions || val.unitList)) {
            return { source: 'hook', data: val };
          }
          hookState = hookState.next;
        }
      } catch(e) {}
      fiber = fiber.return;
      depth++;
    }
    return null;
  }

  findApiInstance();
  const reactData = getReactData();
  if (reactData) {
    log('找到 React 数据:', reactData.source);
    console.log(JSON.stringify(reactData.data).substring(0, 500));
  } else {
    log('未能从 React fiber 获取数据');
  }

  // ============ 第二步：Hook 网络请求看数据结构 ============
  log('监听后续 XHR 请求，请手动操作一道题...');

  const origFetch = window.fetch;
  const capturedRequests = [];

  window.fetch = function(...args) {
    const req = { url: args[0], options: args[1], time: Date.now() };
    if (req.url.includes('answer') || req.url.includes('work') || req.url.includes('question')) {
      capturedRequests.push(req);
      log('捕获 API 请求:', req.url);
      if (req.options?.body) {
        try {
          console.log('  Body:', JSON.parse(req.options.body));
        } catch(e) {
          console.log('  Body raw:', req.options.body);
        }
      }
    }
    return origFetch.apply(this, args).then(resp => {
      const clone = resp.clone();
      if (req.url.includes('answer') || req.url.includes('work') || req.url.includes('question')) {
        clone.text().then(t => {
          try {
            console.log('  Response:', JSON.parse(t));
          } catch(e) {
            console.log('  Response:', t.substring(0, 300));
          }
        });
      }
      return resp;
    });
  };

  // Hook XHR
  const origOpen = XMLHttpRequest.prototype.open;
  const origSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function(method, url) {
    this._autoSolve = { method, url };
    return origOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function(body) {
    if (this._autoSolve?.url?.includes('answer') || this._autoSolve?.url?.includes('work') || this._autoSolve?.url?.includes('question')) {
      log('捕获 XHR:', this._autoSolve.method, this._autoSolve.url);
      console.log('  Body:', body);
    }
    this.addEventListener('load', function() {
      if (this._autoSolve?.url?.includes('answer') || this._autoSolve?.url?.includes('work')) {
        try {
          console.log('  XHR Response:', JSON.parse(this.responseText));
        } catch(e) {}
      }
    });
    return origSend.call(this, body);
  };

  // 存储捕获的请求
  window.__autoSolveCaptured = capturedRequests;
  window.__autoSolveGetCaptured = () => {
    console.log('捕获到的请求:');
    capturedRequests.forEach(r => console.log(r.url, r.options));
    return capturedRequests;
  };

  console.log(`
╔══════════════════════════════════════╗
║  Unipus Auto Solve 脚本已加载          ║
║                                        ║
║  下一步：                                ║
║  1. 在页面上手动做一道题                   ║
║  2. 在 Console 运行:                      ║
║     __autoSolveGetCaptured()             ║
║  3. 把捕获的 Request Body 贴给我           ║
║                                        ║
║  然后我就能批量自动完成全部课程              ║
╚══════════════════════════════════════╝
  `);
})();
