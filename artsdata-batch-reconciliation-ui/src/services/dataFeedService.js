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

  // Convert user-selected type to schema.org format
  const schemaType = `http://schema.org/${selectedType}`;

  return apiResults.map((item, index) => {
    return {
      id: ((page - 1) * limit) + index + 1,
      name: item.name || '',
      uri: item.uri || '',
      url: item.url || '', // May not be provided
      externalId: item.uri ? item.uri.split('/').pop() : '',
      type: item.type || schemaType, // Use selected type if API type is missing
      description: item.description || '',
      location: item.location || '', // New field from API
      startDate: item.startDate || '', // New field from API
      endDate: item.endDate || '', // New field from API
      isni: '', // Not provided by API
      wikidata: '', // Not provided by API
      status: 'needs-judgment', // Default status
      matches: [] // Initialize empty matches array
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