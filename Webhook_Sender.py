import tkinter as tk
from tkinter import messagebox, scrolledtext
import threading
import time
import requests

running = False
sent = 0
failed = 0

# ================= SEND LOGIC =================
def send_messages():
    global running, sent, failed

    webhooks = webhook_box.get("1.0", tk.END).strip().splitlines()
    message = message_entry.get().strip()
    count = count_entry.get().strip()
    delay = delay_var.get()

    if not webhooks or not message:
        messagebox.show_error("Error", "Webhook and message required")
        return

    infinite = count == "0"
    try:
        count = int(count)
    except:
        messagebox.show_error("Error", "Invalid count")
        return

    sent = 0
    failed = 0
    running = True

    while running:
        sent += 1
        last_error = "None"
        had_error = False

        for wh in webhooks:
            try:
                r = requests.post(
                    wh,
                    json={"content": message},
                    timeout=10
                )

                if r.status_code not in (200, 204):
                    had_error = True
                    last_error = f"HTTP {r.status_code}"
                    failed += 1

            except requests.exceptions.RequestException as e:
                had_error = True
                last_error = str(e)
                failed += 1

        # UI update
        status_message.config(text=f"Message: \"{message}\"")
        status_sent.config(text=f"Sent: {sent}" + (" (infinite)" if infinite else f" out of {count}"))
        status_failed.config(text=f"Failed: {failed}")
        status_error.config(text=f"Last error: {last_error}")

        if not infinite and sent >= count:
            break

        time.sleep(delay)

    running = False

# ================= START / STOP =================
def start():
    global running
    if running:
        return
    threading.Thread(target=send_messages, daemon=True).start()

def stop():
    global running
    running = False

# ================= GUI =================
root = tk.Tk()
root.title("Webhook Sender 🚀")
root.geometry("620x540")
root.resizable(False, False)

# Webhooks
tk.Label(root, text="Webhooks (one per line):").pack(anchor="w", padx=10)
webhook_box = scrolledtext.ScrolledText(root, height=6)
webhook_box.pack(fill="x", padx=10)

# Message
tk.Label(root, text="Message:").pack(anchor="w", padx=10)
message_entry = tk.Entry(root)
message_entry.pack(fill="x", padx=10)

# Count
tk.Label(root, text="Amount (0 = infinite):").pack(anchor="w", padx=10)
count_entry = tk.Entry(root)
count_entry.insert(0, "0")
count_entry.pack(fill="x", padx=10)

# Delay
tk.Label(root, text="Delay:").pack(anchor="w", padx=10)
delay_var = tk.DoubleVar(value=0.4)

tk.Radiobutton(root, text="0.4s (best for Discord)", variable=delay_var, value=0.4).pack(anchor="w", padx=20)
tk.Radiobutton(root, text="1s", variable=delay_var, value=1.0).pack(anchor="w", padx=20)
tk.Radiobutton(root, text="2s", variable=delay_var, value=2.0).pack(anchor="w", padx=20)

# Buttons
btn_frame = tk.Frame(root)
btn_frame.pack(pady=10)

tk.Button(btn_frame, text="Start", width=15, bg="#4CAF50", command=start).pack(side="left", padx=5)
tk.Button(btn_frame, text="Stop", width=15, bg="#F44336", command=stop).pack(side="left", padx=5)

# Status
tk.Label(root, text="Status:", font=("Arial", 10, "bold")).pack(anchor="w", padx=10)

status_message = tk.Label(root, text="Message: -")
status_message.pack(anchor="w", padx=20)

status_sent = tk.Label(root, text="Sent: 0")
status_sent.pack(anchor="w", padx=20)

status_failed = tk.Label(root, text="Failed: 0")
status_failed.pack(anchor="w", padx=20)

status_error = tk.Label(root, text="Last error: None", fg="red")
status_error.pack(anchor="w", padx=20)

root.mainloop()
