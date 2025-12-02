# IMG-Toolkit

Fast, private image compression and conversion tool for Debian/Ubuntu.

## Features

- **Image Compression**: Compress images while maintaining quality
- **Format Conversion**: Convert between JPEG, PNG, ICO, and more
- **Batch Processing**: Process multiple files simultaneously
- **PDF Support**: Extract and convert PDF pages to images
- **Multi-language**: English and German interface
- **Self-hosted**: 100% local processing, no data leaves your server
- **Web Interface**: Modern, responsive web UI
- **CLI Support**: Command-line interface for automation

## Supported Formats

### Verified Formats
- HEIC, HEIF, PNG, JPG, JPEG, ICO, EPS, PSD, PDF

### Additional Supported Formats
All formats supported by Pillow library.

## Installation (Debian/Ubuntu)

### Prerequisites
- Debian 11+ or Ubuntu 20.04+
- Root/sudo access
- At least 2GB RAM
- Internet connection (for downloading dependencies)

### Quick Install

```bash
# Clone the repository
git clone https://github.com/IT-BAER/IMG-Toolkit.git
cd IMG-Toolkit

# Run the installation script
sudo bash install.sh
```

The installation script will:
1. Install system dependencies (Python, Node.js, image libraries)
2. Create a dedicated service user
3. Set up a Python virtual environment
4. Build the frontend
5. Create and enable a systemd service

### Access the Web UI

After installation, access the web interface at:
```
http://localhost:5000
```

Or from another machine:
```
http://YOUR_SERVER_IP:5000
```

## Service Management

```bash
# Check status
sudo systemctl status img-toolkit

# View logs
sudo journalctl -u img-toolkit -f

# Restart service
sudo systemctl restart img-toolkit

# Stop service
sudo systemctl stop img-toolkit

# Start service
sudo systemctl start img-toolkit
```

## CLI Usage

The CLI can be used for batch processing and automation:

```bash
# Activate the virtual environment
source /opt/img-toolkit/venv/bin/activate

# Single file conversion
img-toolkit /path/to/image.jpg /output/directory --quality 80 --width 1920

# Folder batch processing
img-toolkit /input/folder /output/folder --quality 85 --width 800

# Options:
#   --quality   JPEG quality (1-100, default: 85)
#   --width     Resize width while maintaining aspect ratio
#   --debug     Enable verbose logging
#   --json-output  Machine-readable JSON output
```

## Configuration

### Change Port

Edit the systemd service file:
```bash
sudo nano /etc/systemd/system/img-toolkit.service
```

Modify the port in the `ExecStart` line, then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart img-toolkit
```

### Reverse Proxy (nginx)

Example nginx configuration:
```nginx
server {
    listen 80;
    server_name img-toolkit.example.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeouts for large file uploads
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        
        # Increase max upload size
        client_max_body_size 100M;
    }
}
```

## Uninstallation

```bash
cd IMG-Toolkit
sudo bash uninstall.sh
```

## Development

### Local Backend Development

```bash
# Install Python dependencies
pip install -r requirements.txt
pip install -e .

# Run development server
img-toolkit web_dev
```

### Local Frontend Development

```bash
cd frontend
pnpm install
pnpm run dev
```

## Language Support

IMG-Toolkit supports English and German. The language is automatically detected from your browser settings, or you can switch manually using the language toggle in the footer.

## Privacy & Security

- **100% Local Processing**: All image processing happens on your server
- **No Telemetry**: No data collection or analytics
- **Open Source**: Full code transparency
- **Offline Capable**: Works without internet after installation
- **Systemd Hardening**: Service runs with restricted permissions

## Directory Structure

```
/opt/img-toolkit/           # Installation directory
├── backend/                # Python backend
│   └── image_converter/    # Main application
├── frontend/               # Next.js frontend (source)
├── venv/                   # Python virtual environment
├── requirements.txt        # Python dependencies
└── setup.py               # Package configuration
```

## Troubleshooting

### Service won't start

Check the logs:
```bash
sudo journalctl -u img-toolkit -n 50
```

### Permission errors

Ensure proper ownership:
```bash
sudo chown -R img-toolkit:img-toolkit /opt/img-toolkit
```

### Port already in use

Check what's using port 5000:
```bash
sudo lsof -i :5000
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**IMG-Toolkit** - Fast, Private Image Compression & Conversion
