/* Nectar — lean enhancements.
   Only a scroll reading-progress bar, on long documentation pages.
   Skips the landing/about pages (which use custom hero layouts) and short pages.
   Re-runs on Material's instant navigation via document$. */

(function () {
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

  if (typeof document$ !== "undefined" && document$.subscribe) {
    // Material for MkDocs instant-navigation lifecycle.
    document$.subscribe(initReadingProgress);
  } else {
    document.addEventListener("DOMContentLoaded", initReadingProgress);
  }
})();
