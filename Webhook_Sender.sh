#!/bin/bash

# Colors
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

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
echo -e "${YELLOW}Welcome to Webhook Sender 🚀${RESET}"
echo

# Ask if multiple webhooks should be used
read -p "Do you want to enter multiple webhooks? (y/n): " multi_choice

webhooks=()
if [[ "$multi_choice" == "y" ]]; then
    echo -e "${CYAN}Enter your webhooks (one per line). Type 'done' when finished:${RESET}"
    while true; do
        read -p "Webhook: " input
        if [[ "$input" == "done" || -z "$input" ]]; then
            break
        fi
        webhooks+=("$input")
    done
else
    read -p "Webhook: " webhook
    webhooks+=("$webhook")
fi

# Prompt for the message
read -p "Message: " message

# Prompt for how many times to send
read -p "How often to send: " count

# Prompt for the delay
read -p "Delay in seconds: " delay

echo
echo -e "${GREEN}Starting to send messages...${RESET}"
sleep 1

# Loop to send the message
for ((i=1; i<=count; i++)); do
    clear
    echo -e "${CYAN}--------------------------------------------------${RESET}"
    echo -e " Sending message ${YELLOW}$i${RESET} of ${YELLOW}$count${RESET}"
    echo -e "${CYAN}--------------------------------------------------${RESET}"
    for wh in "${webhooks[@]}"; do
        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" "$wh" >/dev/null
    done
    echo -e "${GREEN}✔ Message sent!${RESET}"
    sleep $delay
done

echo
echo -e "${GREEN}All messages sent successfully! 🎉${RESET}"
