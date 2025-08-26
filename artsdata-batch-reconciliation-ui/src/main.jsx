import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import { getAppConfig, validateConfig } from './utils/configReader.js'

let reactRoot = null;
let isInitialized = false;

// Function to initialize or reinitialize the React app
function initializeApp() {
  const rootElement = document.getElementById('root');
  
  if (!rootElement) {
    console.error('Root element not found');
    return;
  }

  // Prevent duplicate initialization
  if (isInitialized && reactRoot && rootElement.hasChildNodes()) {
    return;
  }

  // Get configuration from Rails data attributes or use development defaults
  const config = getAppConfig();

  // Validate configuration
  if (!validateConfig(config)) {
    console.error('Invalid application configuration. Please check Rails data attributes.');
  }

  // Unmount existing root if it exists
  if (reactRoot) {
    try {
      reactRoot.unmount();
    } catch (e) {
      console.warn('Could not unmount previous React root:', e);
    }
  }

  // Clear the root element and create a new React root
  rootElement.innerHTML = '';
  
  reactRoot = createRoot(rootElement);
  reactRoot.render(
    <StrictMode>
      <App config={config} />
    </StrictMode>
  );

  isInitialized = true;
}

// Initialize on first load
initializeApp();

// Handle Turbo navigation (only add listener once)
if (!window.reactAppTurboInitialized) {
  document.addEventListener('turbo:load', () => {
    isInitialized = false;
    initializeApp();
  });
  window.reactAppTurboInitialized = true;
}
