Omni-Sentinel V21.3 - Ultimate Edition
Omni-Sentinel is a high-fidelity cybersecurity platform designed for automated vulnerability scanning, network reconnaissance, and threat detection. It leverages a distributed architecture using FastAPI for the API, Celery for asynchronous task execution, and Redis as a message broker. 
 
🚀 Features
Automated Scanning: Integrated support for Nmap (port scanning), Feroxbuster (recursive content discovery), and ExploitDB (vulnerability matching).
Vulnerability Lookup: Direct integration with the NVD NIST API for real-time CVE data.
Multi-User Auth: Secure JWT-based authentication with role-based access control (RBAC).
Visual Evidence: Automated screenshot capture for discovered web services and detailed scan timelines.
Dockerized Deployment: Simplified setup using Docker and Docker Compose for easy scaling. 
Microsoft Learn
Microsoft Learn
 +6
🛠️ Project Structure
text
~/omni-sentinel-v21.3/
├── core/           # Database engine, Auth, and Worker logic
├── dashboard/      # FastAPI application and API routes
├── plugins/        # CVE lookup and custom scan modules
├── output/         # SQLite database and scan results
└── screenshots/    # Captured evidence from web scans

⚙️ Quick Start
1. Prerequisites
Ensure your system has Docker and Docker Compose installed.
2. Deploy
Run the deployment script provided in the main repository:
bash
chmod +x deploy.sh
./deploy.sh

3. Start Services
Navigate to the base directory and spin up the containers: 
GitHub
GitHub
 +1
bash
cd ~/omni-sentinel-v21.3
docker-compose up -d --build
Use code with caution.

4. Access the Platform
API/Backend: http://localhost:8000
Web UI: http://localhost:5173
📝 Configuration
The deployment script generates a .env file in the $BASE directory. You can manually add your NVD_API_KEY there to increase rate limits for CVE lookups.
Variable	Description
SECRET_KEY	Used for JWT token signing.
DB_PATH	Path to the SQLite database.
ADMIN_PASSWORD	Generated password for the initial admin account.
MAX_CONCURRENT_SCANS	Limit for simultaneous worker tasks.
