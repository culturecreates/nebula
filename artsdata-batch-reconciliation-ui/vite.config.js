import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/artsdata-batch-reconciliation-ui/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
  }
})
