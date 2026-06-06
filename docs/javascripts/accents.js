// Tag <body> with the top-level docs area (commands/tips/server) so
// extra.css can pick a Catppuccin accent per area.
(function () {
  const areas = ["commands", "tips", "server"];
  for (const seg of location.pathname.split("/")) {
    if (areas.includes(seg)) {
      document.body.dataset.page = seg;
      return;
    }
  }
})();
