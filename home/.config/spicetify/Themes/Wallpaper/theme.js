// Re-reads colors.css every 2 s, so wallpaper theme switches show without restarting Spotify
(function poll(last) {
    fetch("colors.css?" + Date.now(), { cache: "no-store" })
        .then(r => (r.ok ? r.text() : last))
        .catch(() => last)
        .then(css => {
            if (css && css !== last) {
                let el = document.getElementById("wallpaper-colors");
                if (!el) {
                    el = document.createElement("style");
                    el.id = "wallpaper-colors";
                    document.head.appendChild(el);
                }
                el.textContent = css;
            }
            setTimeout(() => poll(css), 2000);
        });
})("");
