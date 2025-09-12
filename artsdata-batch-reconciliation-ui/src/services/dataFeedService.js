/**
 * Service for fetching data feed results from Artsdata Reconciliation API
 */

const DEFAULT_API_BASE_URL = 'https://staging.recon.artsdata.ca/extend';

/**
 * Fetch dynamic data based on type, graph URL, page and limit using the recon extension API
 * @param {string} type - The entity type (Event, Person, Organization, Place)
 * @param {string} graphUrl - The direct graph URL
 * @param {number} page - Page number (default: 1)
 * @param {number} limit - Number of items per page (default: 20)
 * @param {Object} config - Configuration object with endpoints
 * @returns {Promise<Array>} - Array of transformed data
 */
export async function fetchDynamicData(type, graphUrl, page = 1, limit = 20, config = {}, signal = null) {
  // Use config endpoint or fall back to default
  const apiBaseUrl = config.reconciliationEndpoint ? `${config.reconciliationEndpoint}/extend` : DEFAULT_API_BASE_URL;
  
  try {
    // Check if graphUrl is empty or undefined
    if (!graphUrl || graphUrl.trim() === '') {
      return [];
    }
    
    const encodedGraphUrl = encodeURIComponent(graphUrl);
    const apiUrl = `${apiBaseUrl}/${encodedGraphUrl}/${type}?page=${page}&limit=${limit}`;
    
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      },
      signal: signal // Add abort signal support
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    
    // Handle empty API results
    if (!data || (Array.isArray(data) && data.length === 0)) {
      return [];
    }
    
    return transformApiResults(data, page, limit, type);
  } catch (error) {
    // Don't log aborted requests as errors
    if (error.name === 'AbortError') {
      console.log('Request aborted:', error);
      throw error;
    }
    console.error('Error fetching dynamic data:', error);
    throw error;
  }
}

/**
 * Extract ISNI ID from ISNI URI
 * @param {string} isni_uri - ISNI URI from API
 * @returns {string} - ISNI ID or empty string
 */
function extractIsniId(isni_uri) {
  if (!isni_uri || typeof isni_uri !== 'string') return '';
  
  // Extract ISNI ID from URI (typically the last part after /)
  // Example: "https://isni.org/isni/0000000123456789" -> "0000000123456789"
  const isniMatch = isni_uri.match(/(\d{16})$/);
  return isniMatch ? isniMatch[1] : isni_uri;
}

/**
 * Extract Wikidata ID from Wikidata URI or various other locations
 * @param {string} wikidata_uri - Wikidata URI from API
 * @returns {string} - Wikidata ID or empty string
 */
export function extractWikidataId(wikidata_uri) {
  // Check direct wikidata_uri field first (new format)
  if (wikidata_uri && typeof wikidata_uri === 'string') {
    // Extract just the Q-ID from the full URL
    const match = wikidata_uri.match(/Q\d+/);
    return match ? match[0] : wikidata_uri;
  }
  
  return '';
}

/**
 * Extract first type from comma-separated types string
 * @param {string} typeString - Type string from API (may be comma-separated)
 * @returns {string} - First type or empty string
 */
function extractFirstType(typeString) {
  if (!typeString || typeof typeString !== 'string') return '';
  
  // Split by comma and get the first type, trim whitespace
  const types = typeString.split(',');
  return types[0].trim();
}

/**
 * Transform API results into a normalized format for the UI
 * @param {Array} apiResults - Raw API results (array of items)
 * @param {number} page - Page number
 * @param {number} limit - Items per page
 * @param {string} selectedType - User-selected type from dropdown
 * @returns {Array} - Normalized data array
 */
function transformApiResults(apiResults, page = 1, limit = 20, selectedType = 'Event') {
  if (!Array.isArray(apiResults)) {
    return [];
  }

  // Convert user-selected type to schema.org format (fallback only)
  const schemaType = `http://schema.org/${selectedType}`;

  return apiResults.map((item, index) => {
    // Check if entity already has artsdata_uri (new format)
    const hasArtsdataUri = item.artsdata_uri && item.artsdata_uri.trim() !== '';
    
    // Extract Artsdata ID if artsdata_uri exists
    let artsdataId = null;
    let artsdataName = null;
    if (hasArtsdataUri) {
      artsdataId = item.artsdata_uri.split('/').pop();
      artsdataName = item.name || ''; // Use the entity's own name
    }

    return {
      id: ((page - 1) * limit) + index + 1,
      name: item.name || '',
      uri: item.uri || '',
      url: item.url || '', // Direct from API
      externalId: item.uri ? item.uri.split('/').pop() : '',
      type: extractFirstType(item.type) || schemaType, // Use first API-provided type, fallback to generated schema type
      description: item.description || '',
      location: item.location || '', // New field from API
      startDate: item.start_date || item.startDate || '', // Map start_date to startDate
      endDate: item.end_date || item.endDate || '', // Map end_date to endDate
      isni: item.isni_uri || '', // Preserve original ISNI URI for API calls
      wikidata: item.wikidata_uri || '', // Preserve original Wikidata URI for API calls
      // Store extracted IDs for display purposes  
      isniId: extractIsniId(item.isni_uri), // Extract ISNI ID for display
      wikidataId: extractWikidataId(item.wikidata_uri), // Extract Wikidata ID for display
      postalCode: item.postal_code || '', // Extract postal code from new postal_code field
      addressLocality: item.address_locality || '', // Extract address locality from address_locality field
      addressRegion: item.address_region || '', // Extract address region from address_region field
      // Event-specific properties
      locationName: item.location_name || '', // Map location_name to locationName for Events
      locationArtsdataUri: item.location_artsdata_uri || '', // Map location_artsdata_uri
      eventStatus: item.event_status || '', // Map event_status
      eventAttendanceMode: item.event_attendance_mode || '', // Map event_attendance_mode
      offerUrl: item.offer_url || '', // Map offer_url
      // Check if entity is flagged for review
      isFlaggedForReview: item.is_flagged_for_review === true,
      // Mark status based on flags and reconciliation
      status: hasArtsdataUri ? 'reconciled' : (item.is_flagged_for_review === true ? 'flagged-complete' : 'needs-judgment'),
      linkedTo: artsdataId,
      linkedToName: artsdataName,
      artsdataUri: hasArtsdataUri ? item.artsdata_uri : '', // Preserve full artsdata_uri from data feed
      matches: [], // Initialize empty matches array
      isPreReconciled: hasArtsdataUri // Flag to identify pre-reconciled entities
    };
  });
}

/**
 * Get available entity types (limited to API supported types)
 * @returns {Array} - Array of available types
 */
export function getAvailableTypes() {
  return [
    { value: 'Event', label: 'Event' },
    { value: 'Person', label: 'Person' },
    { value: 'Organization', label: 'Organization' },
    { value: 'Place', label: 'Place' }
  ];
}