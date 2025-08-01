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
      console.log('Empty graph URL provided, returning empty array');
      return [];
    }
    
    const encodedGraphUrl = encodeURIComponent(graphUrl);
    const apiUrl = `${apiBaseUrl}/${encodedGraphUrl}/${type}?page=${page}&limit=${limit}`;
    
    console.log('Fetching from API:', apiUrl);
    
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
    console.log('API Response Data:', data);
    console.log('Selected Type:', type);
    
    // Handle empty API results
    if (!data || (Array.isArray(data) && data.length === 0)) {
      console.log('Empty results from API');
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
function extractWikidataId(wikidata_uri) {
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
      startDate: item.startDate || '', // New field from API
      endDate: item.endDate || '', // New field from API
      isni: extractIsniId(item.isni_uri), // Extract ISNI from new isni_uri field
      wikidata: extractWikidataId(item.wikidata_uri), // Extract Wikidata from new wikidata_uri field
      // Mark as reconciled if already has artsdata_uri
      status: hasArtsdataUri ? 'reconciled' : 'needs-judgment',
      linkedTo: artsdataId,
      linkedToName: artsdataName,
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