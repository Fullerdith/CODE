"""
视觉识别脚本 v2 — 性能优化版
优化: HTTP连接复用 + 减小输出 + 计时日志
用法: python vision.py <图片路径> [提问]
"""
import sys, base64, json, time, ssl
from http.client import HTTPSConnection

API_KEY = "sk-fddd345fa23049c290d393b662d4cc29"
API_HOST = "dashscope.aliyuncs.com"
MODEL = "qwen-vl-plus"
MAX_TOKENS = 800  # 减半，够用且更快

_conn = None
def get_conn():
    global _conn
    if _conn is None:
        _conn = HTTPSConnection(API_HOST, timeout=30,
                                context=ssl.create_default_context())
    return _conn

def encode_image(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def vision(image_path: str, prompt: str = "提取图片中的所有文字，逐字输出。") -> dict:
    t0 = time.time()
    img_b64 = encode_image(image_path)
    t1 = time.time()

    ext = image_path.lower().split(".")[-1]
    mime = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg",
            "webp": "image/webp", "gif": "image/gif"}.get(ext, "image/png")

    body = {
        "model": MODEL,
        "messages": [{"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{img_b64}"}},
            {"type": "text", "text": prompt},
        ]}],
        "max_tokens": MAX_TOKENS,
    }
    payload = json.dumps(body)

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "Connection": "keep-alive",
    }

    conn = get_conn()
    conn.request("POST", "/compatible-mode/v1/chat/completions", body=payload, headers=headers)
    t2 = time.time()

    resp = conn.getresponse()
    data = json.loads(resp.read())
    t3 = time.time()

    text = data["choices"][0]["message"]["content"]

    # 只打印计时，不混入输出
    if (t3 - t0) > 2.0:
        print(f"[耗时: 编码{t1-t0:.1f}s 发送{t2-t1:.1f}s API{t3-t2:.1f}s 总{t3-t0:.1f}s]",
              file=sys.stderr)
    return text

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python vision.py <图片路径> [提问]")
        sys.exit(1)

    path = sys.argv[1]
    prompt = sys.argv[2] if len(sys.argv) > 2 else "提取图片中的所有文字，逐字输出。"

    sys.stdout.reconfigure(encoding='utf-8')
    result = vision(path, prompt)
    print(result)
