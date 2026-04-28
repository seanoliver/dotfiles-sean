/**
 * growth-browser network interceptor
 * Injected via: pass this file's contents as the function body to Playwright MCP's browser_evaluate.
 * Captures all fetch and XHR calls into window.__networkLog.
 *
 * IMPORTANT: Must be injected AFTER navigating to the target page (before user actions).
 * Re-inject after any full navigation, since window.__networkLog lives in page context.
 */
(function () {
  if (window.__interceptorInstalled) return;
  window.__interceptorInstalled = true;
  window.__networkLog = [];

  // --- Intercept fetch ---
  const originalFetch = window.fetch;
  window.fetch = function (...args) {
    const url =
      typeof args[0] === "string"
        ? args[0]
        : args[0]?.url || String(args[0]);
    const options = args[1] || {};
    const entry = {
      type: "fetch",
      url,
      method: (options.method || "GET").toUpperCase(),
      body: options.body ? String(options.body).substring(0, 1000) : null,
      timestamp: Date.now(),
      ts: new Date().toISOString(),
    };
    window.__networkLog.push(entry);
    return originalFetch.apply(this, args);
  };

  // --- Intercept XHR ---
  const originalOpen = XMLHttpRequest.prototype.open;
  const originalSend = XMLHttpRequest.prototype.send;

  XMLHttpRequest.prototype.open = function (method, url) {
    this._logEntry = { type: "xhr", method: method.toUpperCase(), url };
    return originalOpen.apply(this, arguments);
  };

  XMLHttpRequest.prototype.send = function (body) {
    if (this._logEntry) {
      this._logEntry.body = body ? String(body).substring(0, 1000) : null;
      this._logEntry.timestamp = Date.now();
      this._logEntry.ts = new Date().toISOString();
      window.__networkLog.push(this._logEntry);
    }
    return originalSend.apply(this, arguments);
  };

  console.log("[growth-browser] Network interceptor installed ✓");
})();
