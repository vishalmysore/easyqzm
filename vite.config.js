import { defineConfig } from 'vite';

// Relative base so the same build works on a custom domain (easyqz.online)
// and on a GitHub Pages project path (/easyqzm/) without reconfiguration.
export default defineConfig({
  base: './',
  optimizeDeps: {
    // web-llm ships its own workers/wasm; let it resolve at runtime.
    exclude: ['@mlc-ai/web-llm'],
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    target: 'esnext',
    sourcemap: false,
  },
  server: {
    port: 3000,
    open: true,
  },
});
