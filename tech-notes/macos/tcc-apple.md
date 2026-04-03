# Transparency, Consent, and Control (TCC)

Issues with LaunchAgents on macOS.

## ~/Documents Access

Problems with ~/Documents:
- macOS protects ~/Documents with TCC (Transparency, Consent, and Control)
- LaunchAgent background jobs may not have permission to access ~/Documents
- You might get "operation not permitted" errors
- Privacy prompts can't be shown for background processes, causing silent failures
- Both Crontab and LaunchAgents are affected