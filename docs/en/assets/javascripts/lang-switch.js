/*
 * Keep the reader on the same page when they switch languages.
 *
 * The English (/) and Korean (/ko/) builds mirror each other page for page,
 * but the language selector links are static (/ and /ko/), so by default a
 * switch always jumps to the overview. Here we swap only the language prefix
 * of the current path instead.
 *
 * A full reload (not instant navigation) is used on purpose: switching
 * language must also switch <html lang>, the search index, and the nav tree,
 * none of which instant navigation swaps cleanly.
 */
(function () {
  function targetUrl(link) {
    var base = link.getAttribute("hreflang") === "ko" ? "/ko/" : "/";
    var rel = location.pathname
      .replace(/^\/ko(?=\/|$)/, "")
      .replace(/^\//, "");
    return base + rel + location.search + location.hash;
  }

  function langLink(ev) {
    return ev.target && ev.target.closest
      ? ev.target.closest("a[hreflang]")
      : null;
  }

  // Keep the href accurate for hover preview, middle-click, right-click
  // "copy link", and keyboard focus.
  ["pointerover", "focusin", "pointerdown"].forEach(function (type) {
    document.addEventListener(
      type,
      function (ev) {
        var link = langLink(ev);
        if (link) link.setAttribute("href", targetUrl(link));
      },
      true
    );
  });

  // Force a full reload on a plain left-click so the language switches cleanly.
  // Modifier/middle clicks fall through to the (already corrected) href.
  document.addEventListener(
    "click",
    function (ev) {
      var link = langLink(ev);
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
