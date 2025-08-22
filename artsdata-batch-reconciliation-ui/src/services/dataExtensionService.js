/**
 * Data Extension Service for Artsdata APIs
 * Handles data extension operations to enrich match results with additional properties
 */

// Default endpoint for development
const DEFAULT_RECONCILIATION_BASE_URL = 'https://staging.recon.artsdata.ca';

// Cache for available properties by entity type
const propertiesCache = new Map();

// Cache for target properties by entity type (filtered ISNI, Wikidata, URL properties)
const targetPropertiesCache = new Map();

/**
 * Get available properties for a given entity type using the extend/propose API
 * Uses caching to avoid multiple API calls for the same entity type
 * @param {string} entityType - Entity type (Place, Organization, Event, Person)
 * @param {Object} config - Configuration object with endpoints
 * @returns {Promise<Array>} - Available properties for the entity type
 */
export async function getAvailableProperties(entityType, config = {}) {
  // Create cache key including endpoint to handle different configs
  const reconciliationBaseUrl = config.reconciliationEndpoint || DEFAULT_RECONCILIATION_BASE_URL;
  const cacheKey = `${reconciliationBaseUrl}:${entityType}`;
  
  // Return cached result if available
  if (propertiesCache.has(cacheKey)) {
    return propertiesCache.get(cacheKey);
  }
  
  try {
    const url = `${reconciliationBaseUrl}/extend/propose?type=${entityType}`;
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    
    // Cache the result
    propertiesCache.set(cacheKey, data);
    
    return data;
  } catch (error) {
    console.error('Error getting available properties:', error);
    throw error;
  }
}

/**
 * Filter available properties to get only ISNI, Wikidata, and URL properties
 * Uses caching to avoid reprocessing the same entity type properties
 * @param {Array} properties - Available properties from extend/propose API
 * @param {string} entityType - Entity type for caching
 * @param {Object} config - Configuration object for cache key
 * @returns {Array} - Filtered properties (ISNI, Wikidata, URL)
 */
export function filterTargetProperties(properties, entityType, config = {}) {
  // Create cache key including endpoint to handle different configs
  const reconciliationBaseUrl = config.reconciliationEndpoint || DEFAULT_RECONCILIATION_BASE_URL;
  const cacheKey = `${reconciliationBaseUrl}:${entityType}`;
  
  // Return cached result if available
  if (targetPropertiesCache.has(cacheKey)) {
    return targetPropertiesCache.get(cacheKey);
  }
  
  
  if (!Array.isArray(properties)) {
    return [];
  }
  
  const targetProperties = [];
  
  properties.forEach(property => {
    const id = property.id ? property.id.toLowerCase() : '';
    const name = property.name ? property.name.toLowerCase() : '';
    
    
    // Check for sameAs property (contains ISNI and Wikidata)
    if (id === 'sameas' || name === 'sameas' || id === 'sameAs' || name === 'sameAs') {
      targetProperties.push({
        ...property,
        type: 'sameAs' // Use sameAs type for processing
      });
    }
    // Check for URL property
    else if (id.includes('url') || name.includes('url') || id === 'url' || id === 'http://schema.org/url') {
      targetProperties.push({
        ...property,
        type: 'url'
      });
    }
    // Check for address property (contains postal code for Place entities)
    // COMMENTED OUT: Address property handling temporarily disabled
    // else if (id === 'address' || name === 'address') {
    //   targetProperties.push({
    //     ...property,
    //     type: 'address'
    //   });
    // }
    else {
      console.log('Skipping property (not target):', property);
    }
  });
  
  // Cache the filtered result
  targetPropertiesCache.set(cacheKey, targetProperties);
  
  return targetProperties;
}

/**
 * Extend entities with additional properties using the /extend API
 * @param {Array} entityIds - Array of entity IDs to extend
 * @param {Array} properties - Properties to fetch for each entity
 * @param {Object} config - Configuration object with endpoints
 * @returns {Promise<Object>} - Extended data for entities
 */
export async function extendEntities(entityIds, properties, config = {}) {
  const reconciliationBaseUrl = config.reconciliationEndpoint || DEFAULT_RECONCILIATION_BASE_URL;
  
  try {
    const extendQuery = {
      ids: entityIds,
      properties: properties.map(prop => ({ 
        id: prop.id,
        // COMMENTED OUT: Address expand handling temporarily disabled
        // expand: prop.type === 'address' // Only expand address property for nested structure
        expand: false // Disabled address expansion
      }))
    };
    
    
    const url = `${reconciliationBaseUrl}/extend`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(extendQuery)
    });


    if (!response.ok) {
      const errorText = await response.text();
      console.error('Extend API error response:', errorText);
      throw new Error(`HTTP error! status: ${response.status}, body: ${errorText}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error extending entities:', error);
    throw error;
  }
}

/**
 * Process extended data to extract ISNI, Wikidata, and URL values
 * @param {Object} extendedData - Raw extended data from /extend API
 * @param {Array} properties - Properties that were requested
 * @returns {Object} - Processed extended data by entity ID
 */
export function processExtendedData(extendedData, properties) {
  const processedData = {};
  
  
  if (!extendedData || !extendedData.rows || !Array.isArray(extendedData.rows)) {
    return processedData;
  }
  
  // New format: extendedData.rows is an array of entities
  extendedData.rows.forEach(entityRow => {
    const entityId = entityRow.id;
    const processed = {
      isni: null,
      wikidata: null,
      url: null,
      postalCode: null
    };
    
    
    if (entityRow.properties && Array.isArray(entityRow.properties)) {
      entityRow.properties.forEach(propertyData => {
        const propertyId = propertyData.id;
        
        // Find the matching property configuration to get the type
        const propertyConfig = properties.find(p => p.id === propertyId);
        if (!propertyConfig) {
          return;
        }
        
        
        if (propertyData.values && Array.isArray(propertyData.values) && propertyData.values.length > 0) {
          
          if (propertyConfig.type === 'url') {
            // For URL, take the first value
            const value = propertyData.values[0];
            const stringValue = value.str || value.id || '';
            processed.url = stringValue;
          } else if (propertyConfig.type === 'sameAs' && propertyId === 'sameAs') {
            // For sameAs, check all values for ISNI and Wikidata URIs
            
            propertyData.values.forEach(value => {
              const stringValue = value.str || value.id || '';
              
              // Check for ISNI format: https://isni.org/isni/{isni_id}
              if (stringValue.includes('isni.org/isni/')) {
                processed.isni = stringValue; // Store full ISNI URL
              }
              
              // Check for Wikidata format: http://www.wikidata.org/entity/{entityid}
              if (stringValue.includes('wikidata.org/entity/')) {
                processed.wikidata = stringValue; // Store full Wikidata URL
              }
            });
          // COMMENTED OUT: Address property processing temporarily disabled
          // } else if (propertyConfig.type === 'address' && propertyId === 'address') {
          //   // For address, extract postal code from nested structure
          //   
          //   propertyData.values.forEach(addressValue => {
          //     // Address has nested properties structure
          //     if (addressValue.properties && Array.isArray(addressValue.properties)) {
          //       addressValue.properties.forEach(addressProperty => {
          //         if (addressProperty.id === 'postalCode' && addressProperty.values && addressProperty.values.length > 0) {
          //           const postalCodeValue = addressProperty.values[0].str || addressProperty.values[0].id || '';
          //           if (postalCodeValue) {
          //             processed.postalCode = postalCodeValue;
          //           }
          //         }
          //       });
          //     }
          //   });
          // }
          }
        }
      });
    }
    
    processedData[entityId] = processed;
  });
  
  return processedData;
}

/**
 * Extract ISNI ID from sameAs URI format: https://isni.org/isni/{isni_id}
 * @param {string} uri - ISNI URI from sameAs
 * @returns {string} - Extracted ISNI ID or empty string
 */
function extractIsniFromSameAs(uri) {
  if (!uri) return '';
  
  // Extract ISNI ID from https://isni.org/isni/{isni_id}
  const isniMatch = uri.match(/isni\.org\/isni\/(\d{15}[\dX])/i);
  if (isniMatch) {
    return isniMatch[1];
  }
  
  return '';
}

/**
 * Extract Wikidata ID from sameAs URI format: http://www.wikidata.org/entity/{entityid}
 * @param {string} uri - Wikidata URI from sameAs  
 * @returns {string} - Extracted Wikidata ID (Q123456 format) or empty string
 */
function extractWikidataFromSameAs(uri) {
  if (!uri) return '';
  
  // Extract Wikidata ID from http://www.wikidata.org/entity/{entityid}
  const wikidataMatch = uri.match(/wikidata\.org\/entity\/(Q\d+)/i);
  if (wikidataMatch) {
    return wikidataMatch[1];
  }
  
  return '';
}

/**
 * Extract ISNI ID from various ISNI URI formats (legacy function)
 * @param {string} uri - ISNI URI or ID
 * @returns {string} - Extracted ISNI ID or empty string
 */
function extractIsniId(uri) {
  if (!uri) return '';
  
  // Handle various ISNI formats
  const isniMatch = uri.match(/(?:isni[\/:]|P213[\/:])?(\d{15}[\dX])/i);
  if (isniMatch) {
    return isniMatch[1];
  }
  
  // If it's already a clean ISNI ID
  if (/^\d{15}[\dX]$/.test(uri)) {
    return uri;
  }
  
  return uri;
}

/**
 * Extract Wikidata ID from various Wikidata URI formats (legacy function)
 * @param {string} uri - Wikidata URI or ID
 * @returns {string} - Extracted Wikidata ID (Q123456 format) or empty string
 */
function extractWikidataId(uri) {
  if (!uri) return '';
  
  // Handle various Wikidata formats
  const wikidataMatch = uri.match(/(?:wikidata\.org\/entity\/|Q)?(Q\d+)/i);
  if (wikidataMatch) {
    return wikidataMatch[1];
  }
  
  // If it's already a clean Wikidata ID
  if (/^Q\d+$/i.test(uri)) {
    return uri.toUpperCase();
  }
  
  return uri;
}

/**
 * Get entity type from schema.org URL format
 * @param {string} typeUrl - Schema.org type URL
 * @returns {string} - Entity type name (Place, Organization, Event, Person)
 */
export function getEntityTypeFromUrl(typeUrl) {
  if (!typeUrl) return '';
  
  const typeMatch = typeUrl.match(/schema\.org\/(\w+)$/i);
  if (typeMatch) {
    const typeName = typeMatch[1];
    // Capitalize first letter
    return typeName.charAt(0).toUpperCase() + typeName.slice(1);
  }
  
  // Handle direct type names
  const directTypes = ['Event', 'Person', 'Organization', 'Place'];
  const found = directTypes.find(type => 
    typeUrl.toLowerCase().includes(type.toLowerCase())
  );
  
  return found || '';
}

/**
 * Preload properties for all entity types to ensure we have them cached
 * @param {Object} config - Configuration object
 * @returns {Promise<Object>} - Object with properties for all entity types
 */
export async function preloadAllEntityTypeProperties(config = {}) {
  const entityTypes = ['Event', 'Person', 'Organization', 'Place'];
  const allProperties = {};
  
  
  try {
    // Load properties for all entity types in parallel
    const propertyPromises = entityTypes.map(async (entityType) => {
      try {
        const availableProperties = await getAvailableProperties(entityType, config);
        
        // Handle the response format - it might be {type: "Organization", properties: [...]}
        const propertiesArray = Array.isArray(availableProperties) ? 
          availableProperties : 
          (availableProperties.properties || availableProperties);
          
        const targetProperties = filterTargetProperties(propertiesArray, entityType, config);
        return { entityType, targetProperties };
      } catch (error) {
        console.error(`Error loading properties for ${entityType}:`, error);
        return { entityType, targetProperties: [] };
      }
    });
    
    const results = await Promise.all(propertyPromises);
    
    // Build properties map
    results.forEach(({ entityType, targetProperties }) => {
      allProperties[entityType] = targetProperties;
    });
    
    return allProperties;
    
  } catch (error) {
    console.error('Error preloading entity type properties:', error);
    return allProperties;
  }
}

/**
 * Get target properties for a candidate based on its type
 * @param {Object} candidate - Match candidate
 * @param {Object} allProperties - Preloaded properties for all entity types
 * @returns {Array} - Target properties for this candidate's type
 */
function getTargetPropertiesForCandidate(candidate, allProperties) {
  // Try to determine entity type from candidate.type
  let candidateEntityType = '';
  
  if (candidate.type) {
    if (Array.isArray(candidate.type)) {
      // Handle array of types - use first one
      const firstType = candidate.type[0];
      candidateEntityType = getEntityTypeFromUrl(typeof firstType === 'string' ? firstType : firstType.id);
    } else if (typeof candidate.type === 'string') {
      candidateEntityType = getEntityTypeFromUrl(candidate.type);
    } else if (candidate.type.id) {
      candidateEntityType = getEntityTypeFromUrl(candidate.type.id);
    }
  }
  
  // Fallback to checking all entity types if we can't determine the type
  if (!candidateEntityType || !allProperties[candidateEntityType]) {
    // Try all entity types and return the first one that has properties
    for (const entityType of ['Person', 'Organization', 'Event', 'Place']) {
      if (allProperties[entityType] && allProperties[entityType].length > 0) {
        return allProperties[entityType];
      }
    }
    return [];
  }
  
  return allProperties[candidateEntityType] || [];
}

/**
 * Enrich match candidates with extended data
 * @param {Array} candidates - Match candidates from reconciliation
 * @param {string} entityType - Entity type for getting available properties (not used anymore, kept for compatibility)
 * @param {Object} config - Configuration object
 * @returns {Promise<Array>} - Enriched candidates with extended data
 */
/**
 * Remove duplicate entity IDs from array
 * @param {Array} entityIds - Array of entity IDs (may contain duplicates)
 * @returns {Array} - Array of unique entity IDs
 */
function deduplicateEntityIds(entityIds) {
  const uniqueIds = [...new Set(entityIds)];
  if (uniqueIds.length !== entityIds.length) {
  }
  return uniqueIds;
}

export async function enrichMatchCandidates(candidates, entityType, config = {}) {
  try {
    if (!candidates || candidates.length === 0) {
      return candidates;
    }
    
    // Preload properties for all entity types
    const allProperties = await preloadAllEntityTypeProperties(config);
    
    // Collect all unique target properties across all entity types
    const allTargetProperties = [];
    const seenPropertyIds = new Set();
    
    Object.values(allProperties).forEach(properties => {
      properties.forEach(property => {
        if (!seenPropertyIds.has(property.id)) {
          allTargetProperties.push(property);
          seenPropertyIds.add(property.id);
        }
      });
    });
    
    if (allTargetProperties.length === 0) {
      return candidates;
    }
    
    
    // Extract entity IDs from candidates and remove duplicates
    const entityIds = candidates.map(candidate => candidate.id).filter(id => id);
    const uniqueEntityIds = deduplicateEntityIds(entityIds);
    
    if (uniqueEntityIds.length === 0) {
      return candidates;
    }
    
    
    // Extend entities with target properties using deduplicated IDs
    const extendedData = await extendEntities(uniqueEntityIds, allTargetProperties, config);
    const processedExtension = processExtendedData(extendedData, allTargetProperties);
    
    
    // Merge extended data with candidates
    const enrichedCandidates = candidates.map(candidate => {
      const extendedInfo = processedExtension[candidate.id] || {};
      const enriched = {
        ...candidate,
        // Add extended properties while preserving existing ones
        isni: extendedInfo.isni || candidate.isni || '',
        wikidata: extendedInfo.wikidata || candidate.wikidata || '',
        url: extendedInfo.url || candidate.url || '',
        postalCode: extendedInfo.postalCode || candidate.postalCode || ''
      };
      return enriched;
    });
    
    return enrichedCandidates;
    
  } catch (error) {
    console.error('Error enriching match candidates:', error);
    // Return original candidates if enrichment fails
    return candidates;
  }
}