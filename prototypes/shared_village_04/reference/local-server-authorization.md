# Local playtest server authorization

Scott: "fire the docker server up on this system."

Regime: live infrastructure, with Scott's explicit local prototype startup instruction as the exception to PR/CI deployment. Start the existing packaged image through its Compose file on this host, project longwalk-playtest, UDP 7777, persistent named volume. No firewall, DNS or Kubernetes changes. Preserve the first traveler registration for Scott.
