// ========================================
// Educoder 自动答题脚本 — F12 Console 执行
// 考试: 数组与函数 (ID: 214116)
// ========================================

(async function() {
  const EXERCISE_ID = 214116;

  // === 单选题答案 (question_id → [choice_id]) ===
  const answers = {
    13742985: [39805166],  // Q1  B
    13742986: [39805169],  // Q2  A
    13742987: [39805176],  // Q3  D
    13742988: [39805178],  // Q4  B
    13742989: [39805183],  // Q5  C
    13742990: [39805186],  // Q6  B
    13742991: [39805189],  // Q7  A
    13742992: [39805195],  // Q8  C
    13742993: [39805197],  // Q9  A
  };

  // 方法1: 通过 store dispatch
  const dvaApp = window.getDvaApp?.();
  if (dvaApp) {
    console.log('找到 DVA 实例，开始提交单选题...');
    const store = dvaApp._store;

    for (const [qid, choiceIds] of Object.entries(answers)) {
      try {
        await store.dispatch({
          type: 'exercise/saveAnswer',
          payload: { questionId: parseInt(qid), choice_ids: choiceIds }
        });
        console.log('Q' + Object.keys(answers).indexOf(qid) + 1 + ' 已提交');
      } catch(e) {
        console.log('Q failed:', e);
      }
    }
  }

  // 方法2: 直接调 API (备用)
  console.log('尝试直接 API 提交...');
  for (const [qid, choiceIds] of Object.entries(answers)) {
    // 使用页面自己的 request 函数
    const resp = await fetch(
      `https://data.educoder.net/api/exercise_questions/${qid}/exercise_answers.json`,
      {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify({
          question_id: parseInt(qid),
          choice_ids: choiceIds
        })
      }
    );
    const data = await resp.json();
    console.log(`Q${Object.keys(answers).indexOf(qid)+1}:`, data.status === 0 ? 'OK' : data.message);
  }

  console.log('=== 单选题提交完毕 ===');
  console.log('编程题需要通过 Hack 系统单独提交，请查看 educoder_solutions.md');
})();
