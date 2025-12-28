import React from "react";
import ReactDOM from "react-dom/client";

const App = () => (
  <div style={{ padding: 24 }}>
    <h1>💊 Pharmacy UI</h1>
    <p>Connected to Intent Gateway</p>
  </div>
);

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
