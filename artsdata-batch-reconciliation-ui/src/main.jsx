import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import { getAppConfig, validateConfig } from './utils/configReader.js'

// Get configuration from Rails data attributes or use development defaults
const config = getAppConfig();

// Validate configuration
if (!validateConfig(config)) {
  console.error('Invalid application configuration. Please check Rails data attributes.');
}

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App config={config} />
  </StrictMode>,
)
