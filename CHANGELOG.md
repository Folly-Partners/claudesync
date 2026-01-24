# Changelog

All notable changes to ClaudeSync will be documented in this file.

## [2.4.0] - 2026-01-24

### Added
- **Context7 MCP server** - Framework documentation lookup via context7 for up-to-date library docs and code examples

## [2.2.0] - 2026-01-21

### Fixed
- **/texts batch size**: Fixed bug where only 3 conversations were processed instead of 10. Root cause: `search_messages` returns individual messages, not conversations. Now fetches 50 messages per type and dedupes to 10 unique chats.
- **/texts message display**: Fixed bug where AskUserQuestion showed "Response for X?" without showing the actual message content. Added CRITICAL instruction block with explicit format requirements and WRONG vs CORRECT examples.

### Changed
- **/texts batch size**: Reduced from 20 to 10 conversations per batch based on cognitive load research (4-8 items optimal)
- **/texts options**: Reduced from 6 options to 4 (Quick, Full, Archive, Skip) to comply with AskUserQuestion limits
- **/texts drafts**: Simplified from 4 draft options to 2 (Quick and Full) for faster decisions
- **/texts fetch**: Removed `sender: "others"` filter to include chats where Andrew sent last message
- **/texts fetch**: Increased fetch limit from 20 to 50 messages to ensure enough unique conversations after deduplication

### Added
- **/texts checkpoints**: Added checkpoint every 5 chats with options to Continue, Execute now, or Stop
- **/texts validation**: Added empty inbox detection with "INBOX CLEAR" message
- **/texts validation**: Added handling for empty `list_messages` response
- **/texts error handling**: Added explicit Haiku timeout fallback drafts

## [2.0.1] - 2025-01-21

### Fixed
- Fixed invalid hook type `PreStop` causing plugin load failure. Changed to valid `Stop` event name.

## [2.0.0] - 2025-01-20

### Added
- Updike social content engine integration
- `/email` command for Gmail processing
- `/texts` command for Beeper message processing
- SuperThings intelligent task management
- Enhanced planning with parallel research agents

### Changed
- Major refactoring of plugin architecture
- Improved MCP server configuration
