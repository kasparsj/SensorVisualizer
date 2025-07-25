import { defineConfig } from 'vite';

export default defineConfig({
  // The project root (where index.html is located)
  root: 'src',
  build: {
    // The output directory for the build
    outDir: '../dist',
    // Empty the output directory before building
    emptyOutDir: true,
  },
  server: {
    // The port for the development server
    port: 1420,
    // Exit if the port is already in use
    strictPort: true,
  }
});
