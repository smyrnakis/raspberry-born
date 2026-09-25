# Boot report assets

These files implement the reusable boot report documented in
[`chapters/boot-report.md`](../../../chapters/boot-report.md).

The report uses the durable `raspi-notify` queue and has no Python or direct
SMTP dependency. Public IPv4 lookup is enabled by default through Cloudflare's
bounded `/cdn-cgi/trace` request. A lookup failure is reported as `unavailable`
and does not prevent the rest of the report.

Copy `boot-report.conf.example` to the ignored `boot-report.conf` only when
device-specific service or peer checks are needed. The installer defaults to a
read-only check, creates timestamped backups during `--apply`, and does not
enable or start the service.
