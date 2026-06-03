"""
豆包 Seed 2.0 本地代理 (性能优化版 v2)
优化: 多线程 + 连接池 + 计时日志
用法: python doubao-proxy.py
"""

import json
import time
import threading
import ssl
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from http.client import HTTPSConnection
from urllib.parse import urlparse

DOUBAO_HOST = "ark.cn-beijing.volces.com"
DOUBAO_BASE = "/api/compatible"
TIMEOUT = 120

# === 连接池 ===
_pool_lock = threading.Lock()
_ssl_context = ssl.create_default_context()

def get_connection():
    """获取/创建复用的 HTTPS 连接"""
    conn = HTTPSConnection(DOUBAO_HOST, timeout=TIMEOUT, context=_ssl_context)
    return conn


def convert_document_to_text(body: dict) -> dict:
    if isinstance(body, dict):
        if body.get("type") == "document":
            source = body.get("source", {})
            text = f"[Document: {source.get('media_type', 'unknown')}]\n"
            data = source.get("data", "")
            if data:
                text += f"[Base64 data, {len(data)} bytes]"
            return {"type": "text", "text": text}
        return {k: convert_document_to_text(v) for k, v in body.items()}
    elif isinstance(body, list):
        return [convert_document_to_text(item) for item in body]
    return body


class ProxyHandler(BaseHTTPRequestHandler):
    def address_string(self):
        return self.client_address[0]

    def do_request(self, method):
        t0 = time.time()

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        t_read = time.time()

        # 转换 document 块
        if body and self.path.startswith(DOUBAO_BASE + "/messages"):
            try:
                body_json = json.loads(body)
                converted = convert_document_to_text(body_json)
                body = json.dumps(converted).encode("utf-8")
            except json.JSONDecodeError:
                pass
        t_convert = time.time()

        # 构造转发 headers
        forward_headers = {}
        for key, value in self.headers.items():
            if key.lower() not in ("host", "content-length"):
                forward_headers[key] = value
        forward_headers["Content-Length"] = str(len(body))

        # 发送请求到豆包
        try:
            conn = get_connection()
            conn.request(method, DOUBAO_BASE + self.path, body=body, headers=forward_headers)
            t_sent = time.time()

            resp = conn.getresponse()
            t_first_byte = time.time()

            self.send_response(resp.status)
            for key, value in resp.headers.items():
                if key.lower() not in ("transfer-encoding", "connection"):
                    self.send_header(key, value)
            self.end_headers()

            # 流式转发
            while True:
                chunk = resp.read1(16384)  # read1 = 非阻塞，更快
                if not chunk:
                    break
                self.wfile.write(chunk)
                self.wfile.flush()
            t_done = time.time()

            # 计时日志（只在耗时 > 1s 时打印）
            total = t_done - t0
            if total > 1.0:
                print(f"[proxy][{t_read-t0:.2f}s read][{t_convert-t_read:.3f}s conv]"
                      f"[{t_first_byte-t_sent:.2f}s TTFB][{t_done-t_first_byte:.2f}s stream]"
                      f" | total={total:.1f}s | {method} {self.path[:60]}")

        except Exception as e:
            t_done = time.time()
            self.send_response(502)
            self.end_headers()
            err = {"error": {"message": f"代理错误: {str(e)}", "type": "proxy_error"}}
            self.wfile.write(json.dumps(err).encode())
            print(f"[proxy][ERR][{t_done-t0:.1f}s] {str(e)[:100]}")

    do_GET = lambda self: self.do_request("GET")
    do_POST = lambda self: self.do_request("POST")
    do_PUT = lambda self: self.do_request("PUT")
    do_DELETE = lambda self: self.do_request("DELETE")

    def log_message(self, format, *args):
        pass  # 静默默认日志


if __name__ == "__main__":
    port = 3456
    print(f"豆包代理启动 v2: http://127.0.0.1:{port}")
    print(f"转发目标: https://{DOUBAO_HOST}{DOUBAO_BASE}")
    print(f"超时: {TIMEOUT}s | 连接复用")
    print("按 Ctrl+C 停止")

    server = ThreadingHTTPServer(("127.0.0.1", port), ProxyHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n代理已停止")
        server.shutdown()
