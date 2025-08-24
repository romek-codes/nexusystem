{ pkgs, ... }:
let
  lazycommit = pkgs.writeShellScriptBin "lazycommit"
    # bash
    ''
      #!/usr/bin/env bash

      # Configurable settings
      CONFIG_DIR="$HOME/.config/lazycommit"
      CONFIG_FILE="$CONFIG_DIR/api_key"
      MODEL_FILE="$CONFIG_DIR/model"

      # OPENROUTER_MODEL="deepseek/deepseek-chat-v3-0324:free"
      # OPENROUTER_MODEL="meta-llama/llama-3.3-70b-instruct:free"
      OPENROUTER_MODEL="tngtech/deepseek-r1t-chimera:free"
      # OPENROUTER_MODEL="google/gemini-flash-1.5-8b"
      OPENROUTER_TEMPERATURE="0.7"

      # Function to save API key
      save_api_key() {
        mkdir -p "$CONFIG_DIR"
        echo "$1" > "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        echo "✅ API key saved to $CONFIG_FILE"
      }

      get_api_key() {
        # First try environment variable
        if [[ -n "$OPENROUTER_API_KEY" ]]; then
          echo "$OPENROUTER_API_KEY"
          # Save to config for future use
          save_api_key "$OPENROUTER_API_KEY"
          return 0
        fi
        
        # Then try config file
        if [[ -f "$CONFIG_FILE" ]]; then
          API_KEY_FROM_FILE=$(cat "$CONFIG_FILE" | tr -d '[:space:]')
          if [[ -n "$API_KEY_FROM_FILE" ]]; then
            echo "$API_KEY_FROM_FILE"  # This echoes the actual key
            return 0
          fi
        fi
        
        # No API key found
        echo ""  # Echo empty string instead of just returning failure
        return 1
      }

      # Function to save model
      save_model() {
        mkdir -p "$CONFIG_DIR"
        echo "$1" > "$MODEL_FILE"
        chmod 600 "$MODEL_FILE"
        echo "✅ Model saved to $MODEL_FILE"
      }

      # Function to get model
      get_model() {
        if [[ -f "$MODEL_FILE" ]]; then
          cat "$MODEL_FILE"
        else
          echo "$OPENROUTER_MODEL"
        fi
      }

      # Parse command line arguments
      while [[ $# -gt 0 ]]; do
        case $1 in
          --api-key)
            if [[ -n "$2" && "$2" != -* ]]; then
              save_api_key "$2"
              shift 2
            else
              echo "❌ --api-key requires a valid API key"
              exit 1
            fi
            ;;
          --model)
            if [[ -n "$2" && "$2" != -* ]]; then
              save_model "$2"
              shift 2
            else
              echo "❌ --model requires a valid model name"
              exit 1
            fi
            ;;
          -h|--help)
            echo "Usage: lazycommit [options]"
            echo ""
            echo "Options:"
            echo "  --api-key <key>    Set api key"
            echo "  --model <model>    Set model (default: tngtech/deepseek-r1t-chimera:free)"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "The API key can also be set via OPENROUTER_API_KEY environment variable."
            exit 0
            ;;
          *)
            echo "❌ Unknown argument: $1"
            exit 1
            ;;
        esac
      done

      # Get API key
      API_KEY=$(get_api_key)
      if [[ -z "$API_KEY" ]]; then  # Check if the key is empty
        echo "❌ No OpenRouter API key found."
        echo "   Set OPENROUTER_API_KEY environment variable"
        exit 1
      fi

      # Get model
      MODEL=$(get_model)

      # Check if we're in a git repository
      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Not in a git repository"
        exit 1
      fi

      # Check if there are any staged changes
      if ! git diff --cached --quiet >/dev/null 2>&1; then
        # Get the diff of staged changes
        DIFF=$(git diff --cached)
        CHANGED_FILES="$(git diff --cached --name-only | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
      else
        echo "❌ No staged changes found."
        echo "   Please stage your changes first with: git add <files>"
        exit 1
      fi

      printf "\033[36m🤖 Generating commit message...\033[0m\n"
      printf "\033[90mUsing model: $MODEL\033[0m\n"

      SYSTEM_MESSAGE="You are an expert at writing Conventional Commit messages. Follow these rules strictly:

      FORMAT: <type>(<scope>): <subject>
      \n<BLANK LINE>
      \n<body>
      \n<BLANK LINE>
      \n<footer>

      TYPES:
      - feat:     New feature
      - fix:      Bug fix
      - docs:     Documentation changes
      - style:    Formatting, missing semicolons, etc (no code change)
      - refactor: Code refactoring (no behavior change)
      - perf:     Performance improvements
      - test:     Adding or updating tests
      - chore:    Build process, tooling, or auxiliary changes

      RULES:
      - Use imperative mood: \"fix bug\" not \"fixed bug\"
      - Subject line must be 50 characters or less
      - Body should explain why the changes were made and what changed
      - Body should wrap at 72 characters
      - Breaking changes must start with BREAKING CHANGE: in footer

      The following files have changed: ''${CHANGED_FILES}.

      CRITICAL INSTRUCTIONS:
      - Generate ONLY ONE commit message that encapsulates ALL changes
      - Return ONLY the commit message and description, nothing else
      - No explanations, no apologies, no additional text
      - Format must be: subject line + blank line + body
      - Ensure there is exactly one blank line between subject and body

      Analyze the git diff and generate a proper Conventional Commit message."

      # Remove extra spaces and newlines (but preserve intentional line breaks for the format)
      SYSTEM_MESSAGE=$(echo "$SYSTEM_MESSAGE" | sed 's/      //g' | sed 's/^ *//;s/ *$//')

      JSON_DATA=$(jq -n \
        --arg model "$OPENROUTER_MODEL" \
        --arg system_message "$SYSTEM_MESSAGE" \
        --arg user_content "$DIFF" \
        --arg temperature "$OPENROUTER_TEMPERATURE" \
        '{
          model: $model,
          messages: [
            {role: "system", content: $system_message},
            {role: "user", content: $user_content}
          ],
          temperature: ($temperature | tonumber)
        }')

      RESPONSE=$(curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $API_KEY" \
          -d "$JSON_DATA")

      rm -f "$JSON_FILE"

      if [[ $CURL_EXIT_CODE -ne 0 ]]; then
        printf "\033[31m❌ API request failed with curl exit code: $CURL_EXIT_CODE\033[0m\n"
        echo "Response: $RESPONSE"
        exit 1
      fi

      if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
        ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.error.message // .error' 2>/dev/null)
        printf "\033[31m❌ OpenRouter API error: $ERROR_MESSAGE\033[0m\n"
        echo "Full response: $RESPONSE"
        exit 1
      fi

      MESSAGE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty' | sed 's/^ *//;s/ *$//')
      if [[ -z "$MESSAGE" ]]; then
        printf "\033[31m❌ Failed to generate commit message\033[0m\n"
        echo "Response: $RESPONSE"
        exit 1
      fi

      # Clean up the message (remove markdown code blocks if present)
      MESSAGE=$(echo "$MESSAGE" | sed 's/^```.*//' | sed 's/^```$//' | sed '/^$/d')

      # printf "\033[32m✅ Generated commit message:\033[0m\n"
      # echo "---"
      # echo "$MESSAGE"
      # echo "---"

      # Use git's built-in editor with the AI message pre-filled
      git commit -e -m "$MESSAGE"
    '';

in { home.packages = [ lazycommit ]; }
