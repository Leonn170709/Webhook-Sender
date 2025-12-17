from flask import Flask, render_template, request, jsonify
import threading
import time
import requests

app = Flask(__name__)

# ===== GLOBAL STATE =====
sent = 0
failed = 0
running = False
status_lock = threading.Lock()
last_error = "None"

# ===== SEND FUNCTION =====
def send_webhooks(webhooks, message, count, delay):
    global sent, failed, running, last_error
    sent = 0
    failed = 0
    running = True

    infinite = count == 0

    while running:
        sent += 1
        had_error = False
        last_error = "None"

        for wh in webhooks:
            try:
                r = requests.post(wh, json={"content": message}, timeout=10)
                if r.status_code not in (200, 204):
                    had_error = True
                    last_error = f"HTTP {r.status_code}"
                    failed += 1
            except requests.exceptions.RequestException as e:
                had_error = True
                last_error = str(e)
                failed += 1

        with status_lock:
            pass  # status updated automatically via globals

        if not infinite and sent >= count:
            break

        time.sleep(delay)

    running = False

# ===== ROUTES =====
@app.route("/")
def index():
    return render_template("index.html")

@app.route("/start", methods=["POST"])
def start():
    global running
    if running:
        return jsonify({"status": "already running"})

    data = request.json
    webhooks = data.get("webhooks", [])
    message = data.get("message", "")
    count = int(data.get("count", 0))
    delay = float(data.get("delay", 0.4))

    thread = threading.Thread(target=send_webhooks, args=(webhooks, message, count, delay))
    thread.daemon = True
    thread.start()
    return jsonify({"status": "started"})

@app.route("/stop", methods=["POST"])
def stop():
    global running
    running = False
    return jsonify({"status": "stopped"})

@app.route("/status")
def status():
    with status_lock:
        return jsonify({
            "sent": sent,
            "failed": failed,
            "last_error": last_error,
            "running": running
        })

# ===== MAIN =====
if __name__ == "__main__":
    app.run(debug=True)
