import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI

Item {
  id: root

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0
  property var pluginApi: null

  property bool vpnConnected: false
  property string vpnServer: ""
  property string operation: ""
  property string lastError: ""

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0 && screenName) {
      var widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property string displayMode: widgetSettings.displayMode !== undefined ? widgetSettings.displayMode : (widgetMetadata.displayMode || "alwaysShow")
  readonly property string iconColorKey: widgetSettings.iconColor !== undefined ? widgetSettings.iconColor : (widgetMetadata.iconColor || "none")
  readonly property string textColorKey: widgetSettings.textColor !== undefined ? widgetSettings.textColor : (widgetMetadata.textColor || "none")
  readonly property string connectedColorKey: widgetSettings.connectedColor !== undefined ? widgetSettings.connectedColor : (widgetMetadata.connectedColor || "primary")
  readonly property string disconnectedColorKey: widgetSettings.disconnectedColor !== undefined ? widgetSettings.disconnectedColor : (widgetMetadata.disconnectedColor || "none")
  readonly property string stateColorKey: vpnConnected ? connectedColorKey : disconnectedColorKey
  readonly property string effectiveIconColorKey: stateColorKey !== "none" ? stateColorKey : iconColorKey
  readonly property string effectiveTextColorKey: stateColorKey !== "none" ? stateColorKey : textColorKey
  readonly property bool busy: operation !== ""
  readonly property string statusText: {
    if (operation === "connecting") {
      return "Connecting";
    }
    if (operation === "disconnecting") {
      return "Disconnecting";
    }
    if (vpnConnected) {
      return vpnServer !== "" ? vpnServer : "VPN";
    }
    return "VPN";
  }
  readonly property string statusIcon: busy ? "busy" : (vpnConnected ? "shield-lock" : "shield")
  readonly property string tooltip: {
    if (operation === "connecting") {
      return "Connecting Proton VPN";
    }
    if (operation === "disconnecting") {
      return "Disconnecting Proton VPN";
    }
    if (lastError !== "") {
      return lastError;
    }
    if (vpnConnected) {
      return vpnServer !== "" ? "Proton VPN: " + vpnServer : "Proton VPN connected";
    }
    return "Proton VPN disconnected";
  }

  implicitWidth: pill.width
  implicitHeight: pill.height

  function parseStatus(data) {
    const trimmed = String(data || "").trim();
    if (trimmed === "") {
      vpnConnected = false;
      vpnServer = "";
      return;
    }

    const parts = trimmed.split(":");
    vpnConnected = parts[0] === "1";
    const connName = parts.slice(1).join(":");
    vpnServer = connName.replace(/^ProtonVPN\s+/, "");
  }

  function captureError(data) {
    const trimmed = String(data || "").trim();
    if (trimmed !== "") {
      lastError = trimmed.split("\n")[0].trim();
    }
  }

  function refreshStatus() {
    if (!statusProc.running) {
      statusProc.running = true;
    }
  }

  function connectVpn() {
    if (busy || connectProc.running || disconnectProc.running) {
      return;
    }
    operation = "connecting";
    lastError = "";
    connectProc.running = true;
  }

  function disconnectVpn() {
    if (busy || connectProc.running || disconnectProc.running) {
      return;
    }
    operation = "disconnecting";
    lastError = "";
    disconnectProc.running = true;
  }

  function toggleVpn() {
    if (vpnConnected) {
      disconnectVpn();
    } else {
      connectVpn();
    }
  }

  Process {
    id: statusProc
    running: false
    command: ["sh", "-c", "nmcli -t -f DEVICE,STATE,CONNECTION device status 2>/dev/null | awk -F: 'BEGIN{r=\"0:\"} $1==\"proton0\"{r=($2==\"connected\"?\"1\":\"0\") \":\" $3} END{print r}'"]

    stdout: StdioCollector {
      onStreamFinished: root.parseStatus(text)
    }

    stderr: StdioCollector {
      onStreamFinished: root.captureError(text)
    }

    Component.onCompleted: running = true
  }

  Process {
    id: connectProc
    running: false
    command: ["protonvpn", "connect"]

    stderr: StdioCollector {
      onStreamFinished: root.captureError(text)
    }

    onExited: function (exitCode) {
      if (exitCode === 0) {
        lastError = "";
      }
      operation = "";
      refreshStatus();
    }
  }

  Process {
    id: disconnectProc
    running: false
    command: ["protonvpn", "disconnect"]

    stderr: StdioCollector {
      onStreamFinished: root.captureError(text)
    }

    onExited: function (exitCode) {
      if (exitCode === 0) {
        lastError = "";
      }
      operation = "";
      refreshStatus();
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  BarPill {
    id: pill

    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: Color.resolveColorKeyOptional(root.effectiveIconColorKey)
    customTextColor: Color.resolveColorKeyOptional(root.effectiveTextColorKey)
    icon: root.statusIcon
    text: root.statusText
    autoHide: false
    forceOpen: !isBarVertical && root.displayMode === "alwaysShow"
    forceClose: isBarVertical || root.displayMode === "alwaysHide"
    tooltipText: root.tooltip
    onClicked: root.toggleVpn()
    onRightClicked: {
      if (root.vpnConnected) {
        root.disconnectVpn();
      }
    }
    onMiddleClicked: root.refreshStatus()
  }
}
