#!/bin/bash

# ================= COLORS =================
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# ================= STATE ==================
sent=0
failed=0
infinite=false
last_error="None"

# ================= CTRL+C =================
trap 'echo -e "\n${RED}✖ Stopped by user${RESET}";
      echo -e "${GREEN}Sent: $sent${RESET}";
      echo -e "${RED}Failed: $failed${RESET}";
      exit 0' INT

# ================= BANNER =================
clear
echo -e "${CYAN}"
cat << "EOF"
 __        __   _     _                 _
 \ \      / /__| |__ | |__   ___   ___ | | _____ _ __   __ _ _ __ ___
  \ \ /\ / / _ \ '_ \| '_ \ / _ \ / _ \| |/ / __| '_ \ / _` | '_ ` _ \
   \ V  V /  __/ |_) | | | | (_) | (_) |   <\__ \ |_) | (_| | | | | | |
    \_/\_/ \___|_.__/|_| |_|\___/ \___/|_|\_\___/ .__/ \__,_|_| |_| |_|
                                                |_|
EOF
echo -e "${RESET}"
echo -e "${YELLOW}Welcome to Webhook Sender 🚀${RESET}\n"

# ================= WEBHOOKS =================
read -p "Use multiple webhooks? (y/n): " multi_choice
webhooks=()

if [[ "$multi_choice" == "y" ]]; then
    echo -e "${CYAN}Enter webhooks (type 'done' to finish):${RESET}"
    while true; do
        read -p "Webhook: " input
        [[ "$input" == "done" || -z "$input" ]] && break
        webhooks+=("$input")
    done
else
    read -p "Webhook: " webhook
    webhooks+=("$webhook")
fi

# ================= MESSAGE =================
read -p "Message: " message

# ================= COUNT ===================
read -p "How many times to send? (0 = infinite): " count
[[ "$count" == "0" ]] && infinite=true

# ================= DELAY ===================
echo
echo -e "${CYAN}Choose a delay:${RESET}"
echo -e " 1) 0.4 seconds  ${GREEN}(best for Discord)${RESET}"
echo -e " 2) 1 second"
echo -e " 3) 2 seconds"
echo -e " 4) Custom"

read -p "Select option [1-4]: " delay_choice
case "$delay_choice" in
    1) delay="0.4" ;;
    2) delay="1" ;;
    3) delay="2" ;;
    4) read -p "Enter custom delay in seconds: " delay ;;
    *) delay="0.4" ;;
esac

echo
echo -e "${GREEN}Starting...${RESET}"
sleep 1

# ================= MAIN LOOP =================
while true; do
    ((sent++))
    had_error=false
    last_error="None"

    for wh in "${webhooks[@]}"; do
        # Capture HTTP code + curl errors
        curl_output=$(curl -sS -o /dev/null -w "%{http_code}" \
            -X POST -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" "$wh" 2>&1)

        http_code="${curl_output: -3}"

        case "$http_code" in
            200|204)
                ;;
            429)
                last_error="429 Rate Limited"
                had_error=true
                ((failed++))
                ;;
            000)
                last_error="Network / Connection error"
                had_error=true
                ((failed++))
                ;;
            *)
                last_error="HTTP $http_code"
                had_error=true
                ((failed++))
                ;;
        esac
    done

    clear
    echo -e "${CYAN}--------------------------------------------------${RESET}"
    echo -e " Message: ${YELLOW}\"$message\"${RESET}"
    if $infinite; then
        echo -e " Sent: ${GREEN}$sent${RESET} (infinite mode)"
    else
        echo -e " Sent: ${GREEN}$sent${RESET} out of ${YELLOW}$count${RESET}"
    fi
    echo -e " Failed: ${RED}$failed${RESET}"
    if $had_error; then
        echo -e " Last error: ${RED}$last_error${RESET}"
    else
        echo -e " Last error: ${GREEN}None${RESET}"
    fi
    echo -e "${CYAN}--------------------------------------------------${RESET}"

    if ! $infinite && [[ "$sent" -ge "$count" ]]; then
        break
    fi

    sleep "$delay"
done

# ================= END =================
echo
echo -e "${GREEN}Finished sending messages! 🎉${RESET}"
echo -e "${GREEN}Sent: $sent${RESET}"
echo -e "${RED}Failed: $failed${RESET}"
