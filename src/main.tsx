import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { createInertiaApp } from "@inertiajs/react";
import "./index.css";

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob("./*.tsx", { eager: true });
    return pages[`./${name}.tsx`];
  },
  setup({ el, App, props }) {
    createRoot(el).render(
      <StrictMode>
        <App {...props} />
      </StrictMode>,
    );
  },
});
