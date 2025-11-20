/**
 * Reconciliation Service for Artsdata APIs
 * Handles batch reconciliation, minting, and linking operations
 */

import { enrichMatchCandidates, getEntityTypeFromUrl } from './dataExtensionService.js';

// Default endpoints for development (when no config is passed)
const DEFAULT_STAGING_API_BASE = 'https://staging.api.artsdata.ca';
const DEFAULT_RECONCILIATION_BASE_URL = 'https://staging.recon.artsdata.ca';
const DEFAULT_PUBLISHER_URI = 'http://kg.artsdata.ca/resource/K1-1';

const RECONCILIATION_ENDPOINT = '/match'; // Based on reconciliation API spec

/**
 * Call the reconciliation API to get match candidates
 * @param {Array} entities - Array of entities to reconcile
 * @param {string} entityType - schema:Person, schema:Organization, etc.
 * @param {Object} config - Configuration object with endpoints
 * @returns {Promise<Object>} - Reconciliation results
 */
export async function getMatchCandidates(entities, entityType, config = {}) {
  // Use config endpoints or fall back to defaults
  const reconciliationBaseUrl = config.reconciliationEndpoint || DEFAULT_RECONCILIATION_BASE_URL;
  
  try {
    // Determine reconciliation type - use dbo:Agent as default except for Place/Event
    const getReconciliationType = (type) => {
      const normalizedType = type.toLowerCase().replace('schema:', '');
      if (normalizedType === 'place' || normalizedType === 'event') {
        return type; // Use original type for Place and Event
      }
      return 'dbo:Agent'; // Use dbo:Agent for Person, Organization, and others
    };
    
    const reconciliationType = getReconciliationType(entityType);
    
    // Build queries for batch reconciliation
    const queries = entities.map(entity => {
      const conditions = [
        {
          matchType: "name",
          propertyValue: entity.artsdataUri && entity.artsdataUri.trim() !== '' ? entity.artsdataUri : entity.name,
          required: true,
          matchQuantifier: "any"
        }
      ];
      
      // Add URL as separate property
      if (entity.url && entity.url.trim() !== '') {
        conditions.push({
          matchType: "property",
          propertyId: "http://schema.org/url",
          propertyValue: entity.url,
          required: false,
          matchQuantifier: "any"
        });
      }
      
      // Combine ISNI and Wikidata into sameAs property
      const sameAsValues = [];
      
      if (entity.isni && entity.isni.trim() !== '') {
        sameAsValues.push(entity.isni);
      }
      
      if (entity.wikidata && entity.wikidata.trim() !== '') {
        sameAsValues.push(entity.wikidata);
      }
      
      if (sameAsValues.length > 0) {
        conditions.push({
          matchType: "property",
          propertyId: "http://schema.org/sameAs",
          propertyValue: sameAsValues.length === 1 ? sameAsValues[0] : sameAsValues,
          required: false,
          matchQuantifier: "any"
        });
      }
      
      // Add Place-specific conditions for enhanced matching
      if (entityType.toLowerCase().includes('place')) {
        // Add postal code condition
        if (entity.postalCode && entity.postalCode.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "<http://schema.org/address>/<http://schema.org/postalCode>",
            propertyValue: entity.postalCode,
            required: false,
            matchQuantifier: "any"
          });
        }
        
        // Add address locality condition
        if (entity.addressLocality && entity.addressLocality.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "<http://schema.org/address>/<http://schema.org/addressLocality>",
            propertyValue: entity.addressLocality,
            required: false,
            matchQuantifier: "any"
          });
        }
        
        // Add address region condition
        if (entity.addressRegion && entity.addressRegion.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "<http://schema.org/address>/<http://schema.org/addressRegion>",
            propertyValue: entity.addressRegion,
            required: false,
            matchQuantifier: "any"
          });
        }
        
        // Add ISNI and Wikidata for Places (same as other entity types)
        // This ensures Places also get matched on these identifiers when available
      }
      
      // Add Event-specific conditions for enhanced matching
      if (entityType.toLowerCase().includes('event')) {
        // Add location name condition
        if (entity.locationName && entity.locationName.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "<https://schema.org/location>/<https://schema.org/name>",
            propertyValue: entity.locationName,
            required: false,
            matchQuantifier: "any"
          });
        }
        
        // Add location postal code condition
        if (entity.postalCode && entity.postalCode.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "<https://schema.org/location>/<https://schema.org/address>/<https://schema.org/postalCode>",
            propertyValue: entity.postalCode,
            required: false,
            matchQuantifier: "any"
          });
        }
        
        // Add location Artsdata place URI condition
        if (entity.locationArtsdataUri && entity.locationArtsdataUri.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "<https://schema.org/location>/<https://schema.org/sameAs>",
            propertyValue: entity.locationArtsdataUri,
            required: false,
            matchQuantifier: "any"
          });
        }
        
        // Add performer name condition
        if (entity.performerName && entity.performerName.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "<https://schema.org/performer>/<https://schema.org/name>",
            propertyValue: entity.performerName,
            required: false,
            matchQuantifier: "any"
          });
        }

        // Add start date condition
        if (entity.startDate && entity.startDate.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "https://schema.org/startDate",
            propertyValue: entity.startDate,
            required: false,
            matchQuantifier: "any"
          });
        }

        // Add end date condition
        if (entity.endDate && entity.endDate.trim() !== '') {
          conditions.push({
            matchType: "property",
            propertyId: "https://schema.org/endDate",
            propertyValue: entity.endDate,
            required: false,
            matchQuantifier: "any"
          });
        }
      }
      
      return {
        conditions,
        type: reconciliationType,
        limit: 10 // Limit candidates per entity
      };
    });


    const response = await fetch(`${reconciliationBaseUrl}${RECONCILIATION_ENDPOINT}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({ queries })
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    
    // Enrich match candidates with extended data if we have candidates
    if (data && data.results && Array.isArray(data.results)) {
      try {
        // Get entity type for data extension (convert from schema: format)
        const extensionEntityType = getEntityTypeFromUrl(entityType);
        
        // Collect all candidates from all results for batch enrichment
        const allCandidates = [];
        const candidatePositions = []; // Track ALL positions for each candidate (handles duplicates)
        
        data.results.forEach((result, resultIndex) => {
          if (result && result.candidates && Array.isArray(result.candidates)) {
            result.candidates.forEach((candidate, candidateIndex) => {
              allCandidates.push(candidate);
              // Store position info for each candidate occurrence
              candidatePositions.push({ resultIndex, candidateIndex, entityId: candidate.id });
            });
          }
        });
        
        if (allCandidates.length > 0) {
          const enrichedCandidates = await enrichMatchCandidates(allCandidates, extensionEntityType, config);

          // Map enriched candidates back to ALL their positions (handles duplicates)
          enrichedCandidates.forEach((enrichedCandidate, enrichedIndex) => {
            // Find ALL positions where this entity ID appears
            const allPositions = candidatePositions.filter(pos => pos.entityId === enrichedCandidate.id);
            
            // Apply enriched data to ALL occurrences of this entity while preserving original scores
            allPositions.forEach(position => {
              const originalCandidate = data.results[position.resultIndex].candidates[position.candidateIndex];
              
              // Merge enriched properties with original candidate, preserving parent-specific data like score
              const mergedCandidate = {
                ...originalCandidate, // Keep original data (especially score, match status)
                // Only override with extended properties from enrichment
                isni: enrichedCandidate.isni || originalCandidate.isni || '',
                wikidata: enrichedCandidate.wikidata || originalCandidate.wikidata || '',
                url: enrichedCandidate.url || originalCandidate.url || '',
                postalCode: enrichedCandidate.postalCode || originalCandidate.postalCode || '',
                addressLocality: enrichedCandidate.addressLocality || originalCandidate.addressLocality || '',
                addressRegion: enrichedCandidate.addressRegion || originalCandidate.addressRegion || '',
                // Event-specific extended properties
                startDate: enrichedCandidate.startDate || originalCandidate.startDate || '',
                endDate: enrichedCandidate.endDate || originalCandidate.endDate || '',
                locationName: enrichedCandidate.locationName || originalCandidate.locationName || '',
                locationArtsdataUri: enrichedCandidate.locationArtsdataUri || originalCandidate.locationArtsdataUri || '',
                eventStatus: enrichedCandidate.eventStatus || originalCandidate.eventStatus || '',
                eventAttendanceMode: enrichedCandidate.eventAttendanceMode || originalCandidate.eventAttendanceMode || '',
                offerUrl: enrichedCandidate.offerUrl || originalCandidate.offerUrl || '',
                performers: enrichedCandidate.performers || originalCandidate.performers || []
              };

              data.results[position.resultIndex].candidates[position.candidateIndex] = mergedCandidate;
            });
          });
          
        }
      } catch (enrichmentError) {
        console.error('Error enriching match candidates:', enrichmentError);
        // Continue with original data if enrichment fails
      }
    }

    return data;
  } catch (error) {
    console.error('Error getting match candidates:', error);
    throw error;
  }
}

/**
 * Preview minting process for an entity
 * @param {string} uri - URI of the entity to mint
 * @param {string} classToMint - schema:Person, schema:Organization, etc.
 * @param {Object} config - Configuration object with endpoints
 * @param {string} facts - Optional graph of facts
 * @returns {Promise<Object>} - Preview results
 */
// Helper function to construct mint URLs correctly, avoiding duplicate /mint paths
function buildMintUrl(baseEndpoint, path) {
  // Remove trailing slash from base endpoint
  const cleanBase = baseEndpoint.replace(/\/$/, '');

  // Check if base endpoint already ends with /mint
  if (cleanBase.endsWith('/mint')) {
    return `${cleanBase}${path}`;
  } else {
    return `${cleanBase}/mint${path}`;
  }
}

// Helper function to construct link URLs correctly, avoiding duplicate /link paths
function buildLinkUrl(baseEndpoint, path) {
  // Remove trailing slash from base endpoint
  const cleanBase = baseEndpoint.replace(/\/$/, '');

  // Check if base endpoint already ends with /link
  if (cleanBase.endsWith('/link')) {
    return `${cleanBase}${path}`;
  } else {
    return `${cleanBase}/link${path}`;
  }
}

export async function previewMint(uri, classToMint, config = {}, facts = null) {
  // Use config endpoints or fall back to defaults
  const mintEndpoint = config.mintEndpoint || DEFAULT_STAGING_API_BASE;

  try {
    const params = new URLSearchParams({
      uri,
      classToMint
    });

    if (facts) {
      params.append('facts', facts);
    }

    const response = await fetch(`${buildMintUrl(mintEndpoint, '/preview')}?${params}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    // Parse SHACL ValidationReport from the response
    // The API returns a data array containing JSON-LD objects
    // We need to find the ValidationReport object and check sh:conforms
    const validationReport = data.data?.find(item =>
      item['@type']?.includes('http://www.w3.org/ns/shacl#ValidationReport')
    );

    if (!validationReport) {
      // If no validation report found, treat as error
      return {
        status: 'error',
        message: 'No validation report found in preview response',
        rawResponse: data
      };
    }

    // Extract the conforms boolean value
    const conformsArray = validationReport['http://www.w3.org/ns/shacl#conforms'];
    const conforms = conformsArray?.[0]?.['@value'] === 'true';

    if (conforms) {
      // Validation passed - entity can be minted
      return {
        status: 'success',
        message: data.message || 'Validation passed',
        validationReport,
        rawResponse: data
      };
    } else {
      // Validation failed - extract error messages from sh:result
      const resultRefs = validationReport['http://www.w3.org/ns/shacl#result'] || [];
      const errorMessages = [];

      // Find the actual ValidationResult objects in the data array
      resultRefs.forEach(resultRef => {
        const resultId = resultRef['@id'];
        const validationResult = data.data?.find(item => item['@id'] === resultId);

        if (validationResult) {
          const resultMessage = validationResult['http://www.w3.org/ns/shacl#resultMessage'];
          const message = resultMessage?.[0]?.['@value'];

          const resultPath = validationResult['http://www.w3.org/ns/shacl#resultPath'];
          const path = resultPath?.[0]?.['@id'];

          if (message) {
            // Create a user-friendly error message
            const pathName = path ? path.split('/').pop() : 'Unknown field';
            errorMessages.push(`${pathName}: ${message}`);
          }
        }
      });

      // Build a comprehensive error message
      const errorMessage = errorMessages.length > 0
        ? `Validation failed:\n${errorMessages.join('\n')}`
        : (data.message || 'Validation failed - entity cannot be minted');

      return {
        status: 'error',
        message: errorMessage,
        validationReport,
        errors: errorMessages,
        rawResponse: data
      };
    }
  } catch (error) {
    console.error('Error previewing mint:', error);
    throw error;
  }
}

/**
 * Mint a new entity
 * @param {string} uri - URI of the entity to mint
 * @param {string} classToMint - schema:Person, schema:Organization, etc.
 * @param {string} reference - URI of the graph/data feed
 * @param {Object} config - Configuration object with endpoints
 * @returns {Promise<Object>} - Mint results
 */
export async function mintEntity(uri, classToMint, reference, config = {}) {
  // Use config endpoints or fall back to defaults
  const mintEndpoint = config.mintEndpoint || DEFAULT_STAGING_API_BASE;
  const publisherUri = config.userUri || DEFAULT_PUBLISHER_URI;
  
  try {
    const response = await fetch(`${buildMintUrl(mintEndpoint, '')}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        uri,
        classToMint,
        reference,
        publisher: publisherUri
      })
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error minting entity:', error);
    throw error;
  }
}

/**
 * Link an entity to an existing Artsdata entity
 * @param {string} externalUri - URI of the entity to link
 * @param {string} classToLink - schema:Person, schema:Organization, etc.
 * @param {string} adUri - Artsdata URI of the entity to link to
 * @param {Object} config - Configuration object with endpoints
 * @returns {Promise<Object>} - Link results
 */
export async function linkEntity(externalUri, classToLink, adUri, config = {}) {
  // Use config endpoints or fall back to defaults
  const linkEndpoint = config.linkEndpoint || DEFAULT_STAGING_API_BASE;
  
  try {
    const params = new URLSearchParams({
      externalUri,
      classToLink,
      adUri
    });
    
    const response = await fetch(`${buildLinkUrl(linkEndpoint, '')}?${params}`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error linking entity:', error);
    throw error;
  }
}

/**
 * Flag an entity for review
 * @param {string} uri - URI of the entity to flag
 * @param {Object} config - Configuration object with endpoints
 * @returns {Promise<Object>} - Flag results
 */
export async function flagEntity(uri, config = {}) {
  // Use base API endpoint for maintenance operations, not linkEndpoint
  const flagEndpoint = config.linkEndpoint || DEFAULT_STAGING_API_BASE;
  // Remove /link suffix if present since flag endpoint is at base level
  const baseEndpoint = flagEndpoint.replace(/\/link$/, '');
  const publisherUri = config.userUri || DEFAULT_PUBLISHER_URI;
  
  try {
    const params = new URLSearchParams({
      uri,
      publisher: publisherUri
    });
    
    const response = await fetch(`${baseEndpoint}/maintenance/flag_for_review?${params}`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error flagging entity:', error);
    throw error;
  }
}

/**
 * Process reconciliation results and transform them for UI
 * @param {Object} reconciliationResults - Raw reconciliation results
 * @param {Array} originalEntities - Original entities that were reconciled
 * @returns {Array} - Transformed entities with match candidates
 */
export function processReconciliationResults(reconciliationResults, originalEntities) {
  
  // Handle the actual API response format
  const results = reconciliationResults?.results || [];
  
  if (!results || !Array.isArray(results)) {
    return originalEntities.map(entity => ({
      ...entity,
      matches: [],
      hasAutoMatch: false,
      autoMatchCandidate: null
    }));
  }

  return originalEntities.map((entity, index) => {
    const result = results[index] || {};
    const candidates = result.candidates || [];
    
    
    // Check if entity is pre-reconciled and find matching candidate
    let hasAutoMatch = false;
    let autoMatchCandidate = null;
    
    if (entity.isPreReconciled && entity.linkedTo) {
      // Find candidate that matches the entity's artsdata_uri
      const matchingCandidate = candidates.find(candidate => candidate.id === entity.linkedTo);
      if (matchingCandidate) {
        hasAutoMatch = true;
        autoMatchCandidate = matchingCandidate;
      }
    } else {
      // Find true matches (where match property is true) for non-pre-reconciled entities
      const trueMatches = candidates.filter(candidate => candidate.match === true);
      // Auto-judgment logic: only if there's exactly one true match
      hasAutoMatch = trueMatches.length === 1;
      autoMatchCandidate = hasAutoMatch ? trueMatches[0] : null;
    }
    
    // Transform candidates for UI display
    const matches = candidates.map(candidate => {
      // For pre-reconciled entities, mark the matching candidate as a true match
      const isMatchingCandidate = entity.isPreReconciled && entity.linkedTo && candidate.id === entity.linkedTo;
      
      return {
        id: candidate.id,
        name: candidate.name,
        description: candidate.description || candidate.disambiguatingDescription || '',
        type: candidate.type || [],
        score: candidate.score || 0,
        match: isMatchingCandidate ? true : (candidate.match || false), // Override match for pre-reconciled
        externalId: candidate.id || '',
        // Additional fields from Artsdata entities
        url: candidate.url || candidate['http://schema.org/url'] || '',
        isni: candidate.isni || candidate['http://www.wikidata.org/prop/direct/P213'] || '',
        wikidata: candidate.wikidata || candidate['http://www.wikidata.org/entity/'] || '',
        postalCode: candidate.postalCode || candidate['http://schema.org/postalCode'] || '',
        addressLocality: candidate.addressLocality || candidate['http://schema.org/addressLocality'] || '',
        addressRegion: candidate.addressRegion || candidate['http://schema.org/addressRegion'] || '',
        startDate: candidate.startDate || '',
        // Event-specific extended properties
        endDate: candidate.endDate || '',
        locationName: candidate.locationName || '',
        locationArtsdataUri: candidate.locationArtsdataUri || '',
        eventStatus: candidate.eventStatus || '',
        eventAttendanceMode: candidate.eventAttendanceMode || '',
        offerUrl: candidate.offerUrl || '',
        performers: candidate.performers || [],
        organizerName: candidate.organizerName || ''
      };
    });


    const processedEntity = {
      ...entity,
      matches,
      hasAutoMatch,
      autoMatchCandidate,
      // Preserve reconciled status for pre-reconciled entities, otherwise update based on auto-match
      status: entity.isPreReconciled ? 'reconciled' : (hasAutoMatch ? 'Auto-matched' : entity.status)
    };
    
    return processedEntity;
  });
}


/**
 * Get reference URI for a given feed
 * @param {string} feed - Feed identifier
 * @returns {string} - Reference URI
 */
export function getReferenceUri(feed) {
  const feedMap = {
    'iwts-ca': 'http://kg.artsdata.ca/culture-creates/artsdata-planet-iwts/iwts-ca',
    'capacoa': 'http://kg.artsdata.ca/culture-creates/artsdata-planet-capacoa/capacoa',
    'adc-members': 'http://kg.artsdata.ca/culture-creates/artsdata-planet-adc-members/adc-members'
  };
  
  return feedMap[feed] || `http://kg.artsdata.ca/culture-creates/artsdata-planet-${feed}/${feed}`;
}

/**
 * Batch reconcile entities with lazy loading
 * @param {Array} entities - Entities to reconcile
 * @param {string} entityType - Entity type
 * @param {number} batchSize - Number of entities per batch
 * @param {Object} config - Configuration object
 * @param {Function} onProgress - Progress callback function
 * @returns {Promise<Array>} - Reconciled entities
 */
export async function batchReconcile(entities, entityType, batchSize = 100, config = {}, onProgress = null) {
  const results = [];
  const totalBatches = Math.ceil(entities.length / batchSize);

  for (let i = 0; i < entities.length; i += batchSize) {
    const batch = entities.slice(i, i + batchSize);
    const batchNumber = Math.floor(i / batchSize) + 1;

    // Call progress callback if provided
    if (onProgress) {
      onProgress({
        currentBatch: batchNumber,
        totalBatches: totalBatches,
        isProcessing: true,
        entitiesProcessed: i,
        totalEntities: entities.length
      });
    }

    try {
      const reconciliationResults = await getMatchCandidates(batch, entityType, config);
      const processedBatch = processReconciliationResults(reconciliationResults, batch);
      results.push(...processedBatch);
    } catch (error) {
      console.error(`Error reconciling batch ${batchNumber}:`, error);
      // Add batch without matches on error
      results.push(...batch.map(entity => ({
        ...entity,
        matches: [],
        hasAutoMatch: false,
        autoMatchCandidate: null,
        reconciliationError: error.message
      })));
    }
  }

  // Final progress callback
  if (onProgress) {
    onProgress({
      currentBatch: totalBatches,
      totalBatches: totalBatches,
      isProcessing: false,
      entitiesProcessed: entities.length,
      totalEntities: entities.length
    });
  }

  return results;
}