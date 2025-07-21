import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/nebula/artsdata-batch-reconciliation-ui/', // Repository name + subdirectory
  build: {
    outDir: 'dist'
  }
})