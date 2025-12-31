# Plan: Fix Notable Moments Quality

## Problem
Notable moments are capturing nonsensical quotes including:
- TV shows, movies, documentaries playing in background
- Podcasts/YouTube videos
- Random audio fragments without context
- Quotes from media content, not personal conversations

## Solution
Update the NOTABLE_MOMENTS prompt section in `summarizer.py` to be more specific about quality criteria.

## File to Modify
`/Users/andrewwilkinson/Journal/journal/summarizer.py` - lines 187-188

## Current Prompt (line 187-188)
```
4. **NOTABLE_MOMENTS**: Extract the best quotes or moments that were funny, insightful, or memorable (up to 10 max). Clean up garbled audio while preserving original meaning. Format as blockquotes with brief context. Use your judgment on how many to include - could be 0 on a quiet day or 10 on an eventful one. Only include genuinely notable moments.
```

## New Prompt
```
4. **NOTABLE_MOMENTS**: Extract memorable quotes or moments from ACTUAL CONVERSATIONS I participated in (up to 10 max).

INCLUDE:
- Funny things said by me or people I was talking to
- Insightful comments from real conversations
- Memorable exchanges with family, friends, or colleagues
- Kids saying something cute or surprising

EXCLUDE:
- Quotes from TV shows, movies, or documentaries playing in background
- Podcast or YouTube audio
- Song lyrics or media content
- Random audio fragments that lack context
- Anything that sounds like scripted/produced content rather than natural conversation

If a quote sounds like it's from media content (dramatic dialogue, professional narration, influencer-style speech), skip it. Only include organic, personal conversation moments. Quality over quantity - 0 moments is fine if nothing genuinely notable happened in real conversations.

Format as blockquotes with brief context explaining who said it and the situation.
```

## Implementation
Single edit to replace the NOTABLE_MOMENTS instruction in the prompt string.
