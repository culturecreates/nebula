/**
 * Configuration Reader Utility
 * Extracts configuration from Rails-provided data attributes
 * Provides fallback values for development environment
 */

// Development fallback values
const DEFAULT_CONFIG = {
  userUri: 'http://kg.artsdata.ca/resource/K1-1',
  reconciliationEndpoint: 'https://staging.recon.artsdata.ca',
  mintEndpoint: 'https://staging.api.artsdata.ca',
  linkEndpoint: 'https://staging.api.artsdata.ca'
};

/**
 * Reads configuration from the root div data attributes
 * Falls back to hardcoded values for development
 * @returns {Object} Configuration object
 */
export function getAppConfig() {
  const rootElement = document.getElementById('root');
  
  if (!rootElement) {
    console.warn('Root element not found, using default configuration');
    return DEFAULT_CONFIG;
  }

  const config = {
    userUri: rootElement.dataset.userUri || DEFAULT_CONFIG.userUri,
    reconciliationEndpoint: rootElement.dataset.reconciliationEndpoint || DEFAULT_CONFIG.reconciliationEndpoint,
    mintEndpoint: rootElement.dataset.mintEndpoint || DEFAULT_CONFIG.mintEndpoint,
    linkEndpoint: rootElement.dataset.linkEndpoint || DEFAULT_CONFIG.linkEndpoint
  };

  // Log configuration in development
  if (process.env.NODE_ENV === 'development') {
    
    // Check if we're using defaults (development mode)
    const usingDefaults = Object.keys(config).some(key => 
      config[key] === DEFAULT_CONFIG[key] && !rootElement.dataset[toCamelCase(`data-${key}`)]
    );
    
    if (usingDefaults) {
      console.log('🔧 Using development defaults. In production, values will come from Rails data attributes.');
    }
  }

  return config;
}

/**
 * Helper function to convert kebab-case to camelCase for dataset access
 * @param {string} str - The kebab-case string
 * @returns {string} camelCase string
 */
function toCamelCase(str) {
  return str.replace(/-([a-z])/g, (match, letter) => letter.toUpperCase());
}

/**
 * Validates that all required configuration values are present
 * @param {Object} config - Configuration object to validate
 * @returns {boolean} True if valid, false otherwise
 */
export function validateConfig(config) {
  const requiredKeys = ['userUri', 'reconciliationEndpoint', 'mintEndpoint', 'linkEndpoint'];
  
  for (const key of requiredKeys) {
    if (!config[key] || typeof config[key] !== 'string' || config[key].trim() === '') {
      console.error(`Missing or invalid configuration: ${key}`);
      return false;
    }
  }
  
  return true;
}