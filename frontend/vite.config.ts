import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react()],
  server: {
    // В dev-режиме запросы к /api уходят на бэкенд, поэтому CORS не нужен.
    proxy: {
      '/api': 'http://127.0.0.1:8000',
    },
  },
})
