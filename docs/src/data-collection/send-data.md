# How to send us your results!

The main goal of this tool is to stresstest your computer or baremetal server, and send the results to Energizta collaborative database. It will also send the hardware and OS.

```bash
sudo ./energizta.sh --stresstest --send-to-db
```

The data sent to the collaborative database should be completely anonymous and should not be enough to identify your computer or server (no hostname, no IP, no MAC, etc.). The script will display and ask you for confirmation before sending data.
