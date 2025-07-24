/**
 * URL validation utilities for data feed URLs
 */

/**
 * Validates if a string is a valid URL
 * @param {string} url - The URL string to validate
 * @returns {boolean} - True if valid URL, false otherwise
 */
export function isValidUrl(url) {
  if (!url || typeof url !== 'string' || url.trim() === '') {
    return false;
  }

  try {
    const urlObject = new URL(url.trim());
    // Only allow http and https protocols
    return urlObject.protocol === 'http:' || urlObject.protocol === 'https:';
  } catch (error) {
    return false;
  }
}

/**
 * Validates if a URL looks like a valid graph/data feed URL
 * @param {string} url - The URL string to validate
 * @returns {object} - Validation result with isValid boolean and message
 */
export function validateGraphUrl(url) {
  if (!url || typeof url !== 'string' || url.trim() === '') {
    return {
      isValid: false,
      message: 'Please enter a data feed URL'
    };
  }

  const trimmedUrl = url.trim();

  // Check if it's a valid URL structure
  if (!isValidUrl(trimmedUrl)) {
    return {
      isValid: false,
      message: 'Please enter a valid URL (must start with http:// or https://)'
    };
  }

  try {
    const urlObject = new URL(trimmedUrl);
    
    // Check if URL has a valid domain
    if (!urlObject.hostname || urlObject.hostname.length < 3) {
      return {
        isValid: false,
        message: 'Please enter a URL with a valid domain'
      };
    }

    // Additional validation for common graph URL patterns
    // This is a soft validation - we'll allow most URLs but warn about potential issues
    const hostname = urlObject.hostname.toLowerCase();
    const pathname = urlObject.pathname.toLowerCase();
    
    // Check for some common graph URL patterns
    const looksLikeGraphUrl = (
      hostname.includes('kg.') ||
      hostname.includes('artsdata') ||
      pathname.includes('graph') ||
      pathname.includes('data') ||
      pathname.includes('sparql') ||
      pathname.includes('rdf') ||
      pathname.includes('ttl') ||
      // Allow any URL that looks reasonable
      urlObject.pathname.length > 1
    );

    if (!looksLikeGraphUrl) {
      return {
        isValid: true, // Still valid, just a warning
        message: 'URL is valid but may not be a data feed. Please verify the URL is correct.',
        isWarning: true
      };
    }

    return {
      isValid: true,
      message: 'Valid data feed URL'
    };

  } catch (error) {
    return {
      isValid: false,
      message: 'Invalid URL format'
    };
  }
}

/**
 * Debounce function to limit validation frequency
 * @param {Function} func - Function to debounce
 * @param {number} delay - Delay in milliseconds
 * @returns {Function} - Debounced function
 */
export function debounce(func, delay) {
  let timeoutId;
  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func.apply(this, args), delay);
  };
}