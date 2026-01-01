# Improve EU Geo-blocking Page Messaging

## Summary
Update the `/unavailable` page to explicitly mention the EU and explain why the service isn't available there.

---

## Current State

The page currently shows:
- **Heading:** "Not Available in Your Region"
- **Text:** "Deep Personality isn't available in your region yet. We're working on making it accessible to more countries soon."

This is generic and doesn't explain:
1. That the user is in the EU/EEA specifically
2. WHY the service isn't available (GDPR/privacy compliance)

---

## Proposed Changes

**File:** `/Users/andrewwilkinson/Deep-Personality/app/unavailable/page.tsx`

### Update Heading (line 53)
```tsx
// FROM:
<h1>Not Available in Your Region</h1>

// TO:
<h1>Not Available in the EU</h1>
```

### Update Explanation (lines 57-59)
```tsx
// FROM:
<p>Deep Personality isn't available in your region yet. We're working on making it accessible to more countries soon.</p>

// TO:
<p>Deep Personality isn't currently available to users in the European Union due to GDPR compliance requirements. We're working hard to meet EU privacy standards and hope to launch there soon.</p>
```

### Update Footer Note (line 117)
```tsx
// FROM:
<p>We take privacy seriously and are working to meet regional requirements.</p>

// TO:
<p>We take privacy seriously and are working to meet GDPR requirements.</p>
```

---

## Result

EU users will see a clear message that:
1. ✅ Explicitly mentions the EU (not vague "your region")
2. ✅ Explains why (GDPR compliance)
3. ✅ Shows it's temporary (working to launch there)
4. ✅ Retains the waitlist signup for notifications
