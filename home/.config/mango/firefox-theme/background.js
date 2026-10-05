// The wallpaper_theme native host sends the theme apply-theme.sh writes, and again on every change
function connect() {
    const port = browser.runtime.connectNative("wallpaper_theme");
    port.onMessage.addListener(theme => browser.theme.update(theme));
    port.onDisconnect.addListener(() => setTimeout(connect, 5000));
}
connect();
