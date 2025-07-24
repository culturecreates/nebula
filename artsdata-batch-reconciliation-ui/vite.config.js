import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/public/batch-reconciliation-ui/', // Base path for assets
  build: {
    outDir: '../public/batch-reconciliation-ui', // Output directory
    emptyOutDir: true,  // Clears the output directory before building
    manifest: true,     // Generates a manifest.json file
  }
})