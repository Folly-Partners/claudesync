# GTD Email Formatting & Action Rules

## Problem

Emails sent via Zapier Gmail MCP render as one big paragraph with no line breaks. The screenshot shows a cold outreach email that's completely unreadable.

**Root cause**: Zapier Gmail requires `body_type: "html"` and HTML tags (`<br>` or `<p>`) for formatting. Plain text newlines are ignored.

---

## GTD Action Categories

### 1. Delegate Emails (D command)

**Trigger**: `D [person] [optional context]`
- Example: `D Brianna please handle by Friday`
- Example: `D John can you review this contract`

**Email structure**:
```html
body_type: "html"

<p>Hi [Person],</p>

<p>Could you help with this? [task description]</p>

<p>[Research findings if relevant - formatted as <ul><li> bullets]</p>

<p>[Modifier context if provided, e.g., "Ideally by Friday"]</p>

<p>Thanks,<br>
Andrew</p>
```

**Rules**:
- Keep subject concise: "Task: [shortened title]"
- Include research findings if the task was researched
- Add deadline/urgency from modifier naturally
- **No Tiny signature** - these are internal/colleague emails

---

### 2. Introduction Emails (Intro command)

**Trigger**: "Intro X to Y", "Connect X with Y" tasks

**Email structure**:
```html
body_type: "html"

<p>Hi [Person A],</p>

<p>Wanted to intro you to [Person B]. [Person B] is the [role] of [Company] and based in [Location]. I think you guys would hit it off.</p>

<p>[Person B], meet my friend [Person A]. [Person A] runs [Company] and [brief personal context]. You guys should grab a coffee.</p>

<p>I'll leave you to it :-)</p>

<p>-Andrew</p>
```

**Rules**:
- Subject: "Introduction: [Person A] <> [Person B]"
- CC both parties
- Keep casual/friendly tone
- Include location for context
- Search inbox for context on both people first
- Add personal touch ("my friend", "hit it off", etc.)

---

### 3. Cold Outreach / Acquisition Emails

**Trigger**: Tasks like "Email [business/person]", "Reach out to X", "Contact Y about Z"

**For acquisition/business interest:**
```html
body_type: "html"

<p>Hi [Name],</p>

<p>Not sure if you're familiar with me, but I own Tiny, a public holding company. We own about 30 businesses across a variety of industries and we're based in Victoria.</p>

<p>I was wondering if you'd ever consider selling [Company]. We're interested in the [industry/space] :-)</p>

<p>-Andrew</p>
```

**For casual coffee/meeting (when traveling):**
```html
body_type: "html"

<p>Hi [Name],</p>

<p>I'm Andrew Wilkinson - I run a holding company called Tiny that acquires and operates great businesses long-term. I'm in [Location] until [Date] and came across [Business]. [Specific compliment about what impressed you].</p>

<p>I'd love to buy you a coffee while I'm here and learn more about the business. Not sure if you've ever thought about what's next, but if you're ever open to exploring options, I'd be interested in talking.</p>

<p>No pressure either way - just thought it was worth reaching out while I'm on the island.</p>

<p>-Andrew<br>
___<br>
<a href="https://www.tiny.com">www.tiny.com</a></p>
```

**Rules**:
- Subject: Short, intriguing (e.g., "Coffee while I'm in [City]?", "[Company]?")
- Keep it brief - 2-3 paragraphs max
- Casual tone with smiley where appropriate :-)
- Direct ask, low pressure
- Include Tiny signature for external outreach

---

### 4. Follow-up Emails

**Trigger**: "Follow up with X", "Check in with Y", "Bump [person]"

**Email structure**:
```html
body_type: "html"

<p>Hi [Name],</p>

<p>Just wanted to follow up on [previous topic/meeting]. [Specific reference to last interaction]</p>

<p>[Any update or new context if relevant]</p>

<p>[Soft re-ask or next step]</p>

<p>-Andrew<br>
___<br>
<a href="https://www.tiny.com">www.tiny.com</a></p>
```

**Rules**:
- Search inbox first for last conversation
- Reference specific details from prior exchange
- Keep shorter than original outreach

---

### 5. Reply/Response Drafts

**Trigger**: "Reply to X", "Respond to [email about Y]"

**Email structure**: Varies based on context, but always:
```html
body_type: "html"

<p>[Opening acknowledgment]</p>

<p>[Main response content]</p>

<p>[Next steps or closing]</p>

<p>-Andrew<br>
___<br>
<a href="https://www.tiny.com">www.tiny.com</a></p>
```

**Rules**:
- Always search inbox for the thread first
- Match tone/formality of incoming email
- Keep response proportional to original

---

### 6. Research Sharing Emails

**Trigger**: After DD (Deep Dive), user wants to share findings

**Email structure**:
```html
body_type: "html"

<p>Hi [Name],</p>

<p>I looked into [topic] - here's what I found:</p>

<ul>
<li>[Finding 1 with specifics]</li>
<li>[Finding 2 with numbers/facts]</li>
<li>[Finding 3 with actionable insight]</li>
</ul>

<p>[Conclusion or recommendation]</p>

<p>Let me know if you want me to dig deeper on any of this.</p>

<p>-Andrew<br>
___<br>
<a href="https://www.tiny.com">www.tiny.com</a></p>
```

**Rules**:
- Use `<ul><li>` for bullet points
- Include sources inline if relevant
- Summarize, don't dump raw research

---

### 7. Meeting Request Emails

**Trigger**: "Schedule call with X", "Set up meeting with Y", "Book time with Z"

**Email structure**:
```html
body_type: "html"

<p>Hi [Name],</p>

<p>[Context for why meeting - 1 sentence]</p>

<p>Would you have 30 minutes in the next week or two to [specific purpose: chat, catch up, discuss X]?</p>

<p>Happy to work around your schedule.</p>

<p>-Andrew<br>
___<br>
<a href="https://www.tiny.com">www.tiny.com</a></p>
```

**Rules**:
- Keep short - just the ask
- Suggest timeframe but stay flexible
- Include specific purpose for the meeting
- Don't over-explain

---

## Non-Email Action Types

### 8. Company/Founder Research

**Trigger**: "Research [Company]", "DD on [Business]", "Look into [Founder]"

**Action**: Use Tavily for deep research, structure findings as:
```
Company: [Name]
Industry: [Sector]
Location: [HQ]
Founder(s): [Names + backgrounds]
Revenue: [If available]
Key facts:
- [Fact 1]
- [Fact 2]
- [Fact 3]
Why interesting: [Relevance to Tiny]
```

**Rules**:
- Always try to find: revenue, employee count, funding, founders
- Check for recent news/press
- Note any acquisition signals (founder age, no recent funding, etc.)

---

### 9. Contact Lookup

**Trigger**: "Find email for X", "Get contact for Y", "Look up Z's email"

**Action**:
1. Search inbox first (`mcp__zapier__gmail_find_email`)
2. If not found, use web search for "[Name] email" or "[Name] [Company] contact"
3. Check LinkedIn via BrowserBase if needed

**Return format**:
```
Found: [email@domain.com]
Source: [inbox/LinkedIn/website]
Confidence: [high/medium/low]
```

---

### 10. Calendar Tasks

**Trigger**: "Block time for X", "Schedule Y", "Add Z to calendar"

**Action**: Use `mcp__zapier__google_calendar_create_detailed_event`

**Rules**:
- Default duration: 30 min for calls, 60 min for meetings
- Include context in description
- Ask for time if not specified

---

### 11. Document Tasks

**Trigger**: "Create doc for X", "Find document about Y", "Draft proposal for Z"

**Action**:
- Find: `mcp__zapier__google_docs_find_a_document` or `mcp__zapier__google_drive_find_a_file`
- Create: `mcp__zapier__google_docs_create_document_from_text`

**Rules**:
- Search before creating (might already exist)
- Use descriptive titles
- Include date in title for time-sensitive docs

---

### 12. Social Media / Screenshots

**Trigger**: "Check X's Twitter", "Screenshot Y's LinkedIn", "See what Z posted"

**Action**: Use BrowserBase to navigate and screenshot

**Rules**:
- Take screenshot for visual verification
- Extract key text/posts
- Note follower counts, recent activity

---

### 13. Quick Analysis

**Trigger**: "Calculate X", "Compare Y vs Z", "Analyze options for W"

**Action**: Claude thinking (no external tools needed)

**Return format**:
```
Analysis: [Topic]

Option A: [Details]
- Pro: [X]
- Con: [Y]

Option B: [Details]
- Pro: [X]
- Con: [Y]

Recommendation: [Pick with reasoning]
```

---

### 14. Reference/Note Tasks

**Trigger**: "Save for reference", "Add to notes", "Document this decision"

**Action**:
- If task relates to a Things project → Add to project notes
- If standalone reference → Update task notes in Things, then complete
- If needs persistent storage → Create Google Doc

**Rules**:
- Don't create docs for everything - Things notes are often sufficient
- Complete the task after saving (it's done)

---

### 15. Buy/Order/Purchase Tasks

**Trigger**: "Buy X", "Order Y", "Purchase Z tickets"

**Action**:
1. Search for product/tickets online
2. Find best source (Amazon, official site, etc.)
3. Provide link + price + recommendation

**Return format**:
```
Product: [Name]
Best option: [Link]
Price: $X
Notes: [Any relevant info - shipping, availability, etc.]
```

**Rules**:
- For tickets: Check official source first, then resellers
- Include price comparison if relevant
- Flag if out of stock or unavailable

---

### 16. Book/Schedule Appointments

**Trigger**: "Book X appointment", "Schedule Y scan", "Book fitness class"

**Action**:
1. Research the service provider
2. Find booking page/phone number
3. If online booking available, provide direct link
4. If phone only, provide number and suggested script

**Return format**:
```
Provider: [Name]
Booking: [Link] or [Phone number]
Hours: [If relevant]
Next steps: [What to do]
```

**Rules**:
- Prefer online booking links over phone
- Include wait times if known
- Note any prep requirements (fasting, etc.)

---

### 17. Sign Up/Register Tasks

**Trigger**: "Sign up for X", "Register for Y conference"

**Action**:
1. Find official registration page
2. Check dates, pricing, availability
3. Provide registration link

**Return format**:
```
Event/Service: [Name]
Dates: [If applicable]
Cost: $X
Register: [Link]
Deadline: [If applicable]
```

---

### 18. Watch/Read/Review Tasks

**Trigger**: "Watch X video", "Read Y article", "Review Z website"

**Action**:
1. Use Firecrawl to scrape the content
2. Summarize key points
3. Note why it was likely saved

**Return format**:
```
Title: [Name]
Type: [Video/Article/Book/Website]
Summary:
- [Key point 1]
- [Key point 2]
- [Key point 3]
Why saved: [Inferred relevance]
Link: [URL]
```

**Rules**:
- For books: Include where to buy (Amazon, etc.)
- For videos: Include duration
- Mark as "watched/read" summary, not full content

---

### 19. Send [Thing] to [Person] Tasks

**Trigger**: "Send X to Y", "Share Z with W"

**Action**:
1. Find/locate the thing (link, file, info)
2. Draft email with the content/link
3. Use HTML formatting

**Email structure**:
```html
body_type: "html"

<p>Hi [Name],</p>

<p>Wanted to share this with you - [context for why]:</p>

<p>[Link or content]</p>

<p>-Andrew</p>
```

---

### 20. Ask [Person] About/To Tasks

**Trigger**: "Ask X about Y", "Ask X to do Z"

**Action**: This is really an email task. Draft email asking the question.

**Email structure**:
```html
body_type: "html"

<p>Hi [Name],</p>

<p>[Question or request in natural language]</p>

<p>Thanks,<br>
Andrew</p>
```

**Rules**:
- Keep short and direct
- One question/request per email ideally
- No Tiny signature for internal asks

---

### 21. Find/Search Tasks

**Trigger**: "Find X", "Look for Y", "Search for Z"

**Action**:
1. Search inbox first if it's an email/document
2. Use Tavily for web searches
3. Use Firecrawl for specific URLs

**Return format**:
```
Found: [Result]
Source: [Where found]
Link: [If applicable]
```

---

### 22. Cancel/Unsubscribe Tasks

**Trigger**: "Cancel X subscription", "Unsubscribe from Y"

**Action**:
1. Search inbox for account emails to find service
2. Find cancellation page/process
3. Provide instructions or link

**Return format**:
```
Service: [Name]
Cancel here: [Link to cancellation page]
Process: [Steps if not straightforward]
Note: [Any retention offers, refund info, etc.]
```

**Rules**:
- Look for "cancel subscription" or "manage account" pages
- Note if phone call required
- Flag any early termination fees

---

### 23. Invite [Person] to [Event] Tasks

**Trigger**: "Invite X to Y", "Add X to event"

**Action**: Draft invitation email

**Email structure**:
```html
body_type: "html"

<p>Hi [Name],</p>

<p>Would love to have you at [Event] - [brief description].</p>

<p>Details:<br>
Date: [Date]<br>
Location: [Place]<br>
[Any other relevant info]</p>

<p>Let me know if you can make it!</p>

<p>-Andrew</p>
```

---

### 24. Create/Draft Content Tasks

**Trigger**: "Create X playlist", "Draft Y tweet", "Write Z post"

**Action**:
1. Research/gather relevant info
2. Create the content
3. Present for review

**For tweets/social posts**:
```
Draft tweet:
"[Content under 280 chars]"

Alt versions:
1. [Variation 1]
2. [Variation 2]
```

**Rules**:
- For playlists: Suggest songs, provide Spotify/Apple Music links
- For tweets: Keep punchy, offer variations
- For blog posts: Outline first, then draft

---

### 25. Travel/Booking Tasks

**Trigger**: "Book flight to X", "Find hotel in Y", "Reserve restaurant Z"

**Action**:
1. Search for options (use Tavily for travel)
2. Compare prices/ratings
3. Provide top recommendations

**Return format**:
```
Destination: [Place]
Dates: [If specified]

Option 1: [Name]
- Price: $X
- Rating: X/5
- Link: [Booking link]

Option 2: [Name]
- Price: $Y
- Rating: Y/5
- Link: [Booking link]

Recommendation: [Which one and why]
```

**Rules**:
- For flights: Check Google Flights, airline direct
- For hotels: Check hotel direct, Expedia, Booking.com
- For restaurants: Check Resy, OpenTable, direct
- Note cancellation policies

---

## Critical Zapier Gmail Rules

### Always Include

```javascript
{
  body_type: "html",  // REQUIRED for paragraph breaks
  body: "<p>First paragraph</p><p>Second paragraph</p>",
  // ... other fields
}
```

### HTML Formatting Reference

| Need | Use |
|------|-----|
| Paragraph break | `</p><p>` or `<p>...</p>` |
| Line break within paragraph | `<br>` |
| Bullet list | `<ul><li>Item</li></ul>` |
| Bold | `<strong>text</strong>` |
| Link | `<a href="url">text</a>` |
| Signature line break | `Name<br>Title` |

### Common Mistakes to Avoid

1. **Plain newlines** - `\n` does nothing, use `<br>` or `<p>`
2. **Missing body_type** - Defaults to plain text, breaks formatting
3. **Wall of text** - Always break into 3-5 short paragraphs max
4. **Over-formatting** - Keep HTML minimal, no inline styles

---

## Implementation

**File to modify**: `commands/gtd.md`

### Changes:

1. **Add "Email Formatting Rules" section** with:
   - HTML requirements (`body_type: "html"`)
   - Formatting reference table
   - Common mistakes to avoid

2. **Add "Email Templates by Type" section** (7 types):
   - Delegate (D command) - internal, simple signature
   - Introduction - casual, friendly tone, `-Andrew`
   - Cold outreach / Acquisition - two variants (direct ask vs coffee meeting)
   - Follow-up - reference prior conversation
   - Reply/Response - match incoming tone
   - Research sharing - bullet format
   - Meeting request - short and direct

3. **Add "Non-Email Action Types" section** (7 types):
   - Company/founder research - structured DD format
   - Contact lookup - inbox → web search → LinkedIn
   - Calendar tasks - Google Calendar via Zapier
   - Document tasks - Google Docs/Drive via Zapier
   - Social media/screenshots - BrowserBase
   - Quick analysis - Claude thinking
   - Reference/note tasks - Things notes vs Google Docs

4. **Update task categorization table** to include all 14 action types

5. **Signature formats**:
   - External emails: `-Andrew` then `___` then `www.tiny.com`
   - Internal/intro emails: `-Andrew` or `Thanks, Andrew`
