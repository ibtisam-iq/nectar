/* Nectar — lean enhancements.
   1. Scroll reading-progress bar, on long documentation pages.
   2. Focus Mode controller for distraction-free reading.
   Re-runs on Material's instant navigation via document$. */

(function () {
  /* ==========================================================================
     1. READING PROGRESS BAR
     ========================================================================== */
  var cleanup = null;

  function initReadingProgress() {
    // Tear down any bar from the previous (instant-nav) page first.
    if (cleanup) { cleanup(); cleanup = null; }

    // Skip the custom hero pages (home / about).
    if (document.querySelector(".nx-hero, .nx-about-hero")) return;

    var article = document.querySelector("article.md-content__inner");
    if (!article) return;

    // Only bother when there's a meaningful amount to scroll.
    var scrollable = document.documentElement.scrollHeight - window.innerHeight;
    if (scrollable < 600) return;

    var bar = document.createElement("div");
    bar.className = "nx-reading-progress";
    document.body.appendChild(bar);

    function onScroll() {
      var max = document.documentElement.scrollHeight - window.innerHeight;
      bar.style.width = (max > 0 ? (window.scrollY / max) * 100 : 0) + "%";
    }

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll, { passive: true });
    onScroll();

    cleanup = function () {
      bar.remove();
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
    };
  }

  /* ==========================================================================
     2. FOCUS MODE CONTROLLER
     ========================================================================== */
  var FOCUS_ICON_EXPAND = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>';
  var FOCUS_ICON_CONTRACT = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true"><path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/></svg>';

  var keyboardListenerAttached = false;

  function getStoredFocusMode() {
    try {
      return window.sessionStorage && window.sessionStorage.getItem("nx-focus-mode") === "true";
    } catch (e) {
      return false;
    }
  }

  function setStoredFocusMode(enable) {
    try {
      if (window.sessionStorage) {
        window.sessionStorage.setItem("nx-focus-mode", enable ? "true" : "false");
      }
    } catch (e) {
      // Silently handle restricted environments / quota limits
    }
  }

  function updateFocusUI(isFocused) {
    if (isFocused) {
      document.body.classList.add("nx-focus-mode");
    } else {
      document.body.classList.remove("nx-focus-mode");
    }

    var btn = document.querySelector(".nx-focus-btn");
    if (btn) {
      btn.setAttribute("aria-pressed", isFocused ? "true" : "false");
      btn.innerHTML = isFocused ? FOCUS_ICON_CONTRACT : FOCUS_ICON_EXPAND;
    }
  }

  function setFocusMode(enable) {
    setStoredFocusMode(enable);
    updateFocusUI(enable);
  }

  function toggleFocusMode() {
    var isCurrentlyFocused = document.body.classList.contains("nx-focus-mode");
    setFocusMode(!isCurrentlyFocused);
  }

  function isEditableElement(el) {
    if (!el) return false;
    var tagName = el.tagName ? el.tagName.toLowerCase() : "";
    if (tagName === "input" || tagName === "textarea" || tagName === "select") {
      return true;
    }
    if (el.isContentEditable) {
      return true;
    }
    if (typeof el.closest === "function" && (el.closest(".md-search__input") || el.closest(".md-search"))) {
      return true;
    }
    return false;
  }

  function handleFocusKeydown(e) {
    if ((e.key === "z" || e.key === "Z") && !e.ctrlKey && !e.metaKey && !e.altKey) {
      if (isEditableElement(document.activeElement)) {
        return;
      }
      e.preventDefault();
      toggleFocusMode();
      return;
    }

    if (e.key === "Escape") {
      if (document.body.classList.contains("nx-focus-mode")) {
        setFocusMode(false);
      }
    }
  }

  function attachKeyboardListener() {
    if (keyboardListenerAttached) return;
    document.addEventListener("keydown", handleFocusKeydown);
    keyboardListenerAttached = true;
  }

  function insertFocusButton(headerInner, btn) {
    var source = headerInner.querySelector(".md-header__source");
    if (source) {
      headerInner.insertBefore(btn, source);
      return;
    }
    var target = headerInner.querySelector(".md-search, [for='__search'], .md-header__option");
    if (target) {
      headerInner.insertBefore(btn, target);
      return;
    }
    headerInner.appendChild(btn);
  }

  function initFocusMode() {
    attachKeyboardListener();

    var isFocused = getStoredFocusMode();
    if (isFocused) {
      document.body.classList.add("nx-focus-mode");
    } else {
      document.body.classList.remove("nx-focus-mode");
    }

    var headerInner = document.querySelector(".md-header__inner");
    if (!headerInner) return;

    var btn = document.querySelector(".nx-focus-btn");
    if (!btn) {
      btn = document.createElement("button");
      btn.type = "button";
      btn.className = "nx-focus-btn";
      btn.setAttribute("aria-label", "Toggle Focus Mode (Z)");
      btn.title = "Focus Mode (Press Z to toggle, Esc to exit)";
      btn.addEventListener("click", toggleFocusMode);
      insertFocusButton(headerInner, btn);
    } else {
      if (!headerInner.contains(btn)) {
        insertFocusButton(headerInner, btn);
      }
      var allBtns = document.querySelectorAll(".nx-focus-btn");
      if (allBtns.length > 1) {
        for (var i = 1; i < allBtns.length; i++) {
          allBtns[i].remove();
        }
      }
    }

    updateFocusUI(isFocused);
  }

  window.initFocusMode = initFocusMode;

  /* ==========================================================================
     3. LIFECYCLE HOOKS
     ========================================================================== */
  if (typeof document$ !== "undefined" && document$.subscribe) {
    // Material for MkDocs instant-navigation lifecycle.
    document$.subscribe(initReadingProgress);
    document$.subscribe(initFocusMode);
  } else {
    document.addEventListener("DOMContentLoaded", function () {
      initReadingProgress();
      initFocusMode();
    });
  }
})();
