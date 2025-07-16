/**
 * Reconciliation Service for Artsdata APIs
 * Handles batch reconciliation, minting, and linking operations
 */

// API endpoints
const STAGING_API_BASE = 'https://staging.api.artsdata.ca';
const RECONCILIATION_BASE_URL = 'https://staging.recon.artsdata.ca';
const RECONCILIATION_ENDPOINT = '/match'; // Based on reconciliation API spec

// Publisher URI for development (as specified in requirements)
const PUBLISHER_URI = 'http://kg.artsdata.ca/resource/K1-1';

/**
 * Call the reconciliation API to get match candidates
 * @param {Array} entities - Array of entities to reconcile
 * @param {string} entityType - schema:Person, schema:Organization, etc.
 * @returns {Promise<Object>} - Reconciliation results
 */
export async function getMatchCandidates(entities, entityType) {
  try {
    // Build queries for batch reconciliation
    const queries = entities.map(entity => ({
      conditions: [
        {
          matchType: "name",
          propertyId: "schema:name",
          propertyValue: entity.name,
          required: true,
          matchQuantifier: "any"
        }
      ],
      type: entityType,
      limit: 10 // Limit candidates per entity
    }));

    console.log('Reconciliation Query:', { queries });
    console.log('Reconciliation EntityType:', entityType);

    const response = await fetch(`${RECONCILIATION_BASE_URL}${RECONCILIATION_ENDPOINT}`, {
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
    console.log('Reconciliation API Response:', data);
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
 * @param {string} facts - Optional graph of facts
 * @returns {Promise<Object>} - Preview results
 */
export async function previewMint(uri, classToMint, facts = null) {
  try {
    const params = new URLSearchParams({
      uri,
      classToMint
    });
    
    if (facts) {
      params.append('facts', facts);
    }

    const response = await fetch(`${STAGING_API_BASE}/mint/preview?${params}`, {
      method: 'GET',
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
    console.error('Error previewing mint:', error);
    throw error;
  }
}

/**
 * Mint a new entity
 * @param {string} uri - URI of the entity to mint
 * @param {string} classToMint - schema:Person, schema:Organization, etc.
 * @param {string} reference - URI of the graph/data feed
 * @returns {Promise<Object>} - Mint results
 */
export async function mintEntity(uri, classToMint, reference) {
  try {
    const response = await fetch(`${STAGING_API_BASE}/mint`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        uri,
        classToMint,
        reference,
        publisher: PUBLISHER_URI
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
 * @returns {Promise<Object>} - Link results
 */
export async function linkEntity(externalUri, classToLink, adUri) {
  try {
    const params = new URLSearchParams({
      externalUri,
      classToLink,
      adUri
    });
    
    const response = await fetch(`${STAGING_API_BASE}/link?${params}`, {
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
 * Process reconciliation results and transform them for UI
 * @param {Object} reconciliationResults - Raw reconciliation results
 * @param {Array} originalEntities - Original entities that were reconciled
 * @returns {Array} - Transformed entities with match candidates
 */
export function processReconciliationResults(reconciliationResults, originalEntities) {
  console.log('Processing reconciliation results:', { reconciliationResults, originalEntities });
  
  // Handle the actual API response format
  const results = reconciliationResults?.results || [];
  
  if (!results || !Array.isArray(results)) {
    console.log('No reconciliation results or not an array, returning entities with empty matches');
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
    
    // Find true matches (where match property is true)
    const trueMatches = candidates.filter(candidate => candidate.match === true);
    
    // Auto-judgment logic: only if there's exactly one true match
    const hasAutoMatch = trueMatches.length === 1;
    const autoMatchCandidate = hasAutoMatch ? trueMatches[0] : null;
    
    // Transform candidates for UI display
    const matches = candidates.map(candidate => ({
      id: candidate.id,
      name: candidate.name,
      description: candidate.description || candidate.disambiguatingDescription || '',
      type: candidate.type || [],
      score: normalizeScore(candidate.score),
      match: candidate.match || false,
      externalId: candidate.id || ''
    }));

    const processedEntity = {
      ...entity,
      matches,
      hasAutoMatch,
      autoMatchCandidate,
      // Update status based on auto-match
      status: hasAutoMatch ? 'Auto-matched' : entity.status
    };
    
    return processedEntity;
  });
}

/**
 * Normalize score to 0-100 range
 * @param {number} score - Raw score from reconciliation service
 * @returns {number} - Normalized score (0-100)
 */
function normalizeScore(score) {
  if (typeof score !== 'number') return 0;
  
  // If score is already in 0-100 range, return as is
  if (score >= 0 && score <= 100) {
    return Math.round(score);
  }
  
  // For other scoring systems, truncate long numbers
  if (score > 100) {
    return Math.round(score / 10); // Simple normalization fallback
  }
  
  return Math.max(0, Math.round(score));
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
 * @returns {Promise<Array>} - Reconciled entities
 */
export async function batchReconcile(entities, entityType, batchSize = 20) {
  const results = [];
  
  for (let i = 0; i < entities.length; i += batchSize) {
    const batch = entities.slice(i, i + batchSize);
    
    try {
      const reconciliationResults = await getMatchCandidates(batch, entityType);
      const processedBatch = processReconciliationResults(reconciliationResults, batch);
      results.push(...processedBatch);
    } catch (error) {
      console.error(`Error reconciling batch ${i / batchSize + 1}:`, error);
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
  
  return results;
}