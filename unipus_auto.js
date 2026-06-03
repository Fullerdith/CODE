// Unipus 自动答题 v2 - 直接调页面模块
// F12 → Console 粘贴运行

(async function() {
  console.log('=== Unipus Auto v2 ===');

  // 方法1: 从 webpack 模块系统拿
  const wpKeys = Object.keys(window).filter(k => k.includes('webpack') || k.includes('__webpack'));
  console.log('Webpack keys:', wpKeys);

  // 方法2: 从 __webpack_require__ 获取模块
  const wpRequire = window.__webpack_require__ || window.webpackJsonp;
  if (wpRequire) {
    console.log('Found webpack require!');
  }

  // 方法3: 从页面 URL 获取当前课程的 work/question 数据
  // 查找包含 course/work/question 的 script 标签
  const scripts = document.querySelectorAll('script');
  scripts.forEach(s => {
    const text = s.textContent || '';
    if (text.includes('work') && text.includes('question')) {
      console.log('Found inline data in script:', s.id || 'unnamed', text.substring(0, 300));
    }
  });

  // 方法4: 查找 window 上所有可能存 API 函数的对象
  const interestingKeys = Object.keys(window).filter(k => {
    try {
      const v = window[k];
      return typeof v === 'function' && (
        v.name.includes('submit') || v.name.includes('answer') ||
        v.name.includes('cache') || v.name.includes('load')
      );
    } catch(e) { return false; }
  });
  console.log('Submit/answer functions:', interestingKeys);

  // 方法5: 直接从 React root 的 fiber 树里挖
  function digDeep(fiber, depth) {
    if (!fiber || depth > 50) return null;
    try {
      // 检查 fiber 的 pendingProps, memoizedProps, memoizedState
      for (const key of ['memoizedProps', 'pendingProps', 'memoizedState']) {
        const val = fiber[key];
        if (val && typeof val === 'object') {
          // 找包含 work/question 的任意嵌套对象
          const check = (obj, d) => {
            if (!obj || d > 5) return;
            if (typeof obj === 'object' && !Array.isArray(obj)) {
              for (const k in obj) {
                if (k === 'workData' || k === 'questions' || k === 'unit' || k === 'course') {
                  console.log(`Found ${k} at depth ${depth}:`, obj[k]);
                  window.__autoData = obj;
                  return obj;
                }
                check(obj[k], d + 1);
              }
            }
          };
          check(val, 0);
        }
      }
    } catch(e) {}
    return digDeep(fiber.child, depth + 1) || digDeep(fiber.sibling, depth + 1);
  }

  const root = document.getElementById('root');
  if (root) {
    const fiberKey = Object.keys(root).find(k => k.startsWith('__reactFiber'));
    if (fiberKey) {
      console.log('Digging React fiber tree...');
      digDeep(root[fiberKey], 0);
    }
  }

  // 检查是否找到了数据
  setTimeout(() => {
    if (window.__autoData) {
      console.log('=== 成功获取到页面数据 ===');
      console.log(JSON.stringify(window.__autoData).substring(0, 2000));
    } else {
      console.log('=== 未找到自动数据，请尝试以下手动步骤 ===');
      console.log('1. 在 Network 面板筛选 Fetch/XHR');
      console.log('2. 找一个 POST 请求（含 answer/work/submit 字样）');
      console.log('3. 右键 Copy as cURL 贴给我');
    }
  }, 2000);
})();
