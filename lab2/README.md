
## README Requirements

### 1. The deployment steps, in order: what deploy-web.sh installs, creates and starts.

The `deploy-web.sh` script performs the deployment in the following order:

1. It installs Python 3 using `dnf`.
2. It checks whether the `acs730web` service user exists and creates it if necessary.
3. It creates the `/opt/acs730-web` application directory.
4. It creates the `index.html` web page inside the application directory.
5. It changes the ownership of the application directory to `acs730web`.
6. It copies `acs730-web.service` to `/etc/systemd/system/`.
7. It reloads systemd using `systemctl daemon-reload`.
8. It enables the `acs730-web` service so that it starts automatically at boot.
9. It restarts the `acs730-web` service to start the web application.
10. Finally, it uses `curl` to perform a local check of the web application.

### 2. One sentence on the difference between systemctl start and systemctl enable.

`systemctl start` starts a service immediately, while `systemctl enable` configures the service to start automatically when the system boots.

### 3. Why SSH is restricted to a /32 but HTTP is open to 0.0.0.0/0.

SSH is restricted to the workstation's public IP address using a `/32` CIDR because only the administration workstation needs SSH access to the web server. HTTP is open to `0.0.0.0/0` because the web application needs to be accessible to clients over the Internet.

### 4. Which user the application runs as, and why that is not root.

The application runs as the `acs730web` service user. It does not run as root because a dedicated non-root service account follows the principle of least privilege and reduces the security risk if the application is compromised.

## Experiments

1. start without enable. Run sudo systemctl disable acs730-web, confirm with systemctl is-active that the site is still up,
 then reboot. Predict: what does curl return after the reboot, and what does systemctl status say about why? Re-enable it afterwards.

 I predicted that the service would remain active until the server was rebooted.
 After the reboot, I expected the web application to stop working because the disabled service would not start automatically.

Before the reboot, the service remained `active` even though it was disabled. After the reboot, `curl` returned:

`curl: (7) Failed to connect to 44.196.59.129:80 ... Could not connect to server`

`systemctl status acs730-web` showed that the service was `disabled` and `inactive (dead)`.

Disabling a service does not stop a service that is currently running. It removes its automatic startup configuration, so after the reboot systemd did not start `acs730-web`. I re-enabled and started the service after the experiment, and confirmed that it was `enabled` and `active`.Disabling a service does not stop a service that is currently running. It removes its automatic startup configuration, so after the reboot systemd did not start `acs730-web`.
 I re-enabled and started the service after the experiment, and confirmed that it was `enabled` and `active`

2. Drop the capability

I predicted that the service would fail because the non-root `acs730web` user would not have permission to bind the web server to port 80.
 I expected a permission-related error.

After restarting the service, `systemctl status acs730-web` showed that the service failed with `status=1/FAILURE` and was attempting to restart automatically.

I then checked the service logs with `journalctl -u acs730-web -n 20`. The exact error was:

`PermissionError: [Errno 13] Permission denied`

The traceback showed that the error occurred when Python attempted to bind the socket to port 80.

This experiment shows that a non-root service needs the appropriate capability to bind to a privileged port such as port 80.
 Historically, web servers often started as root because root had permission to bind to privileged ports.
 Using `CAP_NET_BIND_SERVICE` allows the `acs730web` user to bind to port 80 without running the entire application as root.
