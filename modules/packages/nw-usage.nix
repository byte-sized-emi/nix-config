{
  stacks.nw-usage.packages = { pkgs, ... }: {
    nw-usage = pkgs.writeShellApplication {
      name = "nw-usage";
      runtimeInputs = with pkgs; [
        curl
        jq
      ];
      text = ''
        # Neuralwatt API usage - shows today's request count, energy consumption and credits
        #
        # Usage:
        #   nw-usage                       # Human-readable output (always fresh)
        #   nw-usage --tmux                # Compact for tmux/statusline (cached 5min)
        #   nw-usage --tmux --color '1;32' # With ANSI color (bright green)
        #   nw-usage --json                # Raw JSON (always fresh)

        CACHE_FILE="/tmp/nw-usage-cache.json"
        CACHE_MAX_AGE=60
        API_KEY_FILE="''${NEURALWATT_API_KEY_FILE:-$HOME/.config/neuralwatt/api_key}"

        FORMAT="human"
        USE_CACHE=false
        COLOR=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --tmux) FORMAT="tmux"; USE_CACHE=true; shift ;;
            --json) FORMAT="json"; shift ;;
            --color)
              COLOR="''${2:-}"
              shift 2
              ;;
            --help|-h)
              echo "Usage: nw-usage [--tmux|--json] [--color CODE]"
              echo "  --tmux        Compact output for statusline (cached)"
              echo "  --json        Raw JSON from API"
              echo "  --color CODE  ANSI color code (e.g., '1;32' for bright green)"
              exit 0
              ;;
            *) echo "Unknown option: $1"; exit 1 ;;
          esac
        done

        use_cache=false
        if [[ "$USE_CACHE" == "true" ]] && [[ -f "$CACHE_FILE" ]]; then
          if [[ "$(uname)" == "Darwin" ]]; then
            cache_mtime=$(stat -f %m "$CACHE_FILE")
          else
            cache_mtime=$(stat -c %Y "$CACHE_FILE")
          fi
          cache_age=$(($(date +%s) - cache_mtime))
          if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
            use_cache=true
          fi
        fi

        if [[ "$use_cache" == "true" ]]; then
          data=$(cat "$CACHE_FILE")
        else
          if [[ -n "''${NEURALWATT_API_KEY:-}" ]]; then
            api_key="$NEURALWATT_API_KEY"
          elif [[ -f "$API_KEY_FILE" ]]; then
            api_key=$(cat "$API_KEY_FILE")
          else
            echo "Error: No API key found. Set NEURALWATT_API_KEY or create $API_KEY_FILE" >&2
            exit 1
          fi

          energy=$(curl -s -H "Authorization: Bearer $api_key" \
            https://api.neuralwatt.com/v1/usage/energy 2>/dev/null)
          quota=$(curl -s -H "Authorization: Bearer $api_key" \
            https://api.neuralwatt.com/v1/quota 2>/dev/null)
          quota=$(echo "''${quota:-null}" | jq -c . 2>/dev/null || echo null)

          if [[ -z "$energy" ]] || ! echo "$energy" | jq -e '.daily[0]' >/dev/null 2>&1; then
            echo "Error: Failed to fetch usage data" >&2
            exit 1
          fi

          data=$(jq -c --argjson q "$quota" '. * ($q // {})' <<< "$energy")
          echo "$data" > "$CACHE_FILE"
        fi

        case "$FORMAT" in
          json)
            echo "$data"
            ;;
          tmux)
            output=$(jq -r '. as $r | .daily[0] | "↗\(.requests) ⚡\(.energy_kwh * 1000 | round)Wh $\($r.usage.current_month.cost_usd)/$\($r.balance.credits_remaining_usd)"' <<< "$data")
            if [[ -n "$COLOR" ]]; then
              printf "\033[%sm%s\033[0m\n" "$COLOR" "$output"
            else
              echo "$output"
            fi
            ;;
          human)
            jq -r '. as $r | .daily[0] | "Neuralwatt Usage for \(.date)\n  Requests: \(.requests)\n  Energy: \(.energy_kwh * 1000 | round)Wh (\(.energy_joules | round)J)\n  Month cost: $\($r.usage.current_month.cost_usd)\n  Credits remaining: $\($r.balance.credits_remaining_usd)"' <<< "$data"
            ;;
        esac
      '';

      meta = with pkgs.lib; {
        homepage = "https://github.com/neuralwatt/neuralwatt-tools";
        description = "CLI for checking Neuralwatt API usage and energy consumption";
        mainProgram = "nw-usage";
        license = licenses.asl20;
      };
    };
  };
}
