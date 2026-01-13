/**
 * Input validation utilities
 */

import { ThingsValidationError } from './errors.js';

// Validate and sanitize AppleScript arguments
export function validateAppleScriptArg(arg: string, fieldName: string): string {
  // Empty strings are valid for optional arguments - pass through as-is
  if (arg === '' || arg === undefined || arg === null) {
    return '';
  }

  // Notes/URLs can be longer, only restrict title-like fields
  const maxLength = fieldName.includes('notes') ? 10000 : 10000;
  if (arg.length > maxLength) {
    throw new ThingsValidationError(`${fieldName} is too long (max ${maxLength} characters)`);
  }

  // Block only characters that could cause shell/AppleScript injection
  // Single quotes are handled by the caller (replaced with '\"'\"')
  // Block: backticks, $(), null bytes, and other shell metacharacters
  const dangerousPattern = /[`$\x00]/;

  if (dangerousPattern.test(arg)) {
    throw new ThingsValidationError(
      `${fieldName} contains invalid characters (backticks, $, or null bytes not allowed)`,
      fieldName
    );
  }

  return arg;
}

// Validate Things ID format
export function validateThingsId(id: string): string {
  // Things IDs are alphanumeric strings of 20-24 characters
  const idPattern = /^[A-Za-z0-9]{20,24}$/;
  
  if (!idPattern.test(id)) {
    throw new ThingsValidationError(
      'Invalid Things ID format. Expected: alphanumeric string like "aBc123dEf456gHi789JkL" (20-24 characters). NOT the project name!',
      'id'
    );
  }
  
  return id;
}

// Sanitize string for URL encoding
export function sanitizeForUrl(value: string): string {
  // Remove any control characters except common whitespace (tab, newline, carriage return)
  // eslint-disable-next-line no-control-regex
  return value.replace(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/g, '');
}