<powershell>
pwsh -ExecutionPolicy Unrestricted -NoProfile -File "${postdeploy_script_path}" -ServerUri "${toscaserver_uri}" -DatabaseUri "${database_fqdn}"
</powershell>