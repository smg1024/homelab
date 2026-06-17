/*
 * Keep the reader on the same page when they switch languages.
 *
 * The English (/) and Korean (/ko/) builds mirror each other page for page,
 * but the language selector links are static (/ and /ko/), so by default a
 * switch always jumps to the overview. Here we swap only the language prefix
 * of the current path instead.
 *
 * The links' href is corrected on every render (first load and after each
 * instant navigation) via Material's `document$` observable. Doing it on
 * render, rather than only on hover/pointerdown, means the target is always
 * right even for touch taps, keyboard activation, prefetch, middle-click, and
 * right-click "copy link" — the cases where the old pointer-only fix let the
 * stale "/" href slip through and land on the overview.
 *
 * A plain left-click additionally forces a full reload, so <html lang>, the
 * search index, and the nav tree all switch cleanly rather than via instant
 * navigation (which would swap only the page content).
 */
(function () {
  function targetUrl(link) {
    var base = link.getAttribute("hreflang") === "ko" ? "/ko/" : "/";
    var rel = location.pathname
      .replace(/^\/ko(?=\/|$)/, "")
      .replace(/^\//, "");
    return base + rel + location.search + location.hash;
  }

  function fixLinks() {
    var links = document.querySelectorAll("a[hreflang]");
    for (var i = 0; i < links.length; i++) {
      links[i].setAttribute("href", targetUrl(links[i]));
    }
  }

  // Re-point the language links on every page render, including the SPA-like
  // instant navigations that reset them back to the static roots.
  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(fixLinks);
  } else {
    document.addEventListener("DOMContentLoaded", fixLinks);
    fixLinks();
  }

  // Plain left-click -> full reload to the mirrored page. Modifier and
  // middle clicks fall through to the (already corrected) href so that
  // "open in new tab" still lands on the right page.
  document.addEventListener(
    "click",
    function (ev) {
      var link =
        ev.target && ev.target.closest
          ? ev.target.closest("a[hreflang]")
          : null;
      if (
        !link ||
        ev.button !== 0 ||
        ev.metaKey ||
        ev.ctrlKey ||
        ev.shiftKey ||
        ev.altKey
      ) {
        return;
      }
      ev.preventDefault();
      ev.stopPropagation();
      location.assign(targetUrl(link));
    },
    true
  );
})();
