import tkinter as tk
from tkinter import messagebox, scrolledtext, ttk
import threading
import time
import requests
import datetime

running = False
sent = 0
failed = 0

def log_message(msg, level="INFO"):
    timestamp = datetime.datetime.now().strftime("%H:%M:%S")
    log_box.config(state="normal")
    log_box.insert(tk.END, f"[{timestamp}] [{level}] {msg}\n")
    log_box.see(tk.END)
    log_box.config(state="disabled")

# ================= SEND LOGIC =================
def send_messages():
    global running, sent, failed

    webhooks = webhook_box.get("1.0", tk.END).strip().splitlines()
    message = message_entry.get().strip()
    count = count_entry.get().strip()
    delay = delay_var.get()

    if not webhooks or not message:
        messagebox.showerror("Error", "Webhook and message required")
        return

    infinite = count == "0"
    try:
        target_count = int(count)
    except:
        messagebox.showerror("Error", "Invalid count")
        return

    sent = 0
    failed = 0
    running = True
    btn_start.config(state="disabled")
    btn_stop.config(state="normal")
    log_message("Sending sequence started.")

    while running:
        last_error = "None"
        had_error = False

        for wh in webhooks:
            if not running: break
            try:
                r = requests.post(
                    wh,
                    json={"content": message},
                    timeout=5
                )
                if r.status_code not in (200, 201, 204):
                    had_error = True
                    last_error = f"HTTP {r.status_code}"
                    failed += 1
                    log_message(f"Fail: {wh[:25]}... ({r.status_code})", "WARN")
                else:
                    log_message(f"Success: {wh[:25]}...")
            except requests.exceptions.RequestException as e:
                had_error = True
                last_error = "Connection Error"
                failed += 1
                log_message(f"Error: {wh[:25]}... (Conn Error)", "ERROR")
        
        sent += 1

        # UI update
        status_message.config(text=f"Message: {message[:30]}..." if len(message) > 30 else f"Message: {message}")
        status_sent.config(text=f"Sent: {sent}" + (" (infinite)" if infinite else f" out of {target_count}"))
        status_failed.config(text=f"Failed: {failed}")
        status_error.config(text=f"Last error: {last_error}")
        root.update_idletasks()

        if not infinite and sent >= target_count:
            break

        for _ in range(int(delay * 10)): # Incremental sleep for faster stop response
            if not running: break
            time.sleep(0.1)

    running = False
    btn_start.config(state="normal")
    btn_stop.config(state="disabled")
    log_message("Sending sequence stopped.")

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
root.geometry("550x700")
root.resizable(False, False)
root.configure(padx=20, pady=20)

style = ttk.Style()
style.configure("TButton", font=("Segoe UI", 10))

# Webhooks
ttk.Label(root, text="Webhooks (one per line):", font=("Segoe UI", 10, "bold")).pack(anchor="w")
webhook_box = scrolledtext.ScrolledText(root, height=5, font=("Consolas", 9))
webhook_box.pack(fill="x", pady=(0, 10))

# Message
ttk.Label(root, text="Message:", font=("Segoe UI", 10, "bold")).pack(anchor="w")
message_entry = ttk.Entry(root)
message_entry.pack(fill="x", pady=(0, 10))

# Count
ttk.Label(root, text="Amount (0 = infinite):", font=("Segoe UI", 10, "bold")).pack(anchor="w")
count_entry = ttk.Entry(root)
count_entry.insert(0, "0")
count_entry.pack(fill="x", pady=(0, 10))

# Delay
ttk.Label(root, text="Delay (seconds):", font=("Segoe UI", 10, "bold")).pack(anchor="w")
delay_var = tk.DoubleVar(value=0.4)
delays_frame = ttk.Frame(root)
delays_frame.pack(fill="x", pady=(0, 10))
for d in [0.4, 1.0, 2.0]:
    ttk.Radiobutton(delays_frame, text=f"{d}s", variable=delay_var, value=d).pack(side="left", padx=5)

# Buttons
btn_frame = ttk.Frame(root)
btn_frame.pack(pady=10)

btn_start = tk.Button(btn_frame, text="START", width=15, bg="#2ecc71", fg="white", font=("Segoe UI", 10, "bold"), relief="flat", command=start)
btn_start.pack(side="left", padx=5)
btn_stop = tk.Button(btn_frame, text="STOP", width=15, bg="#e74c3c", fg="white", font=("Segoe UI", 10, "bold"), relief="flat", command=stop, state="disabled")
btn_stop.pack(side="left", padx=5)

# Status
status_frame = ttk.LabelFrame(root, text=" Status ", padding=10)
status_frame.pack(fill="x", pady=(0, 10))

status_message = ttk.Label(status_frame, text="Message: -")
status_message.pack(anchor="w")
status_sent = ttk.Label(status_frame, text="Sent: 0")
status_sent.pack(anchor="w")
status_failed = ttk.Label(status_frame, text="Failed: 0")
status_failed.pack(anchor="w")
status_error = ttk.Label(status_frame, text="Last error: None", foreground="red")
status_error.pack(anchor="w")

# Logs
ttk.Label(root, text="Logs:", font=("Segoe UI", 10, "bold")).pack(anchor="w")
log_box = scrolledtext.ScrolledText(root, height=8, font=("Consolas", 8), state="disabled", bg="#f4f4f4")
log_box.pack(fill="both", expand=True)

root.mainloop()
