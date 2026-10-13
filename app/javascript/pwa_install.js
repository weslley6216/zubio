export function chooseInstallInvite(eventFired, isIOS, isStandalone, isMobile) {
  if (isStandalone) return "hidden"
  if (!isMobile) return "hidden"
  if (eventFired) return "action"
  if (isIOS) return "instructions"
  return "hidden"
}
