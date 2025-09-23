#!/bin/bash

# Your model (grok-3 or grok-4 if subscribed)
MODEL="grok-3"

# Temp file for message history (JSON array of messages)
HISTORY_FILE="/tmp/grok_history.json"

# Max file size to read (in bytes; adjust if needed to avoid huge token bills)
MAX_FILE_SIZE=100000  # ~100KB; Grok can handle more, but costs rise

# Initialize history with optional system prompt
echo '[{"role": "system", "content": "You are Grok, a helpful AI built by xAI. Analyze code, suggest improvements, or generate new code based on user prompts."}]' > "$HISTORY_FILE"

echo "Welcome to Grok CLI (code edition)! Type 'exit' to quit."
echo "Special commands: @file <filename> <prompt> (appends file content)"
echo "                 @dir <prompt> (appends directory tree)"
echo "                 @ls <prompt> (appends ls -la output)"

while true; do
    # Get user input
    read -p "You: " user_input
    if [ "$user_input" == "exit" ]; then
        break
    fi

    # Parse special commands
    extra_content=""
    prompt="$user_input"

    if [[ "$user_input" == @file* ]]; then
        filename=$(echo "$user_input" | awk '{print $2}')
        prompt=$(echo "$user_input" | cut -d' ' -f3-)
        if [ -f "$filename" ] && [ $(stat -f%z "$filename") -le $MAX_FILE_SIZE ]; then
            extra_content="\n\nFile content from $filename:\n$(cat "$filename")"
        else
            echo "Error: File not found or too large."
            continue
        fi
    elif [[ "$user_input" == @dir* ]]; then
        prompt=$(echo "$user_input" | cut -d' ' -f2-)
        if command -v tree >/dev/null; then
            extra_content="\n\nDirectory tree:\n$(tree -L 2)"
        else
            extra_content="\n\nInstall 'tree' for better output (e.g., brew install tree). Falling back to ls:\n$(ls -R)"
        fi
    elif [[ "$user_input" == @ls* ]]; then
        prompt=$(echo "$user_input" | cut -d' ' -f2-)
        extra_content="\n\nls -la output:\n$(ls -la)"
    fi

    # Combine prompt with extra content
    full_prompt="$prompt$extra_content"

    # Load current history
    history=$(cat "$HISTORY_FILE")

    # Add user message to history
    new_history=$(echo "$history" | jq --arg content "$full_prompt" '. += [{"role": "user", "content": $content}]')

    # Save updated history
    echo "$new_history" > "$HISTORY_FILE"

    # Call API with curl
    response=$(curl -s https://api.x.ai/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $XAI_API_KEY" \
      -d "{
        \"model\": \"$MODEL\",
        \"messages\": $new_history
      }")

    # Check for errors
    error=$(echo "$response" | jq -r '.error.message // null')
    if [ "$error" != "null" ]; then
        echo "API Error: $error"
        continue
    fi

    # Extract Grok's reply
    grok_reply=$(echo "$response" | jq -r '.choices[0].message.content')

    # Print reply
    echo "Grok: $grok_reply"

    # Add assistant message to history
    new_history=$(echo "$new_history" | jq --arg content "$grok_reply" '. += [{"role": "assistant", "content": $content}]')
    echo "$new_history" > "$HISTORY_FILE"

    # Print usage for this turn
    usage=$(echo "$response" | jq '.usage')
    echo "Usage this turn: $usage"
done

# Clean up
rm "$HISTORY_FILE"
echo "CLI session ended."
