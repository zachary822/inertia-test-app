import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";

// https://vitejs.dev/config/
export default defineConfig({
  base: "/public/",
  build: {
    sourcemap: "inline",
    manifest: true,
    rollupOptions: {
      input: "./src/main.tsx",
    },
  },
  plugins: [react()],
});
